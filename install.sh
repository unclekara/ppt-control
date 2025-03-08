#!/bin/bash

# Определение переменных
USER_HOME=$(eval echo ~$SUDO_USER)
PROJECT_DIR="$USER_HOME/ppt-control"

echo "🚀 Начало установки PowerPoint Remote Control..."

# Обновление системы и установка необходимых пакетов
echo "🔄 Обновление системы..."
sudo apt update && sudo apt upgrade -y

echo "📦 Установка необходимых пакетов..."
sudo apt install -y nodejs npm git lighttpd

# Установка PM2 (менеджер процессов для Node.js)
echo "⚙️ Установка PM2..."
sudo npm install -g pm2

# Клонирование проекта
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$PROJECT_DIR"
fi

echo "📥 Клонирование репозитория..."
git clone https://github.com/unclekara/ppt-control.git "$PROJECT_DIR"

# Установка зависимостей
echo "📦 Установка зависимостей..."
cd "$PROJECT_DIR" || exit 1
npm install

# Настройка прав для веб-сервера
echo "🛠 Настройка прав доступа к файлам..."
sudo chown -R www-data:www-data "$PROJECT_DIR/public"
sudo chmod -R 755 "$PROJECT_DIR/public"

# Настройка Lighttpd
echo "🛠 Настройка Lighttpd..."
sudo lighttpd-enable-mod fastcgi
sudo lighttpd-enable-mod fastcgi-php

# Создание конфигурации Lighttpd
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
if ! grep -q "ppt-control" "$LIGHTTPD_CONF"; then
    echo "📄 Добавление конфигурации в Lighttpd..."
    sudo bash -c "cat > /etc/lighttpd/lighttpd.conf <<EOF
server.modules = (
    \"mod_indexfile\",
    \"mod_access\",
    \"mod_alias\",
    \"mod_redirect\",
    \"mod_proxy\"
)

server.document-root = \"$PROJECT_DIR/public\"
server.upload-dirs = ( \"/var/cache/lighttpd/uploads\" )
server.errorlog = \"/var/log/lighttpd/error.log\"
server.pid-file = \"/run/lighttpd.pid\"
server.username = \"www-data\"
server.groupname = \"www-data\"
server.port = 80

index-file.names = ( \"index.html\" )

proxy.server = (
    \"/api/\" => (
        (
            \"host\" => \"127.0.0.1\",
            \"port\" => 3000
        )
    )
)

static-file.exclude-extensions = ( \".php\", \".pl\", \".fcgi\" )

include_shell \"/usr/share/lighttpd/create-mime.conf.pl\"
EOF"
fi

# Перезапуск веб-сервера
echo "🔄 Перезапуск Lighttpd..."
sudo systemctl restart lighttpd
sudo systemctl enable lighttpd

# Запуск сервера с PM2
echo "🚀 Запуск сервера Node.js через PM2..."
pm2 start server.js --name ppt-server
pm2 save
pm2 startup systemd

echo "✅ Установка завершена!"
echo "🌐 Теперь откройте в браузере: http://$(hostname -I | awk '{print $1}')"
