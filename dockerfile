FROM php:8.2.5-fpm-alpine3.17

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip openrc curl nano sqlite nginx supervisor


# Add Repositories
RUN rm -f /etc/apk/repositories &&\
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.17/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.17/community" >> /etc/apk/repositories

RUN export PKG_CONFIG_PATH=/usr/lib/pkgconfig

# Add Build Dependencies
RUN apk add --no-cache --virtual .build-deps  \
    zlib-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    bzip2-dev \
    libzip-dev \
    icu-dev \
    gettext \
    gettext-dev \
    imap-dev \
    krb5-dev \
    icu-dev \
    enchant2-dev \
    openldap-dev \
    freetds-dev \
    aspell-dev \
    libxslt-dev 

# Add Production Dependencies
RUN apk add --update --no-cache --virtual \
    php-mbstring \
    php-fpm \
    php-mysqli \
    php-opcache \
    php-phar \
    php-xml \
    php-zip \
    php-zlib \
    php-pdo \
    php-bz2 \
    php-tokenizer \
    php-session \
    php-pdo_mysql \
    php-pdo_sqlite \
    php-calendar \
    mysql-client \
    dcron \
    jpegoptim \
    pngquant \
    optipng \
    freetype-dev \
    curl \
    nginx \
    supervisor \
    nano

# Configure & Install Extension
RUN docker-php-ext-configure \
    opcache --enable-opcache &&\
    docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ && \
    docker-php-ext-configure zip && \
    docker-php-ext-configure imap && \
    docker-php-ext-install \
    opcache \
    mysqli \
    pdo \
    pdo_mysql \
    intl \
    gd \
    xml \
    bz2 \
    pcntl \
    bcmath \
    zip \
    calendar \
    exif \
    gettext \
    imap \
    soap \
    dba \
    enchant \
    ffi \
    ldap \
    pdo_dblib \
    pspell \
    shmop \
    sysvmsg \
    sysvsem \
    sysvshm \
    xsl \
    sockets


RUN apk add --no-cache ${PHPIZE_DEPS} imagemagick imagemagick-dev
RUN pecl install -o -f imagick\
    &&  docker-php-ext-enable \
        imagick \
        soap
RUN apk del --no-cache ${PHPIZE_DEPS}


# Install modules
RUN php -m


# Add Composer
COPY --from=composer:2.5.4 /usr/bin/composer /usr/local/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

COPY opcache.ini $PHP_INI_DIR/conf.d/
COPY php.ini $PHP_INI_DIR/conf.d/

# Setup Crond and Supervisor by default
RUN echo '*  *  *  *  * /usr/local/bin/php  /var/www/artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/root && mkdir /etc/supervisor.d
ADD master.ini /etc/supervisor.d/
ADD default.conf /etc/nginx/conf.d/
ADD nginx.conf /etc/nginx/
RUN chown -R www-data:www-data /var/lib/nginx

# Remove Build Dependencies
# RUN apk del -f .build-deps
# Setup Working Dir
WORKDIR /var/www/html

CMD ["/usr/bin/supervisord"]
