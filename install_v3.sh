#!/bin/bash
# ============================================================
# install.sh — Zipay Russia Installer
# Tested: Ubuntu 24.04 LTS & Debian 13
# ============================================================
set -e

# =================== KONFIGURASI ====================
APP_DIR="/var/www/zipayrussia"
DB_NAME="zipay_db"
DB_USER="zipay_user"
DB_PASS="ZipayStr0ng2025!"   # <<< GANTI PASSWORD INI
APP_URL="http://localhost"    # <<< GANTI DENGAN IP/DOMAIN VPS
# ====================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

info "Memulai instalasi Zipay Russia..."
[[ $EUID -ne 0 ]] && error "Jalankan sebagai root: sudo bash install.sh"

# Deteksi OS & versi PHP
OS_ID=$(. /etc/os-release && echo "$ID")
OS_VERSION=$(. /etc/os-release && echo "$VERSION_ID" | cut -d. -f1)
info "OS terdeteksi: $OS_ID $OS_VERSION"

# ============================================================
# LANGKAH 1: Update & install dependensi dasar
# ============================================================
info "[1/10] Update sistem..."
apt-get update -qq
apt-get install -y -qq curl wget unzip git software-properties-common lsb-release ca-certificates

# ============================================================
# LANGKAH 2: Install PHP
# ============================================================
info "[2/10] Install PHP..."

PHP_VERSION=""
if [[ "$OS_ID" == "ubuntu" ]]; then
    # Ubuntu: gunakan ondrej/php PPA
    add-apt-repository -y ppa:ondrej/php 2>/dev/null || true
    apt-get update -qq
    PHP_VERSION="8.3"
    apt-get install -y -qq \
        php8.3 php8.3-fpm php8.3-cli php8.3-common \
        php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl \
        php8.3-zip php8.3-bcmath php8.3-intl php8.3-gd \
        php8.3-tokenizer php8.3-fileinfo
elif [[ "$OS_ID" == "debian" ]]; then
    # Debian: PHP 8.4 tersedia langsung
    PHP_VERSION="8.4"
    apt-get install -y -qq \
        php8.4 php8.4-fpm php8.4-cli php8.4-common \
        php8.4-mysql php8.4-mbstring php8.4-xml php8.4-curl \
        php8.4-zip php8.4-bcmath php8.4-intl php8.4-gd \
        php8.4-tokenizer php8.4-fileinfo
else
    warn "OS tidak dikenal, mencoba install PHP 8.3..."
    PHP_VERSION="8.3"
    apt-get install -y -qq php php-fpm php-cli php-mysql php-mbstring \
        php-xml php-curl php-zip php-bcmath php-intl php-gd 2>/dev/null || \
    apt-get install -y php8.3 php8.3-fpm php8.3-mysql php8.3-mbstring \
        php8.3-xml php8.3-curl php8.3-zip php8.3-bcmath
fi

PHP_FPM_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"
info "PHP $PHP_VERSION terinstall. Socket: $PHP_FPM_SOCK"

# ============================================================
# LANGKAH 3: Install Nginx
# ============================================================
info "[3/10] Install Nginx..."
apt-get install -y -qq nginx

# ============================================================
# LANGKAH 4: Install MariaDB
# ============================================================
info "[4/10] Install MariaDB..."
apt-get install -y -qq mariadb-server mariadb-client

# Start MariaDB
mysqld_safe --datadir='/var/lib/mysql' > /tmp/mariadb_install.log 2>&1 &
sleep 4

# Cek socket tersedia
MYSQL_SOCKET=""
for sock in /run/mysqld/mysqld.sock /var/run/mysqld/mysqld.sock /tmp/mysql.sock; do
    if [ -S "$sock" ]; then
        MYSQL_SOCKET="$sock"
        break
    fi
done

if [ -z "$MYSQL_SOCKET" ]; then
    systemctl start mariadb 2>/dev/null || service mariadb start 2>/dev/null || true
    sleep 3
    for sock in /run/mysqld/mysqld.sock /var/run/mysqld/mysqld.sock; do
        [ -S "$sock" ] && MYSQL_SOCKET="$sock" && break
    done
fi

[ -z "$MYSQL_SOCKET" ] && error "MariaDB socket tidak ditemukan. Cek: journalctl -u mariadb"
info "MariaDB running. Socket: $MYSQL_SOCKET"

# ============================================================
# LANGKAH 5: Install Composer
# ============================================================
info "[5/10] Install Composer..."
if ! command -v composer &>/dev/null; then
    curl -sS https://getcomposer.org/installer | php -- --quiet
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi
info "Composer $(composer --version --no-ansi | head -1)"

# ============================================================
# LANGKAH 6: Setup Database
# ============================================================
info "[6/10] Setup database..."
mysql --socket="$MYSQL_SOCKET" -u root <<MYSQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL

info "Database ${DB_NAME} dan user ${DB_USER} dibuat."

