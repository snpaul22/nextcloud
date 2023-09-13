#!/bin/bash

# Create MySQL root password and confirm
get_password_mysql() {
    local MYSQL_ROOT_PASSWORD MYSQL_ROOT_PASSWORD2

    # Prompt for the password
    read -sp "Enter a password: " MYSQL_ROOT_PASSWORD
    echo

    # Prompt to confirm the password
    read -sp "Confirm the password: " MYSQL_ROOT_PASSWORD2
    echo

    # Compare the two passwords
    if [ "$MYSQL_ROOT_PASSWORD" = "$MYSQL_ROOT_PASSWORD2" ]; then
        echo "Password successfully set."
        return 0
    else
        echo "Passwords do not match. Please try again."
        return 1
    fi
}

# MySQL root password creation
echo "Create MySQL root password: "
while true; do
    get_password_mysql
    if [ $? -eq 0 ]; then
        break
    fi
done

read -p "Create MySQL Database for NextCloud Database: " MYSQL_NEXTCLOUD_DB
break
read -p "Create MySQL Username for NextCloud Database: " MYSQL_NEXTCLOUD_USER
break
read -sp "" MYSQL_NEXTCLOUD_PASSWORD

# Create MySQL database password and confirm
get_password_db() {
    local MYSQL_NEXTCLOUD_PASSWORD MYSQL_NEXTCLOUD_PASSWORD2

    # Prompt for the password
    read -sp "Enter a password: " MYSQL_NEXTCLOUD_PASSWORD
    echo

    # Prompt to confirm the password
    read -sp "Confirm the password: " MYSQL_NEXTCLOUD_PASSWORD2
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
echo "Create MySQL Password for NextCloud Database: "
while true; do
    get_password
    if [ $? -eq 0 ]; then
        break
    fi
done

# Create a MySQL database and user for Nextcloud
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE $MYSQL_NEXTCLOUD_DB;
CREATE USER '$MYSQL_NEXTCLOUD_USER'@'localhost' IDENTIFIED BY '$MYSQL_NEXTCLOUD_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_NEXTCLOUD_DB.* TO '$MYSQL_NEXTCLOUD_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT