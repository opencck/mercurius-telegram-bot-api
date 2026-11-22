[English](README.md) | [Русский](README.ru.md) | **中文**

> 本文由模型翻译，尚未经人工审校；如有出入，以英文版为准。

# mercurius-telegram-bot-api

本地 [Telegram Bot API 服务器](https://github.com/tdlib/telegram-bot-api)，从官方源码在固定的提交上构建，不使用第三方镜像。它是 [Mercurius](https://github.com/opencck/mercurius) 的一个模块，也可以
单独使用。在 `--local` 模式下，机器人可以下载和发送最大 2000 MB 的文件（云端 Bot API 只有 20 MB）。

## 设置

| 变量 | 含义 |
|---|---|
| `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` | 必填，从 [my.telegram.org](https://my.telegram.org) 获取 |
| `TELEGRAM_PROXY` | 服务器发出的 webhook 请求所用的 `http://` 或 `https://` 代理；其他类型会被忽略 |
| `TELEGRAM_BOT_TOKEN` | 可选：机器人的令牌，用于健康检查（`getMe` 和 webhook 队列）；没有它时只检查端口 |

构建参数：`TELEGRAM_BOT_API_COMMIT`（固定的提交，Bot API 10.4）和 `BUILD_JOBS`（默认为 1：tdlib 的编译器每个任务要占用数 GB 内存）。

文件保存在 `/var/lib/telegram-bot-api`；机器人按服务器报告的路径读取它们，因此要把同一个文件夹挂载到机器人的容器中。服务器监听 8081 端口。镜像检查的是机器人是否应答，而不只是端口（`probe.sh`，健康检查）：10 秒内响应 `getMe`，并且 webhook 队列在减少。看门狗在最初五分钟之后每分钟执行同样的检查；连续三次未通过后，容器停止，Docker 会再次启动它。

## 运行

```sh
docker build -t mercurius-telegram-bot-api .
docker run --rm -e TELEGRAM_API_ID=... -e TELEGRAM_API_HASH=... -v $PWD/data:/var/lib/telegram-bot-api -p 8081:8081 mercurius-telegram-bot-api
```

在 Mercurius 中，该服务位于 compose 配置 `telegram-api` 下：把它加入 `COMPOSE_PROFILES`，并在 `.env` 中设置
`TELEGRAM_API_URL=http://telegram-api:8081`。曾使用云端 Bot API 的机器人，在切换之前要先从云端退出一次
（`logOut`）。

## 许可证

MIT。Telegram Bot API 服务器：Boost Software License 1.0。
