#!/bin/sh
# The local Bot API server: --local (files up to 2000 MB, kept in /var/lib/telegram-bot-api, read by the application
# from the same path). TELEGRAM_API_ID and TELEGRAM_API_HASH come from the environment (my.telegram.org).
# An HTTP proxy in TELEGRAM_PROXY carries its outgoing webhook requests: the server has no proxy for its own
# connection to Telegram (its --proxy is for webhooks only), so socks5 and vless are not used here.
#
# A watchdog runs probe.sh every WATCHDOG_PERIOD seconds (60). A miss: the bot does not answer (with TELEGRAM_BOT_TOKEN —
# getMe within 10 s; without — the root page), or updates wait for delivery and their number does not go down while
# the webhook reports no error for WATCHDOG_ERROR_WINDOW seconds (600; an error means the receiver is down, and a
# restart of this server does not help it). Three misses in a row — the server hung, the container stops and Docker
# starts it again (restart policy). The first WATCHDOG_GRACE seconds (300) are not checked: after a start the server
# logs the bot in anew, which took minutes. Seen twice: the server stopped delivering webhooks and kept answering its
# root page, so that page alone is not a sign of health.
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
started="$(date +%s)"
missed=0
last=0
while kill -0 "$server" 2>/dev/null; do
    sleep "${WATCHDOG_PERIOD:-60}" &
    wait $! || true
    now="$(date +%s)"
    if [ $((now - started)) -lt "${WATCHDOG_GRACE:-300}" ]; then
        continue
    fi
    miss=""
    if state="$(sh /usr/local/bin/probe.sh)"; then
        pending="${state% *}"
        error="${state#* }"
        if [ "$pending" -gt 0 ] && [ "$pending" -ge "$last" ] && [ $((now - error)) -gt "${WATCHDOG_ERROR_WINDOW:-600}" ]; then
            miss="$pending updates wait and do not go out"
        fi
        last="$pending"
    else
        miss="the bot does not answer"
    fi
    if [ -z "$miss" ]; then
        missed=0
        continue
    fi
    missed=$((missed + 1))
    echo "watchdog: $miss ($missed)" >&2
    if [ "$missed" -ge 3 ]; then
        echo "watchdog: the server hung, stopping" >&2
        kill -KILL "$server" 2>/dev/null || true
        exit 1
    fi
done
wait "$server"
