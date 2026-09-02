# Установка — пошагово

## 1. Требования
Node.js 22.22.3+ (использовал 24.18.0), npm 11.16+

## 2. Установка OpenClaw
npm install -g openclaw@latest --allow-scripts=openclaw

## 3. Базовая настройка
openclaw doctor
openclaw config set gateway.mode local

## 4. Подключение модели OpenAI
export OPENAI_API_KEY="ваш_ключ"
openclaw configure --section model

Важно: модели с зависимостью от плагина codex могут ронять Gateway на старте. Использовалась gpt-5.4-nano — без этой зависимости.

## 5. Подключение Telegram
export TELEGRAM_BOT_TOKEN="ваш_токен_от_botfather"
openclaw configure --section channels

## 6. Обход гео-блокировки OpenAI без VPN на устройстве
Если api.openai.com возвращает 403 Country not supported, поднимите HTTP-прокси (tinyproxy) на VDS в другом регионе:
export HTTPS_PROXY="http://user:pass@ваш-vds-ip:8888"

## 7. Запуск
openclaw gateway run
или как сервис: openclaw gateway install

## 8. Pairing
При первом сообщении бот запросит код:
openclaw pairing approve telegram <код>
