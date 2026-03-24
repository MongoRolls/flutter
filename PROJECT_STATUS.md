# 渴了么项目现状总结

> 生成日期：2026-03-25
> 项目版本：Flutter 2.5.1+1 / Backend 1.0.0

---

## 项目概述

**渴了么 (KeLeMe)** 是一款 AI 驱动的智能饮水提醒应用，包含 Flutter 客户端和 Node.js 后端服务。采用**本地优先 + 可选云端同步**的混合架构。

### 核心价值
- 🤖 AI 饮水计划生成（基于天气、体重、活动量）
- 💬 智能对话助手（DeepSeek API + Function Calling）
- 🔔 智能提醒系统（三种风格：温柔/活泼/严肃）
- 👥 心连心关怀功能（本地 Mock）
- 📊 数据可视化（进度环、月度打卡、连续天数）

---

## 一、后端 (Backend) 现状

### 1.1 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| Runtime | Node.js | 20+ LTS |
| Language | TypeScript | ^5.7.2 |
| Framework | Express.js | ^4.21.2 |
| Database | PostgreSQL | 16 (Alpine) |
| ORM | Prisma | ^6.0.0 |
| Cache | Redis | 7 (Alpine) |
| Auth | JWT | access + refresh 双 token |
| Validation | Zod | ^3.24.1 |
| Logging | Pino | ^9.6.0 |

### 1.2 数据库设计

**已实现的模型：**

| 模型 | 主要字段 | 说明 |
|------|----------|------|
| User | deviceId, email, passwordHash, nickname | 支持设备匿名登录 + 邮箱绑定 |
| UserProfile | dailyGoalMl, wakeTime, bedTime, weightKg, activityLevel | 用户健康档案 |
| DrinkLog | userId, ml, icon, description, loggedAt | 饮水记录，支持批量同步 |
| MemoryFact | userId, category, content, source | AI 长期记忆存储 |
| SessionSummary | userId, summary, createdAt | AI 会话摘要 |
| TodayPlan | userId, date, planJson | 每日 AI 生成的饮水计划 |
| CareContact | ownerId, contactId, nickname | 心连心联系人关系 |

**关键设计：**
- 设备匿名登录：首次启动无需注册，自动创建 `deviceId` 关联用户
- 数据同步：`DrinkLog.syncedAt` 字段标识同步状态
- 唯一约束：`TodayPlan` 的 `[userId, date]` 防止重复计划

### 1.3 API 路由完成度

#### ✅ 已实现（Phase 1-3）

| 模块 | 路由前缀 | 主要端点 |
|------|----------|----------|
| 认证 | `/auth` | 设备登录、邮箱绑定、邮箱登录、Token 刷新、登出 |
| 用户档案 | `/api/profile` | GET/PUT 用户档案 |
| 饮水记录 | `/api/drink-logs` | CRUD + 批量同步（最多 500 条） |
| 每日计划 | `/api/plans` | GET/POST 计划（按日期查询） |
| 记忆存储 | `/api/memory` | CRUD MemoryFact |
| 会话摘要 | `/api/sessions` | CRUD SessionSummary |
| AI 代理 | `/api/ai/chat` | SSE 流式代理 DeepSeek API |
| 关怀联系人 | `/api/care/contacts` | CRUD CareContact |
| 健康检查 | `/health` | 服务状态 |

#### ⚠️ 限流配置

| 类型 | 限流规则 | Key |
|------|---------|-----|
| 通用 API | 100 次/分钟 | 用户 ID 或 IP |
| AI 接口 | 10 次/分钟 | 用户 ID 或 IP |
| 认证接口 | 5 次/分钟 | IP |

### 1.4 安全措施

- ✅ HTTP 安全头（Helmet 中间件）
- ✅ CORS 配置（生产环境限定域名）
- ✅ 密码加密（bcryptjs，cost factor 12）
- ✅ JWT 双 token（access 15min + refresh 7d）
- ✅ Token 黑名单（Redis 存储）
- ✅ API Key 保护（DeepSeek Key 仅存服务端）
- ✅ 输入校验（Zod 全链路）
- ✅ 日志脱敏（Pino redact）

### 1.5 部署配置

**Docker Compose：**
- PostgreSQL 16 Alpine（端口 5432）
- Redis 7 Alpine（端口 6379）
- 数据持久化到 Docker volumes
- 健康检查配置

**Dockerfile：**
- 多阶段构建（构建阶段 + 运行阶段）
- 健康检查：wget 访问 `/health`
- 暴露端口：3000

**环境变量：**
```bash
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/keleme
REDIS_URL=redis://localhost:6379
JWT_SECRET=<至少 32 字符>
JWT_REFRESH_SECRET=<至少 32 字符>
DEEPSEEK_API_KEY=<你的 DeepSeek API Key>
CORS_ORIGIN=http://localhost:*
```

### 1.6 后端架构亮点

1. **零摩擦认证**：首次启动自动设备匿名登录
2. **API Key 安全**：DeepSeek Key 只存服务端，SSE 代理转发
3. **分层清晰**：routes → services → Prisma
4. **类型安全**：TypeScript + Zod 全链路
5. **优雅关闭**：处理 SIGTERM/SIGINT
6. **限流保护**：多级限流，防止滥用

### 1.7 后端待完成事项

- [ ] 测试文件（单元测试 + 集成测试）
- [ ] 数据同步接口优化（增量同步、冲突解决）
- [ ] 社区功能（排行榜、推送通知）
- [ ] 部署文档和 CI/CD 配置

---

## 二、Flutter 客户端现状

### 2.1 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| Framework | Flutter | 3.24+ |
| Language | Dart | ^3.11.1 |
| State Management | ChangeNotifier | 原生，无第三方包 |
| Local Storage | SharedPreferences + Hive | 键值 + 结构化 |
| HTTP Client | Dio | ^5.7.0 |
| AI Integration | DeepSeek API | deepseek-chat 模型 |
| Notifications | flutter_local_notifications | ^21.0.0 |
| Location | geolocator | ^13.0.0 |

### 2.2 项目架构

**特性驱动目录结构：**
```
ke_le_me/lib/
├── core/                    # 核心模块
│   ├── models/              # 数据模型
│   ├── providers/           # 状态管理
│   ├── services/            # 业务服务
│   ├── theme/               # 主题配置
│   └── utils/               # 工具类
├── common/widgets/          # 通用组件
└── features/                # 功能模块
    ├── onboarding/          # 引导页
    ├── home/                # 首页
    ├── plan/                # 智能计划
    ├── chat/                # AI 助手
    ├── community/           # 社区
    ├── settings/            # 设置
    └── debug/               # 调试工具
```

**状态管理架构：**
- `UserProvider`：全局用户状态（档案、今日饮水、月度打卡、连续天数）
- `PlanProvider`：AI 计划生成、时间槽管理
- `ChatProvider`：AI 对话、工具调用、消息历史
- `HeartProvider`：心连心关怀、联系人管理
- `PlazaProvider`：成就系统、挑战进度

**数据流：**
```
Provider (ChangeNotifier)
       ↓ notifyListeners()
Screens (StatefulWidget)
       ↓ setState()
UI 重建
```

### 2.3 已实现功能模块

#### 首页模块 (`features/home/`)

| 功能 | 状态 | 说明 |
|------|------|------|
| 进度环显示 | ✅ | 自定义 ProgressRing，带动画 |
| 快速饮水打卡 | ✅ | 底部弹窗选择预设杯子 |
| 杯子预设管理 | ✅ | 增删改查，SharedPreferences 持久化 |
| 今日饮水记录 | ✅ | 带入场动画的列表 |
| 月度打卡日历 | ✅ | 显示达标/未达标状态 |
| 连续天数统计 | ✅ | 基于历史记录计算 |
| 天气卡片 | ✅ | 显示温度、湿度、UV（Open-Meteo API） |
| 动态目标建议 | ✅ | 基于天气和活动量预测 |

#### 智能计划模块 (`features/plan/`)

| 功能 | 状态 | 说明 |
|------|------|------|
| GPS 定位获取天气 | ✅ | Open-Meteo 免费天气 API |
| 城市名手动输入 | ✅ | 地理编码支持中文 |
| AI 流式生成计划 | ✅ | SSE 流式响应，打字效果 |
| 时间槽饮水记录 | ✅ | 点击槽位记录饮水 |
| 计划采纳为目标 | ✅ | 更新 UserProvider.dailyGoalMl |
| 计划提醒调度 | ✅ | 为未来时间点设置通知 |

