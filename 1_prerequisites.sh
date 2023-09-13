#!/bin/bash

# Update system packages
sudo apt update
sudo apt upgrade -y

# Import required signing keys
sudo wget https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg -P /usr/share/keyrings

# Add required repositories
sudo add-apt-repository ppa:ondrej/php
echo -e "
Types: deb\
URIs: https://www.collaboraoffice.com/repos/CollaboraOnline/CODE-deb\
Suites: ./\
Signed-By: /usr/share/keyrings/collaboraonline-release-keyring.gpg" | sudo tee /etc/apt/sources.list.d/collaboraonline.sources

# Update system packages again
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y apache2 mysql-server php8.2 php8.2-mysql php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-xml php8.2-zip php8.2-imagick libmagickcore-dev libapache2-mod-php8.2 redis-server php-redis coolwsd code-brand

# Enable Apache modules
sudo a2enmod rewrite headers env dir mime setenvif ssl