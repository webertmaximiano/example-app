ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm

## Diretório da aplicação
ARG APP_DIR=/var/www/app

## Versão da Lib do Redis para PHP
ARG REDIS_LIB_VERSION=6.1.0RC1

### apt-utils é um extensão de recursos do gerenciador de pacotes APT
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    apt-utils \
    supervisor \
    nginx

# Dependências para PHP e outras bibliotecas
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libzip-dev \
    unzip \
    libpng-dev \
    libpq-dev \
    libxml2-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql pdo_pgsql pgsql session xml

# Instala Redis e outras extensões
RUN pecl install redis-${REDIS_LIB_VERSION} \
    && docker-php-ext-enable redis 

RUN docker-php-ext-install zip iconv simplexml pcntl gd fileinfo

# Instala Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copia as configurações do Supervisor e PHP
COPY ./docker/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./docker/supervisord/conf /etc/supervisord.d/
COPY ./docker/php/extra-php.ini "$PHP_INI_DIR/99_extra.ini"
COPY ./docker/php/extra-php-fpm.conf /etc/php8/php-fpm.d/www.conf

# Configuração do Nginx
RUN rm -rf /etc/nginx/sites-enabled/* && rm -rf /etc/nginx/sites-available/*
COPY ./docker/nginx/sites.conf /etc/nginx/sites-enabled/default.conf
COPY ./docker/nginx/error.html /var/www/html/error.html

# Configuração da aplicação
WORKDIR $APP_DIR
COPY --chown=www-data:www-data ./ .
RUN chown www-data:www-data $APP_DIR

# Limpeza de cache do APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Comando de inicialização usando supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
