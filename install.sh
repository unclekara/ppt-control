#!/bin/bash

echo "🚀 Начинаем установку ppt-control..."

# 1️⃣ Отключаем интерактивность needrestart
echo "⏹️ Отключаем needrestart интерактивность..."
sudo sed -i 's/^#\$nrconf{restart} =.*/\$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf 2>/dev/null || true

# 2️⃣ Установка зависимостей
echo "📦 Устанавливаем зависимости..."
sudo apt update
sudo apt install -y curl git build-essential lighttpd nodejs npm

# 3️⃣ Установка PM2
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# 4️⃣ Определяем директорию установки
INSTALL_DIR="/home/$USER/ppt-control"

# 5️⃣ Клонируем проект
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"

# 6️⃣ Устанавливаем зависимости проекта
cd "$INSTALL_DIR"
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 7️⃣ Создаём config.json, если он отсутствует
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    echo "🛠 Создаём config.json..."
    echo '{ "ip": "192.168.1.100" }' > "$INSTALL_DIR/config.json"
fi

# 8️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chmod 664 "$INSTALL_DIR/config.json"

# Даём www-data доступ к домашней директории пользователя
echo "📂 Даём доступ к домашней директории..."
sudo chmod o+x "/home/$USER"

# 9️⃣ Настройка Lighttpd
echo "⚙️ Настраиваем Lighttpd..."
sudo lighty-enable-mod proxy
sudo lighty-enable-mod redirect || true

LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

# Устанавливаем корректный document-root
sudo sed -i "s|server.document-root *=.*|server.document-root = \"$INSTALL_DIR/public\"|" "$LIGHTTPD_CONF"

# Добавляем проксирование API
sudo sed -i '/proxy.server/d' "$LIGHTTPD_CONF"
echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a "$LIGHTTPD_CONF" > /dev/null

echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 🔟 Запуск через PM2
echo "🚀 Запускаем сервер через PM2..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | sudo tee /dev/null > /dev/null
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp "/home/$USER"

echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
