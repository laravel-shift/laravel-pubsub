FROM php:8.1-fpm
MAINTAINER Superbalist <tech+docker@superbalist.com>

RUN mkdir /opt/laravel-pubsub
WORKDIR /opt/laravel-pubsub

# Packages
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        zlib1g-dev \
        unzip \
        python \
        librdkafka-dev \
        libzip-dev \
    && rm -r /var/lib/apt/lists/*

# PHP Extensions
RUN docker-php-ext-install -j$(nproc) zip

RUN pecl install rdkafka   && \
    docker-php-ext-enable  \
    rdkafka                \
    zip

# Composer
ENV COMPOSER_HOME /composer
ENV PATH /composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php

# Install Composer Application Dependencies
COPY composer.json /opt/laravel-pubsub/
RUN composer install --no-autoloader --no-scripts --no-interaction
RUN composer require superbalist/php-pubsub-kafka

COPY config /opt/laravel-pubsub/config
COPY src /opt/laravel-pubsub/src
COPY tests /opt/laravel-pubsub/tests
COPY phpunit.php /opt/laravel-pubsub/
COPY phpunit.xml /opt/laravel-pubsub/

RUN composer dump-autoload --no-interaction

CMD ["/bin/bash"]
