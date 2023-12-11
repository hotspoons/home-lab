ssh_authorized_keys     = [
    "ssh-rsa ...= root@vm-host.siomporas.com"
    ]
# cat ~/.ssh/id_rsa | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' | jq -R
ssh_keys                = {
    "ed25519_private"   = "-----BEGIN OPENSSH PRIVATE KEY-----\\nb3Bl..."
    "ed25519_public"    = "ssh-rsa AAAAB3NzaC1yc2EAAA...."
}