# Import SQL schema
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/zipay_database.sql" ]; then
    mysql --socket="$MYSQL_SOCKET" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "${SCRIPT_DIR}/zipay_database.sql"
    info "Schema database diimport."
elif [ -f "/tmp/zipay_database.sql" ]; then
    mysql --socket="$MYSQL_SOCKET" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "/tmp/zipay_database.sql"
    info "Schema database diimport dari /tmp."
else
    warn "zipay_database.sql tidak ditemukan. Jalankan migrasi manual: php artisan migrate"
fi

# ============================================================
# LANGKAH 7: Deploy aplikasi
# ============================================================
info "[7/10] Deploy source code..."
mkdir -p "$(dirname "$APP_DIR")"

# Copy source jika script ada di dalam folder project
if [ -f "${SCRIPT_DIR}/artisan" ]; then
    cp -r "${SCRIPT_DIR}" "$APP_DIR" 2>/dev/null || \
    rsync -a --exclude='.git' --exclude='node_modules' --exclude='vendor' \
        "${SCRIPT_DIR}/" "$APP_DIR/"
    info "Source code dicopy ke $APP_DIR"
else
    info "Diasumsikan sudah ada di $APP_DIR"
fi

cd "$APP_DIR"

# ============================================================
# LANGKAH 8: Composer install
# ============================================================
info "[8/10] Install PHP dependencies..."
sudo -u www-data composer install --no-dev --optimize-autoloader --no-interaction 2>&1 \
    || composer install --no-dev --optimize-autoloader --no-interaction 2>&1

# ============================================================
# LANGKAH 9: Konfigurasi .env
# ============================================================
info "[9/10] Konfigurasi .env..."

[ -f .env.production ] && cp .env.production .env || cp .env.example .env

# Update nilai kritis
sed -i "s|APP_URL=.*|APP_URL=${APP_URL}|" .env
sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=mariadb|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env
sed -i "s|DB_SOCKET=.*|DB_SOCKET=${MYSQL_SOCKET}|" .env
sed -i "s|API_BASE_URL=.*|API_BASE_URL=https://apidev.zipay.id|" .env

# Tambahkan DB_SOCKET jika belum ada
grep -q "DB_SOCKET" .env || echo "DB_SOCKET=${MYSQL_SOCKET}" >> .env

# ============================================================
# LANGKAH 10: Finalisasi
# ============================================================
info "[10/10] Finalisasi..."

# Permission
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"
chmod -R 775 "$APP_DIR/storage"
chmod -R 775 "$APP_DIR/bootstrap/cache"
chmod 644 "$APP_DIR/.env"

# Artisan commands sebagai www-data
sudo -u www-data php "$APP_DIR/artisan" key:generate --force 2>&1

# Storage link manual (lebih reliable dari artisan storage:link)
[ -d "$APP_DIR/storage/app/public" ] || mkdir -p "$APP_DIR/storage/app/public"
[ -L "$APP_DIR/public/storage" ] || \
    ln -sf "$APP_DIR/storage/app/public" "$APP_DIR/public/storage"

# Migrasi (jika schema belum diimport)
sudo -u www-data php "$APP_DIR/artisan" migrate --force 2>&1 || true

# Cache production
sudo -u www-data php "$APP_DIR/artisan" config:cache 2>&1
sudo -u www-data php "$APP_DIR/artisan" route:cache 2>&1
sudo -u www-data php "$APP_DIR/artisan" view:cache 2>&1

# ============================================================
# Konfigurasi Nginx
# ============================================================
info "Konfigurasi Nginx..."
cat > /etc/nginx/sites-available/zipayrussia << NGINX
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root ${APP_DIR}/public;
    index index.php index.html;

    charset utf-8;
    client_max_body_size 20M;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_FPM_SOCK};
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
}
NGINX

ln -sf /etc/nginx/sites-available/zipayrussia /etc/nginx/sites-enabled/zipayrussia
rm -f /etc/nginx/sites-enabled/default

nginx -t || error "Konfigurasi Nginx gagal! Cek: nginx -t"

# Start/Restart services
for svc in "php${PHP_VERSION}-fpm" nginx; do
    systemctl enable "$svc" 2>/dev/null || true
    systemctl restart "$svc" 2>/dev/null || service "$svc" restart 2>/dev/null || true
done

# ============================================================
# Selesai
# ============================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ INSTALASI ZIPAY RUSSIA BERHASIL!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  📌 URL Aplikasi : ${APP_URL}"
echo "  📂 App Dir      : ${APP_DIR}"
echo "  🗄️  Database     : ${DB_NAME} @ ${MYSQL_SOCKET}"
echo "  🐘 PHP          : ${PHP_VERSION} (FPM: ${PHP_FPM_SOCK})"
echo ""
echo "  🔍 Health check :"
echo "     curl -I ${APP_URL}/up"
echo ""
echo "  📋 Log error    :"
echo "     tail -f ${APP_DIR}/storage/logs/laravel.log"
echo "     tail -f /var/log/nginx/error.log"
echo ""
