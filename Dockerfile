FROM php:8.2-fpm-alpine

# Instalar dependências do sistema
RUN apk add --no-cache \
    nginx \
    git \
    supervisor \
    openssl \
    curl \
    mysql-client \
    bash \
    nodejs \
    npm \
    sqlite-dev

# Instalar extensões PHP
RUN docker-php-ext-install pdo_mysql pdo_sqlite opcache

# Configurar diretório de trabalho
WORKDIR /app

# Copiar arquivos do projeto para o container
COPY . /app

# CRÍTICO: Cria um arquivo .env simples
RUN cp .env.example .env

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar dependências do Composer e do NPM
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run build

# Ajustar permissões
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache
RUN chmod -R 775 /app/storage /app/bootstrap/cache

# CORREÇÃO NGINX: Copiar Nginx Config para o arquivo principal
COPY .docker/nginx.conf /etc/nginx/nginx.conf

# CORREÇÃO PHP-FPM: Copiar config do PHP-FPM para corrigir erro de permissão
COPY .docker/fpm.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# Configurar Supervisor para gerenciar Nginx e PHP-FPM
COPY .docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expor a porta 80 (padrão do Nginx)
EXPOSE 80

# Iniciar Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]