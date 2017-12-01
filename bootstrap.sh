#!/usr/bin/env bash

DEV_USERNAME='wako'
DEV_PASSWD='passuser'
ROOT_PASSWD='passroot'
MYSQL_ROOT_PASSWD='passmysql'
MYSQL_USER_LOGIN='wako'
MYSQL_USER_PASSWD='motdepassesimple'

###########################################
##### SYSTEM GENERAL ######################
###########################################
# Definition des mot de passe utilisateurs -
echo root:$ROOT_PASSWD | chpasswd
 # dev user
adduser --quiet --disabled-password --shell /bin/bash --home /home/$DEV_USERNAME --gecos "$DEV_USERNAME" $DEV_USERNAME
echo "$DEV_USERNAME:$DEV_PASSWD" | chpasswd

# on fait taire la bell-ring - on ajotue le clavier fr
sed -i -e "s/\#\ set\ bell-style\ none/set\ bell-style\ none/g" /etc/inputrc
sed -i -e "s/XKBLAYOUT\=\"us\"/XKBLAYOUT\=\"fr\"/g" /etc/default/keyboard ## clavier FR
service keyboard-setup restart

# Personnalisation des comptes: bash vim authorized_keys
cp  /vagrant/misc/hosts /etc/hosts
cp  /vagrant/misc/bash_aliases_user /home/$DEV_USERNAME/.bash_aliases
cp  /vagrant/misc/bashrc_root  /root/.bashrc
cp  /vagrant/misc/vimrc  /root/.vimrc
cp  /vagrant/misc/vimrc  /home/$DEV_USERNAME/.vimrc

mkdir -p /home/$DEV_USERNAME/.ssh

if [ -f /vagrant/ssh/id_rsa.pub ]; then
    cp /vagrant/ssh/id_rsa.pub  /home/$DEV_USERNAME/.ssh/authorized_keys
fi
cp /vagrant/ssh/sshd_config /etc/ssh/sshd_config
service ssh restart


chown -R $DEV_USERNAME:$DEV_USERNAME /home/$DEV_USERNAME/.ssh
chmod 600 /home/$DEV_USERNAME/.ssh/id_rsa*
chown -R $DEV_USERNAME:$DEV_USERNAME /home/$DEV_USERNAME/

cp /vagrant/ssh/config /home/$DEV_USERNAME/.ssh/config
chmod 644  /home/$DEV_USERNAME/.ssh/config

/etc/init.d/ssh restart
#
## update du systeme
apt-get update
apt-get upgrade --quiet --yes
#
## Pour le set de la timezone
apt-get install -y ntp ntpdate
cp  /vagrant/misc/ntp.conf  /etc/ntp.conf
echo 'Europe/Paris' > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata
/etc/init.d/ntp restart
#
## group et utilisateur
usermod -a -G www-data $DEV_USERNAME
usermod -a -G  $DEV_USERNAME www-data
## install tools
apt-get -y install vim curl  htop git sendmail sendmail-bin sshpass
## install apache + php7
apt-get install -y php7.0 php7.0-cli php7.0-curl php7.0-gd php7.0-gmp php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache php7.0-readline php7.0-soap php7.0-xml php7.0-xsl php7.0-zip php7.0-apcu php7.0-ssh2 libapache2-mod-php7.0 php-pear composer
## install stats.so
pear config-set php_ini /etc/php/7.0/cli/php.ini



###########Config APACHE 2.4/PHP
mkdir -p /var/www/wako057.net
for vhost in /etc/apache2/sites-enabled/*; do
    site=$(echo $(basename $vhost) | sed 's/\.conf//g')
    a2dissite $site
done

# copie des vhost / conf
cp /vagrant/apache2/sites-available/*.conf /etc/apache2/sites-available/
cp /vagrant/apache2/conf-available/*.conf /etc/apache2/conf-available/
cp /vagrant/apache2/mods-available/*.conf /etc/apache2/mods-available/
cp /vagrant/apache2/mime.types  /etc/apache2/
cp -r /vagrant/php/7.0/apache2/ /etc/php/7.0

# on active les site
for vhost in /etc/apache2/sites-available/*; do
    site=$(echo $(basename $vhost) | sed 's/\.conf//g')
    a2ensite $site
done

a2dissite 000-default
# on desactive mpm - on active les modules necessaire
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod actions
a2enmod rewrite
a2enmod ssl

# on cree le certificat ssl
mkdir /etc/apache2/ssl
cd /etc/apache2/ssl
openssl genrsa -out dev.wako057.net.key 2048
echo -e "FR\nParis\nParis\nWako057\n\ndev.wako057.net\n\n\n\n" | openssl req -new -key dev.wako057.net.key -out dev.wako057.net.csr
openssl x509 -req -days 365 -in dev.wako057.net.csr -signkey dev.wako057.net.key -out dev.wako057.net.pem
chown -R $DEV_USERNAME:$DEV_USERNAME /var/www/
apache2ctl restart

###########################################
############# MYSQL #######################
###########################################
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWD"
apt-get install -y mysql-server
service mysql stop
mv /var/lib/mysql /data
chown -R mysql:mysql /data/mysql

cp /etc/mysql/my.cnf /etc/mysql/my.cnf.old
cp /vagrant/mysql/my.cnf /etc/mysql/my.cnf
service mysql start

mysql -u root -p$MYSQL_ROOT_PASSWD < /vagrant/mysql/init_env.sql


###########################################
######## PYTHON & PIP & AWS ###############
###########################################
apt-get install -y python-pip python-dev libmysqlclient-dev
pip install MySQL-python
pip install elasticsearch
pip install splunk-sdk

cd
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install awscli
aws configure set preview.cloudfront true

###########################################
########## NODEJS #########################
###########################################
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y nodejs
apt-get install -y build-essential


