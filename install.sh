#!/bin/bash

set -e  # Прерывать выполнение при ошибках

USER_NAME="pptcontrol"
INSTALL_DIR="/home/$USER_NAME/ppt-control"
GIT_REPO="https://github.com/your_username/your_project.git"

# 1. Проверяем, есть ли пользователь, если нет - создаем
if id "$USER_NAME" &>/dev/null; then
    echo "✅ Пользователь $USER_NAME уже существует."
else
    echo "👤 Создаём пользователя $USER_NAME..."
    sudo useradd -m -s /bin/bash $USER_NAME
    echo "✅ Пользователь $USER_NAME создан."
fi

# 2. Устанавливаем зависимости
echo "🔧 Устанавливаем пакеты..."
sudo apt update
sudo apt install -y git nodejs npm lighttpd pm2

# 3. Настраиваем папку проекта
if [ -d "$INSTALL_DIR" ]; then
    echo "📁 Папка $INSTALL_DIR уже существует."
else
    echo "📁 Создаём папку $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown -R $USER_NAME:$USER_NAME "$INSTALL_DIR"
fi

# 4. Клонируем проект с GitHub
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "🔄 Обновляем репозиторий..."
    sudo -u $USER_NAME git -C "$INSTALL_DIR" pull
else
    echo "📥 Клонируем репозиторий..."
    sudo -u $USER_NAME git clone "$GIT_REPO" "$INSTALL_DIR"
fi

# 5. Устанавливаем зависимости Node.js
echo "📦 Устанавливаем npm зависимости..."
cd "$INSTALL_DIR"
sudo -u $USER_NAME npm install

# 6. Настраиваем автозапуск сервера с помощью pm2
echo "🚀 Настраиваем pm2..."
sudo -u $USER_NAME pm2 start "$INSTALL_DIR/server.js" --name ppt-server
sudo -u $USER_NAME pm2 save
sudo pm2 startup systemd -u $USER_NAME --hp /home/$USER_NAME

# 7. Настраиваем Lighttpd
echo "🌍 Настраиваем Lighttpd..."
sudo cp "$INSTALL_DIR/lighttpd.conf" /etc/lighttpd/lighttpd.conf
sudo systemctl restart lighttpd

echo "🎉 Установка завершена!"
