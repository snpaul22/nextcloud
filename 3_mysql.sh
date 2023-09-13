#!/bin/bash

# Define MySQL variables
read -sp "Enter your root user password: " MYSQL_ROOT_PASSWORD
echo
read -p "Create MySQL database for Nextcloud: " MYSQL_NEXTCLOUD_DB
read -p "Create MySQL username for Nextcloud: " MYSQL_NEXTCLOUD_USER


# Create MySQL database password and confirm
get_password_db() {
    local MYSQL_NEXTCLOUD_PASSWORD MYSQL_NEXTCLOUD_PASSWORD2

    # Prompt for the password
    read -sp "Enter a password: " MYSQL_NEXTCLOUD_PASSWORD
    echo

    # Prompt to confirm the password
    read -sp "Re-enter the password: " MYSQL_NEXTCLOUD_PASSWORD2
    echo

    # Compare the two passwords
    if [ "$MYSQL_NEXTCLOUD_PASSWORD" = "$MYSQL_NEXTCLOUD_PASSWORD2" ]; then
        echo "Password successfully set."
        return 0
    else
        echo "Passwords do not match. Please try again."
        return 1
    fi
}

# MySQL database password creation
echo "Create MySQL Password for Nextcloud Database: "
while true; do
    get_password_db
    if [ $? -eq 0 ]; then
        break
    fi
done

# MySQL secure installation preconfiguration
sudo mysql <<SECURE_INSTALL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
SECURE_INSTALL

# MySQL secure installation
sudo mysql_secure_installation

# Create a MySQL database and user for Nextcloud
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE $MYSQL_NEXTCLOUD_DB;
CREATE USER '$MYSQL_NEXTCLOUD_USER'@'localhost' IDENTIFIED BY '$MYSQL_NEXTCLOUD_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_NEXTCLOUD_DB.* TO '$MYSQL_NEXTCLOUD_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# MySQL secure installation revert
sudo mysql -u root -p <<SECURE_REVERT
ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;
SECURE_REVERT