#!/bin/bash

exec > >(tee /var/log/mysql-setup.log) 2>&1

if command -v mysql >/dev/null 2>&1; then
    echo "MySQL is already installed. Skipping installation."
		exit 0
fi

apt update
apt upgrade -y

apt-get install -y mysql-server

sed -i 's/bind-address.*=.*/bind-address=0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql -e "CREATE DATABASE poridhi;"
mysql -e "CREATE USER 'poridhi'@'%' IDENTIFIED BY 'poridhi';"
mysql -e "GRANT ALL PRIVILEGES ON poridhi.* TO 'poridhi'@'%';"
mysql -e "FLUSH PRIVILEGES;"

systemctl restart mysql
systemctl enable mysql
