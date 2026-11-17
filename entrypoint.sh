#!/bin/sh
# The local Bot API server: --local (files up to 2000 MB, kept in /var/lib/telegram-bot-api, read by the application
# from the same path). TELEGRAM_API_ID and TELEGRAM_API_HASH come from the environment (my.telegram.org).
# An HTTP proxy in TELEGRAM_PROXY carries its outgoing webhook requests: the server has no proxy for its own
# connection to Telegram (its --proxy is for webhooks only), so socks5 and vless are not used here.
# A watchdog asks the server every minute; three answers missed in a row — the server hung, the container stops and
# Docker starts it again (restart policy). Seen once: the server stopped answering and delivering webhooks.
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
/usr/local/bin/telegram-bot-api "$@" &
server=$!
trap 'kill -TERM "$server" 2>/dev/null; wait "$server"; exit 0' TERM INT
missed=0
while kill -0 "$server" 2>/dev/null; do
    sleep "${WATCHDOG_PERIOD:-60}" &
    wait $! || true
    # any HTTP answer (even 404) means the server is alive; no answer in 10 s is a miss
    if curl -s -m 10 -o /dev/null http://127.0.0.1:8081/; then
        missed=0
    else
        missed=$((missed + 1))
        echo "watchdog: no answer ($missed)" >&2
        if [ "$missed" -ge 3 ]; then
            echo "watchdog: the server hung, stopping" >&2
            kill -KILL "$server" 2>/dev/null || true
            exit 1
        fi
    fi
done
wait "$server"
