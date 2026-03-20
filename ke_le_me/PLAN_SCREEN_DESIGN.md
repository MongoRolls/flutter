# 【安排】页面架构设计方案（v2.5）

> 创建时间：2026-03-20（v2.5）
> 状态：待实现

---

## 一、问题诊断（v1 缺陷）

| 问题域        | v1 缺陷                                                             |
| ------------- | ------------------------------------------------------------------- |
| 导航架构      | 只说"加 MainShell"，没有说 PlanProvider 怎么创建、生命周期怎么管理  |
| Provider 模式 | 项目不用 Provider 包，靠构造器注入——v1 没解释 PlanProvider 如何融入 |
| AI 流式解析   | v1 直接说"AI 返回 JSON"，未说明如何从 SSE 流中解析非完整 JSON       |
| 时间槽交互    | v1 结果是纯展示，用户没有任何操作（无法标记已喝、无法触发提醒）     |
| 集成动作      | 无"采纳为每日目标"、无"同步到通知"等集成动作                        |
| Hive typeId   | v1 未指定 typeId，与已有 typeId 0/1/2 可能冲突                      |
| 错误状态      | 未设计 GPS 失败、天气失败、AI 失败、JSON 解析失败的兜底 UI          |
| 状态保留      | Tab 切换后状态丢失                                                  |

---

## 二、导航架构（IndexedStack + 构造器注入）

### 2.1 MainShell 设计

```
KeLeMeApp
└── MaterialApp
    └── home:
        ├── 加载中 → LoadingScaffold
        ├── 未 onboarding → OnboardingScreen
        └── 已 onboarding → MainShell (新增)
            ├── IndexedStack（4 个 Tab，状态全部保留）
            │   ├── [0] HomeScreen(userProvider)        ← 现有，无改动
            │   ├── [1] PlanScreen(userProvider, planProvider)  ← 新增
            │   ├── [2] ChatScreen(userProvider)         ← 现有，无改动
            │   └── [3] SettingsScreen(userProvider)     ← 现有，无改动
            └── BottomNavigationBar（4 个 Tab）
```

**为什么用 `IndexedStack` 而非 `PageView`：**

- `IndexedStack` 使每个 Tab 的 Widget 树一直存活，切 Tab 不重建，状态天然保留
- `PageView` 滑动切换，会干扰竖向滚动，且需要 `AutomaticKeepAliveClientMixin`

### 2.2 MainShell 代码骨架

```dart
// lib/main_shell.dart
class MainShell extends StatefulWidget {
  final UserProvider userProvider;
  const MainShell({super.key, required this.userProvider});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PlanProvider _planProvider;

  @override
  void initState() {
    super.initState();
    // PlanProvider 在 Shell 层创建，生命周期与 Shell 绑定
    _planProvider = PlanProvider(userProvider: widget.userProvider);
    // 进入 Shell 时静默加载今日计划（不阻塞）
    _planProvider.loadTodayPlan();
  }

  @override
  void dispose() {
    _planProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(userProvider: widget.userProvider),
          PlanScreen(userProvider: widget.userProvider, planProvider: _planProvider),
          ChatScreen(userProvider: widget.userProvider),
          SettingsScreen(userProvider: widget.userProvider),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
```

### 2.3 main.dart 改动

```dart
// 改 home: 条件判断
home: _userProvider.profile.onboardingCompleted
    ? MainShell(userProvider: _userProvider)   // ← 改这里
    : OnboardingScreen(userProvider: _userProvider),

// 路由表保留 /onboarding（debug 重置后跳转用）
// /home、/chat、/settings 路由不再需要，但保留兼容性
```

---

## 三、Hive 持久化（typeId 规划）

| typeId | 模型             | Box 名              | 状态     |
| ------ | ---------------- | ------------------- | -------- |
| 0      | `MemoryFact`     | `memory_facts`      | 已有     |
| 1      | `SessionSummary` | `session_summaries` | 已有     |
| 2      | `CustomReminder` | `custom_reminders`  | 已有     |
| 3      | `TodayPlan`      | `today_plans`       | **新增** |

> `PlanTimeSlot` 作为嵌套数据，**不单独注册 Hive adapter**，序列化为 JSON 字符串存在 `TodayPlan.slotsJson` 字段中。这样只需一个 adapter，避免引入 typeId 4。

### 3.1 TodayPlan 模型

