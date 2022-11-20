# Home Lab
This is my home lab infrastructure provisioning script, and IaC for setting up basic private cloud resources. This 
is intended to be run on a fresh Rocky 8 host with plenty of RAM and CPU. If attempting to "inception" this in a VM, 
make sure you have the VM connected to the host's network in full bridged network mode or this won't work.

# CloudStack
I am using the latest version of Apache CloudStack to provide a "cloud in a box". CloudStack installation is 
unfortunately a painstakingly manual effort with a lot of error prone steps - my goal is to 100% automate this 
otherwise finnicky installation using a combination of shell scripts, cmk (CloudStack CLI tool), and unfortunately 
UI automation using NodeJS and Cypress, since there appears to be no way to programmaticly fetch API and secret keys 
from CloudStack.

After CloudStack is installed, I will use Terraform to start configuring CloudStack resources, such as templates,
compute instances.

# Requirements
- An AMD or Intel x64-based host with virtualization acceleration enabled, or VM host of same class
- Plenty of RAM and disk space
- Rocky 8 or other 8th generation enterprise Linux freshly installed on host or VM with connectivity to Internet (and bridge to host network if applicable)

# Cloud-In-A-Box Installation
Installation is pretty straight forward - follow these steps on a new, freshly loaded Rocky 8 Linux host
that is connected to the internet:

1. Download this repo and prepare to run it by creating an environment (`.env`) file:

```shell
curl -L -o home-lab-main.zip https://github.com/hotspoons/home-lab/archive/refs/heads/main.zip && unzip home-lab-main.zip && cd home-lab-main/cloudstack/scripts && ./create_env.sh
```

2. Edit the generated ".env" file and set values specific to your environment - at a minimum
update `NMASK`, `POD_IP_START`, and `POD_IP_END` to match your environment, and verify the inferred values for 
`NIC`, `IP`, `GW`, and `DNS` are correct in the generated .env file. If you wish to use a different host for NFS mounts, 
provide those values in `PRI_NFS`, `PRI_MNT`, `SEC_NFS`, `SEC_MNT`
3. Run `./cloud_in_a_box.sh`
4. If you wish to change the IP address of `cloudbr0`, do that now. Restart the host.

*DO NOT RUN THIS SCRIPT ON A HOST YOU CARE ABOUT, THIS WILL FUNDAMENTALLY ALTER THE NATURE OF THE HOST AND IT WILL BE UNSUITABLE FOR MANY PURPOSES*