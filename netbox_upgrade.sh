#!/bin/bash
clear
figlet "Netbox Upgrade"
figlet "A. DUPOUY"
echo " "
echo "Entrez le numero de current version au format 2.x.x"
read OLD
echo "Entrer le numero de new-version au format 2.x.x"
read NEW


wget https://github.com/netbox-community/netbox/archive/v$NEW.tar.gz
sudo tar -xzf v$NEW.tar.gz -C /opt
sudo ln -sfn /opt/netbox-$NEW/ /opt/netbox

sudo cp /opt/netbox-$OLD/local_requirements.txt /opt/netbox/ #May return error if not having local requirements (LDAP, NAPALM...)
sudo cp /opt/netbox-$OLD/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
sudo cp /opt/netbox-$OLD/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/ #May return error if not using LDAP
sudo cp -pr /opt/netbox-$OLD/netbox/media/ /opt/netbox/netbox/
sudo cp /opt/netbox-$OLD/gunicorn.py /opt/netbox/
sudo sh /opt/netbox/upgrade.sh

sudo systemctl daemon-reload
sudo systemctl restart netbox netbox-rq
clear
figlet "Upgrade complete"
