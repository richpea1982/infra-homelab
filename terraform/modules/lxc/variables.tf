variable "hostname"       { type = string }
variable "node_name"      { type = string }
variable "vmid"           { type = number }
variable "unprivileged"   { type = bool }
variable "cores"          { type = number }
variable "memory"         { type = number }
variable "disk_size"      { type = number }
variable "datastore_id"   { type = string }
variable "ip"             { type = string }
variable "gateway"        { type = string }
variable "vlan_id"        { type = number }
variable "ssh_public_key" { type = string }

variable "template_file_id" {
  type        = string
  description = "e.g. proxmox_virtual_environment_download_file.<x>.id, or local:vztmpl/<filename>. Debian point-release template filenames change (13.0-1 -> 13.1-1 -> 13.1-2 already seen in 2025-2026) — verify via `pveam available -section system | grep debian` before applying if a download 404s."
}

variable "mount_nfs" {
  description = "Whether this container needs the 'nfs' feature enabled so it can mount NAS exports from inside the guest OS (shared kernel — no separate NFS client VM needed)."
  type        = bool
  default     = false
}

variable "device_passthrough" {
  description = <<-EOT
    Optional host devices to pass through (e.g. iGPU render node for hardware
    transcoding). Only meaningful for privileged containers in this setup —
    unprivileged containers would need explicit idmap entries too, which we're
    deliberately not using here (see Ansible/Terraform notes).

    KNOWN PROVIDER GOTCHA (bpg/proxmox — GitHub issue #1721): device_passthrough
    has historically only taken effect on a resource *update*, not on initial
    create. If `terraform apply` creates the container but `/dev/dri` is empty
    inside it, run `terraform apply` a second time (a no-op plan that still
    pushes the update) or check whether this is fixed in your pinned provider
    version before assuming something else is wrong.
  EOT
  type = list(object({
    path = string
    uid  = optional(number, 0)
    gid  = optional(number, 0)
    mode = optional(string, "0660")
  }))
  default = []
}
