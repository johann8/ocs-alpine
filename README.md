<h1 align="center">OCS Inventoryi NG</h1>

| pull | size alpine | version | platform |
|:---------------------------------:|:----------------------------------:|:--------------------------------:|:--------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/alpine-ocs?style=flat-square) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/alpine-ocs/latest) | [![](https://img.shields.io/docker/v/johann8/alpine-ocs?sort=date)](https://hub.docker.com/r/johann8/alpine-ocs/tags "Version badge") | ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") |

<p align='justify'>
OCS (Open Computers and Software Inventory Next Generation) is an assets management and deployment solution.
Since 2001, OCS Inventory NG has been looking for making software and hardware more powerful.
OCS Inventory NG asks its agents to know the software and hardware composition of every computer or server.
</p>

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

## Install ocsinventory client on CentOS/Rocky/oracle

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
