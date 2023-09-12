#!/bin/bash

# Variables to update
NEXTCLOUD_SERVER_NAME="your_server_domain_or_IP"
MYSQL_ROOT_PASSWORD="your_mysql_root_password"
MYSQL_NEXTCLOUD_USER="nextcloud_user"
MYSQL_NEXTCLOUD_PASSWORD="your_mysql_nextcloud_password"
MYSQL_NEXTCLOUD_DB="nextcloud_db"
COLLABORA_SERVER_NAME="your_collabora_server_domain_or_IP"
COLLABORA_ADMIN_PASSWORD="your_collabora_admin_password"

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y apache2 mysql-server php8.2 php8.2-mysql php8.2-curl php8.2-gd php8.2-intl php8.2-json php8.2-mbstring php8.2-xml php8.2-zip libapache2-mod-php8.2 redis-server

# Enable Apache modules
sudo a2enmod rewrite headers env dir mime setenvif ssl

# Download and extract Nextcloud
sudo mkdir /var/www/html/nextcloud
sudo wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -P /var/www/html
sudo tar -xvf /var/www/html/latest.tar.bz2 -C /var/www/html/nextcloud --strip-components=1

# Set permissions
sudo chown -R www-data:www-data /var/www/html/nextcloud

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

# Create a MySQL database and user for Nextcloud
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE $MYSQL_NEXTCLOUD_DB;
CREATE USER '$MYSQL_NEXTCLOUD_USER'@'localhost' IDENTIFIED BY '$MYSQL_NEXTCLOUD_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_NEXTCLOUD_DB.* TO '$MYSQL_NEXTCLOUD_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install PHP Redis extension
sudo apt install -y php-redis

# Configure Nextcloud to use Redis for memory caching
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set memcache.local --value '\OC\Memcache\Redis'
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set redis host --value "localhost"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set redis port --value "6379"

# Test Redis configuration
if php -r 'if (class_exists("Redis")) { $redis = new Redis(); $redis->connect("localhost", 6379); echo $redis->ping(); }' | grep -q "PONG"; then
    echo "Redis configuration is working."
else
    echo "Redis configuration test failed. Please check your Redis setup."
fi

# Install Collabora Online dependencies
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Collabora Online repository
sudo add-apt-repository ppa:libreoffice/ppa
sudo apt update

# Install Collabora Online Code Server
sudo apt install -y loolwsd code-brand libreoffice-calc

# Configure Collabora Online
sudo tee /etc/loolwsd/loolwsd.xml > /dev/null <<EOF
<config>
  <admin_console username="admin" password="$COLLABORA_ADMIN_PASSWORD"/>
  <ssl desc="SSL settings">
    <enable>true</enable>
    <termination>proxy</termination>
    <cert_file_path>/etc/loolwsd/ssl.crt</cert_file_path>
    <key_file_path>/etc/loolwsd/ssl.key</key_file_path>
  </ssl>
  <server_name>$COLLABORA_SERVER_NAME</server_name>
  <server_host>localhost</server_host>
  <server_proto>https</server_proto>
  <server_port>9980</server_port>
  <username></username>
  <password></password>
  <cache>
    <enable>true</enable>
  </cache>
</config>
EOF

# Generate a self-signed SSL certificate for Collabora Online (replace with your own certificate if available)
sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/loolwsd/ssl.key -out /etc/loolwsd/ssl.crt -days 365

# Configure Collabora Online proxy for Apache
sudo tee /etc/apache2/sites-available/collabora.conf > /dev/null <<EOF
<VirtualHost *:443>
   ServerName $COLLABORA_SERVER_NAME
   DocumentRoot /var/www/html

   ErrorLog \${APACHE_LOG_DIR}/error.log
   CustomLog \${APACHE_LOG_DIR}/access.log combined

   SSLEngine on
   SSLCertificateFile /etc/loolwsd/ssl.crt
   SSLCertificateKeyFile /etc/loolwsd/ssl.key

   ProxyPass /loleaflet https://localhost:9980/loleaflet retry=0
   ProxyPassReverse /loleaflet https://localhost:9980/loleaflet

   ProxyPass /hosting/discovery https://localhost:9980/hosting/discovery retry=0
   ProxyPassReverse /hosting/discovery https://localhost:9980/hosting/discovery

   ProxyPass /hosting/capabilities https://localhost:9980/hosting/capabilities retry=0
   ProxyPassReverse /hosting/capabilities https://localhost:9980/hosting/capabilities

   ProxyPass /hosting/proxy https://localhost:9980/hosting/proxy retry=0
   ProxyPassReverse /hosting/proxy https://localhost:9980/hosting/proxy

   <Location /loleaflet>
     ProxyPass !
   </Location>
   <Location /hosting/discovery>
     ProxyPass !
   </Location>
   <Location /hosting/capabilities>
     ProxyPass !
   </Location>
   <Location /hosting/proxy>
     ProxyPass !
   </Location>
</VirtualHost>
EOF

# Enable Collabora Online proxy site
sudo a2ensite collabora.conf

# Reload Apache
sudo systemctl reload apache2

# Start the Collabora Online service
sudo systemctl start loolwsd
sudo systemctl enable loolwsd

# Output instructions for Collabora Online configuration in Nextcloud
echo "Collabora Online Code Server has been installed and configured. To enable document editing and collaboration, follow the Nextcloud Collabora Online integration documentation."

# Output instructions to complete Nextcloud setup via web browser
echo "Nextcloud installation complete. Please open a web browser and navigate to http://$NEXTCLOUD_SERVER_NAME/nextcloud to complete the setup."

# Clean up downloaded Nextcloud archive
rm /var/www/html/latest.tar.bz2
