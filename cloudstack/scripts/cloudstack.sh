#!/bin/bash
if ! [ -s ".env" ]; then
  echo ".env file does not exist, cannot continue. Did you copy \".env.example\" to \".env\" and modify it per the instructions?"
  exit 1
fi


## Read in .env file
export $(grep -v '^#' .env | xargs)

## local substitutions
AUTOMATION_URL="http://$IP:8080/client/"

## Start MySQL server, set password
systemctl start mysqld.service
systemctl enable mysqld
mysql -uroot -Bse "FLUSH PRIVILEGES;  ALTER USER root@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PW'; CREATE USER '$MYSQL_CS_UN'@'localhost' IDENTIFIED BY '$MYSQL_CS_PW'; FLUSH PRIVILEGES; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_CS_UN'@'localhost'  WITH GRANT OPTION; "

## Setup CloudStack
cloudstack-setup-databases $MYSQL_CS_UN:$MYSQL_CS_PW@localhost --deploy-as=root:$MYSQL_ROOT_PW -i localhost
cloudstack-setup-management
firewall-cmd --zone=public --permanent --add-port={8080,8250,8443,9090}/tcp
firewall-cmd --reload

/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m $CLOUDSTACK_NFS -u http://download.cloudstack.org/systemvm/$CLOUDSTACK_VERSION/systemvmtemplate-$CLOUDSTACK_VERSION.0-kvm.qcow2.bz2 -h kvm -F



service cloudstack-management restart

## Sometimes cloudstack database gets corrupted on first start. Re-initialize, then restart again
cloudstack-setup-databases $MYSQL_CS_UN:$MYSQL_CS_PW@localhost --deploy-as=root:$MYSQL_ROOT_PW -i localhost
## Enable Kubernetes support in CloudStack
mysql -uroot -p$MYSQL_ROOT_PW  -Bse "USE cloud; UPDATE configuration SET value='true' WHERE name= 'cloud.kubernetes.service.enabled'"
service cloudstack-management restart

# Install cloudmonkey, used to automate initial zone setup not available in terraform tools
curl -o /usr/bin/cmk -L https://github.com/apache/cloudstack-cloudmonkey/releases/download/6.2.0/cmk.linux.x86-64
chmod +x /usr/bin/cmk

CLOUDSTACK_UP=""
# Wait for cloudstack to bootstrap. We will poll up to 5 minutes here every few seconds to see if it is online or not
for i in {1..60}; do
  CLOUDSTACK_UP=$(curl -o /dev/null -s -w "%{http_code}\n" $AUTOMATION_URL | grep 200)
  if [ -n $CLOUDSTACK_UP ]; then
    break
  fi
  sleep 5
done

if [ -n $CLOUDSTACK_UP ]; then
  # And because there doesn't seem to be a practical way to generate API key and secret from a command line, we will cheat and use some UI automation so this can be fully automated
  cd ui-automation
  npm install
  npm run -s cypress:run -- --env username=$USERNAME,password=$PASSWORD,url=$AUTOMATION_URL
  cd ..

  #bash ./zonesetup.sh

fi


