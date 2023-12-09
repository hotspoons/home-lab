export INTERFACE=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')
export ROUTE=$(ip route show default 0.0.0.0/0 | awk '{print $3}')     #TODO DHCP
export IP_ADDR=$(hostname -i)                                          #TODO DHCP
export NS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}') #TODO DHCP
# How large you want each compute node's disk to be
export INSTANCE_DISK_SIZE=400G
# Where to put the storage pool for the VMs
export TF_VAR_storage_pool_path=/media/nvme/vms/k8s
# Where the base EL8 image for your VMs will reside. This must be LVM, and will be downloaded below
export TF_VAR_image_path=/media/nvme/images/Rocky-8-GenericCloud-LVM.latest.x86_64.qcow2
# How many compute nodes for your cluster? You will need CPU, storage and RAM to match
export TF_VAR_instance_count=2
# The domain for which you have a TLS certificate and/or CloudFlare DNS configured, TLD for all deployments
export TF_VAR_domain=siomporas.com
# If you want to add GPUs to specific compute nodes, do it here
export TF_VAR_gpu_nodes= ["", "0"]
# Run `export JOIN_CMD_SALT=1234; export MASTER_HOSTNAME=$(hostname);`, then this: 
#   https://github.com/hotspoons/home-lab/blob/6f2f4f2a4c45e73b4fe1e4ddf902e756439193df/terraform/templates/k8s_master_configure.tftpl#L80-L114
# on master, and capture the last line of output and put it below
export TF_VAR_join_cmd_url=https://rocky-k8s-hosts-0.siomporas.com:8000/1234/join_kubernetes_cluster.sh