```dart
// lib/features/plan/models/today_plan.dart
import 'dart:convert';
import 'package:hive/hive.dart';

part 'today_plan.g.dart';

@HiveType(typeId: 3)
class TodayPlan extends HiveObject {
  @HiveField(0)
  final String date;          // 'yyyy-MM-dd'

  @HiveField(1)
  final String summary;       // AI 文字总结

  @HiveField(2)
  final int totalMl;          // AI 建议总量

  @HiveField(3)
  final String slotsJson;     // JSON array of PlanTimeSlot

  @HiveField(4)
  final String activityType;  // 生成时的活动类型

  @HiveField(5)
  final double? temperature;  // 生成时的温度（℃）

  @HiveField(6)
  final String? cityName;     // 生成时的城市

  @HiveField(7)
  final String createdAt;     // ISO 8601 时间戳

  @HiveField(8)
  final String completedSlotsJson; // 已完成的 slot 时间列表 ['07:30','09:00',...]

  TodayPlan({
    required this.date,
    required this.summary,
    required this.totalMl,
    required this.slotsJson,
    required this.activityType,
    this.temperature,
    this.cityName,
    required this.createdAt,
    this.completedSlotsJson = '[]',
  });

  List<PlanTimeSlot> get slots =>
      (jsonDecode(slotsJson) as List)
          .map((e) => PlanTimeSlot.fromMap(e))
          .toList();

  List<String> get completedSlots =>
      List<String>.from(jsonDecode(completedSlotsJson));

  TodayPlan copyWithCompleted(List<String> newCompleted) => TodayPlan(
    date: date, summary: summary, totalMl: totalMl, slotsJson: slotsJson,
    activityType: activityType, temperature: temperature, cityName: cityName,
    createdAt: createdAt,
    completedSlotsJson: jsonEncode(newCompleted),
  );
}

/// 不是 Hive 类，只是 Dart 数据类
class PlanTimeSlot {
  final String time;   // 'HH:mm'
  final int ml;
  final String note;

  const PlanTimeSlot({required this.time, required this.ml, required this.note});

  factory PlanTimeSlot.fromMap(Map<String, dynamic> m) =>
      PlanTimeSlot(time: m['time'], ml: m['ml'], note: m['note']);

  Map<String, dynamic> toMap() => {'time': time, 'ml': ml, 'note': note};
}
```

### 3.2 main.dart Hive 注册

```dart
Hive.registerAdapter(TodayPlanAdapter());   // 新增
await Hive.openBox<TodayPlan>('today_plans'); // 新增
```

---

## 四、PlanProvider 状态机

```
┌──────────────────────────────────────────────────────────┐
│                     PlanProvider 状态                     │
├─────────────────┬────────────────────────────────────────┤
│ 状态名           │ 含义                                   │
├─────────────────┼────────────────────────────────────────┤
│ idle            │ 初始，未加载                            │
│ loadingPlan     │ 正在从 Hive 读取今日计划               │
│ hasPlan         │ 今日计划已存在（显示结果）              │
│ inputReady      │ 无计划，天气加载完，等用户点生成        │
│ loadingWeather  │ 正在定位/拉取天气                      │
│ generating      │ AI 正在生成（SSE 流式输出）             │
│ parseError      │ AI 返回内容无法解析为 JSON              │
│ weatherError    │ 天气/定位失败，等用户手动输入城市名     │
└─────────────────┴────────────────────────────────────────┘
```

```dart
// lib/features/plan/providers/plan_provider.dart
enum PlanStatus {
  idle, loadingPlan, hasPlan, inputReady,
  loadingWeather, generating, parseError, weatherError
}

class PlanProvider extends ChangeNotifier {
  final UserProvider _userProvider;
  PlanStatus status = PlanStatus.idle;

  // ── 输入 ──
  String activityType = '久坐';  // 久坐/步行/中等运动/高强度运动
  String note = '';
  String wakeTimeOverride = ''; // 空表示使用 profile.wakeTime

  // ── 天气 ──
  WeatherData? weather;
  String? cityName;
  String cityInput = '';        // 手动城市输入框的值

  // ── 生成流式 ──
  String streamingText = '';    // SSE 流中间状态，用于 UI 打字效果

  // ── 结果 ──
  TodayPlan? todayPlan;
  String? errorMessage;

  // ── 面板状态 ──
  bool isInputExpanded = true;  // 有计划时，输入区默认折叠

  PlanProvider({required UserProvider userProvider})
      : _userProvider = userProvider;

  // 方法签名（详见 §五）
  Future<void> loadTodayPlan();
  Future<void> loadWeatherByGps();
  Future<void> loadWeatherByCity(String city);
  Future<void> generatePlan();
  Future<void> toggleSlotCompleted(String slotTime);
  Future<void> adoptAsGoal();
  Future<void> scheduleSlotReminders();
  void retryWeather();
  void reset();  // 清空当日计划，重新生成
}
```

