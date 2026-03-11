# 渴了么 (KE LE ME) - MVP 开发计划

## 项目概述

**应用名称**: 渴了么  
**英文名**: KE LE ME  
**定位**: AI 驱动的智能喝水提醒 & 健康管理工具  
**目标平台**: iOS / Android (Flutter 跨平台)  
**开发周期**: 1 周 (Vibe Coding)  

### 核心亮点（完整版愿景）
- 基于大模型，结合天气/日程/身体数据智能预测饮水量
- 健康小助手对话框（可上传体检报告、血液检测报告等）
- 社交属性：排行榜、积分兑换礼品（水杯、咖啡兑换券等）

### MVP 版本范围（本周目标）
**只做 3 个核心页面，跑通最小闭环：**
1. 新用户设置页（Onboarding）
2. 主页面（Home）
3. 提醒/通知设置页（Settings）

---

## 设计规范

### 色彩系统（深色科技风）
| Token | 色值 | 用途 |
|-------|------|------|
| `bgDeep` | `#060E1C` | 主背景 |
| `bgDark` | `#0A1628` | 次背景/卡片背景 |
| `bgCard` | `#0D1F38` | 卡片 |
| `bgCard2` | `#112440` | 内嵌卡片 |
| `blue` | `#29B6F6` | 主强调色 |
| `orange` | `#FF8F00` | 警告/次强调 |
| `green` | `#26C6A0` | 成功/完成 |
| `purple` | `#9C77E8` | 辅助色 |
| `textWhite` | `#F0F7FF` | 主文字 |
| `textLight` | `#90CAF9` | 次文字 |
| `textMuted` | `#546E7A` | 弱文字 |

### 字体
- 中文: Noto Sans SC (300/400/500/700)
- 数字/等宽: Space Mono (400/700)

### 圆角
- 卡片: 16px
- 小组件: 10px
- 按钮: 10-12px

---

## MVP 页面详细设计

### Page 1: 新用户设置页（Onboarding）

**流程**: 4 步渐进式引导，底部有进度指示器

#### Step 1 - 欢迎 & 基础信息
- Logo + App 名称 "渴了么"
- 输入昵称
- 选择性别（男/女/其他）
- 选择运动量（久坐/轻度/中度/高强度）
- 体重滑块（40-120kg，默认 65kg）
- 底部蓝色「继续」按钮

#### Step 2 - 每日目标设置
- 系统根据体重自动计算推荐值（体重 × 35ml）
- 大号圆环显示目标值
- 滑块手动微调（1500-4000ml）
- 底部「继续」按钮

#### Step 3 - 提醒计划
- 设置起床时间（默认 7:00）
- 设置就寝时间（默认 23:00）
- 提醒间隔选择（30min / 1h / 1.5h / 2h）
- 底部「完成」按钮

#### Step 4 - 通知权限
- 说明文字：为了按时提醒你喝水，需要开启通知
- 水滴图标动画
- 「开启通知」按钮（调用系统权限）
- 「稍后再说」文字按钮

### Page 2: 主页面（Home）

#### 顶部 Header
- 左: Logo 圆点 "渴" + "渴了么" 标题
- 右: 通知铃铛按钮 + 设置按钮

#### 核心区域 - 进度卡片
- 问候语 "👋 早上好，{昵称}"
- 当前日期
- 大圆环进度条（已喝/目标）
- 百分比数字
- 目标文字 "目标 XXXml · 还差 XXXml"
- 「💧 立即喝水打卡」按钮

#### 快捷统计 - 3 格卡片
- 今日打卡次数
- 连续天数（🔥）
- 待完成次数

#### 今日时间表
- AI 生成标签
- 时间轴列表，每行：时间 | 图标 | 描述 | 毫升 | 状态标签(✓完成/现在/待)

#### 本月打卡日历
- 网格展示，颜色区分已打卡/未打卡/今天/未来

#### 快速打卡弹窗（Drawer）
- 点击「立即喝水打卡」弹出底部抽屉
- 快速选择饮水量(150/200/250/350/500ml)
- 确认按钮

### Page 3: 设置/通知页面

#### 基本设置卡片
- 每日饮水目标（滑块: 1500-4000ml）
- 体重设置（滑块: 40-120kg，联动推荐目标）
- 提醒风格选择（💝温柔 / 😄活泼 / 📢严肃）

#### 提醒开关卡片
- 推送通知（开关）— 锁屏显示喝水提醒
- 运动后增强提醒（开关）— 运动结束立即推送
- 会议期间暂停（开关）— 日历有会议时暂停
- 早间规划提醒（开关）— 每天 8:00 提示输入安排

#### 提醒时间卡片
- 起床时间设定
- 就寝时间设定
- 提醒间隔设置

#### 测试提醒按钮
- 「🔔 测试喝水提醒」按钮

---

## 技术架构

### 项目结构
```
lib/
├── main.dart                  # 入口，路由配置
├── app.dart                   # MaterialApp 配置
├── theme/
│   └── app_theme.dart         # 主题色彩/字体定义
├── models/
│   └── user_profile.dart      # 用户设置数据模型
├── providers/
│   └── user_provider.dart     # 状态管理
├── screens/
│   ├── onboarding/
│   │   └── onboarding_screen.dart  # 新用户引导（含 4 步）
│   ├── home/
│   │   └── home_screen.dart        # 主页面
│   └── settings/
│       └── settings_screen.dart    # 设置页面
├── widgets/
│   ├── progress_ring.dart     # 圆环进度条
│   ├── stat_card.dart         # 统计卡片
│   ├── schedule_item.dart     # 时间表行
│   ├── streak_calendar.dart   # 打卡日历
│   ├── drink_drawer.dart      # 快速打卡抽屉
│   └── toggle_switch.dart     # 开关组件
└── utils/
    └── water_calculator.dart  # 饮水量计算工具
```

### 核心依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^latest   # 本地存储用户设置
  flutter_local_notifications: ^latest  # 本地通知
  google_fonts: ^latest         # 字体
  permission_handler: ^latest   # 权限管理
```

### 状态管理
MVP 阶段使用轻量方案：
- `ChangeNotifier` + `Provider` 管理用户状态
- `SharedPreferences` 做本地持久化

### 路由
- `/onboarding` → 新用户引导（首次启动）
- `/home` → 主页面（默认页）
- `/settings` → 设置页面

---

## 开发排期（1 周）

### Day 1 (周三) - 环境搭建 & 项目初始化
- [ ] 安装 Flutter SDK (macOS)
- [ ] `flutter create ke_le_me` 创建项目
- [ ] 配置 `pubspec.yaml` 依赖
- [ ] 建立项目目录结构
- [ ] 实现 `app_theme.dart` 主题系统
- [ ] 实现 `user_profile.dart` 数据模型

### Day 2 (周四) - 新用户设置页
- [ ] `OnboardingScreen` 框架（PageView + 步骤指示器）
- [ ] Step 1: 基础信息表单
- [ ] Step 2: 目标设置（圆环 + 滑块）
- [ ] Step 3: 提醒时间设置
- [ ] Step 4: 通知权限请求
- [ ] 本地存储保存用户设置

### Day 3 (周五) - 主页面核心 UI
- [ ] Header 组件
- [ ] 进度圆环组件 `ProgressRing`
- [ ] 快捷统计卡片
- [ ] 快速打卡抽屉弹窗
- [ ] 打卡逻辑（增加饮水量，更新进度）

### Day 4 (周六) - 主页面完善
- [ ] 今日时间表组件（时间轴列表）
- [ ] 本月打卡日历组件
- [ ] Toast 通知提示
- [ ] 页面数据联动

### Day 5 (周日) - 设置页面
- [ ] 基本设置卡片（目标/体重/风格）
- [ ] 提醒开关卡片（多个 Switch）
- [ ] 提醒时间设置
- [ ] 测试提醒按钮
- [ ] SharedPreferences 读写

### Day 6 (周一) - 通知 & 串联
- [ ] 本地通知配置（flutter_local_notifications）
- [ ] 定时提醒逻辑
- [ ] 首次启动判断（跳 Onboarding 或 Home）
- [ ] 页面间导航串联
- [ ] 数据持久化验证

### Day 7 (周二) - 测试 & 收尾
- [ ] 全流程冒烟测试
- [ ] UI 微调 & 动画润色
- [ ] 响应式适配检查
- [ ] Bug 修复
- [ ] 准备演示

---

## 后续扩展（MVP 之后）

### Phase 2 - AI Agent 集成
- 接入 Firebase AI / Gemini 大模型
- AI 智能生成每日饮水计划
- 结合天气 API 动态调整
- 健康小助手对话框

### Phase 3 - 数据统计
- 近 7 日/月/年饮水统计图表
- 饮品类型分布
- 健康评分趋势

### Phase 4 - 社交 & 激励
- 用户排行榜
- 积分系统
- 成就勋章体系
- 积分兑换礼品

### Phase 5 - 高级功能
- 饮品百科
- 体检报告上传 & AI 分析
- 手环/手表联动
- Pro 会员系统

---

## 参考资源
- 竞品 App: 喝水时间（功能简约、评价好）
- UI 原型: `渴了么-手机版.html`（手机端原型）
- UI 原型: `渴了么-产品功能演示.html`（桌面端完整演示）
- 产品需求: `渴了么-AI产品开发计划书.docx`
- Flutter AI Toolkit: https://github.com/flutter/ai
- Flutter Skills: https://github.com/flutter/skills
