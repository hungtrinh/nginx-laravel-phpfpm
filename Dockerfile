# Build app vendor 
FROM composer:latest as composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN set -e; \
    composer install --prefer-dist --no-scripts --no-dev --optimize-autoloader && \
    composer clear-cache
COPY . .
RUN set -e; \
    composer dump-autoload --no-scripts --no-dev --optimize


# Depending on the composer you use, you may be required to use a different php version.
FROM php:8.2-fpm as app

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \ 
    libjpeg-dev \
    libgd-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
#Mine

# Install extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --with-external-gd
RUN docker-php-ext-install gd

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www


# Copy existing application directory permissions
COPY --from=composer --chown=www:www /app/ /var/www/

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]

# https://hub.docker.com/_/nginx please search and read section "Using environment variables in nginx configuration (new in 1.19)"
FROM nginx:alpine as app-webserver
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d/

COPY app-webserver-nginx.conf.template /etc/nginx/templates/
COPY public/ /var/www/public

RUN rm /etc/nginx/conf.d/default.conf