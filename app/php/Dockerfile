ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm

# install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libxpm-dev \
    zip \
    unzip

# clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# configure GD with JPEG, WebP, FreeType support
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-xpm

# install php extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# redis extension (will be installed conditionally)
ARG USE_REDIS=false
RUN if [ "${USE_REDIS}" = "true" ] ; then \
    pecl install redis && \
    docker-php-ext-enable redis \
    ; fi

# install xdebug
RUN pecl install xdebug-3.4.2 && docker-php-ext-enable xdebug

# get latest composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN mkdir -p /var/log/php /var/www/html/storage/xdebug \
    && chown -R www-data:www-data /var/log/php /var/www/html/storage/xdebug

# set working directory
WORKDIR /var/www/html

# set user permissions
RUN chown -R www-data:www-data /var/www/html
