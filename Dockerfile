# A local Telegram Bot API server, built from the official sources at a pinned commit (no third-party image).
# Optional: the compose profile telegram-api. In --local mode a bot downloads and sends files up to 2000 MB.
# A module of the Mercurius agent: https://github.com/opencck/mercurius
FROM debian:bookworm-slim AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git cmake g++ make gperf zlib1g-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*
# Bot API 10.4 (2026-11-09)
ARG TELEGRAM_BOT_API_COMMIT=7232881b39dfcd048a0d569f1983c5184249ee05
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git /src \
    && cd /src \
    && git checkout "$TELEGRAM_BOT_API_COMMIT" \
    && git submodule update --init --recursive
# One job by default: the compiler of tdlib takes several GB of memory per job, and the host is shared
ARG BUILD_JOBS=1
RUN cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local \
    && cmake --build /build --target install -j "$BUILD_JOBS"

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl libssl3 zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10030 --home /var/lib/telegram-bot-api telegram
COPY --from=build /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
COPY entrypoint.sh probe.sh /usr/local/bin/
USER telegram
EXPOSE 8081
# The same check as the watchdog's: the bot answers, not only the port (probe.sh). The state is seen in docker compose ps
# and docker compose up --wait waits for it; the restart itself is the watchdog's (Docker does not restart an unhealthy
# container). The first minutes the server logs the bot in anew.
HEALTHCHECK --interval=60s --timeout=30s --start-period=300s --retries=3 CMD sh /usr/local/bin/probe.sh >/dev/null
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
