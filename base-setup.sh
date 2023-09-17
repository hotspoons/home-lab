#!/bin/bash
### Utility script to configure cloudflare dynamic DNS, letsencrypt wildcard TLS, and other 
### prerequisites for a nice home lab environment
export LE_LAUNCHER=/opt/bin/le.sh
export LE_WILDCARD_LAUNCHER=/etc/letsencrypt/wildcard.sh
export CLOUDFLARE_DNS_UPDATE=/opt/bin/cloudflare-dns.sh
export CLOUDFLARE_CREDENITALS=/etc/letsencrypt/cloudflare-credentials
export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if ! [[ -f "$SCRIPT_DIR/.env" ]]; then
  echo ".env file does not exist. Please copy .env.example to .env, fill in missing values, and try again"
  exit 1
fi
## Read in .env file
export $(grep -v '^#' $SCRIPT_DIR/.env | xargs)

mkdir -p /etc/letsencrypt
mkdir -p /opt/bin
dnf update -y
dnf install -y yum-utils docker-ce wget git
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

wget https://github.com/K0p1-Git/cloudflare-ddns-updater/raw/main/cloudflare-template.sh -O $CLOUDFLARE_DNS_UPDATE
sed -i "s/auth_email=\"\"/auth_email=\"$AUTH_EMAIL\"/g" $CLOUDFLARE_DNS_UPDATE
sed -i "s/auth_method=\"token\"/auth_method=\"global\"/g" $CLOUDFLARE_DNS_UPDATE
sed -i "s/auth_key=\"\"/auth_key=\"$AUTH_KEY\"/g" $CLOUDFLARE_DNS_UPDATE
sed -i "s/zone_identifier=\"\"/zone_identifier=\"$ZONE_IDENTIFIER\"/g" $CLOUDFLARE_DNS_UPDATE
sed -i "s/record_name=\"\"/record_name=\"$DOMAIN\"/g" $CLOUDFLARE_DNS_UPDATE
chmod +x $CLOUDFLARE_DNS_UPDATE

echo "#!/bin/bash" >> $LE_LAUNCHER
echo "docker run -it --entrypoint $LE_WILDCARD_LAUNCHER --rm --name certbot -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/lib/letsencrypt:/var/lib/letsencrypt" certbot/dns-cloudflare" >> $LE_LAUNCHER

echo "#!/bin/sh" >> $LE_WILDCARD_LAUNCHER
echo "if [[ ! -f \"/etc/letsencrypt/live/$DOMAIN/cert.pem\" ]]; then" >> $LE_WILDCARD_LAUNCHER
echo "  certbot certonly --dns-cloudflare --dns-cloudflare-credentials $CLOUDFLARE_CREDENITALS -d $DOMAIN d *.$DOMAIN -v" >> $LE_WILDCARD_LAUNCHER
echo "else" >> $LE_WILDCARD_LAUNCHER
echo "  certbot renew --dns-cloudflare --dns-cloudflare-credentials $CLOUDFLARE_CREDENITALS -v" >> $LE_WILDCARD_LAUNCHER
echo "fi" >> $LE_WILDCARD_LAUNCHER

echo "dns_cloudflare_email = $AUTH_EMAIL" >> $CLOUDFLARE_CREDENITALS
echo "dns_cloudflare_api_key = $AUTH_KEY" >> $CLOUDFLARE_CREDENITALS

chmod +x $LE_LAUNCHER
chmod +x $LE_WILDCARD_LAUNCHER
chmod 600 $CLOUDFLARE_CREDENITALS

echo "@daily $LE_LAUNCHER" >> /etc/crontab
echo "@hourly $CLOUDFLARE_DNS_UPDATE" >> /etc/crontab

