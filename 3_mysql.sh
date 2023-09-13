#!/bin/bash

# Define MySQL variables
read -sp "Enter MySQL Root Password: " MYSQL_ROOT_PASSWORD
read -p "Create MySQL Username for NextCloud Database: " MYSQL_NEXTCLOUD_USER
read -sp "Create MySQL Password for NextCloud Database: " MYSQL_NEXTCLOUD_PASSWORD
read -p "Create MySQL Database for NextCloud Database: " MYSQL_NEXTCLOUD_DB

# Create a MySQL database and user for Nextcloud
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE $MYSQL_NEXTCLOUD_DB;
CREATE USER '$MYSQL_NEXTCLOUD_USER'@'localhost' IDENTIFIED BY '$MYSQL_NEXTCLOUD_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_NEXTCLOUD_DB.* TO '$MYSQL_NEXTCLOUD_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT