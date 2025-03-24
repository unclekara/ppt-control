#!/bin/bash

set -e

INSTALL_DIR="/home/$USER/ppt-control"

# 1️⃣ Обновляем систему и ставим базовые пакеты
echo "⬆️ Обновляем систему и устанавливаем зависимости..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl git lighttpd

# 2️⃣ Устанавливаем или обновляем Node.js
echo "⬆️ Устанавливаем или обновляем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Проверяем версию Node.js
NODE_VERSION=$(node -v)
echo "✅ Node.js версия: $NODE_VERSION"

# 3️⃣ Устанавливаем PM2 глобально
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# 4️⃣ Клонируем репозиторий, если нужно
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 5️⃣ Устанавливаем зависимости проекта
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 6️⃣ Создаём config.json при отсутствии
if [ ! -f "$INSTALL_DIR/config.json" ]; then
  echo "Создаём config.json по умолчанию..."
  echo '{ "ip": "192.168.1.100" }' | sudo tee "$INSTALL_DIR/config.json" > /dev/null
fi

# 7️⃣ Настройка прав доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chown www-data:www-data "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 8️⃣ Конфигурация Lighttpd
echo "⚙️ Конфигурируем Lighttpd..."
sudo sed -i "s|server.document-root = .*|server.document-root = \"$INSTALL_DIR/public\"|" /etc/lighttpd/lighttpd.conf
if ! grep -q 'mod_proxy' /etc/lighttpd/lighttpd.conf; then
    echo 'server.modules += ( "mod_proxy" )' | sudo tee -a /etc/lighttpd/lighttpd.conf > /dev/null
fi
echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a /etc/lighttpd/lighttpd.conf > /dev/null
sudo systemctl restart lighttpd

# 9️⃣ Запуск через PM2
echo "🚀 Запускаем ppt-server через PM2..."
pm run build || true
pm rebuild || true
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup --silent

# 🔟 Завершение
IP=$(hostname -I | awk '{print $1}')
echo "✅ Установка завершена! Открывай в браузере: http://$IP"
