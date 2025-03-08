#!/bin/bash

echo "🚀 Начинаем установку ppt-control..."

# Получаем текущего пользователя
USER_HOME=$(eval echo ~$SUDO_USER)
PROJECT_DIR="$USER_HOME/ppt-control"

# 🔹 Устанавливаем зависимости
echo "⚙️ Устанавливаем необходимые пакеты..."
sudo apt update && sudo apt install -y nodejs npm pm2 lighttpd

# 🔹 Обновляем Node.js до последней версии
echo "⚙️ Обновляем Node.js..."
sudo npm cache clean -f
sudo npm install -g n
sudo n stable

# 🔹 Настраиваем PM2 для автозапуска
echo "⚙️ Настраиваем PM2..."
sudo pm2 startup systemd -u $SUDO_USER --hp $USER_HOME

# 🔹 Клонируем проект
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️ Папка $PROJECT_DIR уже существует! Удаляем..."
    sudo rm -rf "$PROJECT_DIR"
fi
echo "📥 Клонирование репозитория..."
git clone https://github.com/unclekara/ppt-control.git "$PROJECT_DIR"

# 🔹 Устанавливаем зависимости проекта
echo "📦 Устанавливаем зависимости проекта..."
cd "$PROJECT_DIR"
npm install

# 🔹 Настраиваем права доступа для веб-сервера
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$PROJECT_DIR/public"
sudo chmod -R 755 "$PROJECT_DIR/public"

# 🔹 Настраиваем Lighttpd
echo "⚙️ Настраиваем Lighttpd..."
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

# Резервное копирование конфига Lighttpd
if [ ! -f "$LIGHTTPD_CONF.bak" ]; then
    sudo cp "$LIGHTTPD_CONF" "$LIGHTTPD_CONF.bak"
fi

# Обновляем конфиг Lighttpd
sudo bash -c "cat > $LIGHTTPD_CONF" <<EOF
server.modules = (
    "mod_indexfile",
    "mod_access",
    "mod_alias",
    "mod_redirect",
    "mod_proxy"
)

server.document-root = "$PROJECT_DIR/public"
server.upload-dirs = ( "/var/cache/lighttpd/uploads" )
server.errorlog = "/var/log/lighttpd/error.log"
server.pid-file = "/run/lighttpd.pid"
server.username = "www-data"
server.groupname = "www-data"
server.port = 80

index-file.names = ( "index.html" )

# Проксируем API-запросы к Node.js
proxy.server = (
    "/api/" => (
        (
            "host" => "127.0.0.1",
            "port" => 3000
        )
    )
)

# Доступ к файлам
static-file.exclude-extensions = ( ".php", ".pl", ".fcgi" )

include_shell "/usr/share/lighttpd/create-mime.conf.pl"
include "/etc/lighttpd/conf-enabled/*.conf"
EOF

# 🔄 Перезапускаем Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 🚀 Запускаем сервер через PM2
echo "🚀 Запускаем сервер через PM2..."
pm2 start "$PROJECT_DIR/server.js" --name "ppt-server"
pm2 save

# 🔄 Добавляем сервер в автозапуск
echo "🔧 Добавляем ppt-server в автозапуск..."
pm2 startup

echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
