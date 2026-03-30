## 1. 移除设置页 UI 与状态

- [x] 1.1 在 `flutter/lib/features/settings/screens/settings_screen.dart` 中删除「AI 助手配置」整块 UI（含标题、说明、输入框、保存按钮及任何显隐逻辑）
- [x] 1.2 删除仅被该区块使用的 `State` 成员（如 `TextEditingController`、`_buildApiKeySettings`、`_saveApiKey` 等），并从 `ListView`/`Column` 子节点中移除对应调用
- [x] 1.3 移除不再需要的 import；若 `AiConfig` 仅由此文件引用则删除该 import（以实现为准）

## 2. 代码库清理与验证

- [x] 2.1 全局检索 `saveApiKey`、`_buildApiKey`、`AI 助手配置` 等，确认无残留死代码或错误引用
- [x] 2.2 若 `AiConfig.saveApiKey` 已无调用方，评估是否删除或保留（与 design 中「其它入口」结论一致）

## 3. 静态分析与测试

- [x] 3.1 在 `flutter/` 目录执行 `flutter analyze`，确保无因本次变更产生的新告警或错误
- [x] 3.2 运行 `flutter test`；更新或删除仍断言已移除文案/控件的 widget 测试
