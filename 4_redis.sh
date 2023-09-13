#!/bin/bash

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