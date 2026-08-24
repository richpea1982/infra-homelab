media_lxc = {
  jellyfin = {
    hostname     = "jellyfin"
    node_name    = "pve2"
    vmid         = 3010
    unprivileged = false # privileged — WireGuard/Tailscale-only exposure, no
                          # public attack surface, and it removes the idmap
                          # GID-mapping step for the iGPU render group.
    cores     = 3
    memory    = 6144
    disk_size = 20 # OS only — media library lives on NFS from the NAS, not here
    datastore = "local-lvm"
    ip        = "10.0.30.10/24"
    gateway   = "10.0.30.1"
    vlan_id   = 30
    device_passthrough = [
      { path = "/dev/dri/card1" },
      { path = "/dev/dri/renderD128" }
    ]
  }
  # Photoprism moved to K3s (gitops/apps/photoprism.yaml in the k3s repo) —
  # it never needed pve2-specific GPU pinning, only Jellyfin did. Removed
  # from here rather than left as a second, now-pointless static LXC.
}
