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

# CRÍTICO: Cria um arquivo .env simples para que comandos Artisan/NPM funcionem no Build
RUN cp .env.example .env

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar dependências do Composer e do NPM
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run build

# A linha "key:generate" FOI REMOVIDA COMPLETAMENTE daqui para evitar a falha.

# Ajustar permissões
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache
RUN chmod -R 775 /app/storage /app/bootstrap/cache

# Configurar Nginx
COPY .docker/nginx.conf /etc/nginx/conf.d/default.conf

# Configurar Supervisor para gerenciar Nginx e PHP-FPM
COPY .docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expor a porta 80 (padrão do Nginx)
EXPOSE 80

# Iniciar Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]