# K3s Cluster Bootstrap — README

This document covers the minimum steps required to provision, configure, and recover a 3-node HA K3s cluster using the Ansible playbook.

---

1. Prerequisites

VM Infrastructure
- Ensure k3s-pve2, k3s-pve3, and k3s-pve4 have been provisioned by Terraform.
- Verify target IPs in ansible/hosts/hosts.ini belong to VLAN20 (10.0.20.21–23).

Shared Cluster Token
Generate a 32-character hexadecimal token and save it into your encrypted vault:

openssl rand -hex 32
ansible-vault edit ansible/group_vars/all/vault.yml

Add to vault:
vault_k3s_cluster_token: "<your_generated_token>"

---

2. Bootstrapping a Fresh Cluster

Clean Up Prior Installs (If Retrying)
Run these commands on any node with a failed or partial installation before starting:

sudo /usr/local/bin/k3s-uninstall.sh
sudo rm -f /etc/rancher/k3s/cluster-initialized

Run the Playbook
Execute the deployment playbook from the root ansible/ directory using the symlink:

cd ansible/
ansible-playbook -i hosts/hosts.ini deploy_k3s.yml

Do not target playbooks/deploy_k3s.yml directly, or variables will not load.

---

3. Manual Steps After Deploying

Confirm Node States
kubectl get nodes -o wide

Verify Virtual IP VIP
curl -k https://10.0.20.20:6443/readyz
(A 401 Unauthorized response is the expected healthy signal.)

Register GitHub Deploy Key
sudo cat /etc/ansible-secrets/argocd_k3s_deploy.pub
Add the public key as a read-only Deploy Key in your repository settings.

Verify GitOps Sync
kubectl -n argocd get applications

---

4. Gotchas to Watch Out For

- Token Mismatches: All joining nodes must use the same token as the init node.
- Rejoin Logic Guard: The rejoin task uses a when: cluster_exists | default(false) guard to avoid failures when the VIP is not yet up.
- Playbook Targets: Ensure roles target hosts: k3s_cluster and are not attached to the localhost SSH-key play.
- NIC Configuration: kube-vip is hardcoded to eth0; update if your VM template or NIC naming differs.
- Local-Path StorageClass Warnings: A cosmetic error in journalctl -u k3s about Delete vs Retain is expected and safe to ignore.
- etcd-s3 Insecure Flag: For HTTP-only MinIO backends set etcd-s3-insecure: "true" rather than skipping validation.
- S3 Snapshot Syncs: Failed etcd backups do not retry continuously; they reconcile and sync the backlog on the next successful snapshot.
