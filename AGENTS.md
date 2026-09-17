# infra-homelab

Terraform + Ansible IaC for a 5-node Proxmox homelab. Terraform (bpg/proxmox)
provisions VMs/LXCs; Ansible configures them (K3s bootstrap, NAS, monitoring,
DR automation). Workloads live in the separate k3s repo.

## Layout
- terraform/   root module + modules/vm, modules/lxc; S3/MinIO backend
- ansible/     playbooks/, roles/, hosts/hosts.ini, group_vars (vault)
- docker-images/portfolio   Jekyll portfolio container
- docs/infra-notes/         IPs.txt, infra.md, DR guides

## Conventions
- Terraform: bpg/proxmox, cloud-init image + vendor-data, modules for repeatable units.
- Ansible: playbooks in playbooks/; roles under roles/; secrets only in vault.yml.
- No generated artifacts committed (repomix-output.xml, *.swp, *.bak). See #21.
- Run: ansible-lint, yamllint, ansible-playbook --syntax-check, terraform fmt -check + validate.
- This repo may lag reality vs the live cluster — docs/infra-notes/ has stale copies;
  verify against Proxmox/k3s before trusting.