# Home Lab
This is my home lab infrastructure provisioning script, and IaC for setting up basic private cloud resources. This 
is intended to be run on a fresh Rocky 8 host with plenty of RAM and CPU. If attempting to "inception" this in a VM, 
make sure you have the VM connected to the host's network in full bridged network mode or this won't work.

If this runs correctly, you will have a fully functional Kubernetes cluster with MetalLB and valid SSL certificates
from LetsEncrypt.

## Prerequisities
- A domain, like `siomporas.com`
- Global auth key from free DNS service with [CloudFlare](https://www.cloudflare.com/plans/free/)
- A [pi hole](https://pi-hole.net/) or other DNS server that also services DHCP, with a sub-domain configured for
DHCP host, e.g. `lan.siomporas.com`
- An AMD or Intel x64-based host with virtualization acceleration enabled, or VM host of same class
    - TODO make this work on ARM, RISC-V
- Plenty of RAM and disk space
- Rocky 8 or other 8th generation enterprise Linux freshly installed on host or VM with connectivity to Internet (and bridge to host network if applicable)
- An NFS server (or use the provided script to configure one on your VM host)

## libvirt
I am using `libvirt` with a corresponding Terraform provider to simplify setup and provisioning of virtualized compute
without a lot of overhead. I had tried this before with OVirt and CloudStack, and both tools got in the way and didn't
provide much if any real additional value over controlling the underlying virtualization directly. 

Example compute settings are in `terraform/terraform.tfvars.example` - copy this file to `terraform/terraform.tfvars` 
and provide your own values.

## SSL
TODO
 - Document TLS/DNS certbot setup using CloudFlare DNS. This is a nice and simple way to get a real certificate for
 running local workloads
 - Document how to pass in certificates and private keys to the TF vars

## Kubernetes
TODO
 - Document Kubernetes setup


