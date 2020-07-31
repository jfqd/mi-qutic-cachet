
if mdata-get server_name 1>/dev/null 2>&1; then
  SERVER_NAME=`mdata-get server_name`
  sed -i "s:SERVER_NAME:$SERVER_NAME:g" /opt/local/etc/httpd/vhosts/01-cachet.conf
else
  SERVER_NAME=""
  sed -i "s:ServerName SERVER_NAME::g" /opt/local/etc/httpd/vhosts/01-cachet.conf
fi

if mdata-get server_alias 1>/dev/null 2>&1; then
  SERVER_ALIAS=`mdata-get server_alias`
  sed -i "s:SERVER_ALIAS:$SERVER_ALIAS:g" /opt/local/etc/httpd/vhosts/01-cachet.conf
else
  sed -i "s:ServerAlias SERVER_ALIAS::g" /opt/local/etc/httpd/vhosts/01-cachet.conf
fi

# setup env-file
cd /var/www/htdocs/Cachet

APP_URL="https://${SERVER_NAME}"
APP_KEY=$(php artisan key:generate)

if mdata-get proxysql_database 1>/dev/null 2>&1; then
  DB_DATABASE=`mdata-get proxysql_database`
else
  DB_DATABASE="cachet"
fi

DB_USERNAME=`mdata-get proxysql_database_user`
DB_PASSWORD=`mdata-get proxysql_database_pwd`

MAIL_HOST=$(mdata-get mail_smarthost)
MAIL_USERNAME=$(mdata-get mail_auth_user)
MAIL_PASSWORD=$(mdata-get mail_auth_pass)
MAIL_ADDRESS=$(mdata-get mail_adminaddr)

cat >> .env << EOF
APP_ENV=production
APP_DEBUG=false
APP_URL=${APP_URL}
APP_KEY=${APP_KEY}

DB_DRIVER=mysql
DB_HOST=localhost
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_PORT=3306

CACHE_DRIVER=apc
SESSION_DRIVER=apc
QUEUE_DRIVER=sync
CACHET_EMOJI=false

MAIL_DRIVER=smtp
MAIL_HOST=${MAIL_HOST}
MAIL_PORT=587
MAIL_USERNAME=${MAIL_USERNAME}
MAIL_PASSWORD=${MAIL_PASSWORD}
MAIL_ADDRESS=${MAIL_ADDRESS}
MAIL_NAME="Status Page"
MAIL_ENCRYPTION=tls

REDIS_HOST=null
REDIS_DATABASE=null
REDIS_PORT=null

GITHUB_TOKEN=null
EOF

chmod 0640 .env
chown -R www:www /var/www/htdocs/Cachet

# install dependencies, create app-key and run migrations
sudo -u www composer install --no-dev -o || true
sudo -u www php artisan app:install || true
sudo -u www php artisan config:cache || true

chown -R www:www /var/www/htdocs/Cachet

# Enable apache by default
/usr/sbin/svcadm enable svc:/pkgsrc/apache:default
