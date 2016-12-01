#!/usr/bin/env bash

DEV_USERNAME='greg'
DEV_PASSWD='toto'
ROOT_PASSWD='toto42'
PHP_INSTALL_DIR='/usr/local'
MYSQL_ROOT_PASSWD='toto42'
MYSQL_USER_LOGIN='greg'
MYSQL_USER_PASSWD='blublu'


###########################################
##### SYSTEM GENERAL ######################
###########################################

# disque dur /opt
mkfs.ext4 /dev/sdb
echo `blkid /dev/sdb | awk '{print$2}' | sed -e 's/"//g'` /opt               ext4    errors=remount-ro 0       1 >> /etc/fstab
mount /opt


# Definition des mot de passe utilisateurs - on fait taire la bell-ring
echo -e "$ROOT_PASSWD\n$ROOT_PASSWD" | passwd --quiet  &> /dev/null 
useradd -mU -s /bin/bash $DEV_USERNAME 
echo -e "$DEV_PASSWD\n$DEV_PASSWD" | passwd --quiet $DEV_USERNAME &> /dev/null 
sed -i -e "s/\#\ set\ bell-style\ none/set\ bell-style\ none/g" /etc/inputrc ## petit goodies pour ne pas avoir de sonnette sur le bash windows


mkdir -p /home/$DEV_USERNAME/.ssh
cp /vagrant/ssh/id_rsa.pub  /home/$DEV_USERNAME/.ssh/authorized_keys
cp /vagrant/ssh/id_rsa /home/$DEV_USERNAME/.ssh/id_rsa
cp /vagrant/ssh/id_rsa.pub /home/$DEV_USERNAME/.ssh/id_rsa.pub
cp /vagrant/ssh/config /home/$DEV_USERNAME/.ssh/config

chown -R $DEV_USERNAME:$DEV_USERNAME /home/$DEV_USERNAME/.ssh
chmod 600 /home/$DEV_USERNAME/.ssh/id_rsa*
chown -R $DEV_USERNAME:$DEV_USERNAME /home/$DEV_USERNAME/
/etc/init.d/ssh restart


# update du systeme
apt-get update
apt-get upgrade --quiet --yes

exit 0;
# installation des package necessaire a la compilation de php
#apt-get install -y linux-headers-$(uname -r) apache2-mpm-prefork apache2-dev curl vim libxml2-dev libcurl4-openssl-dev libssl-dev libjpeg-dev libpng12-dev libgmp-dev libmcrypt-dev libxslt1-dev libtool chrony htop autoconf git


###########################################
########### APACHE 2.4 ####################
###########################################

# on desactive les sites par defaut
for vhost in /etc/apache2/sites-enabled/*; do
    site=$(echo $(basename $vhost) | sed 's/\.conf//g')
    a2dissite $site
done

# copie des vhost / conf
cp /vagrant/apache2/sites-available/*.conf /etc/apache2/sites-available/
cp /vagrant/apache2/conf-available/*.conf /etc/apache2/conf-available/
cp /vagrant/apache2/mods-available/*.conf /etc/apache2/mods-available/
cp /vagrant/apache2/mime.types  /etc/apache2/

