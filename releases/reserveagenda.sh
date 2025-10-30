#!/usr/bin/env bash
set -Eeuo pipefail

echo "=========================================================="
echo "🚀 ReserveAgenda - Instalador Automático (v1.2)"
echo "=========================================================="

TMP_DIR="/tmp/reserveagenda_install"
INSTALL_DIR="/usr/local/reserveagenda/installer"
PACKAGE_URL="https://github.com/Elton-Coelho/reserveagenda-saas/releases/latest/download/reserveagenda-tools-v1.1.zip"
REPO_URL="https://github.com/Elton-Coelho/reserveagenda-core.git"

echo "📦 Atualizando pacotes e dependências..."
apt update -y >/dev/null
apt install -y unzip curl git sudo ca-certificates >/dev/null

mkdir -p "$TMP_DIR"
echo "📥 Baixando pacote de instalação..."
curl -fsSL "$PACKAGE_URL" -o "$TMP_DIR/tools.zip"

echo "📂 Extraindo arquivos..."
unzip -qo "$TMP_DIR/tools.zip" -d "$INSTALL_DIR"
chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR"/templates/*.sh 2>/dev/null || true

echo "🔐 Carregando token GitHub..."
source /usr/local/reserveagenda/.secrets.env || { echo '❌ Arquivo .secrets.env não encontrado.'; exit 1; }
echo "🔗 Clonando repositório privado..."
git clone -b main https://${GITHUB_TOKEN}@github.com/Elton-Coelho/reserveagenda-core.git /home/deploy/reserveagenda

echo "💾 Instalando dependências Laravel..."
cd /home/deploy/reserveagenda
composer install --no-dev --prefer-dist -q
php artisan key:generate --force
php artisan migrate --force

echo "=========================================================="
echo "✅ Instalação concluída com sucesso!"
echo "📁 Diretório: /home/deploy/reserveagenda"
echo "🌐 Desenvolvido por Grupo Shark | Super Zapp / ReserveAgenda"
echo "=========================================================="
