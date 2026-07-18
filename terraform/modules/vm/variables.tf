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
variable "image_checksum" {
  type    = string
  default = "df2bd468b08566c0409a7982d6489d73499ad22f9a28646b538c2f21d08f15040a5e4737952ca209e9ad4488cd00793191791be9f135dee93082c86fcca3300c"
}
variable "vlan_id" {
  type    = number
  default = null
}
