#!/bin/sh
# The local Bot API server: --local (files up to 2000 MB, kept in /var/lib/telegram-bot-api, read by the application
# from the same path). TELEGRAM_API_ID and TELEGRAM_API_HASH come from the environment (my.telegram.org).
# An HTTP proxy in TELEGRAM_PROXY carries its outgoing webhook requests: the server has no proxy for its own
# connection to Telegram (its --proxy is for webhooks only), so socks5 and vless are not used here.
set -eu
if [ -z "${TELEGRAM_API_ID:-}" ] || [ -z "${TELEGRAM_API_HASH:-}" ]; then
    echo "TELEGRAM_API_ID and TELEGRAM_API_HASH are required (my.telegram.org)" >&2
    exit 1
fi
mkdir -p /tmp/telegram-bot-api
set -- --local --dir=/var/lib/telegram-bot-api --temp-dir=/tmp/telegram-bot-api --http-port=8081
case "${TELEGRAM_PROXY:-}" in
    http://*|https://*) set -- "$@" "--proxy=${TELEGRAM_PROXY}" ;;
esac
exec /usr/local/bin/telegram-bot-api "$@"
