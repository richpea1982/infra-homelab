terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1" # NOTE: device_passthrough support and its exact
                          # schema have moved fast in this provider (it only
                          # landed after Proxmox VE 8.2 added the underlying
                          # API). Confirm 0.94.0 actually documents
                          # device_passthrough before applying — if not,
                          # this module needs a version bump, which is a
                          # root-level decision since it's pinned repo-wide
                          # in your existing terraform/versions.tf.
    }
  }
}
