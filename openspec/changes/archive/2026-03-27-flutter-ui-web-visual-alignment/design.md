## Context

- Flutter 应用已具备完整功能与既有主题（`flutter/lib/core/theme/app_theme.dart` 等），通用卡片见 `flutter/lib/common/widgets/glass_card.dart`。
- 品牌视觉以官网 **light** 下 KeLeME token 与 GlassCard 为**对照基准**；实现与文档仅落在 `flutter/`，**不修改** Next.js 站点代码。
- 约束来自产品需求：不大改布局、零新依赖、不对齐深色模式、性能优先于像素级复刻玻璃模糊。

## Goals / Non-Goals

**Goals:**

- 在 `AppColors` / `ThemeData` 中集中表达与官网 light 语义一致的背景、表面、主色与文字层级。
- 统一卡片类容器的圆角、阴影与边框策略，减少各屏魔法数字。
- 产出可评审的 web（只读）↔ Flutter token 对应关系，供实现与 CR 对照。
- 主导航核心屏在样式刷新后可通过产品手动验收。

**Non-Goals:**

- 修改 `web/` 或后端 API。
- Flutter 内深色模式、官网 Hero 装饰与营销动画的 1:1 复刻。
- 新增 `pubspec.yaml` 依赖或更换状态管理方案。
- 重组页面信息架构或区块顺序。

## Decisions

1. **Token 单一事实来源（实现侧）**  
   - **决策**：Flutter 侧以 `AppColors`（及必要时的 theme 扩展）为运行时唯一来源；官网 CSS 仅作为**对照输入**，在独立文档/表中列出映射。  
   - **备选**：直接在代码注释中散落对照——**拒绝**，不利于评审与维护。

2. **玻璃态 vs 性能**  
   - **决策**：默认在少量、小区域使用 `BackdropFilter`；列表或低端设备上采用「半透明白 + 轻阴影 + 细边框」降级，并在 PR/实现说明中可简短注明原因。  
   - **备选**：全屏模糊——**拒绝**，与性能风险冲突。

3. **间距与圆角**  
   - **决策**：垂直间距使用有限集合（如 8 / 12 / 16 / 24）；卡片主圆角对齐官网「约 16px / rounded-2xl」意图，逻辑像素取整允许 ±1px。  
   - **备选**：完全连续数值——**拒绝**，不利于一致性与代码审查。

4. **文档存放**  
   - **决策**：token 对照表落在仓库内明确路径（优先 `flutter/` 下 `doc/` 或 `.cursor/project/` 中之一，由任务清单敲定），并在 `SPEC.md` 或主规格索引中增加指向（若本次归档流程要求更新主规格）。  
   - **备选**：仅口头/PR 描述——**拒绝**，不满足 FR-1 可评审性。

## Risks / Trade-offs

- **[Risk] 模糊与多层半透明导致掉帧** → **Mitigation**：限制 `BackdropFilter` 层级与区域；使用 `RepaintBoundary` 隔离重绘；必要时降级为无模糊样式。  
- **[Risk] 与官网计算样式存在可见色差** → **Mitigation**：以 token 表为共识；产品验收接受有限偏差（功能与可读性优先）。  
- **[Risk] 各屏历史 `BoxDecoration` 遗漏** → **Mitigation**：以 `GlassCard`（或统一封装）为默认；搜索/CR 收敛硬编码色与圆角。

## Migration Plan

- **发布**：随常规 App 版本发布；无数据迁移、无后端开关。
- **回滚**：若观感问题阻塞发布，可通过 Git 回退主题相关提交；无用户数据影响。

## Open Questions

- Token 对照表最终文件路径（`flutter/doc/` 与 `.cursor/project/`）由实现阶段与仓库惯例二选一即可，无产品阻塞。
