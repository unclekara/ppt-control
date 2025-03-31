#!/bin/bash

set -e

INSTALL_DIR="/home/$(logname)/ppt-control"

echo "🚀 Начинаем установку ppt-control..."

# 1️⃣ Обновление системы
echo "🔄 Обновляем систему..."
sudo apt update -y
sudo apt upgrade -y

# 2️⃣ Установка необходимых пакетов
echo "📦 Устанавливаем необходимые пакеты..."
sudo apt install -y curl git build-essential lighttpd

# 3️⃣ Установка или обновление Node.js 18
echo "⬆️ Устанавливаем или обновляем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "✅ Node.js версия: $(node -v)"
echo "✅ NPM версия: $(npm -v)"

# 4️⃣ Установка PM2
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

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

# 7️⃣ Создание config.json, если его нет
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    echo "⚙️ Создаём config.json по умолчанию..."
    echo '{ "ip": "192.168.1.100" }' | sudo tee "$INSTALL_DIR/config.json" > /dev/null
fi

# 8️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 9️⃣ Настройка Lighttpd
echo "⚙️ Настраиваем Lighttpd..."
sudo lighty-enable-mod proxy
sudo lighty-enable-mod redirect 2>/dev/null || true

sudo sed -i "s|server.document-root = .*|server.document-root = \"$INSTALL_DIR/public\"|" /etc/lighttpd/lighttpd.conf

sudo bash -c "cat >> /etc/lighttpd/lighttpd.conf" <<EOL

# API proxy config
proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )
EOL

echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 🔟 Запуск ppt-server через PM2
echo "🚀 Запускаем ppt-server через PM2..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | grep sudo | bash

echo "✅ Установка завершена!"
echo "🌐 Открой в браузере: http://$(hostname -I | awk '{print $1}')"
