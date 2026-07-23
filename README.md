# MiMo Degenerate Loop Report

MiMo 模型退化循环问题的完整调查报告。

## 问题

使用 `xiaomimimo/mimo-v2.5-pro` 模型时，当 `reasoning=True`，在有限历史测试中曾观察到退化循环；“约 30%”是该批测试的历史观察值，不应外推为所有版本、提示词或接口的总体概率：
- 同一段输出重复 8-11 次
- 持续约 6 分钟
- 输出语言从中文切换为英文
- 不执行任何工具调用

## 文件结构

```
mimo-loop-report/
├── README.md                           # 本文档
├── logs/
│   └── degenerate_loop_raw.log        # 原始日志（含系统配置和完整时间线）
├── reproduce/
│   └── test_loop_reproduce.sh         # 复现脚本（需要 API 密钥）
└── analysis/
    └── root_cause_analysis.md         # 根因分析
```

## 快速开始

### 查看日志

```bash
cat logs/degenerate_loop_raw.log
```

日志包含完整的系统配置、模型参数和循环时间线。

### 阅读分析

```bash
cat analysis/root_cause_analysis.md
```

分析涵盖：
- 退化循环的详细特征
- 语言切换机制分析
- Token 概率分布塌缩的推测
- 各修复方案的原理和效果评估

### 复现（需要 API 密钥）

```bash
export MIMO_API_KEY="your_key_here"
bash reproduce/test_loop_reproduce.sh --count 10 --timeout 300
```

概率约 30%，需要多次测试才能捕获循环。

## 关键发现

1. **工作假设**：`reasoning=True` 相关路径可能在特定输入条件下出现固定重复；机制尚未得到模型内部证据证实
2. **参数修复无效**：`frequency_penalty`、`temperature`、System Prompt 调整均无效
3. **工程修复有效**：`timeoutSeconds=180` + `maxTokens=8000` 可在工程侧阻止循环
4. **行为检测可用**：输出模式检测可提供独立告警；误报率和覆盖范围取决于阈值与样例

详见 [analysis/root_cause_analysis.md](analysis/root_cause_analysis.md)。

## 工具方案

检测脚本和防护措施参考 [mimo-stable](https://github.com/xli498/mimo-stable) 项目。

## 许可

MIT
