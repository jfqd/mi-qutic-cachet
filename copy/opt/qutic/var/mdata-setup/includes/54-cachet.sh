
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
cd /var/www/htdocs/cachet

APP_URL="https://${SERVER_NAME}"
APP_KEY=$(php artisan key:generate)

if mdata-get proxysql_database 1>/dev/null 2>&1; then
  DB_HOST=`mdata-get database_host`
else
  DB_HOST="127.0.0.1"
fi

if mdata-get proxysql_database 1>/dev/null 2>&1; then
  DB_DATABASE=`mdata-get database_name`
else
  DB_DATABASE="cachet"
fi

DB_USERNAME=`mdata-get database_user`
DB_PASSWORD=`mdata-get database_pwd`

MAIL_HOST=$(mdata-get mail_smarthost)
MAIL_USERNAME=$(mdata-get mail_auth_user)
MAIL_PASSWORD=$(mdata-get mail_auth_pass)
MAIL_ADDRESS=$(mdata-get mail_adminaddr)

cat >> .env << EOF
APP_NAME=Cachet
APP_ENV=local
APP_KEY=${APP_KEY}
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_URL=${APP_URL}

APP_LOCALE=de
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

APP_MAINTENANCE_DRIVER=file
# APP_MAINTENANCE_STORE=database

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_UNIX_SOCKET=null
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_PORT=3306
DB_PREFIX=null

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database

CACHE_STORE=database
CACHE_PREFIX=

MEMCACHED_HOST=127.0.0.1

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_HOST=mail.qutic.com
MAIL_PORT=587
MAIL_USERNAME=${MAIL_USERNAME}
MAIL_PASSWORD=${MAIL_PASSWORD}
MAIL_FROM_ADDRESS=${MAIL_ADDRESS}
MAIL_FROM_NAME="Status Page"
MAIL_ENCRYPTION=tls


AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

VITE_APP_NAME="${APP_NAME}"

CACHET_BEACON=false
CACHET_EMOJI=false
CACHET_AUTO_TWITTER=false
CACHET_PATH=/
CACHET_TRUSTED_PROXIES=""

NIGHTWATCH_ENABLED=false
EOF

chmod 0640 .env
chown -R www:www /var/www/htdocs/cachet

# install dependencies, create app-key and run migrations
sudo -u www "yes no |composer install --no-dev -o" || true
sudo -u www "yes | composer update cachethq/core"  || true
chown -R www:www /var/www/htdocs/cachet

sudo -u www "php artisan vendor:publish --tag=cachet" || true
sudo -u www "php artisan migrate" || true

chown -R www:www /var/www/htdocs/cachet

# * * * * * php artisan schedule:run >> /dev/null 2>&1

# Enable apache by default
/usr/sbin/svcadm enable svc:/pkgsrc/apache:default
