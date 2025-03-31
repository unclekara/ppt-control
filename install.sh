#!/bin/bash
set -e

echo "🚀 Начинаем установку ppt-control..."

# 📛 Отключаем интерактивность needrestart
echo "⏹️ Отключаем needrestart интерактивность..."
sudo sed -i 's/^#\$nrconf{restart} =.*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf 2>/dev/null || true

# 🧬 Проверка и обновление ядра
echo "🧬 Проверяем ядро..."
CURRENT_KERNEL=$(uname -r | cut -d '-' -f1)
REQUIRED_KERNEL="6.1"
if dpkg --compare-versions "$CURRENT_KERNEL" lt "$REQUIRED_KERNEL"; then
  echo "🆕 Обновляем ядро до linux-generic..."
  sudo apt update
  sudo apt install -y linux-generic
else
  echo "✅ Текущее ядро $CURRENT_KERNEL соответствует требованиям"
fi

# 📦 Установка зависимостей
echo "📦 Устанавливаем зависимости..."
sudo apt update
sudo apt install -y curl git build-essential lighttpd

# ⬆️ Установка Node.js 18 LTS
echo "⬆️ Устанавливаем или обновляем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 🧠 Установка PM2
echo "⚙️ Устанавливаем PM2..."
sudo npm install -g pm2

# 🏗 Определение пользователя и директории
INSTALL_USER=${SUDO_USER:-$USER}
INSTALL_HOME=$(eval echo "~$INSTALL_USER")
INSTALL_DIR="$INSTALL_HOME/ppt-control"

# 📥 Клонирование проекта
if [ -d "$INSTALL_DIR" ]; then
  echo "⚠️ Папка ppt-control уже существует! Удаляем..."
  sudo rm -rf "$INSTALL_DIR"
fi
echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"

# 📦 Установка зависимостей проекта
cd "$INSTALL_DIR"
npm install

# 🔧 Настройка прав
echo "🔧 Настраиваем права доступа..."
sudo chown -R "$INSTALL_USER":"$INSTALL_USER" "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR/public"
sudo touch "$INSTALL_DIR/config.json"
sudo chown "$INSTALL_USER":"$INSTALL_USER" "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# ⚙️ Настройка lighttpd
echo "⚙️ Настраиваем Lighttpd..."
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"

# Устанавливаем document-root
sudo sed -i "s|server.document-root.*|server.document-root = \"$INSTALL_DIR/public\"|" "$LIGHTTPD_CONF"

# Включаем модуль proxy, если ещё не включён
if ! grep -q 'mod_proxy' "$LIGHTTPD_CONF"; then
  echo 'server.modules += ( "mod_proxy" )' | sudo tee -a "$LIGHTTPD_CONF" > /dev/null
fi

# Настраиваем проксирование API-запросов
sudo tee -a "$LIGHTTPD_CONF" > /dev/null <<EOF

# ppt-control proxy
proxy.server = (
  "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) )
)
EOF

# Проверка, что настройки применились
echo "🔍 Проверка настроек lighttpd:"
grep "server.document-root" "$LIGHTTPD_CONF"
grep "mod_proxy" "$LIGHTTPD_CONF" || echo "⚠️ mod_proxy не найден в конфиге!"
grep "proxy.server" "$LIGHTTPD_CONF" || echo "⚠️ proxy.server не найден в конфиге!"

# 🔄 Перезапуск lighttpd
sudo systemctl restart lighttpd

# 🚀 Запуск ppt-control
echo "🚀 Запускаем сервер ppt-control через PM2..."
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | grep sudo | bash

echo "✅ Установка завершена! Открой в браузере: http://$(hostname -I | awk '{print $1}')"