---

## 五、核心方法逻辑

### 5.1 loadTodayPlan()

```dart
Future<void> loadTodayPlan() async {
  status = PlanStatus.loadingPlan;
  notifyListeners();

  final box = Hive.box<TodayPlan>('today_plans');
  final today = _todayKey();  // 'yyyy-MM-dd'
  final plan = box.get(today);

  if (plan != null) {
    todayPlan = plan;
    isInputExpanded = false;   // 有计划时折叠输入区
    status = PlanStatus.hasPlan;
    notifyListeners();
    return;
  }

  // 无计划 → 拉取天气
  await loadWeatherByGps();
}
```

### 5.2 天气加载（GPS 优先，失败降级）

```dart
Future<void> loadWeatherByGps() async {
  status = PlanStatus.loadingWeather;
  notifyListeners();
  try {
    final loc = await LocationService.instance.getCurrentLocation();
    cityName = loc.isDefault ? '北京' : null;
    weather = await WeatherService.instance.getWeather(loc.lat, loc.lon);
    status = PlanStatus.inputReady;
  } catch (e) {
    status = PlanStatus.weatherError;
    errorMessage = '定位失败，请手动输入城市名';
  }
  notifyListeners();
}

Future<void> loadWeatherByCity(String city) async {
  status = PlanStatus.loadingWeather;
  cityInput = city;
  notifyListeners();
  try {
    // Geocoding → 坐标 → 天气
    final coords = await _geocodeCity(city);  // 调用 Open-Meteo geocoding
    weather = await WeatherService.instance.getWeather(coords.lat, coords.lon);
    cityName = city;
    status = PlanStatus.inputReady;
  } catch (e) {
    status = PlanStatus.weatherError;
    errorMessage = '找不到城市"$city"，请重新输入';
  }
  notifyListeners();
}
```

### 5.3 AI 生成（流式 SSE + JSON 解析）

```dart
Future<void> generatePlan() async {
  status = PlanStatus.generating;
  streamingText = '';
  errorMessage = null;
  notifyListeners();

  try {
    final config = await AiConfig.load();
    final service = AiService(config);
    final prompt = PlanPromptBuilder.build(
      profile: _userProvider.profile,
      weather: weather,
      cityName: cityName,
      activityType: activityType,
      note: note,
      wakeTime: wakeTimeOverride.isEmpty
          ? _userProvider.profile.wakeTime : wakeTimeOverride,
    );

    final messages = [
      {'role': 'system', 'content': PlanPromptBuilder.systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    // 流式累积
    await for (final event in service.streamRaw(messages)) {
      if (event is AiTextDelta) {
        streamingText += event.delta;
        notifyListeners();  // 触发打字效果
      }
    }

    // 流结束后解析 JSON
    final plan = _parseJson(streamingText);
    if (plan == null) {
      status = PlanStatus.parseError;
      errorMessage = 'AI 返回格式异常，请重试';
      notifyListeners();
      return;
    }

    // 持久化到 Hive
    final today = _todayKey();
    final todayPlanObj = TodayPlan(
      date: today,
      summary: plan.summary,
      totalMl: plan.totalMl,
      slotsJson: jsonEncode(plan.slots.map((s) => s.toMap()).toList()),
      activityType: activityType,
      temperature: weather?.temperature,
      cityName: cityName,
      createdAt: DateTime.now().toIso8601String(),
    );
    await Hive.box<TodayPlan>('today_plans').put(today, todayPlanObj);

    todayPlan = todayPlanObj;
    isInputExpanded = false;
    status = PlanStatus.hasPlan;
    notifyListeners();
  } catch (e) {
    status = PlanStatus.parseError;
    errorMessage = '生成失败：$e';
    notifyListeners();
  }
}

// JSON 解析容错：提取 {...} 块（防止 AI 在 JSON 前后输出闲话）
TodayPlanParsed? _parseJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start == -1 || end == -1) return null;
  try {
    final obj = jsonDecode(raw.substring(start, end + 1));
    return TodayPlanParsed.fromMap(obj);
  } catch (_) {
    return null;
  }
}
```

### 5.4 时间槽记录饮水

```dart
// 点击 Bottom Sheet 确认后调用
Future<void> logSlotDrink(PlanTimeSlot slot) async {
  if (todayPlan == null) return;

  // 1. 记录到 UserProvider（驱动首页进度更新）
  await _userProvider.addDrink(slot.ml, type: '💧', desc: slot.note);

  // 2. 标记此 slot 为已记录
  final completed = List<String>.from(todayPlan!.completedSlots);
  if (!completed.contains(slot.time)) {
    completed.add(slot.time);
    final updated = todayPlan!.copyWithCompleted(completed);
    await Hive.box<TodayPlan>('today_plans').put(updated.date, updated);
    todayPlan = updated;
    notifyListeners();
  }
}

// 取消标记（不回撤 addDrink，只清除完成标记）
Future<void> unlogSlot(String slotTime) async {
  if (todayPlan == null) return;
  final completed = List<String>.from(todayPlan!.completedSlots)
    ..remove(slotTime);
  final updated = todayPlan!.copyWithCompleted(completed);
  await Hive.box<TodayPlan>('today_plans').put(updated.date, updated);
  todayPlan = updated;
  notifyListeners();
}
```

### 5.5 集成动作

```dart
// 采纳为每日目标（更新 UserProvider）
Future<void> adoptAsGoal() async {
  if (todayPlan == null) return;
  _userProvider.profile.dailyGoalMl = todayPlan!.totalMl;
  await _userProvider.saveProfile();
}

// 同步今日计划提醒（覆盖式）
Future<void> scheduleSlotReminders() async {
  if (todayPlan == null) return;

  // 1. 取消 ID 范围 1000-1999 的计划提醒
  await NotificationService.instance.cancelPlanReminders();

  // 2. 只为未来时间点安排通知
  final now = DateTime.now();
  int scheduled = 0;
  for (int i = 0; i < todayPlan!.slots.length; i++) {
    final slot = todayPlan!.slots[i];
    final parts = slot.time.split(':');
    final dt = DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
    if (dt.isAfter(now)) {
      await NotificationService.instance.scheduleCustomReminder(
        title: '💧 计划喝水',
        body: '${slot.note}（${slot.ml}ml）',
        datetime: dt,
        repeat: RepeatMode.none,
        notificationId: 1000 + i,   // 固定 ID 段，方便整体取消
      );
      scheduled++;
    }
  }
  // 返回已安排数量，由 UI 层显示 Snackbar
  return scheduled;
}
```

---

## 六、AI Prompt 设计

### 6.1 System Prompt（纯 JSON 模式）

```
你是一个专业饮水健康顾问。用户会提供个人信息和当天情况，你必须返回一个**纯 JSON 对象**，
不得包含任何其他文字、markdown 代码块标记或解释。

返回格式：
{
  "summary": "string（50-100字，中文，说明今日建议和关键理由）",
  "totalMl": number（整百，范围 1500-5000）,
  "slots": [
    { "time": "HH:mm", "ml": number（50的倍数）, "note": "string（10-20字）" }
  ]
}

要求：
- slots 按时间升序排列
- slots 数量 8-12 个
- 所有 slot ml 之和必须等于 totalMl
- 时间范围：起床时间 到 睡前 30 分钟
- note 简洁有针对性（结合活动和天气，不要泛泛而谈）
```

### 6.2 User Prompt 构建

```dart
// lib/features/plan/utils/plan_prompt_builder.dart
static String build({...}) => '''
用户信息：
- 性别：${profile.gender == 'male' ? '男' : '女'}
- 体重：${profile.weight}kg
- 基础活动量：${profile.activityLevel}

今日情况：
- 今日主要活动：$activityType
- 起床时间：$wakeTime，睡觉时间：${profile.bedTime}
- 当前天气：${weather != null
    ? '${cityName ?? ''}  气温 ${weather.temperature.round()}℃（体感 ${weather.apparentTemp.round()}℃）'
      '，湿度 ${weather.humidity.round()}%，UV指数 ${weather.uvIndexMax?.round() ?? '未知'}'
    : '天气数据不可用'}
- 今日备注：${note.isEmpty ? '无' : note}

当前时间：${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2,'0')}
今日已喝水：${userProvider.todayMl}ml

请生成今日个性化饮水计划。
''';
```

