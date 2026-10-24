# Backend KopsisKu — PHP + Apache.
FROM php:8.3-apache

# Ekstensi yang dipakai backend: mysqli, mbstring, curl (fileinfo bawaan PHP).
# libonig-dev dibutuhkan mbstring.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libcurl4-openssl-dev libonig-dev \
 && docker-php-ext-install mysqli mbstring curl \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/*

# .htaccess butuh AllowOverride All (memblokir .sql/.env/*.local.php).
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# API hidup di /koperasi_siswa/backend — cocok dengan APP_PREFIX=/koperasi_siswa.
COPY backend /var/www/html/koperasi_siswa/backend
