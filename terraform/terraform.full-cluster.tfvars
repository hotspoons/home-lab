# VM setup

storage_pool_path       = "/media/nvme/vms/k8s"
image_path              = "/media/nvme/images/Rocky-8-GenericCloud-LVM.latest.x86_64.qcow2"
remote_host             = "qemu+ssh://file-server.lan"
compute_name            = "rocky-k8s-hosts"
memory                  = "8192"
memory_per_node         = ["8192", "65536", "65536"]
instance_count          = 3
cpu_cores               = 8
gpu_nodes               = ["","","0 1 2"]
network_bridge          = "ovirtmgmt"
root_password           = "changeme"
domain                  = "siomporas.com"
el_version              = "8"

# Kubernetes settings
join_cmd_url           = ""
cloudflare_email        = "richietommy@yahoo.com"
cert_full_chain         = "/etc/letsencrypt/live/siomporas.com/fullchain.pem"
cert_cert               = "/etc/letsencrypt/live/siomporas.com/cert.pem"
cert_private_key        = "/etc/letsencrypt/live/siomporas.com/privkey.pem"
nfs_server              = "vm-host.siomporas.com"
nfs_path                = "/nfs/exports/kubernetes"
nfs_provision_name      = "siomporas.com/nfs"
pi_hole_server          = "pi.hole"
start_ip                = "192.168.1.207"
end_ip                  = "192.168.1.246"
vip_ip                  = "192.168.1.206"
base_arch               = "x86_64"
aarch                   = "amd64"
containerd_version      = "1.6.24-3.1.el8"
helm_version            = "3.12.3"
gitlab_helmchart_version= "7.4.1"
kubernetes_version      = "1.28.2"
external_dns_ip         = "192.168.1.201"
external_dns_suffix     = ""
gitlab_ip               = "192.168.1.220"
workloads_on_control_plane = false
setup_vip_lb            = true
setup_nfs_provisioner   = true
setup_tls_secrets       = false
setup_cert_manager      = true
setup_gitlab            = true
setup_pihole_dns        = true
setup_dev_tools         = true
setup_wasm              = false 


