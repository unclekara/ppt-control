#!/bin/bash

echo "🚀 Начинаем установку PowerPoint Remote Control..."

# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Удаляем старую версию Node.js, если она есть
echo "⚙️ Удаляем старую версию Node.js..."
sudo apt-get remove --purge nodejs npm libnode-dev -y
sudo rm -rf /usr/lib/node_modules ~/.npm ~/.nvm

# Устанавливаем Node.js 18
echo "📦 Устанавливаем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверяем установку Node.js и npm
node -v && npm -v

# Устанавливаем PM2
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# Устанавливаем Lighttpd
echo "🌐 Устанавливаем и настраиваем Lighttpd..."
sudo apt-get install lighttpd -y
sudo systemctl enable lighttpd

# Очищаем старую папку проекта, если она есть
if [ -d "/home/$USER/ppt-control" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "/home/$USER/ppt-control"
fi

# Клонируем репозиторий
echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "/home/$USER/ppt-control"
cd "/home/$USER/ppt-control"

# Устанавливаем зависимости
echo "📦 Устанавливаем зависимости проекта..."
npm install

# Настраиваем права доступа для веб-сервера
sudo chown -R www-data:www-data "/home/$USER/ppt-control/public"
sudo chmod -R 755 "/home/$USER/ppt-control/public"

# Перезапускаем Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# Запускаем сервер и добавляем в автозапуск
echo "🚀 Запускаем сервер..."
pm2 start "/home/$USER/ppt-control/server.js" --name ppt-server
pm2 save
pm2 startup

echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
