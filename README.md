# ppt-control

### 📋 Описание
**ppt-control** — это лёгкий сервер для удалённого управления презентацией по сети. Веб-интерфейс позволяет переключать слайды, задавать IP получателя и сохранять настройки.

Приложение работает через HTTP и отправляет команды на выбранный IP и порт по протоколу UDP (по умолчанию 61000) и расчитан на работу с программой Remote Show Control.

---

### ⚙️ Установка на сервер

#### 1. Обнови ядро вручную (если требуется)
На некоторых системах (например, Ubuntu 20.04) необходимо обновить ядро до версии 5.15+ или 6.x:
```bash
sudo apt update && sudo apt install --install-recommends linux-generic-hwe-22.04
sudo reboot
```

#### 2. Выполни установку скриптом
```bash
wget https://raw.githubusercontent.com/unclekara/ppt-control/main/install.sh
chmod +x install.sh
sudo ./install.sh
```
После установки веб-интерфейс будет доступен по адресу:
```
http://<IP_СЕРВЕРА>
```
Страница настройки IP адреса компьютера с PowerPoint находится по адресу:
http://<IP_СЕРВЕРА>/settings.html

---

### 📦 Зависимости (устанавливаются автоматически)
- Node.js 18+
- npm
- pm2
- lighttpd
- git, curl, build-essential

---

### ✅ Поддерживаемые системы
Проект протестирован и работает на:
- Ubuntu 22.04+ ✅ (рекомендуется)
- Debian 12+ ✅
- Raspberry Pi OS (на базе Debian 12)
- Linux Mint 21+
- Kali Linux 2023+
- Pop!_OS 22.04+

#### ⚠️ Условия работы
- Ядро Linux версии **5.15+** (желательно 6.x)
- Node.js версии **18 или выше**

#### ❌ Не рекомендуется:
- Ubuntu 20.04 и ниже — потребуется ручное обновление ядра
- Debian 10/11 — устаревшие версии Node.js и зависимостей
- Arch, Alpine, CentOS — скрипт не адаптирован, требуется ручная настройка

---

### 🧪 Тестирование
Для тестирования можно использовать VirtualBox с Ubuntu Server 22.04 или Debian 12 без GUI, настроив сетевой режим "Сетевой мост" или "Только хост" с пробросом порта 80 для доступа через браузер.

---

### 💬 Поддержка и обратная связь
Если возникли ошибки, проблемы с доступом или ты хочешь улучшить функциональность — создай issue или pull request на GitHub.
