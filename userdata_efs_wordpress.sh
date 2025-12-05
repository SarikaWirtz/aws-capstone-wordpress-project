#!/bin/bash
set -xe
exec 2>/var/log/user-data-errors.log

# Set database variables for RDS
DBName="${DBName}"
DBUser="${DBUser}"
DBPassword="${DBPassword}"
DBRootPassword="${DBRootPassword}"
DBHost=$(echo "${DBHost}" | sed 's/:3306//')
efs_id="${efs_id}"
alb_dns="${alb_dns}"
efs_dns_name="${efs_dns_name}"

##############################
# Update System
##############################
sudo dnf update -y

##############################
# Install Apache, PHP 8.2, Tools
##############################
sudo dnf install -y httpd git amazon-efs-utils wget unzip rsync

###############################
# Install PHP, PHP-FPM, and required extensions
###############################
sudo dnf install -y php php-fpm php-mysqli php-cli php-json php-opcache php-xml php-gd php-curl php-mbstring php-intl php-zip php-soap

##############################
# Enable & Start Apache + PHP-FPM
##############################
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl enable php-fpm
sudo systemctl start php-fpm

##############################
# Prepare Web Directory
##############################
sudo mkdir -p /var/www/html
sudo chown -R apache:apache /var/www/html

##############################
# Download WordPress Repo (Git)
##############################
if [ ! -d /var/www/html/.git ]; then
    cd /var/www/html
    git clone https://github.com/SarikaWirtz/testWordpress.git .
    sudo chown -R apache:apache /var/www/html
fi

##############################
# Mount EFS
##############################
sudo mkdir -p /mnt/efs

mount -t nfs4 -o nfsvers=4.1 ${efs_dns_name}:/ /mnt/efs

##############################
# Prepare wp-content in EFS
##############################
sudo mkdir -p /mnt/efs/wp-content

# If EFS is empty, copy from WordPress
if [ -z "$(ls -A /mnt/efs/wp-content)" ]; then
    sudo cp -R /var/www/html/wp-content/* /mnt/efs/wp-content/
fi

# Remove local wp-content and symlink to EFS
sudo rm -rf /var/www/html/wp-content
ln -s /mnt/efs/wp-content /var/www/html/wp-content

# Fix permissions
sudo chown -R apache:apache /mnt/efs/wp-content

##############################
# Create wp-config.php
##############################
if [ ! -f /var/www/html/wp-config.php ]; then
    sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sudo chown apache:apache /var/www/html/wp-config.php
fi

##############################
# Update wp-config.php dynamically
##############################
cd /var/www/html

sed -i "s/'database_name_here'/'${DBName}'/g" wp-config.php
sed -i "s/'username_here'/'${DBUser}'/g" wp-config.php
sed -i "s/'password_here'/'${DBPassword}'/g" wp-config.php
sed -i "s/'localhost'/'${DBHost}'/g" wp-config.php

##############################
# Fix Ownership & Permissions
##############################
sudo usermod -a -G apache ec2-user

sudo chown -R ec2-user:apache /var/www/
sudo chmod 2775 /var/www/
find /var/www/ -type d -exec chmod 2775 {} \;
find /var/www/ -type f -exec chmod 0664 {} \;

##############################
# Restart Apache
##############################
sudo systemctl restart httpd
