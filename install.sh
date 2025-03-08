#!/bin/bash

set -e  # Прерывать скрипт при ошибке

echo "🚀 Установка ppt-control..."

# 1. Определяем текущего пользователя
USER=$(whoami)
INSTALL_DIR="/home/$USER/ppt-control"

# 2. Обновляем систему
echo "🔄 Обновление пакетов..."
sudo apt update && sudo apt upgrade -y

# 3. Устанавливаем необходимые зависимости
echo "📦 Установка зависимостей..."
sudo apt install -y git curl nodejs npm pm2

# 4. Проверяем и устанавливаем Node.js (если версия ниже 16)
NODE_VERSION=$(node -v 2>/dev/null || echo "none")
if [[ "$NODE_VERSION" == "none" || "$NODE_VERSION" < "v16" ]]; then
    echo "⚡ Обновление Node.js до версии 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# 5. Клонируем проект (если не был скачан)
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📥 Клонирование репозитория..."
    git clone https://github.com/unclekara/ppt-control.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 6. Устанавливаем npm-зависимости
echo "📦 Установка npm-зависимостей..."
npm install

# 7. Настраиваем pm2 и автозапуск сервера
echo "🚀 Настройка pm2..."
pm2 stop ppt-server || true  # Остановка сервера, если запущен
pm2 start server.js --name "ppt-server"
pm2 save
pm2 startup | grep "sudo" | bash  # Автоматически выполняем команду для автозапуска

echo "✅ Установка завершена! Сервер запущен."
echo "💡 Открывай в браузере: http://<IP-сервера>"
