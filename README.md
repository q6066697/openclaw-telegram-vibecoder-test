# OpenClaw + Telegram — тестовое задание "Вайбкодер"

Разворачивание OpenClaw локально (WSL) с подключением Telegram-бота через OpenAI API, с обходом гео-блокировки OpenAI без использования VPN на устройстве.

Помимо базового деплоя, в репозитории реализованы собственный OpenClaw skill
(`web-search` — см. [skills/web-search](skills/web-search)) и
security-хардненинг деплоя (env-only секреты, SecretRef для gateway-токена,
Basic Auth + IP allowlist на прокси, pairing/owner-политика для Telegram —
см. [SECURITY.md](SECURITY.md)).

## Стек
- OpenClaw 2026.8.2
- Node.js 24
- OpenAI (gpt-5.4-nano)
- Telegram Bot API
- tinyproxy на собственном VDS (Амстердам) — точечный HTTP-прокси для обхода гео-блока OpenAI

## Проблема и решение

Задание требовало обеспечить стабильную работу бота без VPN на устройстве.

Выяснилось, что Telegram доступен напрямую, а OpenAI API возвращает 403 Country not supported. Вместо VPN на всё устройство — лёгкий HTTP-прокси (tinyproxy) на VDS в Амстердаме, трафик к OpenAI идёт через HTTPS_PROXY только для процесса OpenClaw.

## Установка

См. SETUP.md — пошаговая инструкция.

## Сложности

- Скрытая зависимость дефолтной модели от плагина codex
- Ограниченное место на исходном VDS — переход на локальную установку в WSL
- Гео-блокировка OpenAI отдельно от Telegram — разные проблемы, разные решения

## Структура проекта

```
.
├── README.md                       — этот файл
├── SETUP.md                        — пошаговая установка
├── SECURITY.md                     — секреты: env-only, SecretRef, proxy Basic Auth, Telegram owner-политика
├── ARCHITECTURE.md                 — диаграмма потока Telegram → Gateway → Agent → OpenAI и разбор решения про гео-блок
├── config/
│   └── openclaw.example.json       — пример openclaw.json без реальных секретов (плейсхолдеры)
├── scripts/
│   ├── setup-proxy.sh              — идемпотентная установка/настройка tinyproxy на VDS
│   ├── start.sh                    — запуск Gateway с переменными из .env (сам .env не коммитится)
│   └── healthcheck.sh              — проверка, что Gateway и Telegram-провайдер живы
└── skills/
    └── web-search/                 — собственный OpenClaw skill: веб-поиск (Brave Search API + no-key DuckDuckGo фоллбэк)
        ├── SKILL.md
        └── scripts/search.sh
```
