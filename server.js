const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const dgram = require("dgram");

const app = express();
const PORT = 3000;
const CONFIG_FILE = path.join(__dirname, "config.json");

app.use(cors());
app.use(express.static("public"));

const PPT_PORT = 61000; // Порт управления PowerPoint
const udpClient = dgram.createSocket("udp4");

// Функция загрузки конфигурации
function loadConfig() {
    if (fs.existsSync(CONFIG_FILE)) {
        try {
            return JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8"));
        } catch (error) {
            console.error("❌ Ошибка чтения config.json:", error);
        }
    }
    return { ip: "192.168.1.100" }; // Значение по умолчанию
}

let config = loadConfig();

// API для получения текущих настроек
app.get("/api/get-settings", (req, res) => {
    config = loadConfig();
    res.json(config);
});

// API для обновления IP-адреса
app.get("/api/set-ip", (req, res) => {
    const newIP = req.query.ip;
    if (!newIP) {
        return res.status(400).json({ error: "IP-адрес не указан!" });
    }

    config.ip = newIP;

    try {
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 4));
        console.log(`✅ IP обновлён: ${newIP}`);
        res.json({ success: true, ip: newIP });
    } catch (error) {
        console.error("❌ Ошибка записи в config.json:", error);
        res.status(500).json({ error: "Ошибка сохранения IP-адреса!" });
    }
});

// Функция отправки команды в PowerPoint
function sendCommand(command) {
    const message = Buffer.from(command);
    udpClient.send(message, 0, message.length, PPT_PORT, config.ip, (err) => {
        if (err) {
            console.error("❌ Ошибка отправки команды:", err);
        } else {
            console.log(`📡 Отправлена команда: "${command}" на ${config.ip}:${PPT_PORT}`);
        }
    });
}

// API для отправки команд "NEXT" и "PREV"
app.get("/api/command", (req, res) => {
    const action = req.query.action; // Получаем параметр action (NEXT или PREV)

    if (!action || (action !== "NEXT" && action !== "PREV")) {
        return res.status(400).json({ error: "Некорректная команда! Используйте ?action=NEXT или ?action=PREV" });
    }

    sendCommand(action);
    res.json({ success: true, command: action });
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`🚀 Server is running on port ${PORT}`);
});
