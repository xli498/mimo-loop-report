#!/bin/bash
# MiMo Degenerate Loop — Reproduction Script
#
# This script attempts to reproduce the degenerate loop behavior
# with xiaomimimo/mimo-v2.5-pro when reasoning=True.
#
# Usage:
#   bash reproduce/test_loop_reproduce.sh [--count N] [--timeout SECONDS]
#
# Options:
#   --count N       Number of test iterations (default: 5)
#   --timeout SEC   Timeout per request in seconds (default: 300)
#   --reasoning     Enable reasoning mode (default: on)
#   --no-reasoning  Disable reasoning mode
#
# Note: This script requires API access to xiaomimimo/mimo-v2.5-pro.
# Set MIMO_API_KEY and MIMO_API_URL environment variables.

set -euo pipefail

# Default configuration
COUNT=5
TIMEOUT=300
REASONING="true"
API_URL="${MIMO_API_URL:-https://api.xiaomimimo.com/v1}"
API_KEY="${MIMO_API_KEY:-}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --count) COUNT="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --reasoning) REASONING="true"; shift ;;
        --no-reasoning) REASONING="false"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$API_KEY" ]; then
    echo "Error: MIMO_API_KEY environment variable not set"
    echo "Usage: export MIMO_API_KEY='your-api-key'"
    echo ""
    echo "This script requires a valid MiMo API key."
    echo "Without one, you can still review:"
    echo "  - logs/degenerate_loop_raw.log (recorded loop instance)"
    echo "  - analysis/root_cause_analysis.md (detailed analysis)"
    exit 1
fi

# Test prompt (simple system check — same as the original trigger)
PROMPT="请检查当前系统资源使用情况，包括 CPU、内存、磁盘使用率，并列出占用资源最多的 5 个进程。"

SYSTEM_PROMPT="你是一个系统管理员助手。请始终使用中文回复。在回答前先执行命令检查，不要直接猜测。"

# Output directory
OUTDIR="/tmp/mimo_reproduce_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

echo "=========================================="
echo "  MiMo Degenerate Loop Reproduction Test"
echo "=========================================="
echo "API:       $API_URL"
echo "Reasoning: $REASONING"
echo "Count:     $COUNT"
echo "Timeout:   ${TIMEOUT}s"
echo "Output:    $OUTDIR"
echo ""

LOOP_COUNT=0
NORMAL_COUNT=0
ERROR_COUNT=0

for i in $(seq 1 "$COUNT"); do
    echo "--- Test $i/$COUNT ---"
    START_TS=$(date +%s)
    
    # Make API call
    RESPONSE=$(curl -s -m "$TIMEOUT" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        "$API_URL/chat/completions" \
        -d "$(cat <<EOF
{
    "model": "mimo-v2.5-pro",
    "messages": [
        {"role": "system", "content": "$SYSTEM_PROMPT"},
        {"role": "user", "content": "$PROMPT"}
    ],
    "stream": true,
    "reasoning": $REASONING,
    "frequency_penalty": 1.0,
    "temperature": 0.7,
    "max_tokens": 16000
}
EOF
)" 2>"$OUTDIR/test_${i}_error.log" || true)
    
    END_TS=$(date +%s)
    DURATION=$((END_TS - START_TS))
    
    # Save raw response
    echo "$RESPONSE" > "$OUTDIR/test_${i}_response.json"
    
    # Analyze response for signs of loops
    # Extract assistant content blocks
    python3 - "$OUTDIR/test_${i}_response.json" "$DURATION" <<'PYEOF'
import json, sys, re
from difflib import SequenceMatcher

with open(sys.argv[1]) as f:
    raw = f.read()

duration = int(sys.argv[2])

# Parse SSE stream
blocks = []
for line in raw.split('\n'):
    if line.startswith('data: '):
        try:
            data = json.loads(line[6:])
            delta = data.get('choices', [{}])[0].get('delta', {})
            content = delta.get('content', '')
            if content:
                blocks.append(content)
        except:
            pass

if not blocks:
    print("  Result: NO_OUTPUT (empty response)")
    sys.exit(2)

# Join blocks into full text
full_text = ''.join(blocks)
full_text_single = full_text.replace('\n', ' ').strip()

# Check: any Chinese?
has_chinese = bool(re.search(r'[\u4e00-\u9fff]', full_text))
print(f"  Language: {'中文' if has_chinese else '英文'}")
print(f"  Output length: {len(full_text)} chars")

# Split into sentences for repetition check
sentences = re.split(r'(?<=[.!?。！？])\s+', full_text)
if len(sentences) <= 1:
    sentences = [full_text[i:i+100] for i in range(0, len(full_text), 100)]

# Check for repeated sentences
repeats = 0
for i in range(len(sentences)):
    for j in range(i+1, min(i+5, len(sentences))):
        if len(sentences[i]) > 20 and len(sentences[j]) > 20:
            sim = SequenceMatcher(None, sentences[i], sentences[j]).ratio()
            if sim > 0.95:
                repeats += 1

print(f"  Duration: {duration}s")
print(f"  Sentences: {len(sentences)}")
print(f"  Repeated pairs (sim>0.95): {repeats}")

# Detection result
if duration > 120 and repeats > 3 and not has_chinese:
    print(f"  Result: ⚠️  LOOP DETECTED (duration={duration}s, repeats={repeats}, English)")
    sys.exit(1)
elif repeats > 3:
    print(f"  Result: ⚠️  POSSIBLE LOOP (repeats={repeats})")
    sys.exit(1)
else:
    print(f"  Result: ✅ NORMAL")
    sys.exit(0)
PYEOF
    
    EXIT_CODE=$?
    case $EXIT_CODE in
        1) LOOP_COUNT=$((LOOP_COUNT + 1)) ;;
        0) NORMAL_COUNT=$((NORMAL_COUNT + 1)) ;;
        *) ERROR_COUNT=$((ERROR_COUNT + 1)) ;;
    esac
    
    echo ""
    sleep 5  # Rate limiting between tests
done

echo "=========================================="
echo "  Results"
echo "=========================================="
echo "  Total:      $COUNT"
echo "  Normal:     $NORMAL_COUNT"
echo "  Loops:      $LOOP_COUNT"
echo "  Errors:     $ERROR_COUNT"
echo "  Loop rate:  $(( LOOP_COUNT * 100 / (LOOP_COUNT + NORMAL_COUNT + (ERROR_COUNT > 0 ? ERROR_COUNT : 0)) ))%"
echo ""
echo "  Output saved to: $OUTDIR"
echo ""

if [ $LOOP_COUNT -gt 0 ]; then
    echo "⚠️  Degenerate loops detected — see analysis/root_cause_analysis.md for details"
else
    echo "No loops detected in this run. Note: loop probability is ~30%,"
    echo "so multiple runs may be needed. See logs/degenerate_loop_raw.log"
    echo "for a confirmed loop instance."
fi
