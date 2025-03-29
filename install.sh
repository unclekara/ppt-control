#!/bin/bash

set -e

INSTALL_DIR="/home/$USER/ppt-control"

print_step() {
  echo -e "\n\033[1;36m$1\033[0m"
}

print_step "🚀 Начинаем установку ppt-control..."

# 1. Обновление системы
print_step "⚙️ Обновляем систему..."
sudo apt update && sudo apt upgrade -y

# 2. Установка зависимостей
print_step "🔧 Устанавливаем необходимые пакеты..."
sudo apt install -y curl git build-essential lighttpd

# 3. Установка/обновление Node.js 18 LTS
print_step "⬆️ Устанавливаем Node.js 18..."
if ! node -v | grep -q 'v18'; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
fi

echo "✅ Node.js версия: $(node -v)"

# 4. Установка PM2
print_step "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# 5. Клонирование проекта
print_step "📥 Клонируем ppt-control из GitHub..."
if [ -d "$INSTALL_DIR" ]; then
  echo "⚠️ Папка ppt-control уже существует! Удаляем..."
  sudo rm -rf "$INSTALL_DIR"
fi

git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 6. Установка зависимостей проекта
print_step "📦 Устанавливаем зависимости проекта..."
npm install

# 7. Настройка прав
print_step "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo chown $USER:$USER "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# 8. Настройка Lighttpd
print_step "⚙️ Настраиваем Lighttpd..."
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
sudo lighty-enable-mod proxy || true
sudo lighty-enable-mod redirect || true

# Меняем document-root
sudo sed -i "s|server.document-root\s*=.*|server.document-root = \"$INSTALL_DIR/public\"|" "$LIGHTTPD_CONF"

# Добавляем прокси
if ! grep -q 'mod_proxy' "$LIGHTTPD_CONF"; then
  echo 'server.modules += ( "mod_proxy" )' | sudo tee -a "$LIGHTTPD_CONF"
fi

echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee /etc/lighttpd/conf-available/90-ppt-api.conf > /dev/null
sudo ln -sf /etc/lighttpd/conf-available/90-ppt-api.conf /etc/lighttpd/conf-enabled/90-ppt-api.conf

sudo systemctl restart lighttpd

# 9. Запуск через PM2
print_step "🚀 Запускаем сервер..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save

# 10. Автозапуск PM2
print_step "🔁 Настраиваем автозапуск PM2..."
STARTUP_CMD=$(pm2 startup systemd -u $USER --hp $HOME | grep sudo)
eval "$STARTUP_CMD"

print_step "✅ Установка завершена! Открывай в браузере: http://$(hostname -I | awk '{print $1}')"
