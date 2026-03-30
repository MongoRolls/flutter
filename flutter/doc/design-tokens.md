# KeLeME：官网 light ↔ Flutter 设计 Token 对照

> **参考来源（只读）**：仓库内 `web/app/globals.css` 的 `:root`（light）与 `web/components/glass-card.tsx`。  
> **运行时事实来源**：`flutter/lib/core/theme/app_theme.dart` 中的 `AppColors`、`AppRadius`、`AppShadows`、`AppTheme.lightTheme`。

## 品牌与语义色

| Web（`:root` / 语义） | 值 | Flutter |
|---------------------|-----|---------|
| `--kelem-bg` / `--background` | `#f5f8ff` | `AppColors.bgMain` |
| `--kelem-card` / `--card` | `#ffffff` | `AppColors.bgCard` |
| `--kelem-sky` / `--primary` | `#29b6f6` | `AppColors.blue` |
| `--kelem-sky-deep` | `#0288d1` | `AppColors.blueDark` |
| `--kelem-sky-bright` | `#4fc3f7` | `AppColors.skyBright` |
| `--kelem-green` | `#4caf50` | `AppColors.green` |
| `--kelem-orange` | `#ff9800` | `AppColors.orange` |
| `--kelem-pink` | `#ff6b9d` | `AppColors.pink` |
| `--kelem-text-secondary` / `--muted-foreground` | `#546e7a` | `AppColors.textSecondary` |
| `--kelem-text-hint` | `#90a4ae` | `AppColors.textHint` |
| `--foreground` / `--card-foreground` | `#1a2340` | `AppColors.textPrimary` |
| `--muted` | `#eff4fb` | `AppColors.bgSection` |
| `--secondary` | `#e3f2fd` | `AppColors.blueLight` |
| `--secondary-foreground` | `#0288d1` | `AppColors.blueDark` |
| `--border` / `--input` | `#e8eff5` | `AppColors.divider` |

## 圆角（`--radius: 1rem` = 16px）

| Web token | 计算（约） | Flutter（逻辑像素） |
|-----------|------------|---------------------|
| `--radius-sm` | `radius × 0.6` | `AppRadius.sm` → 9.6 |
| `--radius-md` | `radius × 0.8` | `AppRadius.md` → 12.8 |
| `--radius-lg` | `radius` | `AppRadius.lg` → 16 |
| `--radius-xl` | `radius × 1.4` | `AppRadius.xl` → 22.4 |
| `--radius-2xl` | `radius × 1.8` | `AppRadius.x2l` → 28.8 |
| `--radius-3xl` | `radius × 2.2` | `AppRadius.x3l` → 35.2 |
| `--radius-4xl` | `radius × 2.6` | `AppRadius.x4l` → 41.6 |

GlassCard / 主卡片圆角与官网 `rounded-2xl` 意图一致时，使用 **`AppRadius.lg`（16）**；±1px 视为可接受。

## 阴影与 GlassCard（light）

| Web（GlassCard） | Flutter |
|------------------|---------|
| `shadow-[0_2px_12px_rgba(0,0,0,0.06)]` | `AppShadows.card`（`BoxShadow` 近似） |
| `border-white/60` | `AppColors.glassBorder`（`#FFFFFF` @ 60%） |
| `bg-card/95` | 浅色背景下与实色白接近，使用 `AppColors.bgCard` |
| `backdrop-blur-md` | 默认不叠加大面积模糊；低端机可用纯色 + 边框降级（见 `GlassCard`） |

顶栏/底部分割轻阴影：`AppShadows.bar`。

## 模态层（对话框与底部面板）

> **与页面 `GlassCard` 区分**：模态内容区为**纯色实底**（`AppColors.bgCard` + `AppShadows.card`），**不使用**页面卡片的毛玻璃/模糊效果。

| Token / 规则 | Flutter |
|--------------|---------|
| 居中对话框最大宽度 | `min(400, 屏宽 − 48)` 逻辑像素（见 `appDialogMaxWidth`） |
| 居中对话框圆角 | **`AppRadius.x2l`（28.8）**（`AppDialogScaffold` / `DialogTheme`） |
| 对话框表面 / 可选描边 | `AppColors.bgCard`，`Border.all(AppColors.divider, width: 1)` |
| 阴影 | `AppShadows.card` |
| 破坏性主按钮（确认删除等） | `AppColors.redDeep` 背景 + 白字（`showAppConfirmDialog` + `isDestructive: true`） |
| 底部面板上圆角 | **`AppRadius.x2l`**（`showAppModalSheet` / `BottomSheetTheme`） |
| 拖动指示条 | 宽 36 × 高 4，`AppColors.divider` |

封装入口：`lib/common/widgets/app_confirm_dialog.dart`、`app_info_dialog.dart`、`app_modal_sheet.dart`；统一导出见 `common/widgets/widgets.dart`。

## 间距（有限集合）

列表与区块垂直间距优先使用 **8 / 12 / 16 / 24**（`SizedBox`、`EdgeInsets`）。

## 深色模式

本客户端**不对齐**官网 `.dark`；Flutter 仅维护 **light** `ThemeData`（`AppTheme.lightTheme`）。
