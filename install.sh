#!/bin/bash

set -e

echo "🚀 Начинаем установку ppt-control..."

INSTALL_DIR="/home/$USER/ppt-control"

# 1️⃣ Устанавливаем зависимости
echo "📦 Обновляем пакеты и устанавливаем зависимости..."
sudo apt update
sudo apt install -y curl git build-essential lighttpd

# 2️⃣ Проверка и установка Node.js >= 18
echo "🧪 Проверка версии Node.js..."
NODE_VERSION=$(node -v 2>/dev/null || echo "none")

if [[ "$NODE_VERSION" == "none" || "$NODE_VERSION" < "v16" ]]; then
    echo "⬆️ Устанавливаем Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "✅ Node.js уже установлен: $NODE_VERSION"
fi

# 3️⃣ Установка/обновление npm и pm2
echo "🛠 Устанавливаем/обновляем npm и pm2..."
sudo npm install -g npm pm2

# 4️⃣ Клонируем проект
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка уже существует. Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 5️⃣ Устанавливаем зависимости проекта
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 6️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 7️⃣ Настройка Lighttpd
echo "⚙️ Настраиваем Lighttpd..."

LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
DOCROOT_LINE="server.document-root = \"$INSTALL_DIR/public\""

# Заменим document-root
sudo sed -i "s|^server.document-root.*|$DOCROOT_LINE|" "$LIGHTTPD_CONF"

# Подключим необходимые модули
sudo lighttpd-enable-mod proxy
sudo lighttpd-enable-mod redirect || true

# Проксирование /api
echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee /etc/lighttpd/conf-available/99-ppt-control.conf > /dev/null
sudo ln -sf /etc/lighttpd/conf-available/99-ppt-control.conf /etc/lighttpd/conf-enabled/99-ppt-control.conf

# Перезапуск Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 8️⃣ Запуск сервера через PM2
echo "🚀 Запускаем сервер с помощью PM2..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | bash

echo "✅ Установка завершена! Открывай: http://$(hostname -I | awk '{print $1}')"
