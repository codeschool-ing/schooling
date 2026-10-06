---
title: DALL-E, and the names that replaced it
version: 1
---

This lesson's title names **DALL-E**, and the course was designed when that was the name of OpenAI's image model. It is no longer the name to write in code. The sheet the course reads prices from (LiteLLM's, at the commit `lab.sh` pins) lists OpenAI's own image models like this:

```
ana@lab:~/mm$ sheet provider openai --mode image_generation | grep -vE "^(low|medium|high|standard|[0-9])" 
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
chatgpt-image-latest                                  -        -        5       10  ......
gpt-image-1                                           -        -        5        -  ......
gpt-image-1-mini                                      -        -        2        -  ......
gpt-image-1.5                                         -        -        5       10  V....P
gpt-image-1.5-2025-12-16                              -        -        5       10  V....P
gpt-image-2                                           -        -        5        -  V....P
gpt-image-2-2026-04-21                                -        -        5        -  V....P
gpt-image-2.5-flare                                   -        -        5        -  V....P
gpt-image-2.5-flare-2026-09-08                        -        -        5        -  V....P
gpt-image-2.5-sunburst                                -        -        5        -  V....P
gpt-image-2.5-sunburst-2026-09-08                     -        -        5        -  V....P
ana@lab:~/mm$ sheet show gpt-image-1 | grep -E "deprecation|supported_endpoints"
deprecation_date                           2026-10-23
supported_endpoints                        ['/v1/images/generations', '/v1/images/edits']
ana@lab:~/mm$ for q in low medium high; do printf "%-7s" $q; sheet show $q/1024-x-1024/gpt-image-1 | grep input_cost_per_image; done
low    input_cost_per_image                       0.011
medium input_cost_per_image                       0.042
high   input_cost_per_image                       0.167
```

**There is no `dall-e-3` among OpenAI's own entries any more**; the name survives in the sheet only under other providers that resell it. What OpenAI lists is the GPT image family, from `gpt-image-1` to `gpt-image-2.5`, with dated snapshots such as `gpt-image-2-2026-04-21`. And `gpt-image-1` itself carries a **deprecation date of 23 October 2026**, seventeen days after the lab's calendar.

Three habits follow, and they matter more in image generation than anywhere else in this course, because image models are replaced faster than text ones:

1. **Name a dated snapshot** (`gpt-image-1.5-2025-12-16`) in production, so that the model does not change under you, and an alias (`gpt-image-1.5`) only where you want the newest.
2. **Keep the model name in one place**, read from configuration, so that moving off a deprecated model is a one-line change and a test run, not a search through the code.
3. **Re-run lesson 3's grid on the new model before switching.** The same prompt on a new model is a new experiment; a banner style that took two rounds to settle can move.

`sheet retiring` lists every entry with a deprecation date, soonest first, and it is worth running every quarter against the names your code uses.
