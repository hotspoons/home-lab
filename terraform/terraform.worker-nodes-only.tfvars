# VM setup
storage_pool_path       = "/media/nvme/vms/k8s"
image_path              = "/media/nvme/images/Rocky-8-GenericCloud-LVM.latest.x86_64.qcow2"
remote_host             = "qemu+ssh://file-server.lan"
compute_name            = "gpu-hosts"
memory                  = "8192"
memory_per_node         = ["24576", "8192", "8192"]
instance_count          = 3
cpu_cores               = 24
gpu_nodes               = ["0", "", ""]
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
external_dns_ip         = "192.168.1.201"

