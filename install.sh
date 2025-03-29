#!/bin/bash

set -e

INSTALL_DIR="/home/$USER/ppt-control"

# ♻️ Очистка экрана
clear

# ✨ Цвета для вывода
GREEN='\033[0;32m'
NC='\033[0m'

# Ὠ0 Приветствие
echo -e "${GREEN}🚀 Начинаем установку ppt-control...${NC}"

# ⚙️ Проверка и обновление ядра
KERNEL_VERSION=$(uname -r | cut -d '-' -f1)
echo -e "${GREEN}🔍 Текущая версия ядра: $KERNEL_VERSION${NC}"

if [[ "$KERNEL_VERSION" < "5.15" ]]; then
  echo -e "${GREEN}⬆️ Обновляем ядро...${NC}"
  sudo apt update
  sudo apt install --yes linux-generic
fi

# ♻️ Обновление системы
echo -e "${GREEN}🔧 Обновляем систему...${NC}"
sudo apt update && sudo apt upgrade -y

# ⚙️ Установка зависимостей
echo -e "${GREEN}🔧 Устанавливаем зависимости...${NC}"
sudo apt install -y curl git build-essential lighttpd

# ⬆️ Установка/обновление Node.js 18
if ! command -v node &> /dev/null || [[ $(node -v) != v18* ]]; then
  echo -e "${GREEN}⬆️ Устанавливаем Node.js 18...${NC}"
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# ⚙️ Установка PM2
echo -e "${GREEN}⚙️ Устанавливаем PM2...${NC}"
sudo npm install -g pm2

# Ὄ2 Клонирование проекта
if [ -d "$INSTALL_DIR" ]; then
  echo -e "${GREEN}⚠️ Папка ppt-control уже существует! Удаляем...${NC}"
  sudo rm -rf "$INSTALL_DIR"
fi

echo -e "${GREEN}📥 Клонируем ppt-control из GitHub...${NC}"
git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"

# ὎6 Установка зависимостей проекта
cd "$INSTALL_DIR"
echo -e "${GREEN}📦 Устанавливаем зависимости проекта...${NC}"
npm install

# ⚖️ Права доступа
echo -e "${GREEN}🔧 Настраиваем права доступа...${NC}"
sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo chmod -R 755 "$INSTALL_DIR/public"
touch "$INSTALL_DIR/config.json"
sudo chown $USER:$USER "$INSTALL_DIR/config.json"
sudo chmod 664 "$INSTALL_DIR/config.json"

# ⚖️ Настройка Lighttpd
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
echo -e "${GREEN}⚙️ Настраиваем Lighttpd...${NC}"
sudo lighty-enable-mod proxy || true
sudo sed -i "s|server.document-root = .*|server.document-root = \"$INSTALL_DIR/public\"|" $LIGHTTPD_CONF
echo 'proxy.server = ( "/api/" => ( ( "host" => "127.0.0.1", "port" => 3000 ) ) )' | sudo tee /etc/lighttpd/conf-available/99-ppt-proxy.conf > /dev/null
sudo ln -sf /etc/lighttpd/conf-available/99-ppt-proxy.conf /etc/lighttpd/conf-enabled/99-ppt-proxy.conf
sudo systemctl restart lighttpd

# ⏰ Запуск сервера
echo -e "${GREEN}🚀 Запускаем сервер...${NC}"
pm run build || true
pm run start || true
pm2 start "$INSTALL_DIR/server.js" --name=ppt-server
pm2 save
pm2 startup | bash

# ✅ Завершено
echo -e "${GREEN}✅ Установка завершена! Открой браузер: http://$(hostname -I | awk '{print $1}')${NC}"

