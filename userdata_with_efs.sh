#!/bin/bash

exec 2>/tmp/log/user-data-errors.log

# Set database variables for RDS
DBName="${db_name}"
DBUser="${username}"
DBPassword="${password}"
DBRootPassword="${DBRootPassword}"
DBHost=$(echo "${rds_endpoint}" | sed 's/:3306//')
efs_id="${efs_id}"
alb_dns="${alb_dns}"
efs_dns_name="${efs_dns_name}"

# Install updates
sudo yum update -y

# Install Apache server
sudo yum install -y httpd

# Install MariaDB, PHP, and necessary tools
sudo amazon-linux-extras install -y php8.0
sudo amazon-linux-extras enable mariadb10.5
sudo yum clean metadata
sudo yum install php-fpm amazon-efs-utils wget rsync
sudo yum install -y mariadb unzip

# ===============================
# Start and enable Apache
# ===============================
sudo systemctl enable httpd
sudo systemctl enable php-fpm
sudo systemctl start httpd

# Wait for MariaDB to fully start
sleep 10

# Ensure www directory exists and owner
sudo mkdir -p /var/www/html
sudo chown -R apache:apache /var/www/html


# ===============================
# Install WordPress normally (so wp-content has default themes + plugins)
# ===============================
if [ ! -f /var/www/html/wp-config.php ]; then
    sudo cd /tmp
    sudo wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -r wordpress/* /var/www/html/
    sudo chown -R apache:apache /var/www/html
fi

# ===============================
# 2. Ensure EFS exists
# ===============================

sudo mkdir -p /mnt/efs

# ===============================
# 3. Mount EFS.
# ===============================

mount -t nfs4 -o nfsvers=4.1 ${efs_dns_name}:/ /mnt/efs

# ===============================
# Create wp-content inside EFS if not exists.
# (mount efs only after downloading wordpress otherwise 
# wp-content will be emptyeg.theme etc)
# ==================================
mkdir -p /mnt/efs/wp-content

# =======================================
# If EFS wp-content is empty, copy the default wp-content into it
# ===============================
if [ -z "$(ls -A /mnt/efs/wp-content)" ]; then
    cp -R /var/www/html/wp-content/* /mnt/efs/wp-content/
fi

# ===============================
# Remove local wp-content
# ===============================
rm -rf /var/www/html/wp-content


# ===============================
# Symlink EFS wp-content to WordPress directory
# ===============================
ln -s /mnt/efs/wp-content /var/www/html/wp-content

# ===============================
# Fix permissions
# ===============================

chown -R apache:apache /mnt/efs/wp-content


# ===============================
# Create wp-config.php
# ===============================
if [ ! -f /var/www/html/wp-config.php ]; then
    sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sudo chown apache:apache /var/www/html/wp-config.php
fi

# ===============================
# Update wp-config.php dynamically
# ===============================

cd /var/www/html

sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sudo sed -i "s/'localhost'/'$DBHost'/g" wp-config.php


# Grant permissions
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www/
sudo chmod 2775 /var/www/
sudo find /var/www/ -type d -exec chmod 2775 {} \;
sudo find /var/www/ -type f -exec chmod 0664 {} \;

# ===============================
# Start Apache server and enable it on system startup
# ===============================
sudo systemctl enable httpd
sudo systemctl start httpd
