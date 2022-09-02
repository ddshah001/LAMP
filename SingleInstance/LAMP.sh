#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

sudo yum update -y

#Install apache
sudo yum install -y httpd httpd-tools mod_ssl 
sudo systemctl enable httpd
sudo systemctl start httpd

#Install PHP7
sudo yum install amazon-linux-extras -y
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata 
sudo yum install php php-common php-pear -y
sudo yum install php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}  -y
sudo chown -R $USER:$USER /var/www/
echo "<?php phpinfo(); ?>" > /var/www/html/info.php 
sudo systemctl restart httpd

# Install MYSql
sudo yum install -y mariadb-server 
sudo systemctl status mariadb
sudo systemctl start mariadb

mysql -sfu root <<EOS
-- set root password
UPDATE mysql.user SET Password=PASSWORD('$1') WHERE User='root';
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOS
