# MiMo-v2.5-Pro Degenerate Loop: P0 Bug Report

收件人：小米 MiMo 模型工程团队
日期：2026-05-28 | 模型版本：xiaomimimo/mimo-v2.5-pro

---

## 摘要

严重等级：P0。就是最严重的那个。

MiMo-v2.5-Pro 在 Agent 工具调用场景下会疯掉。重复输出同一段话数分钟，所有已知缓解手段全部无效。

是废了。

## 复现

模型：xiaomimimo/mimo-v2.5-pro
频率：~30%，每 3 次任务就抽一次

## 症状

Agent 完成工具调用后进入总结阶段。轰。Loop：

The output seems to show the config was applied successfully... (x8, 6 分钟)

特征：
- 逐字重复。token 级别一模一样。
- 全英文。无视 System Prompt。
- 无视 frequency_penalty=1.0。
- 无自我感知。

## 根因

英文推理路径不稳定 + 没有跳出机制 + 状态转换故障。

## 尝试过的手段

全部无效。这是模型推理层的 Bug。

## 期望修复

1. 模型层：内置重复检测
2. API 层：repetition_detection 参数
3. API 层：stop_reason 标识

## License

MIT