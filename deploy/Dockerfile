# Image backend KopsisKu — PHP 8 + extensi mysqli + Apache.
# Konteks build = root repo (lihat docker-compose.yml).
FROM php:8.4-apache

# extensi mysqli dibutuhkan backend/config/db.php
RUN docker-php-ext-install mysqli \
    && a2enmod rewrite

# Salin hanya backend/ — app/ (Flutter) tidak dibutuhkan di server.
COPY backend/ /var/www/html/backend/

# Folder upload harus bisa ditulis user web (www-data).
RUN mkdir -p /var/www/html/backend/storage/uploads/produk \
             /var/www/html/backend/storage/uploads/profil \
    && chown -R www-data:www-data /var/www/html/backend/storage \
    && chmod -R 775 /var/www/html/backend/storage/uploads

# Jangan layani file sensitif lewat web.
RUN printf '%s\n' \
      '<FilesMatch "\.(sql|log|md|local\.php)$">' \
      '    Require all denied' \
      '</FilesMatch>' \
      'Options -Indexes' \
      > /var/www/html/backend/.htaccess

EXPOSE 80
