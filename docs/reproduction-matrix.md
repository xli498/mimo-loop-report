# Reproduction Matrix

| Scenario | Artifact / command | Expected observation | Claim class | Boundary |
|---|---|---|---|---|
| Historical loop observation | `logs/degenerate_loop_raw.log` | repeated output, language switch, no tool calls | Observed | historical artifact only |
| Provider reproduction | `reproduce/test_loop_reproduce.sh` | result must be recorded per run | Reproducible only after a successful documented run | requires authorized API access; do not publish keys |
| Detector review | `../mimo-stable/scripts/detect_loop.py --timeout 60 --log ../mimo-stable/logs/sample_degenerate_loop.log` | loop alert under the review threshold | Reproducible detector behavior | review threshold is not a production recommendation |
| Engineering containment | timeout / max-token / detector configuration | bounds runtime or raises alert | Mitigation | may truncate valid work or miss novel loop shapes |
