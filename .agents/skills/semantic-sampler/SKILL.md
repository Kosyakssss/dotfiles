---
name: semantic-sampler
description: Sample less-predictable possibilities through externally randomized semantic partitions. Use for random or unusual examples, divergent brainstorming, genuinely distinct alternatives, UI or product directions, and requests to avoid superficial reskins.
compatibility: Requires /dev/urandom, od, and awk.
---

# Semantic sampler

Use external random bits to explore a possibility space before answering. This improves diversity; it is not uniform sampling.

## Procedure

Infer the target set, constraints, result count, and meaningful dimensions from the request. Do not ask the user to configure the sampler.

From this skill's directory, run:

```sh
sh scripts/random-bits N
```

`N` is the number of requested results. Each output line is an independent 16-bit stream.

For each stream, start with all valid possibilities. For each bit:

1. Divide the current region into two mutually exclusive, roughly comparable semantic subsets.
2. Partition on a consequential dimension not already fixed. Prefer structure, behavior, mechanism, workflow, or interaction over cosmetic traits.
3. Do not name concrete candidates or use circular divisions such as common/unusual or good/bad.
4. Follow subset `0` or `1` according to the bit.

Stop when the region is narrow or the bits are exhausted, then produce one concrete result consistent with the path and the user's constraints. If a partition creates an empty or contradictory path, revise that partition without changing its bit.

## Multiple results

Sample each result with its own stream. Then ensure the results differ in underlying concept, not only wording or appearance. If two are reskins, revise the later one from an unused semantic region while preserving its stream.

For UI and product directions, establish different interaction models, information architectures, workflows, or control structures before choosing visual style.

## Output

Answer normally. Do not narrate the partitions or claim true randomness unless the user asks to inspect the sampled paths.
