#!/bin/bash

set -e

INSTALL_DIR="/home/$USER/ppt-control"

echo "🚀 Начинаем установку ppt-control..."

# 1️⃣ Обновление системы и установка необходимых пакетов
echo "⚙️ Обновляем систему и устанавливаем зависимости..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential lighttpd

# 2️⃣ Установка Node.js 18 и npm
echo "⬆️ Устанавливаем или обновляем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "✅ Node.js версия: $(node -v)"
echo "✅ npm версия: $(npm -v)"

# 3️⃣ Установка PM2
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# 4️⃣ Клонирование репозитория
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 5️⃣ Установка зависимостей проекта
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 6️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo touch "$INSTALL_DIR/config.json"
sudo chown www-data:www-data "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 7️⃣ Настройка Lighttpd
echo "⚙️ Настраиваем Lighttpd..."

LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

# Устанавливаем корректный document-root
sudo sed -i "s|server.document-root *=.*|server.document-root = \"$INSTALL_DIR/public\"|" $LIGHTTPD_CONF

# Включаем необходимые модули
sudo lighty-enable-mod proxy
sudo lighty-enable-mod redirect

# Добавляем proxy настройку (если ещё не добавлена)
if ! grep -q "proxy.server" "$LIGHTTPD_CONF"; then
    echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a "$LIGHTTPD_CONF" > /dev/null
fi

# Перезапуск Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 8️⃣ Запуск сервера через PM2
echo "🚀 Запускаем сервер через PM2..."
pm2 start server.js --name=ppt-server
pm2 save
pm2 startup | bash

# 9️⃣ Финал
echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
