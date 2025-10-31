#!/usr/bin/env bash
# ==========================================================
# ReserveAgenda - Script de instalação interna (v1.2c)
# ==========================================================
set -euo pipefail
APP_PATH=${1:-/home/deploy/reserveagenda}
APP_NAME=${2:-ReserveAgenda}
APP_DOMAIN=${3:-localhost}
USE_MYSQL=${4:-y}
DB_HOST=${5:-127.0.0.1}
DB_PORT=${6:-3306}
DB_DATABASE=${7:-reserveagenda}
DB_USERNAME=${8:-usuario}
DB_PASSWORD=${9:-senha}

echo "=========================================================="
echo "🚀 Instalando ReserveAgenda em ${APP_PATH}"
echo "=========================================================="

mkdir -p "$APP_PATH"
cd "$APP_PATH"

echo "📦 Clonando repositório principal..."
git clone -b main https://github.com/Elton-Coelho/reserveagenda-core.git "$APP_PATH" >/dev/null 2>&1 || true

echo "⚙️ Instalando dependências Laravel..."
composer install --no-dev --prefer-dist -q

cp .env.example .env || true
php artisan key:generate --force

if [[ "$USE_MYSQL" =~ ^[Yy] ]]; then
  sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
  sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" .env
  sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" .env
  sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env
  sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env
  sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
else
  sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env
fi

php artisan migrate --force || true

echo "=========================================================="
echo "✅ ${APP_NAME} instalado com sucesso!"
echo "🌐 http://${APP_DOMAIN}"
echo "📁 Caminho: ${APP_PATH}"
echo "=========================================================="
