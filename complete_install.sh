#!/bin/bash

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
   ServerName your_server_domain_or_IP

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
MYSQL_ROOT_PASSWORD="your_mysql_root_password"
MYSQL_NEXTCLOUD_USER="nextcloud_user"
MYSQL_NEXTCLOUD_PASSWORD="your_mysql_nextcloud_password"
MYSQL_NEXTCLOUD_DB="nextcloud_db"

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

# Output instructions to complete Nextcloud setup via web browser
echo "Nextcloud installation complete. Please open a web browser and navigate to http://your_server_domain_or_IP/nextcloud to complete the setup."

# Clean up downloaded Nextcloud archive
rm /var/www/html/latest.tar.bz2
