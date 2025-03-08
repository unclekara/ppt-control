#!/bin/bash

echo "🚀 Начинаем установку PowerPoint Remote Control..."

# Получаем имя текущего пользователя
USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)
PROJECT_DIR="$HOME_DIR/ppt-control"

# Функция для проверки и установки пакетов
install_package() {
    if ! dpkg -s "$1" &> /dev/null; then
        echo "📦 Устанавливаем $1..."
        sudo apt-get install -y "$1"
    else
        echo "✅ $1 уже установлен!"
    fi
}

# **Обновляем систему и устанавливаем зависимости**
echo "🔄 Обновляем систему и устанавливаем зависимости..."
sudo apt-get update -y
install_package git
install_package curl
install_package lighttpd
install_package nodejs
install_package npm

# **Обновление Node.js, если версия ниже 18**
NODE_VERSION=$(node -v 2>/dev/null | cut -d. -f1 | tr -d 'v')
if [[ -z "$NODE_VERSION" || "$NODE_VERSION" -lt 18 ]]; then
    echo "🔄 Обновляем Node.js до версии 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
    sudo apt-get install -y nodejs
fi
echo "✅ Node.js версия: $(node -v)"

# **Установка PM2**
if ! command -v pm2 &> /dev/null; then
    echo "⚙️ Устанавливаем PM2..."
    sudo npm install -g pm2
else
    echo "✅ PM2 уже установлен!"
fi

# **Клонирование проекта**
if [[ -d "$PROJECT_DIR" ]]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$PROJECT_DIR"
fi
echo "📥 Клонирование репозитория..."
git clone https://github.com/unclekara/ppt-control.git "$PROJECT_DIR"

# **Установка зависимостей проекта**
cd "$PROJECT_DIR"
echo "📦 Устанавливаем зависимости проекта..."
npm install

# **Настройка прав для Lighttpd**
echo "⚙️ Настраиваем Lighttpd..."
sudo chown -R www-data:www-data "$PROJECT_DIR/public"
sudo chmod -R 755 "$PROJECT_DIR/public"

# **Настройка конфигурации Lighttpd**
echo "⚙️ Конфигурируем веб-сервер..."
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
sudo tee "$LIGHTTPD_CONF" > /dev/null <<EOF
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

proxy.server = (
    "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) )
)

static-file.exclude-extensions = ( ".php", ".pl", ".fcgi" )

include_shell "/usr/share/lighttpd/create-mime.conf.pl"
include "/etc/lighttpd/conf-enabled/*.conf"
EOF

# **Перезапуск Lighttpd**
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# **Запуск сервера Node.js с PM2**
echo "🚀 Запускаем сервер..."
pm2 start "$PROJECT_DIR/server.js" --name "ppt-server"
pm2 save
pm2 startup systemd

echo "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
