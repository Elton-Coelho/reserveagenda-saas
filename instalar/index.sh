#!/usr/bin/env bash
# ==========================================================
# ReserveAgenda - Instalador Automático (index.sh)
# Autor: Grupo Shark / Super Zapp
# Versão: 1.2b (Laravel 12 / PHP 8.3)
# ==========================================================

set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Funções visuais
# -------------------------
info(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn(){ echo -e "\e[1;33m[AVISO]\e[0m $*"; }
err(){ echo -e "\e[1;31m[ERRO]\e[0m $*"; }
confirm(){ read -r -p "$* [y/N]: " ans; [[ "$ans" = "y" || "$ans" = "Y" ]]; }

# -------------------------
# Entrada de dados
# -------------------------
echo
info "🧠 Iniciando instalador automático do sistema ReserveAgenda..."
read -r -p "URL do pacote (ZIP) [https://github.com/Elton-Coelho/reserveagenda-saas/raw/main/releases/reserveagenda-tools-v1.2b.zip]: " REPO_URL
REPO_URL=${REPO_URL:-https://github.com/Elton-Coelho/reserveagenda-saas/raw/main/releases/reserveagenda-tools-v1.2b.zip}

read -r -p "Nome da empresa (APP_NAME) [ReserveAgenda]: " APP_NAME
APP_NAME=${APP_NAME:-ReserveAgenda}

read -r -p "Dominio ou IP (sem http://) [144.126.135.75]: " APP_DOMAIN
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
fi

# -------------------------
# Instala pacotes base
# -------------------------
info "🔧 Instalando pacotes necessários..."
apt update -y && apt install -y unzip curl git apache2 php php-cli php-mbstring php-xml php-curl php-zip composer libapache2-mod-php php-sqlite3 php-mysql

a2enmod rewrite headers >/dev/null 2>&1 || true
systemctl enable apache2 >/dev/null 2>&1

# -------------------------
# Prepara diretório
# -------------------------
info "📁 Criando estrutura de pastas..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH"
cd "$APP_PATH"

# -------------------------
# Download do pacote
# -------------------------
info "⬇️ Baixando pacote de instalação..."
curl -L -o reserveagenda-tools.zip "$REPO_URL"
unzip -q reserveagenda-tools.zip -d /tmp/reserveagenda-tools
cd /tmp/reserveagenda-tools/reserveagenda-tools-v1.2b || cd /tmp/reserveagenda-tools

# -------------------------
# Executa script principal
# -------------------------
info "⚙️ Executando instalador interno..."
chmod +x reserveagenda.sh
bash reserveagenda.sh "$APP_PATH" "$APP_NAME" "$APP_DOMAIN" "$USE_MYSQL" "$DB_HOST" "$DB_PORT" "$DB_DATABASE" "$DB_USERNAME" "$DB_PASSWORD"

# -------------------------
# Apache
# -------------------------
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
</VirtualHost>
EOF

a2ensite "${APP_DOMAIN}.conf"
systemctl reload apache2

# -------------------------
# Finalização
# -------------------------
info "✅ Instalação concluída com sucesso!"
echo
echo "Acesse:"
echo "  → http://${APP_DOMAIN}/"
echo "  → http://${APP_DOMAIN}/saude"
echo "  → http://${APP_DOMAIN}/info.php"
echo
info "🎯 ReserveAgenda instalado em: $APP_PATH"
