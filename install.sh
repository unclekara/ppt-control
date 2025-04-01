#!/bin/bash
set -e

INSTALL_DIR="/home/$USER/ppt-control"
CONFIG_FILE="$INSTALL_DIR/config.json"
PUBLIC_DIR="$INSTALL_DIR/public"
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

echo "🚀 Начинаем установку ppt-control..."

# Отключаем интерактивность needrestart
echo "⏹️ Отключаем needrestart интерактивность..."
sudo sed -i 's/^#\$nrconf{restart}.*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf || true

# Обновляем систему и ставим базовые пакеты
echo "🧰 Обновляем систему и устанавливаем зависимости..."
sudo apt update
sudo apt install -y curl git build-essential lighttpd

# Устанавливаем или обновляем Node.js до версии 18
REQUIRED_NODE_MAJOR=18
NODE_VERSION=$(node -v 2>/dev/null || echo "v0.0.0")
NODE_MAJOR=$(echo "$NODE_VERSION" | grep -oP '\d+' | head -1)

if [ "$NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ]; then
  echo "⬆️ Обновляем Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
else
  echo "✅ Node.js версия: $NODE_VERSION"
fi

# Обновляем npm и устанавливаем pm2
echo "🛠 Устанавливаем/обновляем npm и pm2..."
sudo npm install -g npm
sudo npm install -g pm2

# Удаляем старую копию проекта, если есть
if [ -d "$INSTALL_DIR" ]; then
  echo "🧹 Удаляем старую версию проекта..."
  sudo rm -rf "$INSTALL_DIR"
fi

# Клонируем репозиторий
echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"

# Устанавливаем зависимости проекта
echo "📦 Устанавливаем зависимости проекта..."
cd "$INSTALL_DIR"
npm install

# Создаём config.json, если отсутствует
if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚙️ Создаём config.json..."
  echo '{ "ip": "" }' | sudo tee "$CONFIG_FILE" > /dev/null
fi

# Настройка прав
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo chmod -R 755 "$PUBLIC_DIR"
sudo chown "$USER":"$USER" "$CONFIG_FILE"
sudo chmod 664 "$CONFIG_FILE"

# Настройка Lighttpd
echo "⚙️ Настраиваем Lighttpd..."
sudo lighty-enable-mod proxy || true
sudo lighty-enable-mod redirect || true

# Обновляем document-root
sudo sed -i "s|^server.document-root *=.*|server.document-root = \"$PUBLIC_DIR\"|" "$LIGHTTPD_CONF"

# Удостоверимся, что правило proxy.server есть
if ! grep -q 'proxy.server' "$LIGHTTPD_CONF"; then
  echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a "$LIGHTTPD_CONF" > /dev/null
fi

# Проверим корректность и перезапустим lighttpd
sudo lighttpd -t -f "$LIGHTTPD_CONF"
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# Запускаем ppt-server через PM2
echo "🚀 Запускаем сервер через PM2..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | grep sudo | sed 's/^/sudo /' | bash

# Повторно проверяем config.json
echo "📄 Проверка config.json и прав:"
ls -l "$CONFIG_FILE"

echo "✅ Установка завершена! Открой в браузере: http://$(hostname -I | awk '{print $1}')"
