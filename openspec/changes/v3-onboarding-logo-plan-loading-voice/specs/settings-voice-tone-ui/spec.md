## ADDED Requirements

### Requirement: 基础设置中音色选项展示

设置中的「基础设置」分组 MUST 提供「音色」入口；用户 MUST 能查看多个预设音色风格（名称与简短描述）并选择其一；选择 MUST 仅保存在客户端本地（如 `SharedPreferences`），MUST NOT 调用任何外部 TTS 或音色 API。

#### Scenario: 入口可见

- **WHEN** 用户打开「设置」并展开基础设置区域
- **THEN** 存在「音色」或等价文案的入口项

#### Scenario: 选择预设并持久化

- **WHEN** 用户选择某一预设音色并返回
- **THEN** 再次进入设置时仍显示当前选中项

#### Scenario: 无网络调用

- **WHEN** 用户切换音色预设
- **THEN** 应用不发起 HTTP 请求用于音色合成或音色列表拉取
