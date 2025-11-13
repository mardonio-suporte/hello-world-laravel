FROM php:8.2-fpm-alpine

# Instalar dependàncias do sistema
RUN apk add --no-cache \
    nginx \
    git \
    supervisor \
    openssl \
    curl \
    mysql-client \
    bash \
    nodejs \
    npm

# Instalar extens‰es PHP
RUN docker-php-ext-install pdo_mysql opcache

# Configurar diret¢rio de trabalho
WORKDIR /app

# Copiar arquivos do projeto para o container
COPY . /app

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar dependàncias do Composer e do NPM
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run build

# Gerar chave da aplicaá∆o (necess†rio para o primeiro deploy)
#RUN php artisan key:generate --no-interaction

# Ajustar permiss‰es
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache
RUN chmod -R 775 /app/storage /app/bootstrap/cache

# Configurar Nginx
COPY .docker/nginx.conf /etc/nginx/conf.d/default.conf

# Configurar Supervisor para gerenciar Nginx e PHP-FPM
COPY .docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expor a porta 80 (padr∆o do Nginx)
EXPOSE 80

# Iniciar Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]