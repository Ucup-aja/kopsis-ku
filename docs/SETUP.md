# Setup Detail

## Fresh Install

```bash
sudo dnf install php php-mysqlnd mariadb-server httpd   # Fedora
sudo systemctl enable --now mariadb httpd
sudo mariadb < backend/database/schema.sql
mariadb -u flutter_app -p'ucup1211' -e "SHOW TABLES FROM koperasi_siswa;"

sudo chown -R apache:apache backend/storage/uploads
sudo chmod -R 775 backend/storage/uploads
sudo restorecon -Rv /var/www/html/koperasi_siswa  # SELinux

cd app && flutter pub get
flutter run -d linux   # atau chrome
```

## Reset Data

```bash
mariadb -u flutter_app -p'ucup1211' -e "
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE koperasi_siswa.transaksi;
TRUNCATE koperasi_siswa.produk;
TRUNCATE koperasi_siswa.pengguna;
SET FOREIGN_KEY_CHECKS=1;"
rm -f backend/storage/uploads/produk/* backend/storage/uploads/profil/*
```

## Ganti Kredensial DB

Edit `backend/config/db.php` dan `backend/database/schema.sql` (GRANT) — lalu reload MariaDB.
