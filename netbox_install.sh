#!/bin/bash
clear
echo "------------------------"
echo "Netbox Installer"
echo "A. DUPOUY"
echo "------------------------"
echo " "

##### Presets #####
echo "Enter database password for user Netbox: "
read dbpasswd
echo "Enter server name (ex: netbox.example.com): "
read servername
currentdir=$(pwd)
apt install -y sudo

##### Database installation #####
sudo apt update
sudo apt install -y postgresql
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE DATABASE netbox;"
sudo -u postgres psql -c "CREATE DATABASE netbox;"
sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD '$dbpasswd';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;"

##### Redis install ######
sudo apt install -y redis-server

##### Netbox install #####
sudo apt install -y adduser git python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
sudo pip3 install --upgrade pip
mkdir /opt/netbox/
cd /opt/netbox/
sudo git clone -b master --depth 1 https://github.com/netbox-community/netbox.git .
sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/

##### Netbox configuration ####
cd /opt/netbox/netbox/netbox/
sudo cp configuration.example.py configuration.py
sudo sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" configuration.py
sudo sed -i "s/'USER': '',/'USER': 'netbox',/" configuration.py
sudo sed -i "s/'PASSWORD': '',           # PostgreSQL password/'PASSWORD': '$dbpasswd',/" configuration.py
privatekey=$(python3 ../generate_secret_key.py)
sudo sed -i "s/SECRET_KEY = ''/SECRET_KEY = '$privatekey'/" configuration.py

##### Netbox script #####
cd /opt/netbox
sudo sh /opt/netbox/upgrade.sh

##### Netbox create superuser #####
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
echo "=== NETBOX Super User creation ==="
python3 manage.py createsuperuser
ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

##### Gunicorn and systemd #####
sudo cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
sudo cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start netbox netbox-rq
sudo systemctl enable netbox netbox-rq

##### Apache2 install and config #####
sudo apt install -y apache2
sudo cp $currentdir/netbox.conf /etc/apache2/sites-available/netbox.conf
# Change config to HTTP port 80
sudo sed -i "s/ServerName netbox.example.com/ServerName $servername/" /etc/apache2/sites-available/netbox.conf
sudo a2enmod ssl proxy proxy_http headers
sudo a2dissite 000-default
sudo a2ensite netbox
sudo systemctl restart apache2

##### End of script #####
sudo systemctl restart netbox netbox-rq
echo "================="
echo "Upgrade complete"
echo "If service restart failed, please check the ExecStart path of service"
