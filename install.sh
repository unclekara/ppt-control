#!/bin/bash

set -e

INSTALL_DIR="/home/$USER/ppt-control"

# 1️⃣ Обновляем систему и устанавливаем необходимые пакеты
sudo apt update -y && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo apt install -y curl git build-essential lighttpd

# 2️⃣ Проверяем и обновляем Node.js (если версия < 14)
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 14 ]; then
  echo "⬆️ Устанавливаем или обновляем Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
fi

echo "✅ Node.js версия: $(node -v)"

# 3️⃣ Устанавливаем PM2 глобально
sudo npm install -g pm2

# 4️⃣ Клонируем проект
if [ -d "$INSTALL_DIR" ]; then
  echo "⚠️ Папка ppt-control уже существует, удаляем..."
  sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 5️⃣ Устанавливаем зависимости
npm install

# 6️⃣ Устанавливаем права доступа
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chown $USER:$USER "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 7️⃣ Конфигурируем Lighttpd
sudo sed -i "s|server.document-root = .*|server.document-root = \"$INSTALL_DIR/public\"|" /etc/lighttpd/lighttpd.conf

if ! grep -q 'mod_proxy' /etc/lighttpd/lighttpd.conf; then
  echo 'server.modules += ("mod_proxy")' | sudo tee -a /etc/lighttpd/lighttpd.conf > /dev/null
fi

echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a /etc/lighttpd/lighttpd.conf > /dev/null

sudo systemctl restart lighttpd

# 8️⃣ Запускаем сервер через PM2
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | grep sudo | sh

# 9️⃣ Завершение
IP=$(hostname -I | awk '{print $1}')
echo "✅ Установка завершена! Открой в браузере: http://$IP"
