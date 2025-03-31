#!/bin/bash
set -e

INSTALL_DIR="/home/$(whoami)/ppt-control"

echo "🚀 Начинаем установку ppt-control..."

# 🧠 Отключаем интерактивные окна needrestart
echo "⏹️ Отключаем needrestart интерактивность..."
sudo sed -i 's/^#\$nrconf{restart} =.*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf

# 🧠 Проверка и обновление ядра
echo "🧬 Проверяем ядро..."
CURRENT_KERNEL=$(uname -r | grep -oP '^\d+\.\d+\.\d+')
AVAILABLE_KERNEL=$(apt-cache search linux-image | grep -Eo 'linux-image-[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9]+' | sort -V | tail -1)

if ! uname -r | grep -q "${AVAILABLE_KERNEL#linux-image-}"; then
  echo "🆕 Обновляем ядро до $AVAILABLE_KERNEL"
  sudo apt install -y "$AVAILABLE_KERNEL"
  echo "🔁 Необходимо перезагрузить систему после установки, чтобы активировать новое ядро."
else
  echo "✅ Ядро уже актуально: $CURRENT_KERNEL"
fi

# 🛠️ Установка необходимых пакетов
echo "⚙️ Устанавливаем необходимые пакеты..."
sudo apt update
sudo apt install -y build-essential curl git lighttpd

# ⬆️ Устанавливаем или обновляем Node.js
echo "⬆️ Устанавливаем или обновляем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
echo "✅ Node.js версия: $(node -v)"

# 📥 Клонируем ppt-control из GitHub
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Папка ppt-control уже существует! Удаляем..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "📥 Клонируем ppt-control из GitHub..."
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"

# 📦 Устанавливаем зависимости проекта
cd "$INSTALL_DIR"
echo "📦 Устанавливаем зависимости проекта..."
npm install

# 🔧 Настраиваем права доступа
echo "🔧 Настраиваем права доступа..."
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"
[ -f "$INSTALL_DIR/config.json" ] && sudo chown $(whoami):$(whoami) "$INSTALL_DIR/config.json" && sudo chmod 664 "$INSTALL_DIR/config.json"

# ⚙️ Настраиваем Lighttpd
echo "⚙️ Настраиваем Lighttpd..."
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
sudo lighty-enable-mod proxy || true

# Заменим document-root
sudo sed -i "s|server.document-root *= *\"[^\"]*\"|server.document-root = \"$INSTALL_DIR/public\"|" "$LIGHTTPD_CONF"

# Проверим, установлен ли нужный путь
if grep -q "server.document-root = \"$INSTALL_DIR/public\"" "$LIGHTTPD_CONF"; then
    echo "✅ Путь server.document-root корректно установлен."
else
    echo "❌ Не удалось установить server.document-root!" >&2
    exit 1
fi

# Добавим прокси на /api/, если ещё не добавлено
if ! grep -q 'proxy.server = ( "/api/' "$LIGHTTPD_CONF"; then
    echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee -a "$LIGHTTPD_CONF" > /dev/null
fi

# 🔄 Перезапускаем Lighttpd
echo "🔄 Перезапускаем Lighttpd..."
sudo systemctl restart lighttpd

# 🚀 Запускаем сервер через PM2
echo "🚀 Устанавливаем PM2 и запускаем ppt-server..."
sudo npm install -g pm2
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | tail -n 1 | bash

# 📬 Финальное сообщение
echo "✅ Установка завершена! Открой в браузере: http://$(hostname -I | awk '{print $1}')"
