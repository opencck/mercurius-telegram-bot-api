[English](README.md) | **Русский**

# mercurius-telegram-bot-api

Локальный [сервер Telegram Bot API](https://github.com/tdlib/telegram-bot-api), собранный из официальных исходников на
закреплённом коммите, без сторонних образов. Модуль [Меркурия](https://github.com/opencck/mercurius), работает и сам по
себе. В режиме `--local` бот скачивает и отправляет файлы до 2000 МБ (облачный Bot API — до 20 МБ).

## Настройки

| Переменная | Смысл |
|---|---|
| `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` | обязательны, с [my.telegram.org](https://my.telegram.org) |
| `TELEGRAM_PROXY` | прокси `http://` или `https://` для исходящих запросов вебхука сервера; другие виды не используются |

Аргументы сборки: `TELEGRAM_BOT_API_COMMIT` (закреплённый коммит, Bot API 10.4) и `BUILD_JOBS` (по умолчанию 1:
компилятор tdlib берёт несколько ГБ памяти на задачу).

Файлы лежат в `/var/lib/telegram-bot-api`; бот читает их по пути, который сообщает сервер, поэтому в контейнер бота
монтируется та же папка. Сервер слушает порт 8081.

## Запуск

```sh
docker build -t mercurius-telegram-bot-api .
docker run --rm -e TELEGRAM_API_ID=... -e TELEGRAM_API_HASH=... -v $PWD/data:/var/lib/telegram-bot-api -p 8081:8081 mercurius-telegram-bot-api
```

В Меркурии сервис — в профиле compose `telegram-api`: добавьте его в `COMPOSE_PROFILES` и задайте
`TELEGRAM_API_URL=http://telegram-api:8081` в `.env`. Бот, работавший с облачным Bot API, перед переходом один раз
выходит из него (`logOut`).

## Лицензия

MIT. Сервер Telegram Bot API — Boost Software License 1.0.
