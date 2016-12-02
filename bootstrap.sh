#!/usr/bin/env bash

DEV_USERNAME='greg'
DEV_PASSWD='toto'
ROOT_PASSWD='toto42'

PHP_VERSION='7.0.13'
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
sed -i -e "s/XKBLAYOUT\=\"us\"/XKBLAYOUT\=\"fr\"/g" /etc/default/keyboard ## clavier FR
service keyboard-setup restart

# Personnalisation des comptes: bash vim
cp  /vagrant/misc/hosts /etc/hosts
# customisation prompt bash + aliases
cp  /vagrant/misc/bash_aliases_user /home/$DEV_USERNAME/.bash_aliases
cp  /vagrant/misc/bashrc_root  /root/.bashrc
# customisation vim 
cp  /vagrant/misc/vimrc  /root/.vimrc
cp  /vagrant/misc/vimrc  /home/$DEV_USERNAME/.vimrc

# creation  des reporte ssh et alimentation
mkdir -p /home/$DEV_USERNAME/.ssh
cp /vagrant/ssh/id_rsa /home/$DEV_USERNAME/.ssh/id_rsa
cp /vagrant/ssh/id_rsa.pub /home/$DEV_USERNAME/.ssh/id_rsa.pub
cp /vagrant/ssh/config /home/$DEV_USERNAME/.ssh/config
cp /vagrant/ssh/id_rsa.pub  /home/$DEV_USERNAME/.ssh/authorized_keys

# Avec les bon droits
chown -R $DEV_USERNAME:$DEV_USERNAME /home/$DEV_USERNAME/.ssh
chmod 600 /home/$DEV_USERNAME/.ssh/id_rsa*
chown -R $DEV_USERNAME:$DEV_USERNAME /home/$DEV_USERNAME/

# On authorise le ssh par mot de passe en plus des clef SSH
sed -i -e "s/PasswordAuthentication\ no/PasswordAuthentication\ yes/g" /etc/ssh/sshd_config
/etc/init.d/ssh restart

# pour avoir le apache fast-cgi
sed -i -e "s/deb\ http\:\/\/httpredir\.debian\.org\/debian\ jessie\ main/deb\ http\:\/\/httpredir\.debian\.org\/debian\ jessie\ main\ non-free/g" /etc/apt/sources.list
sed -i -e "s/deb\-src\ http\:\/\/httpredir\.debian\.org\/debian\ jessie\ main/deb\-src\ http\:\/\/httpredir\.debian\.org\/debian\ jessie\ main\ non-free/g" /etc/apt/sources.list

# update du systeme
apt-get update
apt-get upgrade --quiet --yes

# installation des package necessaire a la compilation de php
apt-get install -y linux-headers-$(uname -r) apache2-mpm-worker libapache2-mod-fastcgi apache2-dev curl vim libxml2-dev libcurl4-openssl-dev libssl-dev libjpeg-dev libpng12-dev libgmp-dev libmcrypt-dev libxslt1-dev libtool chrony htop autoconf git

# bug configure php
ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

# Pour le set de la timezon 
cp  /vagrant/misc/ntp.conf  /etc/ntp.conf
echo 'Europe/Paris' > /etc/timezone
#service ntp restart
dpkg-reconfigure --frontend noninteractive tzdata

# group et utilisateur wister et www-data
usermod -a -G www-data $DEV_USERNAME
usermod -a -G  $DEV_USERNAME www-data

###########################################
########### APACHE 2.4 ####################
###########################################

