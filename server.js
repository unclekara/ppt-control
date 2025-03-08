const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;
const CONFIG_FILE = path.join(__dirname, "config.json");

app.use(cors());
app.use(express.static("public"));

// Функция загрузки конфигурации
function loadConfig() {
    if (fs.existsSync(CONFIG_FILE)) {
        try {
            return JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8"));
        } catch (error) {
            console.error("❌ Ошибка чтения config.json:", error);
        }
    }
    return { ip: "192.168.1.100" };
}

let config = loadConfig();

// API для получения текущих настроек
app.get("/api/get-settings", (req, res) => {
    config = loadConfig();
    res.json(config);
});

// API для обновления IP
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

// Запуск сервера
app.listen(PORT, () => {
    console.log(`🚀 Server is running on port ${PORT}`);
});