#### AI 助手模块 (`features/chat/`)

| 功能 | 状态 | 说明 |
|------|------|------|
| 流式对话 | ✅ | DeepSeek API + SSE |
| 工具调用 | ✅ | Function Calling（最多 8 轮） |
| 记忆持久化 | ✅ | Hive 存储 MemoryFact |
| 会话摘要 | ✅ | 退出时生成摘要 |
| 建议气泡 | ✅ | 首次对话显示快捷建议 |
| System Prompt 构建 | ✅ | 动态加载用户信息、天气、记忆 |

**已注册的 AI 工具：**

| 工具名 | 功能 |
|--------|------|
| `add_drink` | 记录饮水 |
| `get_today_progress` | 查询今日进度 |
| `save_health_note` | 保存健康信息到记忆 |
| `set_reminder` | 设置自定义提醒 |
| `get_weather` | 获取天气信息 |
| `update_profile` | 更新用户档案 |

#### 社区模块 (`features/community/`)

| 功能 | 状态 | 说明 |
|------|------|------|
| 心连心关怀 | ⚠️ | Mock 数据，本地通知模拟 |
| 联系人管理 | ✅ | 添加/删除联系人 |
| 成就系统 | ✅ | 自动解锁条件检测 |
| 挑战进度 | ✅ | 基于连续天数更新 |

#### 设置模块 (`features/settings/`)

| 功能 | 状态 | 说明 |
|------|------|------|
| 每日目标调整 | ✅ | 滑动条，联动体重推荐 |
| 提醒时间设置 | ✅ | 时间选择器 |
| 提醒风格选择 | ✅ | 温柔/活泼/严肃 |
| API Key 配置 | ✅ | 支持覆盖内置 Key |
| 健康档案查看 | ✅ | 展示 AI 记忆的事实 |
| 通知测试 | ✅ | 触发即时通知 |

#### 调试模块 (`features/debug/`)

隐藏入口（连续点击 logo 或版本号 5 次），提供：
- 设备信息查看
- 通知权限检查/测试
- 状态导出
- 数据重置

### 2.4 与后端的集成状态

**BackendApiService 架构：**
- 单例模式
- Dio HTTP 客户端
- JWT 自动刷新拦截器
- 设备匿名登录

**已集成的 API：**

| API 端点 | 状态 | 用途 |
|----------|------|------|
| `POST /auth/device` | ✅ | 设备匿名登录 |
| `POST /auth/refresh` | ✅ | Token 刷新 |
| `GET /api/profile` | ✅ | 获取用户档案 |
| `PUT /api/profile` | ✅ | 更新用户档案 |
| `POST /api/drink-logs` | ✅ | 创建饮水记录 |
| `GET /api/drink-logs` | ✅ | 获取饮水记录 |
| `POST /api/drink-logs/bulk-sync` | ✅ | 批量同步 |
| `POST /api/ai/chat` | ✅ | AI 代理模式 |

**当前集成模式：混合模式（本地优先 + 可选后端同步）**

1. **本地数据**：SharedPreferences + Hive 存储所有用户数据
2. **后端同步**：可选，通过 BackendApiService 同步
3. **AI 代理**：支持两种模式
   - 直连 DeepSeek API（使用内置或用户配置的 Key）
   - 通过后端代理（需要后端认证）

### 2.5 AI 功能实现详情

**模型选择：**
- 默认模型：`deepseek-chat`
- API 基地址：`https://api.deepseek.com`
- 内置 Key：代码中硬编码备用 Key

**System Prompt 组成：**
1. 角色设定（小可，健康助手）
2. 用户信息（昵称、体重、目标、作息）
3. 今日状态（已喝水量、进度、连续天数）
4. 当前天气（温度、湿度、UV、AI 建议）
5. 长期记忆（从 MemoryService 加载）
6. 近期对话摘要（从 SessionSummary 加载）

**工具调用流程：**
```
用户发送消息
      ↓
ChatProvider.sendMessage()
      ↓
AiService.sendMessageStream() → SSE 流
      ↓
收到 AiToolCallDelta 事件
      ↓
FunctionRegistry.execute(toolName, args)
      ↓
生成 ToolCall 结果消息
      ↓
继续请求 AI（最多 8 轮）
      ↓
收到 AiDone 事件
      ↓
保存消息到 ChatStorageService
```

**智能目标预测：**
```dart
double base = weightKg * 35;  // 基础：体重 × 35ml

// 天气因素
if (weather.temperature > 35) base *= 1.25;
if (weather.humidity < 30) base *= 1.10;
if (weather.uvIndexMax > 8) base *= 1.10;

// 活动量因素
if (activityLevel == '中等') base *= 1.15;
if (activityLevel == '较多') base *= 1.25;

return base.clamp(1500, 5000);
```

### 2.6 通知系统

**三种提醒风格：**

| 风格 | 示例消息 |
|------|----------|
| 温柔 | "该喝水啦，来一杯温水吧 ~" |
| 活泼 | "叮咚！你的水杯在召唤你！" |
| 严肃 | "请注意：长时间未饮水会影响身体机能" |

**调度逻辑：**
- 在起床时间 ~ 就寝时间之间
- 按设定间隔调度通知
- 提前调度未来 7 天的通知
- 使用 timezone 包处理时区

### 2.7 依赖项清单

| 包名 | 版本 | 用途 |
|------|------|------|
| `shared_preferences` | ^2.3.4 | 本地键值存储 |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | 结构化本地存储 |
| `dio` | ^5.7.0 | HTTP 客户端 |
| `flutter_local_notifications` | ^21.0.0 | 本地通知 |
| `timezone` / `flutter_timezone` | ^0.11.0 / ^3.0.1 | 时区处理 |
| `geolocator` | ^13.0.0 | GPS 定位 |
| `google_fonts` | ^6.2.1 | 字体（Noto Sans SC, Space Mono） |
| `flutter_markdown` | ^0.7.7+1 | Markdown 渲染 |

### 2.8 Flutter 客户端架构亮点

1. **清晰的模块化架构**：特性驱动，职责分离
2. **本地优先**：离线可用，数据隐私友好
3. **AI 深度集成**：工具调用、记忆系统、会话摘要
4. **智能目标预测**：结合天气、活动量动态调整
5. **完善的调试工具**：方便开发和测试

### 2.9 Flutter 客户端待完善事项

- [ ] 后端同步不完整：部分 API 已定义但 Flutter 端未完全调用
- [ ] 社区功能 Mock 化：心连心功能为本地模拟，无真实社交
- [ ] 无 Provider 包：手动监听 ChangeNotifier 代码重复
- [ ] 测试覆盖不足：只有默认的 widget_test.dart
- [ ] 国际化支持：当前仅支持中文

---

## 三、架构对比

### 3.1 数据流对比

| 维度 | 后端 | Flutter 客户端 |
|------|------|----------------|
| 数据存储 | PostgreSQL + Redis | SharedPreferences + Hive |
| 状态管理 | 无状态 REST API | ChangeNotifier（原生） |
| 缓存策略 | Redis 缓存 + JWT 黑名单 | 本地持久化，无需缓存 |
| 数据同步 | 单向：客户端 → 服务端 | 双向：本地 ↔ 云端 |
| 离线支持 | 不支持（需在线） | 完全支持（本地优先） |

### 3.2 AI 集成对比

| 维度 | 后端 | Flutter 客户端 |
|------|------|----------------|
| API Key 存储 | 服务端环境变量 | 客户端 SharedPreferences |
| AI 调用模式 | SSE 代理转发 | 直连 或 代理 |
| 工具调用 | 不处理，透传 | Function Calling 本地执行 |
| 记忆系统 | 数据库存储 MemoryFact | Hive 存储 MemoryFact |
| 会话摘要 | 数据库存储 SessionSummary | Hive 存储 SessionSummary |

### 3.3 认证机制对比

| 维度 | 后端 | Flutter 客户端 |
|------|------|----------------|
| 登录方式 | 设备匿名 + 邮箱绑定 | 设备匿名登录 |
| Token 管理 | JWT（access + refresh） | 本地存储，自动刷新 |
| 权限验证 | JWT 中间件 | 拦截器自动附加 Authorization 头 |
| 登出处理 | Redis 黑名单 | 清除本地 Token |

---

## 四、核心业务流程

### 4.1 用户首次启动流程

```
用户打开应用
      ↓
检查 SharedPreferences 中是否有 userProfile
      ↓ 无
显示引导页（OnboardingScreen）
      ↓
设置每日目标、起床/就寝时间、提醒风格
      ↓
保存到 UserProvider + SharedPreferences
      ↓
BackendApiService.deviceLogin() → 创建匿名用户
      ↓
保存 accessToken、refreshToken、deviceId
      ↓
跳转到首页（HomeScreen）
```

### 4.2 饮水打卡流程

```
用户点击"喝水"按钮
      ↓
显示 BottomSheet 选择杯子预设
      ↓
选择预设（如 250ml 杯子）
      ↓
UserProvider.addDrink(250ml)
      ↓
更新 _todayMl、_logs
      ↓
notifyListeners() → UI 刷新
      ↓
保存到 SharedPreferences（today_ml, today_logs）
      ↓
如果已登录后端：
      ↓
BackendApiService.createDrinkLog(250ml)
      ↓
POST /api/drink-logs
      ↓
返回保存的记录（含 id）
```

### 4.3 AI 对话流程

```
用户发送消息："今天天气怎么样？"
      ↓
ChatProvider.sendMessage("今天天气怎么样？")
      ↓
构建 System Prompt（用户信息 + 天气 + 记忆）
      ↓
AiService.sendMessageStream(messages)
      ↓
检查 AiConfig：
  - useBackendProxy=true → POST /api/ai/chat（代理）
  - useBackendProxy=false → 直连 DeepSeek API
      ↓
SSE 流式返回
      ↓
收到 AiTextDelta → 追加到当前消息 content
      ↓
收到 AiToolCallDelta → 解析工具调用
      ↓
FunctionRegistry.execute("get_weather", args)
      ↓
执行本地代码获取天气
      ↓
生成 ToolCall 结果消息
      ↓
继续请求 AI（多轮调用）
      ↓
收到 AiDone → 保存消息到 Hive
```

### 4.4 智能计划生成流程

```
用户进入智能计划页面
      ↓
检查 GPS 权限
      ↓
获取当前位置（latitude, longitude）
      ↓
调用 Open-Meteo API 获取天气
      ↓
显示天气卡片（温度、湿度、UV）
      ↓
用户点击"生成计划"按钮
      ↓
构建 Prompt："根据天气 XXX、体重 XXX、活动量 XXX，生成饮水计划"
      ↓
调用 AI API（SSE 流式）
      ↓
解析 AI 返回的 JSON 计划
      ↓
渲染时间槽 UI（每个槽位显示时间、建议饮水量、建议饮品）
      ↓
用户点击某个槽位
      ↓
记录饮水（调用 UserProvider.addDrink）
      ↓
调度该时间点的通知
```

---

## 五、技术债务与改进建议

### 5.1 后端技术债务

| 问题 | 影响 | 建议 |
|------|------|------|
| 无测试覆盖 | 重构风险高 | 补充单元测试（Vitest）和集成测试（Supertest） |
| 缺少 CI/CD | 部署依赖人工 | 配置 GitHub Actions（lint → test → build → deploy） |
| 无 API 文档 | 前后端协作成本高 | 集成 Swagger/OpenAPI |
| 错误码不规范 | 前端错误处理困难 | 定义统一错误码枚举 |
| 日志未持久化 | 生产问题排查困难 | 集成日志收集（如 Logtail、Datadog） |

### 5.2 Flutter 客户端技术债务

| 问题 | 影响 | 建议 |
|------|------|------|
| 手动 ChangeNotifier 监听 | 代码重复、易出错 | 迁移到 Riverpod 或 Provider |
| 测试覆盖不足 | 重构风险高 | 补充单元测试和 Widget 测试 |
| 社区功能 Mock | 无法真实使用 | 对接后端心连心 API |
| 后端同步不完整 | 数据可能不一致 | 完善同步逻辑（增量同步、冲突解决） |
| 国际化缺失 | 无法拓展海外市场 | 集成 flutter_localizations |

### 5.3 架构改进建议

#### 5.3.1 后端改进

1. **API 文档自动化**
   ```typescript
   // 集成 swagger-jsdoc
   import swaggerJsdoc from 'swagger-jsdoc';

   const options = {
     definition: {
       openapi: '3.0.0',
       info: { title: 'KeLeME API', version: '1.0.0' },
     },
     apis: ['./src/routes/*.ts'],
   };

   const specs = swaggerJsdoc(options);
   app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
   ```

2. **统一错误码**
   ```typescript
   // src/utils/errors.ts
   export enum ErrorCode {
     INVALID_INPUT = 'INVALID_INPUT',
     UNAUTHORIZED = 'UNAUTHORIZED',
     NOT_FOUND = 'NOT_FOUND',
     RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
     AI_API_ERROR = 'AI_API_ERROR',
   }

   export class AppError extends Error {
     constructor(
       public code: ErrorCode,
       public statusCode: number,
       message: string
     ) {
       super(message);
     }
   }
   ```

3. **CI/CD 配置**
   ```yaml
   # .github/workflows/ci.yml
   name: CI
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       services:
         postgres:
           image: postgres:16-alpine
           env:
             POSTGRES_DB: keleme_test
             POSTGRES_PASSWORD: test
           ports:
             - 5432:5432
         redis:
           image: redis:7-alpine
           ports:
             - 6379:6379
       steps:
         - uses: actions/checkout@v3
         - uses: actions/setup-node@v3
         - run: npm ci
         - run: npx prisma migrate deploy
         - run: npm test
         - run: npm run lint
   ```

#### 5.3.2 Flutter 客户端改进

1. **迁移到 Riverpod**
   ```dart
   // 之前
   class UserProvider extends ChangeNotifier {
     int _todayMl = 0;
     void addDrink(int ml) {
       _todayMl += ml;
       notifyListeners();
     }
   }

   // 之后
   final todayMlProvider = StateProvider<int>((ref) => 0);

   final userProvider = StateNotifierProvider<UserNotifier, UserProfile>((ref) {
     return UserNotifier();
   });

   class UserNotifier extends StateNotifier<UserProfile> {
     UserNotifier() : super(UserProfile());

     void addDrink(int ml) {
       state = state.copyWith(todayMl: state.todayMl + ml);
     }
   }
   ```

2. **后端同步优化**
   ```dart
   class SyncService {
     Future<void> syncDrinkLogs() async {
       final unsyncedLogs = await hive.getUnsyncedDrinkLogs();

       if (unsyncedLogs.isEmpty) return;

       final response = await backendApi.bulkSyncDrinkLogs(unsyncedLogs);

       // 标记为已同步
       for (var log in unsyncedLogs) {
         log.syncedAt = DateTime.now();
         await hive.saveDrinkLog(log);
       }
     }
   }
   ```

3. **测试补充**
   ```dart
   // test/core/utils/goal_predictor_test.dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:ke_le_me/core/utils/goal_predictor.dart';

   void main() {
     group('GoalPredictor', () {
       test('基础目标 = 体重 × 35ml', () {
         final prediction = GoalPredictor.predict(
           weightKg: 60,
           activityLevel: '较少',
           weather: null,
         );
         expect(prediction.baseMl, 2100);
       });

       test('高温天气增加目标 25%', () {
         final prediction = GoalPredictor.predict(
           weightKg: 60,
           activityLevel: '较少',
           weather: WeatherData(temperature: 40),
         );
         expect(prediction.finalMl, greaterThan(2100 * 1.2));
       });
     });
   }
   ```

---

## 六、部署与运维

### 6.1 后端部署

**开发环境：**
```bash
cd backend
docker-compose up -d          # 启动 PostgreSQL + Redis
npx prisma migrate dev        # 运行数据库迁移
npm run dev                   # 启动开发服务器（tsx watch）
```

**生产环境：**
```bash
cd backend
docker build -t keleme-backend .
docker run -d \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DATABASE_URL=postgresql://... \
  -e REDIS_URL=redis://... \
  -e JWT_SECRET=... \
  -e DEEPSEEK_API_KEY=... \
  keleme-backend
```

**健康检查：**
```bash
curl http://localhost:3000/health
# 响应：{ "status": "ok", "timestamp": "2026-03-25T..." }
```

### 6.2 Flutter 客户端部署

**开发调试：**
```bash
cd ke_le_me
flutter pub get
flutter run -d macos          # 或 -d chrome / -d <device_id>
```

**生产构建：**
```bash
# Android APK
flutter build apk --release

# iOS（需要 Xcode）
flutter build ios --release

# macOS（需要 Xcode）
flutter build macos --release

# Web
flutter build web --release
```

