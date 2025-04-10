# ppt-control

**ppt-control** — это простой сервер на Node.js с веб-интерфейсом для удалённого управления презентацией PowerPoint, запущенной на другом компьютере в локальной сети.  
С помощью кнопок на странице можно отправлять команды "Next" и "Previous" на указанный IP-адрес и порт, по умолчанию — `61000`.

## Особенности

- Удобный веб-интерфейс для управления презентацией
- Настройка IP-адреса целевого ПК с PowerPoint
- Интеграция с [Remote Show Control](https://irisdown.co.uk/rsc.html)
- Возможность запуска на Raspberry Pi и серверах с Ubuntu 22.04+
- Работа по локальной сети или через интернет (например, с помощью KeenDNS)

## Установка

```bash
sudo wget https://raw.githubusercontent.com/unclekara/ppt-control/main/install.sh
sudo chmod +x install.sh
sudo ./install.sh

```

> ❗ Перед установкой убедись, что система обновлена и перезагружена.

## После установки

- Приложение будет доступно по адресу: `http://<IP-сервера>`
- Страница настройки находится по адресу: `http://<IP-сервера>/settings.html`
- Конфигурация хранится в `config.json` внутри проекта
- Сервер запускается автоматически через PM2

## Пример использования

### Управление презентацией из внешней сети через KeenDNS

**Сценарий:**
- На ПК с PowerPoint установлен [Remote Show Control](https://irisdown.co.uk/rsc.html), слушающий команды на порту `61000`.
- На роутере Keenetic настроен доступ через KeenDNS к локальному серверу `ppt-control`.
- Пользователь в любой точке мира открывает веб-интерфейс `ppt-control`, доступный по адресу вида `https://username.keenetic.link`.
- С помощью кнопок "NEXT" и "PREV" можно удалённо управлять презентацией.

**Схема:**
```
[📱 Внешнее устройство]
     |
     v
[🌐 KeenDNS домен]
     |
     v
[🖥 Сервер ppt-control]
     |
     v
[💻 Компьютер с PowerPoint + Remote Show Control]
```

## Поддерживаемые ос

- Raspberry Pi OS (Bookworm, 64-bit)
- Ubuntu Server 22.04 LTS
- Debian 12+
- Любая система с systemd, Node.js 18+ и Lighttpd

## Лицензия

MIT

