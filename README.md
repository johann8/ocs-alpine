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