**发布检查清单：**
- [ ] 更新 `pubspec.yaml` 中的版本号
- [ ] 运行 `flutter analyze` 确保无警告
- [ ] 运行 `flutter test` 确保测试通过
- [ ] 检查权限配置（AndroidManifest.xml、Info.plist、*.entitlements）
- [ ] 检查 API Key 配置（内置 Key 或后端代理地址）
- [ ] 测试通知功能（各平台）
- [ ] 测试后端同步功能

---

## 七、关键文件路径速查

### 7.1 后端关键文件

| 用途 | 路径 |
|------|------|
| 入口文件 | `backend/src/index.ts` |
| Express 配置 | `backend/src/app.ts` |
| 数据库模型 | `backend/prisma/schema.prisma` |
| 环境变量 | `backend/src/config/env.ts` |
| 认证服务 | `backend/src/services/auth.service.ts` |
| AI 代理路由 | `backend/src/routes/ai.routes.ts` |
| 用户档案路由 | `backend/src/routes/profile.routes.ts` |
| 饮水记录路由 | `backend/src/routes/drink-logs.routes.ts` |
| 项目规范 | `backend/.cursorrules` |
| Docker 配置 | `backend/docker-compose.yml` |

### 7.2 Flutter 客户端关键文件

| 用途 | 路径 |
|------|------|
| 应用入口 | `ke_le_me/lib/main.dart` |
| 全局状态 | `ke_le_me/lib/core/providers/user_provider.dart` |
| 后端 API 客户端 | `ke_le_me/lib/core/services/backend_api_service.dart` |
| AI 服务 | `ke_le_me/lib/features/chat/services/ai_service.dart` |
| AI 配置 | `ke_le_me/lib/features/chat/services/ai_config.dart` |
| System Prompt 构建 | `ke_le_me/lib/features/chat/providers/system_prompt_builder.dart` |
| 通知服务 | `ke_le_me/lib/core/services/notification_service.dart` |
| 主题配置 | `ke_le_me/lib/core/theme/app_theme.dart` |
| 首页 | `ke_le_me/lib/features/home/screens/home_screen.dart` |
| AI 助手页 | `ke_le_me/lib/features/chat/screens/chat_screen.dart` |
| 智能计划页 | `ke_le_me/lib/features/plan/screens/plan_screen.dart` |
| 目标预测算法 | `ke_le_me/lib/core/utils/goal_predictor.dart` |
| 项目说明 | `CLAUDE.md` |

---

## 八、总结

### 8.1 项目优势

1. **架构清晰**：前后端分层明确，职责分离
2. **本地优先**：离线可用，数据隐私友好
3. **AI 深度集成**：工具调用、记忆系统、会话摘要
4. **智能目标预测**：结合天气、活动量动态调整
5. **零摩擦认证**：设备匿名登录，用户体验友好
6. **API Key 安全**：服务端代理，客户端不暴露 Key
7. **完善的调试工具**：方便开发和测试

### 8.2 主要挑战

1. **测试覆盖不足**：前后端均缺少完善的测试
2. **社区功能未实现**：心连心功能为本地 Mock
3. **后端同步不完整**：部分 API 未完全集成
4. **无 CI/CD**：部署依赖人工
5. **国际化缺失**：仅支持中文
6. **状态管理原始**：手动 ChangeNotifier 监听

### 8.3 下一步计划建议

#### 短期（1-2 周）
- [ ] 补充后端单元测试和集成测试
- [ ] 完善后端同步逻辑（增量同步、冲突解决）
- [ ] 集成 Swagger/OpenAPI 文档
- [ ] 配置 GitHub Actions CI/CD

#### 中期（1-2 月）
- [ ] 迁移到 Riverpod 状态管理
- [ ] 实现真实的心连心社交功能
- [ ] 补充 Flutter 测试覆盖
- [ ] 国际化支持（英文）

#### 长期（3-6 月）
- [ ] 排行榜和推送通知
- [ ] 数据分析和可视化增强
- [ ] 性能优化（懒加载、缓存策略）
- [ ] 多主题支持

---

**文档版本**：1.0.0
**最后更新**：2026-03-25
**维护者**：KeLeMe Team
