# Testing the New etcd Restore Path Locally (Ubuntu, multipass, no prod contact)

Goal: validate Path C (`restore.yml`) end-to-end without ever pointing it
at production MinIO credentials, the production S3 bucket in write mode,
or the live cluster. This mirrors the "scratch environment for risky
experiments" principle already used elsewhere in this repo.

## 1. VMs

```bash
sudo snap install multipass
multipass launch --name k3s-test1 --cpus 2 --memory 4G --disk 20G jammy
# optional, only needed if you also want to test multi-node rejoin
# rather than just the restore mechanism itself:
multipass launch --name k3s-test2 --cpus 2 --memory 4G --disk 20G jammy
multipass launch --name k3s-test3 --cpus 2 --memory 4G --disk 20G jammy
multipass list   # note the assigned IPs
```

3 × 4GB comfortably fits in 32GB alongside a MinIO container and your
normal desktop use.

## 2. Throwaway local MinIO — never prod

```bash
docker run -d --name minio-test \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=testuser \
  -e MINIO_ROOT_PASSWORD=testpassword123 \
  -v ~/minio-test-data:/data \
  minio/minio server /data --console-address ":9001"
```

Find your Ubuntu host's real LAN IP (`ip addr` — something like
`192.168.x.x` or your homelab's DHCP range) — the multipass VMs reach
the host over its bridge, **not** `127.0.0.1`.

## 3. Copy (read-only) a real snapshot in, from prod

```bash
# Read-only against prod — never write here
mc alias set prod http://10.0.10.15:9000 <MINIO_ROOT_USER> <MINIO_ROOT_PASSWORD>
mc ls prod/k3s-etcd-snapshots/
mc cp prod/k3s-etcd-snapshots/<snapshot-name> ./snapshot-copy

# Push into the local, disposable MinIO instead
mc alias set testminio http://<ubuntu-host-lan-ip>:9000 testuser testpassword123
mc mb testminio/k3s-etcd-snapshots
mc cp ./snapshot-copy testminio/k3s-etcd-snapshots/<snapshot-name>
```

## 4. Scratch inventory + vars

Create a throwaway `test-hosts.ini`:

```ini
[k3s_cluster]
k3s-test1 ansible_host=<multipass-ip-1> k3s_node_index=1

[k3s_cluster:vars]
ansible_user=ubuntu
```

(Add test2/test3 with `k3s_node_index=2`/`3` if testing rejoin too.)

Run against it with **dummy** credentials, never the real vault file:

```bash
ansible-playbook -i test-hosts.ini deploy_k3s.yml \
  -e k3s_restore_from_snapshot=true \
  -e k3s_restore_snapshot_name=<snapshot-name> \
  -e vault_minio_root_user=testuser \
  -e vault_minio_root_password=testpassword123 \
  -e etcd_s3_endpoint=<ubuntu-host-lan-ip>:9000 \
  -e vault_k3s_cluster_token=<any-throwaway-32-char-hex> \
  -e k3s_api_server=<multipass-ip-1>
```

(`k3s_api_server` normally points at the kube-vip VIP; for a single-node
mechanism test it's fine to point it at the node's own IP — kube-vip
just won't have anywhere meaningful to float to with only one node up.)

## 5. Verify

```bash
multipass exec k3s-test1 -- sudo kubectl get nodes -o wide
multipass exec k3s-test1 -- sudo kubectl get pods -A
```

You should see Kubernetes objects reappear (Deployments, PVC
definitions, Secrets) from whatever was in the snapshot. **PVCs will not
actually bind** — there's no Ceph in this scratch environment — so don't
read stuck PVC binding as a failure of this test; the thing being
validated here is the restore mechanism and Ansible's handling of it
(stale-state cleanup, the one-shot `--cluster-reset` flag removal, kube-vip
manifest placement), not full workload health.

## What this test does NOT cover

The Ceph RBD stale-lock behavior flagged in `restore.yml` can only be
observed against real Ceph, since there's no Ceph in this scratch setup.
Treat a clean pass here as "the automation itself works," not as full
proof the whole DR story is closed — the Ceph side still needs a
deliberate, low-blast-radius test against real hardware before you'd
call this fully proven.

## Teardown

```bash
multipass delete k3s-test1 k3s-test2 k3s-test3 --purge
docker rm -f minio-test
rm -rf ~/minio-test-data
```