# on desactive les sites par defaut
for vhost in /etc/apache2/sites-enabled/*; do
    site=$(echo $(basename $vhost) | sed 's/\.conf//g')
    a2dissite $site
done

# copie des vhost / conf
#cp /vagrant/apache2/sites-available/*.conf /etc/apache2/sites-available/
#cp /vagrant/apache2/conf-available/*.conf /etc/apache2/conf-available/
cp /vagrant/apache2/mods-available/*.conf /etc/apache2/mods-available/
#cp /vagrant/apache2/mime.types  /etc/apache2/


# on active les site
for vhost in /vagrant/apache2/mods-available/*; do
    site=$(echo $(basename $vhost) | sed 's/\.conf//g')
    a2ensite $site
done

a2enmod actions fastcgi

###########################################
############# PHP #########################
###########################################
#  on commence l'installation de php
cd $PHP_INSTALL_DIR
echo "On recupere les sources php : http://fr2.php.net/distributions/php-${PHP_VERSION}.tar.gz -o php-${PHP_VERSION}.tar.gz"
curl -s  http://fr2.php.net/distributions/php-${PHP_VERSION}.tar.gz -o php-${PHP_VERSION}.tar.gz

echo "On detar l'archive"
tar xzf php-${PHP_VERSION}.tar.gz
cd php-${PHP_VERSION}

echo "On lance le configure Php"
#./configure --prefix=/usr/local/php-$PHP_VERSION --enable-inline-optimization --disable-debug --with-config-file-path=/usr/local/php-$PHP_VERSION/etc --with-config-file-scan-dir=/usr/local/php-$PHP_VERSION/etc/conf.d --with-gd --with-mcrypt --with-openssl --with-libdir=/lib/x86_64-linux-gnu --with-mysqli=mysqlnd --enable-ftp --enable-sockets --enable-zip --with-jpeg-dir=/usr --with-zlib-dir=/usr --with-curl=/usr --with-libxml-dir=/usr/local/libxml2 --with-gmp --with-apxs2=/usr/bin/apxs2 --with-xsl=/usr/local/libxslt --enable-soap --enable-mbstring --enable-sysvsem
#./configure --prefix=$PHP_INSTALL_DIR/php-$PHP_VERSION --enable-inline-optimization --disable-debug --with-config-file-path=$PHP_INSTALL_DIR/php-$PHP_VERSION/etc --with-config-file-scan-dir=$PHP_INSTALL_DIR/php-$PHP_VERSION/etc/conf.d --with-gd --with-mcrypt --with-openssl --with-libdir=/lib/x86_64-linux-gnu --with-mysqli=mysqlnd --enable-ftp --enable-sockets --enable-zip --with-jpeg-dir=/usr --with-zlib-dir=/usr --with-curl=/usr --with-libxml-dir=/usr/local/libxml2 --with-gmp --with-apxs2=/usr/bin/apxs2 --with-xsl=/usr/local/libxslt --enable-soap --enable-mbstring --enable-sysvsem &> /dev/null
./configure --prefix=$PHP_INSTALL_DIR/php-$PHP_VERSION --enable-inline-optimization --disable-debug --with-config-file-path=$PHP_INSTALL_DIR/php-$PHP_VERSION/etc --with-config-file-scan-dir=$PHP_INSTALL_DIR/php-$PHP_VERSION/etc/conf.d --with-gd --with-mcrypt --with-openssl --with-libdir=/lib/x86_64-linux-gnu --with-mysqli=mysqlnd --enable-ftp --enable-sockets --enable-zip --with-jpeg-dir=/usr --with-zlib-dir=/usr --with-curl=/usr --with-libxml-dir=/usr/local/libxml2 --with-gmp --with-xsl=/usr/local/libxslt --enable-soap --enable-mbstring --enable-sysvsem --enable-fpm  --with-fpm-user=www-data --with-fpm-group=www-data

echo "On lance le make"
make  &> /dev/null
echo "On lance l'installation"
make install

ln -s $PHP_INSTALL_DIR/php-$PHP_VERSION $PHP_INSTALL_DIR/php
ln -s $PHP_INSTALL_DIR/php/etc/ /etc/php
ln -s $PHP_INSTALL_DIR/php/bin/php /usr/bin/php
ln -s $PHP_INSTALL_DIR/php/bin/phpize /usr/bin/phpize
ln -s $PHP_INSTALL_DIR/php/bin/pecl /usr/bin/pecl
ln -s $PHP_INSTALL_DIR/php/bin/pear /usr/bin/pear

echo "On parametre php"
cp /usr/local/php-${PHP_VERSION}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
cp /usr/local/php-${PHP_VERSION}/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
mv /etc/php/php-fpm.d/www.conf.default /etc/php/php-fpm.d/www.conf
chmod +x /etc/init.d/php-fpm

sed -i -e "s/listen\ \=\ 127\.0\.0\.1\:9000/listen\ \=\ \/var\/run\/php\-fpm\.sock/g" /etc/php/php-fpm.d/www.conf
sed -i -e "s/\;listen\.owner\ \=\ www\-data/listen\.owner\ \=\ www\-data/g" /etc/php/php-fpm.d/www.conf
sed -i -e "s/\;listen\.group\ \=\ www\-data/listen\.group\ \=\ www\-data/g" /etc/php/php-fpm.d/www.conf
sed -i -e "s/\;listen\.mode\ \=\ 0660/listen\.mode\ \=\ 0660/g" /etc/php/php-fpm.d/www.conf


cd /etc/init.d
update-rc.d php-fpm defaults
#a2enmod action


/etc/init.d/php-fpm restart
/etc/init.d/apache2 restart
# a2dismod mpm_event
#a2dismod mpm_prefork















