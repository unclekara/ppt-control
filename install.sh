#!/bin/bash

set -e  # Останавливаем выполнение при ошибке

echo "🚀 Начинаем установку ppt-control..."

# Определяем текущего пользователя
USER_HOME=$(eval echo ~$SUDO_USER)
INSTALL_DIR="$USER_HOME/ppt-control"

# 1️⃣ Установка необходимых пакетов
echo "📦 Устанавливаем зависимости..."
sudo apt update && sudo apt install -y lighttpd git curl nodejs npm

# 2️⃣ Установка PM2 (если его нет)
if ! command -v pm2 &> /dev/null; then
    echo "⚙️ Устанавливаем PM2..."
    sudo npm install -g pm2
fi

# 3️⃣ Клонирование репозитория
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 4️⃣ Установка зависимостей проекта
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 5️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"

# 6️⃣ Настройка Lighttpd
echo "⚙️ Настраиваем Lighttpd..."

LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

# Заменяем server.document-root на правильный путь
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

# 7️⃣ Запуск сервера через PM2
echo "🚀 Запускаем сервер..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup

echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
