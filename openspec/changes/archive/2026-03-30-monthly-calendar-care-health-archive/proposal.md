## Why

首页「本月打卡」用顺序 `Wrap` 展示整月日期，未来日期对比度过低且与真实周历不一致；社区「添加关怀的人」仍保留扫码入口，与「仅好友短码」预期不符；AI 健康档案缺少单条删除，且若数据已同步云端，删除应一并反映到后端。本次在不大改饮水同步与好友码协议的前提下补齐体验与删除闭环。

## What Changes

- **本月打卡**：改为周日为一周起始的 7 列网格，月初用空白占位；未到来日期仍显示清晰日数字；可选周表头（如「日一二…」）；修正「本月 X 天达标」统计口径，使与图例及当日达标状态一致（含当日达标时计入，按实现择优）。
- **社区关怀**：移除扫码按钮与跳转扫码页；输入框文案仅强调好友短码；在「我的短码」等展示处增加**刷新/轮换**能力（调用既有好友码轮换接口，与现网协议一致）。
- **健康档案**：列表或条目上提供删除；确认后硬删除（无软恢复）；先调后端 `DELETE /api/memory/:id`（若已登录且同步过），成功后再删本地 Hive；失败时明确提示且不破坏本地一致性策略（见设计）。
- **非目标**：不改好友码字符集与 lookup API；不引入跨月日历或完整日历组件；不涉及 `web/`。

## Capabilities

### New Capabilities

- `home-monthly-streak-calendar`: 首页本月打卡卡片的周历布局、未来日期可读性、达标天数字段口径。
- `community-care-contact-entry`: 添加关怀联系人仅手动输入好友短码、移除扫码；好友短码展示处支持刷新（轮换）。
- `health-archive-delete`: AI 健康档案单条删除（确认、本地 + 后端一致化）。

### Modified Capabilities

- （无）主仓 `openspec/specs/` 下社区规格为扁平 `community.md`，本变更以新增 capability 规格为主，不强制 delta 旧文件。

## Impact

- **Flutter**：`flutter/lib/features/home/screens/home_screen.dart`（`_buildStreakCalendar`）；`flutter/lib/features/community/screens/add_contact_screen.dart`、`_MyFriendCodeSheet` 所在文件；`flutter/lib/features/settings/screens/health_archive_screen.dart`；`flutter/lib/core/services/backend_api_service.dart`（新增 memory 删除等 HTTP 封装，若尚不存在）；可能 `scan_friend_code_screen.dart` 仅在被引用处清理 import/路由。
- **Backend**：`DELETE /api/memory/:id` 已存在；实现阶段以**对接与错误处理**为主，一般无需改路由（若鉴权或错误码需对齐再议）。
- **依赖**：不新增包；移除扫码相关 UI 后可减少对 `mobile_scanner` 等引用（若仅本页使用可评估是否从 `pubspec` 移除，属可选清理）。
