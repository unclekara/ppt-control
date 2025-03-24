#!/bin/bash

set -e

INSTALL_DIR="/home/$USER/ppt-control"

# 1️⃣ Обновляем систему и ставим базовые утилиты
echo "⚙️ Обновляем пакеты и устанавливаем зависимости..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y git curl build-essential lighttpd

# 2️⃣ Устанавливаем Node.js 18.x
if ! command -v node &> /dev/null || [[ $(node -v) != v18* ]]; then
    echo "⚙️ Устанавливаем Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# 3️⃣ Устанавливаем PM2
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# 4️⃣ Удаляем старую версию проекта, если есть
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

# 5️⃣ Клонируем проект из GitHub
echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 6️⃣ Устанавливаем зависимости проекта
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 7️⃣ Настройка прав доступа
USER_HOME=$(eval echo ~$USER)
echo "🔧 Настраиваем права доступа на $INSTALL_DIR..."
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chown -R $USER:$USER "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 8️⃣ Конфигурация Lighttpd
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
echo "⚙️ Настраиваем Lighttpd..."

# Настраиваем document-root
sudo sed -i "s|server.document-root = .*|server.document-root = \"$INSTALL_DIR/public\"|" $LIGHTTPD_CONF

# Подключаем mod_proxy, если не подключен
if ! grep -q 'mod_proxy' $LIGHTTPD_CONF; then
    echo 'server.modules += ( "mod_proxy" )' | sudo tee -a $LIGHTTPD_CONF > /dev/null
fi

# Проксируем /api/ к node.js
if ! grep -q 'proxy.server' $LIGHTTPD_CONF; then
    echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a $LIGHTTPD_CONF > /dev/null
fi

# Перезапуск Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 9️⃣ Запуск сервера через PM2
echo "🚀 Запускаем ppt-server через PM2..."
pm run build || true
pm run start || true
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server || true
pm2 save
pm2 startup | bash

# 🔟 Финальное сообщение
echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