---

## 七、页面 UI 设计

### 7.1 PlanScreen 结构

```
PlanScreen（SingleChildScrollView）
│
├── [AppBar 区] — 标题"今日安排" + 日期副标题
│
├── [基础目标卡] BasicGoalCard
│   ├── 大字：每日基础目标 X ml
│   ├── 因子行：体重贡献 + 活动量贡献 + 天气贡献
│   └── 底部：「前往设置修改」文字按钮
│
├── [输入区] PlanInputSection（AnimatedCrossFade 折叠/展开）
│   ├── 标题行：「今日计划参数」+ 折叠按钮
│   ├── 活动类型：SegmentedButton（4 选 1）
│   ├── 天气卡：WeatherStatusWidget
│   │   ├── 加载中：旋转图标 + "正在定位..."
│   │   ├── 成功：天气 emoji + 温度 + 湿度 + 城市名 + 刷新按钮
│   │   └── 失败：城市名输入框 + 搜索按钮
│   ├── 起床时间：Row（图标 + 时间文字 + 编辑图标，点击弹 TimePicker）
│   └── 今日备注：TextField（最多 100 字）
│
├── [生成按钮区]
│   ├── 状态=inputReady：蓝色「AI 生成今日计划」按钮
│   ├── 状态=generating：灰色按钮（禁用）+ 旋转进度圈
│   └── 状态=parseError：红色提示 + 「重试」按钮
│
└── [结果区] AiPlanResultSection（状态=hasPlan 时显示）
    ├── [流式动画区] StreamingTextCard（generating 时显示）
    │   └── 打字机效果展示 streamingText
    │
    ├── [摘要卡] SummaryCard
    │   ├── 图标 🤖 + "AI 建议"标签
    │   ├── summary 文字
    │   └── 右上角：重新生成按钮（小图标，点击展开输入区）
    │
    ├── [时间轴] SlotTimeline
    │   └── 每个 SlotItem：
    │       ├── 左：时间线（竖线 + 圆点，完成变绿）
    │       ├── 中：时间 chip（HH:mm）+ ml badge + note 文字
    │       └── 右：完成勾选圆圈（点击切换完成状态）
    │
    └── [操作栏] ActionRow（固定在底部 or 列表末尾）
        ├── 「设为今日目标 (X ml)」—— 调用 adoptAsGoal()
        └── 「同步到提醒」—— 调用 scheduleSlotReminders()
```

### 7.2 基础目标卡细节

```
┌─────────────────────────────────────┐
│  💧 基础饮水目标                     │
│                                     │
│         2100 ml                     │  ← 大字，Space Mono
│                                     │
│  [体重 75kg → 2625] [久坐 →-525]    │  ← 因子 Chip
│  [天气 35°C →+400]                  │
│                                     │
│  前往设置修改 →                      │
└─────────────────────────────────────┘
```

因子计算来自 `GoalPredictor.predict()`，从 `UserProvider.goalPrediction` 读取即可，**不重复计算**。

### 7.3 时间槽的定位与交互（重新设计）

**时间轴是什么：** AI 把全天饮水量拆分成 8-12 个具体的"喝水任务"，用户在对应时间点按计划执行，点击即可一键记录到首页今日进度。时间轴是计划和实际执行之间的桥梁。

**核心：点击时间槽 = 把这次饮水记录到首页进度**

时间槽 4 种视觉状态：

```
状态           视觉
───────────────────────────────────────────────
未到时间        正常，蓝色时间 chip，圆点灰色
即将到来        蓝色 chip 脉冲闪烁（距现在 ≤30min）
已过 + 未记录   整行透明度 40%，chip 变灰
已记录          绿色 ✓ 圆点，显示实际记录时间
```

**点击交互流程：**

```
用户点击某个时间槽
        ↓
弹出 Bottom Sheet
  ┌──────────────────────────────────────────┐
  │  💧 记录 09:00 的饮水                     │
  │                                          │
  │  上午工作间隙补水                         │
  │                                          │
  │       [ 记录 250ml ]   ← 蓝色主按钮       │
  │       [ 取消 ]                            │
  └──────────────────────────────────────────┘
        ↓ 点击「记录 250ml」
UserProvider.addDrink(slot.ml, type: '💧', desc: slot.note)
        ↓
TodayPlan.completedSlots 追加该 slot 时间（Hive 持久化）
        ↓
首页进度环实时更新（UserProvider.notifyListeners）
```

**已记录的槽样式：**

```
  ✓  09:00  ──────────────  250ml
            上午工作间隙补水      实际记录：09:12
```

- 点击已记录的槽：提示"已于 09:12 记录，是否取消标记？"
- 取消标记只移除 completedSlots 记录，不回撤 UserProvider 的饮水数据（饮水日志由首页管理）

### 7.4 "同步到提醒"交互流程（重新设计）

**按钮位置：** 摘要卡下方、时间轴上方的操作行

**按钮文案（动态）：**
- 有未来槽：`同步今日计划提醒 (8 个)` — 括号是未来时间槽数
- 全部已过：`今日计划已结束` — 灰色禁用状态

**完整交互：**

```
点击「同步今日计划提醒 (8 个)」
        ↓
AlertDialog 确认：
  标题：「设置今日饮水提醒」
  内容：「将为 09:00 / 10:30 / 12:00 ... 等 8 个时间点
        设置提醒，今日已有的计划提醒会被替换。」
  [取消]  [确认]
        ↓ 确认
1. 取消通知 ID 1000-1999 范围（计划提醒专用 ID 段）
2. 为每个未来时间槽调用：
   NotificationService.scheduleCustomReminder(
     title: '💧 计划喝水',
     body: '${slot.note}（${slot.ml}ml）',
     datetime: todayAt(slot.time),
     repeat: RepeatMode.none,
     notificationId: 1000 + slotIndex,
   )
3. Snackbar：'✓ 已设置 8 个提醒'
```

**技术说明：** 计划提醒 ID 固定使用 1000-1999 段，避免与常规水提醒（ID 0-999）冲突。`NotificationService.cancelPlanReminders()` 只取消此范围。

### 7.5 操作区布局

```
SummaryCard（摘要 + 右上角重新生成按钮）
        ↓
操作行（两个按钮并排）：
  [设为今日目标 (3200ml)]    [同步今日计划提醒 (8 个)]
  次要，灰色边框              主要，蓝色填充

SlotTimeline（时间轴列表）
  每个 SlotItem 点击 → 记录饮水 Bottom Sheet
```

### 7.6 状态转换动画

| 场景 | 动画 |
|------|------|
| 生成中 → 结果 | `AnimatedSwitcher` 淡入淡出 |
| 输入区折叠/展开 | `AnimatedCrossFade`（300ms） |
| Slot 记录完成 | 圆点灰→绿 `AnimatedContainer`（200ms） |
| 即将到来 slot | 时间 chip 脉冲 `AnimationController` |
| 打字机效果 | 流式 `notifyListeners` 驱动 |

---

## 八、文件清单

### 8.1 新建文件

| 路径                                                    | 作用                          | 预计行数 |
| ------------------------------------------------------- | ----------------------------- | -------- |
| `lib/main_shell.dart`                                   | IndexedStack + BottomNav 容器 | ~80      |
| `lib/features/plan/screens/plan_screen.dart`            | 主页面，组合各 Widget         | ~200     |
| `lib/features/plan/providers/plan_provider.dart`        | 状态机 + 所有业务逻辑         | ~250     |
| `lib/features/plan/models/today_plan.dart`              | Hive 模型 + PlanTimeSlot      | ~80      |
| `lib/features/plan/models/today_plan.g.dart`            | 自动生成的 Hive adapter       | 自动     |
| `lib/features/plan/utils/plan_prompt_builder.dart`      | System + User Prompt 构建     | ~60      |
| `lib/features/plan/widgets/basic_goal_card.dart`        | 基础目标展示 + 因子拆解       | ~80      |
| `lib/features/plan/widgets/plan_input_section.dart`     | 活动/天气/时间/备注输入       | ~180     |
| `lib/features/plan/widgets/weather_status_widget.dart`  | 天气加载/成功/失败三态        | ~120     |
| `lib/features/plan/widgets/ai_plan_result_section.dart` | 摘要 + 时间轴组合             | ~80      |
| `lib/features/plan/widgets/streaming_text_card.dart`    | 打字机效果展示                | ~50      |
| `lib/features/plan/widgets/slot_timeline.dart`          | 时间轴列表                    | ~120     |
| `lib/features/plan/widgets/slot_item.dart`              | 单个时间槽 Widget + 记录底部弹窗 | ~100 |
| `lib/features/plan/widgets/action_row.dart`             | 采纳目标 + 同步提醒按钮行   | ~60      |
| `lib/core/utils/app_version.dart`                       | 版本号常量（统一管理）       | ~15      |

