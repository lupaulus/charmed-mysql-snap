#!/bin/bash

set -eo pipefail

# PHPMyAdmin configuration
PHPMYADMIN_PORT="${PHPMYADMIN_PORT:-8080}"
PHP_VERSION="8.1"

# Set up directories
mkdir -p "${SNAP_DATA}/etc/nginx/sites-available"
mkdir -p "${SNAP_DATA}/etc/nginx/sites-enabled"
mkdir -p "${SNAP_COMMON}/var/lib/nginx"
mkdir -p "${SNAP_COMMON}/var/log/nginx"
mkdir -p "${SNAP_COMMON}/run/php"
mkdir -p "${SNAP_DATA}/etc/phpmyadmin"
mkdir -p "${SNAP_COMMON}/var/lib/phpmyadmin/tmp"

# Configure PHPMyAdmin
if [ ! -f "${SNAP_DATA}/etc/phpmyadmin/config.inc.php" ]; then
    cat > "${SNAP_DATA}/etc/phpmyadmin/config.inc.php" << 'EOF'
<?php
/* phpMyAdmin configuration for MySQL snap */
$cfg['blowfish_secret'] = 'charmed-mysql-snap-secret-key-change-me';

$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['socket'] = '/var/snap/charmed-mysql/common/var/run/mysqld/mysqld.sock';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

$cfg['UploadDir'] = '/var/snap/charmed-mysql/common/var/lib/phpmyadmin/upload';
$cfg['SaveDir'] = '/var/snap/charmed-mysql/common/var/lib/phpmyadmin/save';
$cfg['TempDir'] = '/var/snap/charmed-mysql/common/var/lib/phpmyadmin/tmp';
?>
EOF
fi

# Link PHPMyAdmin config
ln -sf "${SNAP_DATA}/etc/phpmyadmin/config.inc.php" "${SNAP}/usr/share/phpmyadmin/config.inc.php" 2>/dev/null || true

# Configure nginx
cat > "${SNAP_DATA}/etc/nginx/nginx.conf" << EOF
daemon off;
user snap_daemon;
worker_processes auto;
pid ${SNAP_COMMON}/run/nginx.pid;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include ${SNAP}/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    access_log ${SNAP_COMMON}/var/log/nginx/access.log;
    error_log ${SNAP_COMMON}/var/log/nginx/error.log;
    
    gzip on;
    
    server {
        listen ${PHPMYADMIN_PORT};
        server_name localhost;
        
        root ${SNAP}/usr/share/phpmyadmin;
        index index.php index.html index.htm;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
        
        location ~ \.php$ {
            include ${SNAP}/etc/nginx/fastcgi_params;
            fastcgi_pass unix:${SNAP_COMMON}/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
        
        location ~* ^.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
            access_log off;
            expires max;
        }
    }
}
EOF

# Configure PHP-FPM
cat > "${SNAP_DATA}/etc/php-fpm.conf" << EOF
[global]
pid = ${SNAP_COMMON}/run/php/php${PHP_VERSION}-fpm.pid
error_log = ${SNAP_COMMON}/var/log/nginx/php${PHP_VERSION}-fpm.log

[www]
user = snap_daemon
group = snap_daemon
listen = ${SNAP_COMMON}/run/php/php${PHP_VERSION}-fpm.sock
listen.owner = snap_daemon
listen.group = snap_daemon
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF

# Set proper permissions
chown -R snap_daemon:snap_daemon "${SNAP_COMMON}/var/lib/phpmyadmin" || true
chown -R snap_daemon:snap_daemon "${SNAP_COMMON}/var/lib/nginx" || true
chown -R snap_daemon:snap_daemon "${SNAP_COMMON}/var/log/nginx" || true
chown -R snap_daemon:snap_daemon "${SNAP_COMMON}/run/php" || true

# Start PHP-FPM
"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon \
    -- \
    "${SNAP}/usr/sbin/php-fpm${PHP_VERSION}" \
    --nodaemonize \
    --fpm-config "${SNAP_DATA}/etc/php-fpm.conf" &

PHP_FPM_PID=$!

# Give PHP-FPM time to start
sleep 2

# Start nginx
"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon \
    -- \
    "${SNAP}/usr/sbin/nginx" \
    -c "${SNAP_DATA}/etc/nginx/nginx.conf" &

NGINX_PID=$!

# Wait for both processes
wait $PHP_FPM_PID $NGINX_PID
