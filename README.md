# MiMo-v2.5-Pro Degenerate Loop: P0 Bug Report

**收件人：小米 MiMo 工程团队**
**日期：2026-05-28 | 模型：xiaomimimo/mimo-v2.5-pro**

---

## TL;DR

严重等级 P0。就是最严重那个。

MiMo-v2.5-Pro 在 Agent 工具调用场景下会**直接死循环**。同一段话重复输出 8 次、6 分钟、逐字一模一样。

所有你能想到的参数——试过了。全部无效。

模型层面就是坏的。

---

## 复现

**模型：** xiaomimimo/mimo-v2.5-pro
**触发概率：** ~30%。每 3 次任务抓一次。不是小概率事件，是大概率事故。
**场景：** Agent 完成工具调用 → 进入总结阶段 → Boom。

```
The output seems to show the config was applied successfully... (x8, 6 分钟)
```

## 症状

- 逐字复制。Token 级别的完全重复。
- 全英文输出。无视任何中文 System Prompt。
- frequency_penalty=1.0？无视。
- temperature 调高？更糟。
- 模型不知道自己错了。没有跳出机制。没有 self-awareness。

## 根因

不是 prompt 问题。不是配置问题。是**模型推理层的 Bug**。

英文推理 token 的概率分布塌缩。注意力机制聚焦刚输出的 token，自我强化。就像神经网络给自己打了一针 dopamine，停不下来。

## 试过什么

| 手段 | 结果 |
|------|------|
| frequency_penalty ↑ | 没用 |
| temperature 调高 | 更随机 → 更多循环 |
| 强制中文 System Prompt | 降低频率，没根治 |
| 上下文压缩 | Bug 在生成层，不在输入层 |
| 所有参数的排列组合 | 全部无效 |

## 期望修复（认真说）

1. **模型层** — 内置 token 级别重复检测。模型应该知道自己卡住了。
2. **API 层** — 加 `repetition_detection` 参数。Server 侧兜底。
3. **API 层** — `stop_reason` 标记 "repetition"。不是所有异常都是 EOS。

---

这报告不是骂人。是修 Bug 的第一步。你们做得出 V2.5，就能修好这个。

## License

MIT
