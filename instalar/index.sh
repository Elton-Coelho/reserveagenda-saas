#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

info(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[1;33m[AVISO]\e[0m $*"; }
err(){  echo -e "\e[1;31m[ERRO]\e[0m $*"; }

echo
info "🧠 Iniciando instalador automático do sistema ReserveAgenda..."

DEFAULT_URL="https://github.com/Elton-Coelho/reserveagenda-saas/raw/main/releases/reserveagenda-tools-v1.2.zip"
read -r -p "URL do pacote (ZIP) [${DEFAULT_URL}]: " REPO_URL
REPO_URL=${REPO_URL:-$DEFAULT_URL}
REPO_URL=$(echo "$REPO_URL" | tr -d '\r' | xargs)

read -r -p "Nome da empresa (APP_NAME) [ReserveAgenda]: " APP_NAME
APP_NAME=${APP_NAME:-ReserveAgenda}

read -r -p "Domínio ou IP (sem http://) [144.126.135.75]: " APP_DOMAIN
APP_DOMAIN=${APP_DOMAIN:-144.126.135.75}

read -r -p "Diretório de instalação [/home/deploy/reserveagenda]: " APP_PATH
APP_PATH=${APP_PATH:-/home/deploy/reserveagenda}

read -r -p "Conectar banco MySQL? (y = sim / n = sqlite) [y]: " USE_MYSQL
USE_MYSQL=${USE_MYSQL:-y}

if [[ "$USE_MYSQL" =~ ^[Yy] ]]; then
  read -r -p "DB_HOST [127.0.0.1]: " DB_HOST; DB_HOST=${DB_HOST:-127.0.0.1}
  read -r -p "DB_PORT [3306]: " DB_PORT; DB_PORT=${DB_PORT:-3306}
  read -r -p "DB_DATABASE [reserveagenda]: " DB_DATABASE; DB_DATABASE=${DB_DATABASE:-reserveagenda}
  read -r -p "DB_USERNAME [usuario]: " DB_USERNAME; DB_USERNAME=${DB_USERNAME:-usuario}
  read -r -p "DB_PASSWORD [senha]: " DB_PASSWORD; DB_PASSWORD=${DB_PASSWORD:-senha}
else
  DB_HOST="localhost"; DB_PORT="3306"; DB_DATABASE="sqlite"; DB_USERNAME=""; DB_PASSWORD=""
fi

info "🔧 Instalando pacotes necessários..."
apt update -y && apt install -y unzip curl git apache2 php php-cli php-mbstring php-xml php-curl php-zip composer libapache2-mod-php php-sqlite3 php-mysql
a2enmod rewrite headers >/dev/null 2>&1 || true
systemctl enable apache2 >/dev/null 2>&1

info "📁 Criando estrutura de pastas..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH"
cd "$APP_PATH"

info "⬇️ Baixando pacote de instalação..."
curl -L --fail -o /tmp/reserveagenda-tools.zip "$REPO_URL" || { err "Falha ao baixar o pacote."; exit 1; }

if [[ ! -s /tmp/reserveagenda-tools.zip ]]; then
  err "O arquivo ZIP baixado está vazio ou corrompido."
  exit 1
fi

unzip -q /tmp/reserveagenda-tools.zip -d /tmp/reserveagenda-tools
cd /tmp/reserveagenda-tools || exit 1

info "⚙️ Executando instalador interno..."
chmod +x reserveagenda.sh || true
bash reserveagenda.sh "$APP_PATH" "$APP_NAME" "$APP_DOMAIN" "$USE_MYSQL" "$DB_HOST" "$DB_PORT" "$DB_DATABASE" "$DB_USERNAME" "$DB_PASSWORD"

VHOST_FILE="/etc/apache2/sites-available/${APP_DOMAIN}.conf"
info "🌐 Criando VirtualHost..."
cat > "$VHOST_FILE" <<EOF
<VirtualHost *:80>
    ServerAdmin admin@${APP_DOMAIN}
    ServerName ${APP_DOMAIN}
    DocumentRoot ${APP_PATH}/public
    <Directory ${APP_PATH}/public>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${APP_DOMAIN}-error.log
    CustomLog \${APACHE_LOG_DIR}/${APP_DOMAIN}-access.log combined
</VirtualHost>
EOF

a2ensite "${APP_DOMAIN}.conf" >/dev/null 2>&1
systemctl reload apache2

info "✅ Instalação concluída com sucesso!"
echo
echo "Acesse:"
echo "  → http://${APP_DOMAIN}/"
echo "  → http://${APP_DOMAIN}/saude"
echo "  → http://${APP_DOMAIN}/info.php"
echo
info "🎯 ReserveAgenda instalado em: $APP_PATH"
