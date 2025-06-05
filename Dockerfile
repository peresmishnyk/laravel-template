FROM composer:2 as vendor

WORKDIR /app

COPY database/ database/
COPY composer.json composer.json
COPY composer.lock composer.lock

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist


FROM php:8.3-fpm-alpine AS app

ARG APP_ENV=production

RUN apk add --no-cache \
    # build-base and libtool are needed for pecl extensions
    build-base \
    libtool \
    # mcrypt is deprecated but some projects might still use it
    # libmcrypt-dev \
    # Common PHP extensions
    icu-dev \
    libxml2-dev \
    libzip-dev \
    oniguruma-dev \
    sqlite-dev \
    # For PostgreSQL
    postgresql-dev \
    # For MySQL
    # mysql-client \
    # For Redis
    hiredis \
    && docker-php-ext-install \
    bcmath \
    ctype \
    # dba \
    dom \
    exif \
    gd \
    iconv \
    intl \
    # ldap \
    # mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    # phar \
    posix \
    # soap \
    sockets \
    # sodium \
    # sysvmsg \
    # sysvsem \
    # sysvshm \
    # tokenizer \
    xml \
    # xmlreader \
    # xmlrpc \
    # xmlwriter \
    # xsl \
    zip \
    && pecl install redis \
    && docker-php-ext-enable redis

# If you are using a different user for your application,
# make sure to change the user and group here
RUN addgroup -g 1000 -S laravel && \
    adduser -u 1000 -S laravel -G laravel

WORKDIR /var/www/html

COPY --from=vendor /app/vendor/ /var/www/html/vendor/
COPY . /var/www/html/

RUN chown -R laravel:laravel /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    # Fix permissions for writable directories
    # These directories need to be writable by the web server
    chown -R laravel:laravel /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R ug+w /var/www/html/storage /var/www/html/bootstrap/cache && \
    # Remove unnecessary files from the image
    rm -rf /var/www/html/tests && \
    # Optimize autoloader
    composer dump-autoload --optimize --no-dev --classmap-authoritative && \
    # Clear caches
    php artisan optimize:clear && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

USER laravel

EXPOSE 9000

CMD ["php-fpm"]
