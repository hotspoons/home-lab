#!/bin/bash

### STEP 1 - install Rocky 8, set a static IP
### STEP 2 - copy the file ".env.example" to ".env"; set values specific to your environment - at a minimum NIC, IP, GW, DNS, VM_HOST_UN, VM_HOST_PW, NMASK, 
#####               And the following if you don't want to use the default setup for data: PRI_NFS, PRI_MNT, SEC_NFS, SEC_MNT

### STEP 3 - run this script
### STEP 4 - any hardware or environment-specific customizations to the OS setup, such as importing NFS mounts, setting up a RAID, etc. should be done before:
### STEP 5 - run cloudstack.sh 
### STEP 6 - log into the web GUI on http://host-ip-or-name:8080/client/#/user/login?redirect=%2F (username: admin, password: password) -> 
#####              Accounts -> View Users (middle pane) -> admin -> generate keys (button in upper right) -> okay -> 
#####              copy api key and secret keys to .env file, API_KEY and SECRET_KEY values respectively
### STEP 7 - run zonesetup.sh

dnf install nfs-utils -y
dnf -y upgrade --refresh

