# KeLeME (渴了么) — 主规格

> 版本：1.0.0 · 最后更新：2026-03-27

## 概述

KeLeME 是一款 AI 驱动的智能饮水提醒应用，采用 **本地优先 + 云端同步** 架构。Flutter 客户端负责离线数据与 UI，后端 (Express + Prisma + PostgreSQL + Redis) 提供认证、数据持久化与 AI 代理。

## 技术栈

| 层         | 技术                                                           |
|------------|----------------------------------------------------------------|
| 客户端     | Flutter 3.x / Dart，Hive 本地存储，SharedPreferences          |
| 后端       | Express 4 + TypeScript，Prisma ORM，PostgreSQL 16，Redis 7    |
| AI         | DeepSeek Chat（后端代理），Open-Meteo（天气），Nominatim（地理编码） |
| 容器       | Podman (docker-compose)                                        |

## 规格索引

| 领域                     | 规格文件                           | 说明                                   |
|--------------------------|------------------------------------|----------------------------------------|
| Flutter 设计 token       | `specs/design-tokens/spec.md`；实现对照见 `flutter/doc/design-tokens.md` | 官网 light 对齐、全局 light 主题、Glass 容器、间距与产品验收 |
| 认证与用户               | `specs/auth.md`                    | 设备登录、邮箱绑定、JWT 令牌、刷新/注销 |
| 用户资料                 | `specs/profile.md`                 | 个人信息、饮水目标、作息与提醒偏好      |
| 饮水记录与离线同步       | `specs/drink-logs.md`              | 记录 CRUD、批量同步、离线队列、日归档   |
| AI 聊天                  | `specs/ai-chat.md`                 | 流式对话、Function Calling、记忆系统    |
| 每日饮水计划             | `specs/daily-plan.md`              | AI 生成、Slot 执行、通知调度            |
| 通知                     | `specs/notifications.md`           | 定时提醒、自定义提醒、权限管理          |
| 社区关怀                 | `specs/community.md`               | 好友码、关怀联系人、挑战系统            |
| 天气与智能目标           | `specs/weather-goal.md`            | 天气获取、AI 动态目标预测               |

## 架构原则

1. **本地优先**：所有数据先写入 SharedPreferences / Hive，UI 无需等待网络
2. **后台同步**：操作失败时入队（DrinkSyncService），后续自动重试
3. **双令牌认证**：accessToken（短期）+ refreshToken（长期，支持 Redis 黑名单）
4. **后端代理 AI**：客户端不接触 AI API Key，统一通过后端 `/api/ai/chat` SSE 代理
5. **功能分层**：`core/`（基础设施）→ `features/`（业务功能）

## 数据流总览

```
Flutter 客户端                              后端
─────────────                             ─────────
UserProvider ──→ SharedPreferences (本地真相)
    │                    ↕ 异步
    ├── BackendApiService ←──→ Express API
    │       │                              │
    │       ├── /auth/*                    ├── JWT 验证
    │       ├── /api/profile               ├── Prisma → PostgreSQL
    │       ├── /api/drink-logs            ├── Redis (黑名单/限流)
    │       ├── /api/plans                 │
    │       ├── /api/memory                │
    │       ├── /api/care                  │
    │       └── /api/ai/chat ──→ SSE ──→  └── DeepSeek API
    │
    ├── DrinkSyncService (离线队列 + 重试)
    ├── NotificationService (本地提醒)
    ├── WeatherService → Open-Meteo API
    ├── MemoryService → Hive
    └── GoalPredictor (纯函数)
```

## 错误处理

- 后端统一使用自定义错误类：`UnauthorizedError`、`ConflictError`、`NotFoundError`、`ValidationError`、`TooManyRequestsError`
- Express 全局错误中间件将错误转换为 `{ error: { code, message } }` JSON 响应
- 客户端侧 `BackendApiService` 拦截 401 自动刷新令牌，失败则重新设备登录
