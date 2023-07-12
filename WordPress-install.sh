#!/bin/bash

# Update system
apt update
apt upgrade -y

# Install Nginx
apt install nginx -y


# Configure Nginx
cat > /etc/nginx/sites-available/wordpress <<EOF
server {
    listen 80;
    server_name your_domain.com;

    root /var/www/html/wordpress;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

# Restart Nginx
systemctl restart nginx

# Install MySQL/MariaDB
apt install mysql-server -y

# Secure MySQL installation
#mysql_secure_installation

# Create MySQL database and user
MYSQL_ROOT_PASSWORD="dp1ZVK6Ppqg71U5kH&Dugh8BtR4yVv"
MYSQL_DATABASE="wordpress"
MYSQL_USER="wp_user"
MYSQL_PASSWORD="dp1ZVK6Ppqg71U5kH&Dugh8BtR4yVv"

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE ${MYSQL_DATABASE};
CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Install PHP and required extensions
sudo apt-get install -y php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-fpm

# Download and extract WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xf latest.tar.gz
mv wordpress /var/www/html/

# Set permissions
chown -R www-data:www-data /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# Configure WordPress
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sed -i "s/database_name_here/${MYSQL_DATABASE}/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/${MYSQL_USER}/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/${MYSQL_PASSWORD}/" /var/www/html/wordpress/wp-config.php

# Generate unique keys and salts
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wordpress/wp-config.php

# Restart PHP-FPM
systemctl restart php8.1-fpm

# Clean up
rm /tmp/latest.tar.gz

# Done!
echo "WordPress installation is complete. You can access it at http://your_domain.com"
