#!/bin/bash
set -e  # Останавливаем скрипт при ошибке

echo "🚀 Начинаем установку ppt-control..."

# 1️⃣ Обновление системы и установка базовых инструментов
echo "⚙️ Обновляем систему и устанавливаем зависимости..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git unzip

# 2️⃣ Удаление старых версий Node.js и PM2
echo "🧹 Удаляем старые версии Node.js и PM2 (если есть)..."
sudo apt remove -y nodejs npm || true
sudo rm -rf ~/.nvm ~/.npm /usr/local/lib/node_modules

# 3️⃣ Установка актуальной версии Node.js и PM2
echo "📥 Устанавливаем Node.js 18 и PM2..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
npm install -g pm2

# Проверяем установленную версию
echo "✅ Node.js версия: $(node -v)"
echo "✅ NPM версия: $(npm -v)"
echo "✅ PM2 версия: $(pm2 -v)"

# 4️⃣ Установка и настройка Lighttpd
echo "⚙️ Устанавливаем и настраиваем Lighttpd..."
sudo apt install -y lighttpd
sudo systemctl enable --now lighttpd

LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

# Устанавливаем корректный document-root
INSTALL_DIR="/home/$(whoami)/ppt-control"
sudo sed -i "s|server.document-root = .*|server.document-root = \"$INSTALL_DIR/public\"|" $LIGHTTPD_CONF

# Проверяем, есть ли уже модуль proxy
if ! grep -q 'mod_proxy' $LIGHTTPD_CONF; then
    echo 'server.modules += ( "mod_proxy" )' | sudo tee -a $LIGHTTPD_CONF > /dev/null
fi

# Добавляем проксирование API-запросов на порт 3000
echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a $LIGHTTPD_CONF > /dev/null

# Перезапускаем Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 5️⃣ Клонирование репозитория
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 6️⃣ Установка зависимостей проекта
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 7️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"

# 8️⃣ Запуск сервера через PM2
echo "🚀 Запускаем сервер через PM2..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup

echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
