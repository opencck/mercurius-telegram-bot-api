#!/bin/sh
# Does the server do its work: not "is the port open", but "does the bot answer". The healthcheck of the image and the
# watchdog of entrypoint.sh both run it.
#
# With TELEGRAM_BOT_TOKEN: getMe must answer "ok":true within PROBE_TIMEOUT seconds (10 by default) — a hung server
# still answers its root page at once but takes half a minute or more on a method of the bot. Then getWebhookInfo; the
# script prints two numbers: the updates waiting for delivery and the date of the last webhook error (0 — none). The
# watchdog reads them to tell a queue that does not drain from a receiver that is down.
# Without the token: any HTTP answer of the root page (the old check).
#
# Exit 0 — healthy; 1 — not. Nothing of the token or of the answers is printed.
#
# ref: references/hermes-agent/plugins/platforms/telegram/telegram_polling_probe.py@e96221fa:L66-L87 — a wedged
#      intake is seen only in pending_update_count while getMe stays healthy; here the server itself holds the queue
#      of the webhook, so its number comes with the date of the last webhook error
set -u
timeout="${PROBE_TIMEOUT:-10}"
base=http://127.0.0.1:8081
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
    curl -s -m "$timeout" -o /dev/null "$base/" || exit 1
    echo "0 0"
    exit 0
fi
me="$(curl -s -m "$timeout" "$base/bot${TELEGRAM_BOT_TOKEN}/getMe" 2>/dev/null)" || exit 1
case "$me" in
    *'"ok":true'*) ;;
    *) exit 1 ;;
esac
info="$(curl -s -m "$timeout" "$base/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo" 2>/dev/null)" || exit 1
case "$info" in
    *'"ok":true'*) ;;
    *) exit 1 ;;
esac
pending="$(printf '%s' "$info" | sed -n 's/.*"pending_update_count":\([0-9]*\).*/\1/p')"
error="$(printf '%s' "$info" | sed -n 's/.*"last_error_date":\([0-9]*\).*/\1/p')"
echo "${pending:-0} ${error:-0}"
