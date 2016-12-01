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
