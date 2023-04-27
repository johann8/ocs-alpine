<h1 align="center">OCS Inventoryi NG</h1>
<p align='justify'>
<a href="https://ocsinventory-ng.org)">OCS</a> (Open Computers and Software Inventory Next Generation) is an assets management and deployment solution.
Since 2001, OCS Inventory NG has been looking for making software and hardware more powerful.
OCS Inventory NG asks its agents to know the software and hardware composition of every computer or server.
</p>

- [OCS Inventory Docker Image](#ocs-inventory-docker-image)
- [Install OCS Inventory NG](#install-ocs-inventory-ng)
  - [Setup Plugins](#setup-plugins)
  - [Configuration](#configuration)
  - [Restapi](#restapi)
  - [Manage](#manage)
  - [Inventory](#inventory)
- [Install ocsinventory client on CentOS/Rocky/Oracle](#install-ocsinventory-client-on-centosrockyoracle)
- [Install ocsinventory client on Debian/Ubuntu](#install-ocsinventory-client-on-debianubuntu)

## OCS Inventory Docker Image
| pull | size alpine | version | platform |
|:---------------------------------:|:----------------------------------:|:--------------------------------:|:--------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/alpine-ocs?style=flat-square) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/alpine-ocs/latest) | [![](https://img.shields.io/docker/v/johann8/alpine-ocs?sort=date)](https://hub.docker.com/r/johann8/alpine-ocs/tags "Version badge") | ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") |

## Install OCS Inventory NG

- create folders

```bash
DOCKERDIR=/opt/ocs
mkdir -p ${DOCKERDIR}/data/ocsinventory/{perlcomdata,ocsreportsdata,varlibdata,httpdconfdata} 
mkdir -p ${DOCKERDIR}/data/mariadb/{config,dbdata,socket}
mkdir -p ${DOCKERDIR}/data/nginx/{config,certs,auth}
chown -R 101:101 ${DOCKERDIR}/data/ocsinventory/perlcomdata/
chown -R 101:101 ${DOCKERDIR}/data/ocsinventory/ocsreportsdata/
chown -R 101:101 ${DOCKERDIR}/data/ocsinventory/varlibdata/
cd ${DOCKERDIR}
tree -d -L 3 ${DOCKERDIR}
```

- Download config files
```bash
DOCKERDIR=/opt/ocs
cd ${DOCKERDIR}
wget https://raw.githubusercontent.com/johann8/ocs-alpine/master/docker-compose.yml
wget https://raw.githubusercontent.com/johann8/ocs-alpine/master/docker-compose.override.yml
wget https://raw.githubusercontent.com/johann8/ocs-alpine/master/.env
wget https://raw.githubusercontent.com/johann8/ocs-alpine/master/nginx/config/ocsinventory.conf.template
mv ocsinventory.conf.template data/nginx/config
```

- Generate a self-signed certificate for server `ocsinventory.mydomain.de`

```bash
# Generate private key
openssl genrsa -out /etc/pki/tls/private/ca.key 2048 

# Generate CSR (Common Name is ocsinventory.mydomain.de)
openssl req -new -key /etc/pki/tls/private/ca.key -out /etc/pki/tls/private/ca.csr

# Generate Self Signed Key
openssl x509 -req -days 3650 -in /etc/pki/tls/private/ca.csr -signkey /etc/pki/tls/private/ca.key -out /etc/pki/tls/certs/ca.crt
openssl x509 -in  /etc/pki/tls/certs/ca.crt -text -noout

# convert crt to pem
cd /etc/pki/tls/certs && openssl x509 -in ca.crt -out cacert.pem
cd -
openssl x509 -in  /etc/pki/tls/certs/cacert.pem -text -noout

# copy certificates
DOCKERDIR=/opt/ocs
cp /etc/pki/tls/private/ca.key ${DOCKERDIR}/data/nginx/certs/ocs.key
cp /etc/pki/tls/certs/ca.crt ${DOCKERDIR}/data/nginx/certs/ocs.crt
cp /etc/pki/tls/certs/cacert.pem ${DOCKERDIR}/
```
- Generate basic auth file for API (if you want to use API)

```bash
DOCKERDIR=/opt/ocs
htpasswd -bBc ${DOCKERDIR}/data/nginx/auth/ocsapi.htpasswd admin MyPassword
```

## Setup Plugins
- Download plugins
```bash
DOCKERDIR=/opt/inventory
cd ${DOCKERDIR}/data/ocsinventory/ocsreportsdata/

# Download Windows plugins
wget https://github.com/PluginsOCSInventory-NG/officepack/releases/download/3.4/officepack.zip
wget https://github.com/PluginsOCSInventory-NG/uptime/releases/download/2.1/uptime.zip
wget https://github.com/PluginsOCSInventory-NG/winupdate/releases/download/3.0/winupdate.zip
wget https://github.com/PluginsOCSInventory-NG/defaultwindowsapp/releases/download/v1.1/defaultwindowsapp.zip
wget https://github.com/PluginsOCSInventory-NG/networkshare/releases/download/v3.0/networkshare.zip
wget https://github.com/PluginsOCSInventory-NG/listprinters/releases/download/v2.0/listprinters.zip
wget https://github.com/PluginsOCSInventory-NG/osinstall/releases/download/2.0/osinstall.zip
wget https://github.com/PluginsOCSInventory-NG/winserverfeatures/releases/download/1.0/winserverfeatures.zip
wget https://github.com/PluginsOCSInventory-NG/anydesk/releases/download/2.2/anydesk.zip
wget https://github.com/PluginsOCSInventory-NG/security/releases/download/2.0/security.zip
wget https://github.com/PluginsOCSInventory-NG/wmiproductlist/releases/download/2.0/wmiproductlist.zip
wget https://github.com/PluginsOCSInventory-NG/winsecdetails/releases/download/1.0/winsecdetails.zip

# Linux plugins
wget https://github.com/PluginsOCSInventory-NG/crontabTasks/releases/download/v2.1/crontabtasks.zip
wget https://github.com/PluginsOCSInventory-NG/lastpublicip/releases/download/1.1/lastpublicip.zip
```
- Extract plugins
```bash
unzip officepack.zip && rm -rf officepack.zip
unzip uptime.zip -d uptime && rm -rf uptime.zip
unzip winupdate.zip && rm -rf winupdate.zip
unzip defaultwindowsapp.zip && rm -rf defaultwindowsapp.zip
unzip networkshare.zip && rm -rf networkshare.zip
unzip listprinters.zip && rm -rf listprinters.zip
unzip osinstall.zip && rm -rf osinstall.zip
unzip winserverfeatures.zip && rm -rf winserverfeatures.zip
unzip anydesk.zip && rm -rf anydesk.zip && chmod -R o-w anydesk
unzip security.zip && rm -rf security.zip
unzip wmiproductlist.zip && rm -rf wmiproductlist.zip
unzip winsecdetails.zip && rm -rf winsecdetails.zip
unzip crontabtasks.zip && rm -rf crontabtasks.zip
unzip lastpublicip.zip && rm -rf lastpublicip.zip
chown -R 101:101 ${DOCKERDIR}/data/ocsinventory/ocsreportsdata/
```

### Install plugins via WebGUI
- Got to http://ocs.changeme.de/ocsreports/ 
- Login and go to =>Extensions =>Extensions manager

## Configuration
- Configuration =>General configuration =>Server => Set as in picture
![General configuration Server](https://raw.githubusercontent.com/johann8/ocs-alpine/master/docs/assets/screenshots/OCS_configuration_server.png)

- Configuration =>General configuration =>Deployment: DOWNLOAD -> On; 
- Configuration =>General configuration =>Registry: REGISTRY -> On;
- Configuration =>General configuration =>Interface:<br> 
  ACTIVE_NEWS -> On<br>
  LOG_GUI -> On<br>
- Configuration =>General configuration =>Security:<br>
  SECURITY_AUTHENTICATION_NB_ATTEMPT -> 3<br>
  SECURITY_AUTHENTICATION_TIME_BLOCK -> 60<br>
  SECURITY_PASSWORD_ENABLED -> On<br>
  SECURITY_PASSWORD_MIN_CHAR -> 7<br>
  SECURITY_PASSWORD_FORCE_NB -> On<br>
  ECURITY_PASSWORD_FORCE_UPPER -> On 

- Configuration =>General configuration =>Inventory files:<br>
  GENERATE_OCS_FILES -> On<br>
  OCS_FILES_OVERWRITE -> On

- Configuration =>General configuration =>LDAP configuration => Set as in picture
![General configuration LDAP](https://raw.githubusercontent.com/johann8/ocs-alpine/master/docs/assets/screenshots/OCS_configuration_LDAP-configuration.png)

- Configuration =>Users =>Profiles =>sadmin => Set as in picture
![General Users Profile](https://raw.githubusercontent.com/johann8/ocs-alpine/master/docs/assets/screenshots/OCS_configuration_user-profiles-sadmin.png)

## Restapi
If variable `OCS_DISABLE_API_MODE: 0` in `docker-compose.yml` is commented, then restapi is disabled. You do not have to configure anything more.
Otherwise `location ocsapi` must be protected from unauthorized access. You must change the preconfigured user and password in file `.htpasswd-ocsapi` (default admin/ocsAPI). You can access this file from docker host.

```bash
# Generate password for example "MyPassword22"
htpasswd -nbBC 10 admin MyPassword22

# Entry insert
DOCKERDIR=/opt/ocs
vim ${DOCKERDIR}/data/ocsinventory/httpdconfdata/.htpasswd-ocsapi
-----
admin:$2y$10$b9sZIIF3xizmn2iywf0JjeoC8cT.LDEv3.tGTtYbJu5HIvfkEMKKa
-----

# restart docker container
DOCKERDIR=/opt/ocs
cd ${DOCKERDIR}
docker-compose down && docker-compose up -d
```

## Manage
- Manage =>Assets categories => Set as in picture
![Manage Assets categories](https://raw.githubusercontent.com/johann8/ocs-alpine/master/docs/assets/screenshots/OCS_manage_assets-categories.png)

- Manage =>Administrative data => Set as in picture
![Manage Administrative data](https://raw.githubusercontent.com/johann8/ocs-alpine/master/docs/assets/screenshots/OCS_manage_administrative-data.png)

## Inventory
- Inventory =>Groups => Set as in picture
![Inventory Groups ](https://raw.githubusercontent.com/johann8/ocs-alpine/master/docs/assets/screenshots/OCS_inventory_groups.png)

## Install ocsinventory client on CentOS/Rocky/Oracle

```bash
# add repo
dnf install http://rpm.ocsinventory-ng.org/ocsinventory-release-latest.el8.ocs.noarch.rpm
dnf config-manager --set-enabled powertools
dnf install ocsinventory-agent net-snmp-perl perl-Parse-EDID

# create backup
cp /etc/ocsinventory/ocsinventory-agent.cfg /etc/ocsinventory/ocsinventory-agent.cfg_orig

# edit ocsinventory config files
sed -i -e '/# server = your.ocsserver.name/c\server = https://ocsinventory.mydomain.de:4443/ocsinventory' /etc/ocsinventory/ocsinventory-agent.cfg
sed -i -e 's/local =/basevarlib =/' \
       -e 's/# tag = your_tag/tag = Linux_VM/' /etc/ocsinventory/ocsinventory-agent.cfg 

echo ' ' >> /etc/ocsinventory/ocsinventory-agent.cfg 
echo '# Additional options' >> /etc/ocsinventory/ocsinventory-agent.cfg 
echo 'debug=1' >> /etc/ocsinventory/ocsinventory-agent.cfg 
echo 'ssl=1' >> /etc/ocsinventory/ocsinventory-agent.cfg 
echo 'ca=/etc/ocsinventory/cacert.pem' >> /etc/ocsinventory/ocsinventory-agent.cfg 

# copy certificate 
# On ocsinventory server: 
DOCKERDIR=/opt/ocs
cat ${DOCKERDIR}/cacert.pem

# On ocsinventory client
vim /etc/ocsinventory/cacert.pem
--------------------
paste cacert.pem
--------------------

# activate cron 
sed -i -e 's/OCSMODE\[0\]=none/OCSMODE\[0\]=cron/' /etc/sysconfig/ocsinventory-agent

# test ocinventory
mv /etc/cron.hourly/ocsinventory-agent /etc/cron.daily/
bash /etc/cron.daily/ocsinventory-agent
tail -f -n2000   /var/log/ocsinventory-agent/ocsinventory-agent.log

# if everything works then disable debug
sed -i -e "s/debug=1/debug=0/" /etc/ocsinventory/ocsinventory-agent.cfg
``` 

- Set firewall rules

```bash
firewall-cmd --zone=public --add-port=4443/tcp --permanent
firewall-cmd --reload
firewall-cmd --zone=public --list-all
```

## Install ocsinventory client on Debian/Ubuntu

```bash
# create folder and file
mkdir -p /var/log/ocsinventory-agent/
touch /var/log/ocsinventory-agent/ocsinventory-agent.log

# add repo
curl -fsSL http://deb.ocsinventory-ng.org/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/ocs-archive-keyring.gpg
echo "deb http://deb.ocsinventory-ng.org/debian/ bullseye main" | sudo tee /etc/apt/sources.list.d/ocsinventory.list
apt-get update

# Ocsinventory agent install and answer the questions as follows
apt-get install ocsinventory-agent
y
0
y
y
https://ocsinventory.mydomain.de:4443
n
y
Linux
y
enter
y
y
enter
y
/var/log/ocsinventory-agent/ocsinventory-agent.log
n
y
/etc/ocsinventory/cacert.pem
y
n
y

# show cron job
cat /etc/cron.d/ocsinventory-agent
-----------------------
PATH=/usr/sbin:/usr/bin:/sbin:/bin
3 8 * * * root /usr/bin/ocsinventory-agent --lazy > /dev/null 2>&1
----------------------

# show config file
cat /etc/ocsinventory/ocsinventory-agent.cfg 

# paste here cacert.pem certificate from ocsinventory server
vim /etc/ocsinventory/cacert.pem
------------------
paste cacert.pem
-----------------

# run first inventory
/usr/bin/ocsinventory-agent --lazy

# show log
tail -f -n2000   /var/log/ocsinventory-agent/ocsinventory-agent.log

# # if everything works then disable debug
sed -i "s/debug=1/debug=0/" /etc/ocsinventory/ocsinventory-agent.cfg 
```
Enjoy !
