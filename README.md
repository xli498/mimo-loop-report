# MiMo-v2.5-Pro Degenerate Loop Bug Report

> **面向小米 MiMo 模型工程团队**  
> **报告日期：2026-05-28** | **模型版本：xiaomimimo/mimo-v2.5-pro**

---

## 1. 问题摘要

**严重等级：P0 — 阻断性 Bug**

**一句话描述：** MiMo-v2.5-Pro 在 Agent 工具调用场景下会陷入 Degenerate Loop（退化循环），模型连续输出完全相同的文本段落，持续数分钟，直到外部干预（用户发新消息或切换模型）才能恢复。当前所有已知的 prompt 层和参数层缓解手段均无效。

---

## 2. 复现信息

| 项目 | 详情 |
|------|------|
| **模型** | xiaomimimo/mimo-v2.5-pro |
| **API 端点** | `https://token-plan-cn.xiaomimimo.com/v1` |
| **API 类型** | OpenAI-compatible completions |
| **平台** | OpenClaw Agent (QQ Bot channel) |
| **场景** | Agent 工具调用（Tool Calling）后 → 总结回复阶段 |
| **频率** | 高频复现（约 30% 的 Agent 任务触发） |
| **首次发现** | 2026-05-27 19:54 (UTC+8) |

---

## 3. 问题现象详细描述

### 3.1 典型复现场景

在 Agent 执行自动任务时，模型成功完成工具调用并验证结果后，进入"总结回复"阶段时触发 Degenerate Loop。模型开始反复输出以下模式的英文文本：

```
"The output seems to show the config was applied successfully..."
"The config was applied successfully..."
"The output seems to show the config was applied successfully..."
"The config was applied successfully..."
（重复 8 次，持续约 6 分钟）
```

### 3.2 核心特征

- **逐字重复：** 每次输出的内容完全相同或高度相似，不是"意思相同但措辞不同"，而是 token 级别的重复
- **语言切换触发：** 循环内容几乎总是英文，即使对话上下文全程中文。推测模型在推理/思考阶段切换到英文后，陷入英文推理路径的固定模式
- **无视 System Prompt：** System Prompt 中明确要求"思考和输出一律用中文"，但模型在 loop 状态下完全忽略该指令
- **无视停止信号：** 即使设置了 `frequency_penalty=1.0`（极高值），也无法打断循环
- **自我感知缺失：** 模型在 loop 状态下不具备"我已经输出过这段话"的感知能力，无法自行检测并跳出循环

---

## 4. 根因分析（推测）

> 以下分析基于可观测现象的逆向推断，供工程团队定位参考。

### 4.1 英文推理路径稳定性不足

MiMo 模型以中文为主要训练语言。当模型在推理阶段（thinking/reasoning）自发切换到英文时，英文 token 的条件概率分布可能出现"塌缩"——即少数几个 token 序列获得压倒性概率优势，导致采样（即使是 temperature>0 的随机采样）几乎必然命中同一序列。

### 4.2 推理状态机缺少"跳出"机制

正常的语言模型在生成重复内容时，应通过 repetition penalty 或内置的多样性机制跳出循环。MiMo 在该场景下表现为：一旦进入某个"完成态"的输出模式，模型的注意力机制会持续聚焦于刚输出的 token，形成正反馈循环。这暗示模型在长上下文 + 工具调用场景下的注意力分配可能存在缺陷。

### 4.3 Tool-Calling 后的状态转换异常

问题集中出现在"工具调用完成 → 总结回复"的状态转换节点。推测模型在处理 tool_result 后，内部状态未能正确从"执行模式"切换到"对话模式"，导致生成逻辑卡在某个中间状态。

---

## 5. 已尝试的缓解手段及效果

| 手段 | 参数 | 效果 |
|------|------|------|
| 调整 temperature | 0.6 / 0.8 / 1.0 | ❌ 无效 |
| 降低 temperature | 0.2 / 0 | ❌ 反而更差（确定性塌缩） |
| frequency_penalty | 0.5 / 0.8 / 1.0 | ❌ 无效（最高值也无法打断） |
| presence_penalty | 0.4 / 0.6 | ❌ 无效 |
| 强制中文 System Prompt | "思考和输出一律用中文" | 🟡 降低频率但未根治 |
| maxTokens 限制 | 各种上限 | ❌ 仅延迟触发，不防御 |
| contextWindow 压缩 | 减少上下文 | ❌ 无效果 |

**结论：当前所有已知的 prompt 层和参数层手段均无法根治此问题。这是模型推理层面的 Bug，不是使用方式的问题。**

---

## 6. 影响范围评估

- **Agent 场景全面阻断：** MiMo 作为 Agent backbone 时，Degenerate Loop 会导致整个 Agent 管道卡死，所有下游任务排队等待，直到人工干预
- **Token 资源浪费：** 单次 Loop 事件消耗约 6 分钟 × 持续输出的 token 量，在按 token 计费的场景下造成直接经济损失
- **自动化流程不可靠：** 任何依赖 MiMo 的定时任务、自动化工作流都无法保证稳定运行，因为 Loop 随时可能触发且无法自动恢复
- **用户信任损耗：** 对于不了解底层原因的用户，会认为"AI 卡住了"或"AI 坏了"，严重影响产品体验

---

## 7. 期望的修复方向

### 7.1 模型层：内置重复检测与跳出机制

在推理引擎层面实现 token 序列重复检测。当检测到连续 N 次（如 3 次）输出高度相似的 token 序列时，自动注入扰动（如提升 temperature、采样低概率 token）或强制停止当前生成。**这是最根本的解决方案。**

### 7.2 模型层：强化英文推理路径的稳定性

如果英文推理确实是触发因素，建议在 RLHF/DPO 阶段增加英文推理场景的训练数据，或在推理时对英文 reasoning token 施加额外的多样性约束。

### 7.3 API 层：提供 repetition_detection 参数

在 API 层面提供可配置的重复检测阈值，允许调用方设置"连续重复 N 次则自动终止"的硬限制。这比在应用层检测更高效，因为应用层只能在收到完整响应后才能判断。

### 7.4 API 层：提供 stop_reason 标识

当模型因重复检测而终止生成时，在响应中返回明确的 stop_reason（如 "repetition_detected"），让调用方能区分正常结束和异常终止。

---

## 附录：环境信息

| 项目 | 详情 |
|------|------|
| **模型 ID** | xiaomimimo/mimo-v2.5-pro |
| **API 类型** | OpenAI-compatible |
| **Agent 框架** | OpenClaw |
| **运行环境** | Huawei Cloud CCI (containerized) |
| **操作系统** | Linux x64 |
| **Node.js** | v24.14.0 |
| **报告日期** | 2026-05-28 |
| **报告人** | OpenClaw Agent 运维团队 |

---

*— 报告结束 —*
