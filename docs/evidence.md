# Evidence and Claim Boundaries

## Claim classes

| Class | Meaning | Current examples |
|---|---|---|
| Observed | Directly visible in committed logs | Chinese-to-English switch, repeated English blocks, no tool call in `logs/degenerate_loop_raw.log` |
| Reproducible | Covered by a deterministic fixture or script | See `mimo-stable` detector fixtures; this repository does not claim cross-provider reproduction without a valid test run |
| Hypothesis | Plausible mechanism without model-internal telemetry | fixed-point / probability-collapse explanation |
| Mitigation | External control that bounds impact, not a cure | timeout, max token cap, output-pattern monitoring |

## Scope and limits

- The historical “about 30%” figure is an observation from a limited prior test batch. It is not a population estimate and must not be treated as a current provider-wide rate.
- This repository contains no logits, hidden states, or vendor internals. Any mechanism claim is a hypothesis.
- Parameter results are scoped to the logged configuration and tested prompts; they do not prove universal ineffectiveness.
- Before reuse, record model identifier, endpoint, date, prompt class, reasoning setting, sample count, timeout, and artifact path.
