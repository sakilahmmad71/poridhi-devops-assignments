#!/bin/bash

exec > >(tee /var/log/nodejs-setup.log) 2>&1

if command -v node >/dev/null 2>&1; then
		echo "Node.js is already installed. Skipping installation."
		exit 0
fi

apt update
apt upgrade -y

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
apt-get install -y nodejs

apt-get install netcat-openbsd mysql-client -y

mkdir -p /usr/local/bin
cp check-mysql.sh /usr/local/bin/check-mysql.sh
chmod +x /usr/local/bin/check-mysql.sh
