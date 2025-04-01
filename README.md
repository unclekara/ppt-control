# 📊 ppt-control

**ppt-control** — это веб-интерфейс и API-сервер для удалённого управления презентациями Microsoft PowerPoint. Проект позволяет отправлять команды `NEXT` и `PREV` на указанный IP-адрес и порт, обеспечивая интеграцию с программой [Remote Show Control](https://www.remoteshowcontrol.com/).

## 🚀 Возможности

- Отправка команд `NEXT` и `PREV` по UDP
- Простое API: `/api/command?action=NEXT` или `?action=PREV`
- Веб-интерфейс для ручного управления
- Совместимость с PowerPoint + Remote Show Control

## 🔧 Установка

> Поддерживаемые ОС: **Ubuntu 22.04+**, **Debian 12+** и совместимые Linux-дистрибутивы с systemd и lighttpd.

1. Подготовка: Обновите ядро и перезагрузите систему (рекомендуется).
2. Выполните установку:

```bash
wget https://raw.githubusercontent.com/unclekara/ppt-control/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

3. После установки:

- Веб-интерфейс доступен по адресу: `http://<ваш_IP>/`
- Страница настроек адреса компьютера с PowerPoint: `http://<ваш_IP>/settings.html`

## 🔌 Интеграция

Настройте PowerPoint с помощью утилиты **Remote Show Control**, доступной на [официальном сайте](https://www.remoteshowcontrol.com/), чтобы принимать команды от ppt-control.

## 🗂️ Структура проекта

```
ppt-control/
├── public/               # HTML-интерфейс
├── server.js             # Node.js сервер
├── config.json           # Конфигурация IP-адреса
└── install.sh            # Установочный скрипт
```

## 📜 Лицензия

Проект распространяется под лицензией MIT.
