#!/bin/bash

# Download and extract Nextcloud
sudo mkdir /var/www/html/nextcloud
sudo wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -P /var/www/html
sudo tar -xvf /var/www/html/latest.tar.bz2 -C /var/www/html/nextcloud --strip-components=1

# Set permissions
sudo chown -R www-data:www-data /var/www/html/nextcloud

# Define NextCloud server variables
read -p "Enter NextCloud Server Domain or IP: " NEXTCLOUD_SERVER_NAME

# Create a new Apache configuration for Nextcloud
sudo tee /etc/apache2/sites-available/nextcloud.conf > /dev/null <<EOF
<VirtualHost *:80>
   ServerAdmin admin@example.com
   DocumentRoot /var/www/html/nextcloud
   ServerName $NEXTCLOUD_SERVER_NAME

   ErrorLog \${APACHE_LOG_DIR}/error.log
   CustomLog \${APACHE_LOG_DIR}/access.log combined

   Alias /nextcloud "/var/www/html/nextcloud/"

   <Directory /var/www/html/nextcloud/>
       Options +FollowSymlinks
       AllowOverride All
       Require all granted
       <IfModule mod_dav.c>
           Dav off
       </IfModule>
       SetEnv HOME /var/www/html/nextcloud
       SetEnv HTTP_HOME /var/www/html/nextcloud
   </Directory>
</VirtualHost>
EOF

# Enable the Nextcloud site and disable the default site
sudo a2ensite nextcloud.conf
sudo a2dissite 000-default.conf

# Restart Apache
sudo systemctl restart apache2