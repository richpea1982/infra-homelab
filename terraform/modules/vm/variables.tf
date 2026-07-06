variable "hostname"       { type = string }
variable "node_name"      { type = string }
variable "vmid"           { type = number }
variable "ip"             { type = string }
variable "gateway"        { type = string }
variable "cores"          { type = number }
variable "memory"         { type = number }
variable "disk_size"      { type = number }
variable "datastore_id"   { type = string }
variable "ssh_public_key" { type = string }

variable "image_url" {
  type    = string
  default = "https://cloud.debian.org/images/cloud/trixie/20260623-2518/debian-13-genericcloud-amd64-20260623-2518.qcow2"
}
