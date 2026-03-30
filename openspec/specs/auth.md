# 规格：认证与用户管理

> 领域：backend + flutter · 版本：1.0.0 · 最后更新：2026-03-27

## 概述

KeLeME 采用 **双令牌认证**，支持两种登录路径：
- **匿名设备登录**（默认）：首次启动自动生成 UUID deviceId，无需任何用户操作
- **邮箱绑定登录**：在已有设备账户上绑定邮箱+密码，升级为可跨设备账户

---

## 需求

### REQ-AUTH-01：设备登录

**描述**：任何持有 deviceId 的客户端均可登录，不存在的 deviceId 将自动注册新用户。

**场景 1：新设备首次登录**
- Given 客户端无本地 deviceId
- When POST `/auth/device` 不携带 `deviceId`
- Then 创建新 User，返回 `{ accessToken, refreshToken, deviceId, isNewUser: true }`，`deviceId` 由后端生成 UUID

**场景 2：老设备恢复**
- Given 客户端本地持有已注册的 `deviceId`
- When POST `/auth/device` 携带该 `deviceId`
- Then 查找已有 User 并返回新令牌，`isNewUser: false`

**场景 3：非法 deviceId 格式**
- Given 客户端传入非 UUID 格式字符串
- When POST `/auth/device`
- Then 返回 400，错误码 `VALIDATION_ERROR`

---

### REQ-AUTH-02：邮箱绑定

**描述**：已登录的设备账户可绑定邮箱+密码，实现跨设备登录能力。

**场景 1：成功绑定**
- Given 当前用户已通过设备登录，未绑定邮箱
- When POST `/auth/bind-email` 携带合法 email 和 password（≥8字符）
- Then 更新 User 的 email 和 passwordHash，返回 200

**场景 2：重复绑定同一邮箱（幂等）**
- Given 当前用户已绑定该邮箱
- When POST `/auth/bind-email` 携带同一邮箱和合法密码
- Then 返回 200，不报错（更新密码）

**场景 3：邮箱已被其他账户占用**
- Given 该 email 已在其他 User 记录中
- When POST `/auth/bind-email`
- Then 返回 409，错误码 `CONFLICT`

**场景 4：密码过短**
- Given password 少于 8 字符
- When POST `/auth/bind-email`
- Then 返回 400，错误码 `VALIDATION_ERROR`

---

### REQ-AUTH-03：邮箱登录

**描述**：已绑定邮箱的用户可通过邮箱+密码登录。

**场景 1：正确凭据**
- Given 用户已绑定邮箱且密码正确
- When POST `/auth/login` 携带 email + password
- Then 返回 `{ accessToken, refreshToken }`，HTTP 200

**场景 2：凭据错误（邮箱不存在或密码错误）**
- Given email 不存在，或密码不匹配
- When POST `/auth/login`
- Then 返回 401，错误消息 "邮箱或密码错误"（不区分具体原因，防止用户枚举）

**场景 3：触发限流**
- Given 同一 IP 在 60 秒内尝试超过 5 次
- When POST `/auth/login`
- Then 返回 429，响应头含 `Retry-After`

---

### REQ-AUTH-04：访问令牌刷新

**描述**：accessToken 过期后，客户端用 refreshToken 换取新 accessToken。

**场景 1：正常刷新**
- Given refreshToken 有效且未在 Redis 黑名单中
- When POST `/auth/refresh` 携带 refreshToken
- Then 返回新 `{ accessToken }`，HTTP 200

**场景 2：refreshToken 已注销（在黑名单中）**
- Given 该 refreshToken 已通过 /auth/logout 加入 Redis 黑名单
- When POST `/auth/refresh`
- Then 返回 401，错误码 `UNAUTHORIZED`

**场景 3：refreshToken 格式非法/已过期**
- Given JWT 签名无效或已过期
- When POST `/auth/refresh`
- Then 返回 401

---

### REQ-AUTH-05：注销

**描述**：将当前 refreshToken 加入 Redis 黑名单，使其失效。

**场景 1：正常注销**
- Given 用户持有有效 refreshToken
- When POST `/auth/logout` 携带 refreshToken（需已登录）
- Then 将 refreshToken 写入 Redis（key: `rt:bl:{token}`，TTL = 剩余有效期）并返回 200

---

### REQ-AUTH-06：客户端自动认证恢复

**描述**：Flutter 客户端在启动时自动恢复或重建认证状态，用户无感知。

**场景 1：本地令牌有效**
- Given SharedPreferences 中存有 accessToken
- When `BackendApiService.ensureAuthenticated()` 被调用
- Then GET `/api/profile` 成功，认证恢复完成

**场景 2：accessToken 过期但 refreshToken 有效**
- Given GET `/api/profile` 返回 401
- When Dio 拦截器自动尝试 refreshToken
- Then 获取新 accessToken 并重试原请求

**场景 3：所有令牌均失效（离线过长或重装）**
- Given refresh 也失败
- When 拦截器回退
- Then 自动调用 `deviceLogin()`，使用存储的 deviceId 重新注册，透明切换回匿名模式

---

## API 端点

| 方法   | 路径               | 认证 | 限流         | 说明                  |
|--------|--------------------|----|--------------|----------------------|
| POST   | `/auth/device`     | 否 | 5次/min/IP   | 设备登录/注册         |
| POST   | `/auth/bind-email` | 是 | —            | 绑定邮箱密码          |
| POST   | `/auth/login`      | 否 | 5次/min/IP   | 邮箱密码登录          |
| POST   | `/auth/refresh`    | 否 | —            | 刷新 accessToken      |
| POST   | `/auth/logout`     | 是 | —            | 注销 refreshToken     |

---

## 数据模型

### User（Prisma）

| 字段           | 类型      | 约束                 | 说明             |
|----------------|-----------|----------------------|------------------|
| `id`           | String    | PK, cuid             | 用户唯一 ID      |
| `deviceId`     | String?   | unique               | 设备匿名 ID      |
| `phone`        | String?   | unique               | 手机（预留）     |
| `email`        | String?   | unique               | 绑定邮箱         |
| `passwordHash` | String?   | —                    | bcrypt 哈希      |
| `nickname`     | String    | default "水友"       | 昵称             |
| `friendCode`   | String?   | unique, 6字符        | 好友码           |
| `createdAt`    | DateTime  | default now          | 创建时间         |
| `updatedAt`    | DateTime  | @updatedAt           | 更新时间         |

### 令牌规格

| 类型           | 签名 Secret         | 有效期  | 说明                     |
|----------------|---------------------|---------|--------------------------|
| accessToken    | `JWT_SECRET`        | 短期    | Bearer Token，携带于请求头 |
| refreshToken   | `JWT_REFRESH_SECRET`| 长期    | 换取新 accessToken       |

---

## 客户端实现路径

- **文件**：`flutter/lib/core/services/backend_api_service.dart`
- 初始化：`init()` 读取本地令牌 → 构建 Dio 实例 + 认证拦截器
- 关键字段（存于 SharedPreferences）：`backend_access_token`、`backend_refresh_token`、`backend_device_id`
- 自动重试：401 → 尝试 `POST /auth/refresh` → 失败则 `POST /auth/device`
