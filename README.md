**English** | [Русский](README.ru.md)

# mercurius-telegram-bot-api

A local [Telegram Bot API server](https://github.com/tdlib/telegram-bot-api), built from the official sources at a
pinned commit, with no third-party image. It is a module of [Mercurius](https://github.com/opencck/mercurius) and can be
used on its own. In `--local` mode a bot downloads and sends files up to 2000 MB (the cloud Bot API gives 20 MB).

## Settings

| Variable | Meaning |
|---|---|
| `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` | required, from [my.telegram.org](https://my.telegram.org) |
| `TELEGRAM_PROXY` | an `http://` or `https://` proxy for the server's outgoing webhook requests; other kinds are ignored |

Build arguments: `TELEGRAM_BOT_API_COMMIT` (the pinned commit, Bot API 10.4) and `BUILD_JOBS` (1 by default: the
compiler of tdlib takes several GB of memory per job).

Files are kept in `/var/lib/telegram-bot-api`; the bot reads them at the path the server reports, so mount the same
folder into the bot's container. The server listens on port 8081. A watchdog asks it every minute; after three missed
answers in a row the container stops and Docker starts it again.

## Run

```sh
docker build -t mercurius-telegram-bot-api .
docker run --rm -e TELEGRAM_API_ID=... -e TELEGRAM_API_HASH=... -v $PWD/data:/var/lib/telegram-bot-api -p 8081:8081 mercurius-telegram-bot-api
```

In Mercurius the service is in the compose profile `telegram-api`: add it to `COMPOSE_PROFILES` and set
`TELEGRAM_API_URL=http://telegram-api:8081` in `.env`. A bot that worked with the cloud Bot API is logged out of it once
(`logOut`) before the switch.

## License

MIT. Telegram Bot API server: Boost Software License 1.0.
