# VM setup

remote_host             = "qemu+ssh://file-server.lan"
compute_name            = "rocky-gpu-hosts"
memory                  = "8192"
memory_per_node         = ["16384", "24576"]
instance_count          = 2
cpu_cores               = 24
gpu_nodes               = ["","0"]
network_bridge          = "br0"
root_password           = "changeme"
domain                  = "siomporas.com"
el_version              = "8"

# Kubernetes settings
join_cmd_url           = "https://rocky-k8s-hosts-0.siomporas.com:8000/1234/join_kubernetes_cluster.sh"
base_arch               = "x86_64"
aarch                   = "amd64"
containerd_version      = "1.6.24-3.1.el8"
helm_version            = "3.12.3"
gitlab_helmchart_version= "7.4.1"
kubernetes_version      = "1.28.2"
ssh_authorized_keys     = [
]
ssh_keys                = {
}
