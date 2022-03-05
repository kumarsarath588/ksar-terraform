#!/bin/bash
set -ex

DB_NAME=$1
DB_USER=$2
DB_PASSWORD=$3

# -*- Mysql installation 
sudo yum install -y --quiet "http://repo.mysql.com/mysql80-community-release-el7.rpm"
#sudo yum update -y --quiet
sudo yum install -y --quiet mysql-community-server.x86_64

sudo systemctl enable mysqld
sudo systemctl start mysqld

#Fix to obtain temp password and set it to blank
password=$(sudo grep -oP 'temporary password(.*): \K(\S+)' /var/log/mysqld.log)
sudo mysqladmin --user=root --password="$password" password aaBB**cc1122
sudo mysql --user=root --password=aaBB**cc1122 -e "UNINSTALL COMPONENT 'file://component_validate_password'"
sudo mysqladmin --user=root --password="aaBB**cc1122" password ""


#Mysql secure installation
sudo mysql -u root<<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES on ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF