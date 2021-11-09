#!/bin/bash
clear
echo "------------------------"
echo "Netbox Upgrade"
echo "A. DUPOUY"
echo "------------------------"
echo " "

######### PRESETS ############
echo "Entrez le numero de current version au format 3.x.x"
read OLD
echo "Entrer le numero de new-version au format 3.x.x"
read NEW

######## Download & extract ###########

wget https://github.com/netbox-community/netbox/archive/v$NEW.tar.gz
sudo tar -xzf v$NEW.tar.gz -C /opt
sudo ln -sfn /opt/netbox-$NEW/ /opt/netbox

###### Copy of config ############
while true; do
    read -p "Avez vous setup des local_requirements ? [y/n]" yn
    case $yn in
        [Yy]* ) sudo cp /opt/netbox-$OLD/local_requirements.txt /opt/netbox/; break;;
        [Nn]* ) echo "";;
        * ) echo "Merci de repondre yes(y) or no(n)";;
    esac
done

while true; do
    read -p "Avez vous setup une authentification LDAP ? [y/n]" yn
    case $yn in
        [Yy]* ) sudo cp /opt/netbox-$OLD/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/; break;;
        [Nn]* ) echo "";;
        * ) echo "Merci de repondre yes(y) or no(n)";;
    esac
done

sudo cp /opt/netbox-$OLD/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
sudo cp -pr /opt/netbox-$OLD/netbox/media/ /opt/netbox/netbox/
sudo cp /opt/netbox-$OLD/gunicorn.py /opt/netbox/

###### Execution of Netbox upgrade script ######
cd /opt/netbox/
sudo sh /opt/netbox/upgrade.sh

###### Daemon reload ##########
sudo systemctl daemon-reload
sudo systemctl restart netbox netbox-rq
clear
echo "Upgrade complete"
echo "If service restart failed, please check the ExecStart path of service"