### 8.2 需修改的文件

| 文件                                         | 改动                                                                            |
| -------------------------------------------- | ------------------------------------------------------------------------------- |
| `lib/main.dart`                              | ① `home:` 改为 `MainShell`；② 注册 `TodayPlanAdapter`；③ 打开 `today_plans` box |
| `lib/features/home/screens/home_screen.dart` | 移除 Header 上的设置/聊天跳转按钮，页面底部加一行小版本号文字 |
| `lib/features/settings/screens/settings_screen.dart` | 版本号区域改为醒目展示（大字版本 + 小字构建日期）|
| `lib/core/services/notification_service.dart` | 新增 `cancelPlanReminders()` 方法（取消 ID 1000-1999）|

### 8.3 零改动复用

| 资源                   | 路径                                      | 复用点                                           |
| ---------------------- | ----------------------------------------- | ------------------------------------------------ |
| `UserProfile`          | `core/models/user_profile.dart`           | gender, weight, activityLevel, wakeTime, bedTime |
| `GoalPredictor`        | `core/utils/goal_predictor.dart`          | predict() → GoalPrediction                       |
| `WeatherService`       | `core/services/weather_service.dart`      | getWeather(lat, lon)                             |
| `LocationService`      | `core/services/location_service.dart`     | getCurrentLocation()                             |
| `WeatherData`          | `core/models/weather_data.dart`           | temperature, humidity, uvIndexMax                |
| `AiService`            | `features/chat/services/ai_service.dart`  | streamRaw(messages)                              |
| `AiConfig`             | `features/chat/services/ai_config.dart`   | load()                                           |
| `NotificationService`  | `core/services/notification_service.dart` | scheduleCustomReminder()                         |
| `GlassCard`            | `common/widgets/glass_card.dart`          | 卡片容器                                         |
| `AppColors / AppTheme` | `core/theme/app_theme.dart`               | 颜色、字体                                       |

---

## 九、AI 返回 JSON 格式约定（与 Prompt 一致）

```json
{
  "summary": "今天气温35°C较炎热，加上下午有篮球运动，建议今日饮水3200ml，注意运动前中后补水。",
  "totalMl": 3200,
  "slots": [
    { "time": "07:30", "ml": 300, "note": "起床后先喝温水，启动代谢" },
    { "time": "09:00", "ml": 250, "note": "上午工作间隙补水" },
    { "time": "10:30", "ml": 250, "note": "保持水分，避免疲劳" },
    { "time": "12:00", "ml": 300, "note": "午饭前补水助消化" },
    { "time": "14:00", "ml": 300, "note": "运动前30分钟补水" },
    { "time": "15:30", "ml": 400, "note": "运动中及运动后补水" },
    { "time": "17:00", "ml": 250, "note": "运动恢复期持续补水" },
    { "time": "19:00", "ml": 300, "note": "晚饭前补水" },
    { "time": "21:00", "ml": 200, "note": "睡前适量补水" },
    { "time": "22:30", "ml": 150, "note": "睡前1小时少量补水即可" }
  ]
}
```

**解析策略（容错）：**

1. 正常：整体是合法 JSON → `jsonDecode` 直接解析
2. AI 输出了代码块包裹：剥离 ` ```json ... ``` `
3. AI 在 JSON 前后有闲话：正则找 `{...}` 最外层块
4. 以上均失败：`status = parseError`，显示重试 UI

---

## 十、BottomNavigationBar 视觉规范

```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: AppColors.bgDeep,
  selectedItemColor: AppColors.blue,
  unselectedItemColor: Colors.white38,
  selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  unselectedLabelStyle: TextStyle(fontSize: 11),
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded),     label: '首页'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today),   label: '安排'),
    BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded),label: 'AI 助手'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '设置'),
  ],
)
```

**Badge 扩展点**：当今日有 AI 计划时，「安排」Tab 显示绿点角标（后续实现）。

---

## 十一、HomeScreen 改动说明

原 HomeScreen 头部有「⚙️设置」和「💬聊天」两个跳转按钮（pushNamed），迁移到底部 Tab 后：

- **保留**：这两个按钮可以保留（给已打开 HomeScreen 的用户切换 Tab 的快捷方式），但将 `pushNamed` 改为调用 `MainShell._switchTab(index)` 回调
- **或删除**：头部只保留 App 名 logo + debug 彩蛋，Tab 切换完全靠底部导航

推荐**删除**，保持 UI 简洁。Header 改为仅展示日期问候语。

---

## 十二、版本号功能

### 12.1 设计目标

用户在手机上能快速看到当前版本号，不需要去 AppStore 或问开发者才知道。

### 12.2 版本号来源

使用 Dart 常量，版本号与 `pubspec.yaml` 保持一致，手动同步：

```dart
// lib/core/utils/app_version.dart
class AppVersion {
  /// 与 pubspec.yaml 的 version 字段保持一致，发版前手动更新
  static const String version = '1.0.0';
  static const String buildDate = '2026-03-20';

  /// 完整展示字符串，如 "v1.0.0"
  static const String display = 'v$version';

  /// 设置页详细展示，如 "v1.0.0 · 2026-03-20"
  static const String detail = 'v$version · $buildDate';
}
```

> 不引入 `package_info_plus` 额外依赖，降低依赖复杂度，发版时只需同步修改 `pubspec.yaml` 和 `app_version.dart`。

### 12.3 展示位置

**① 设置页（主要展示位置）**

```
现有设置页底部「版本信息」区域改为：

  ┌──────────────────────────────────┐
  │  渴了么                           │
  │  v1.0.0                ← 大字体   │
  │  2026-03-20            ← 副文字   │
  │                                  │
  │  (5次点击) → Debug 页面           │
  └──────────────────────────────────┘
```

改动：`settings_screen.dart` 版本区域从单行小字升级为居中两行展示。

**② 首页底部（次要展示位置）**

首页 `SingleChildScrollView` 内容最底部加一行：

```dart
Padding(
  padding: const EdgeInsets.only(bottom: 24, top: 8),
  child: Text(
    AppVersion.display,
    style: TextStyle(
      color: Colors.white24,
      fontSize: 11,
      fontFamily: 'SpaceMono',
    ),
    textAlign: TextAlign.center,
  ),
)
```

展示效果：`v1.0.0`，字色极浅（`white24`），不抢夺视觉焦点。

### 12.4 版本号更新流程（发版 Checklist）

```
1. 修改 pubspec.yaml：version: 1.1.0+2
2. 修改 lib/core/utils/app_version.dart：
   version = '1.1.0'
   buildDate = '2026-XX-XX'
3. flutter build apk/ios
4. git tag v1.1.0
```

---

## 十三、实现顺序（推荐）

1. **Step 1** — `AppVersion` 常量 + 首页底部版本号小字 + 设置页版本区域升级
2. **Step 2** — `TodayPlan` 模型 + 运行 `build_runner` 生成 adapter
3. **Step 3** — `main.dart` 注册 adapter + 打开 box
4. **Step 4** — `NotificationService.cancelPlanReminders()` 方法
5. **Step 5** — `PlanProvider` 骨架（状态机 + loadTodayPlan + loadWeatherByGps）
6. **Step 6** — `MainShell` + `BottomNavigationBar`（PlanScreen 先空页占位）
7. **Step 7** — `BasicGoalCard` + `PlanInputSection` + `WeatherStatusWidget`
8. **Step 8** — `generatePlan()` 流式接入（打字机效果 + JSON 解析）
9. **Step 9** — `SlotTimeline` + `SlotItem`（含记录饮水 Bottom Sheet）
10. **Step 10** — `ActionRow`（adoptAsGoal + scheduleSlotReminders + 确认 Dialog）
11. **Step 11** — `HomeScreen` 头部按钮清理

---

## 十三、扩展点（后续版本）

| 功能             | 技术方向                                                |
| ---------------- | ------------------------------------------------------- |
| 每日免费次数限制 | `SharedPreferences` 记录当日生成次数，超额弹付费引导    |
| 计划完成度统计   | completedSlots.length / slots.length，在首页/安排页展示 |
| 语音输入备注     | `speech_to_text` 包，iOS/Android 系统 ASR               |
| AQI / 花粉数据   | Open-Meteo Air Quality API（免费，无 key）              |
| 历史计划浏览     | HealthArchiveScreen 新增「历史计划」Tab                 |
| 计划分享         | 截图 + Share sheet                                      |
