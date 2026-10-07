---
title: DALL-E, and the names that replaced it
version: 1
---

This lesson's title names **DALL-E**, and the course was designed when that was the name of OpenAI's image model. It is no longer the name to write in code. LiteLLM's sheet, read with lesson 3's `prices.py`, lists the image models it files under OpenAI like this:

```
ana@lab:~/mm$ python prices.py find "" image_generation | grep " openai " | grep -vE "^(low|medium|high|standard|hd|[0-9])"
chatgpt-image-latest                         openai                     2026-12-01
gpt-image-1                                  openai                     2026-10-23
gpt-image-1-mini                             openai                     2026-12-01
gpt-image-1.5                                openai                     2026-12-01
gpt-image-1.5-2025-12-16                     openai                     2026-12-01
gpt-image-2                                  openai                     
gpt-image-2-2026-04-21                       openai                     
gpt-image-2.5-flare                          openai                     
gpt-image-2.5-flare-2026-09-08               openai                     
gpt-image-2.5-sunburst                       openai                     
gpt-image-2.5-sunburst-2026-09-08            openai                     
ana@lab:~/mm$ python prices.py show gpt-image-1 | grep -E "deprecation|supported_endpoints"
deprecation_date                           2026-10-23
supported_endpoints                        ['/v1/images/generations', '/v1/images/edits']
ana@lab:~/mm$ for q in low medium high; do printf "%-7s" $q; python prices.py show $q/1024-x-1024/gpt-image-1 | grep input_cost_per_image; done
low    input_cost_per_image                       0.011
medium input_cost_per_image                       0.042
high   input_cost_per_image                       0.167
```

**There is no `dall-e-3` among OpenAI's own entries any more**; the name survives in the sheet only under other providers that resell it. What OpenAI lists is the GPT image family, from `gpt-image-1` to `gpt-image-2.5`, with dated snapshots such as `gpt-image-2-2026-04-21`. And the last column is the one to read: `gpt-image-1` itself carries a **deprecation date of 23 October 2026**, sixteen days after this lesson was recorded, and most of the family below `gpt-image-2` ends on 1 December.

Three habits follow, and they matter more in image generation than anywhere else in this course, because image models are replaced faster than text ones:

1. **Name a dated snapshot** (`gpt-image-1.5-2025-12-16`) in production, so that the model does not change under you, and an alias (`gpt-image-1.5`) only where you want the newest.
2. **Keep the model name in one place**, read from configuration, so that moving off a deprecated model is a one-line change and a test run, not a search through the code.
3. **Re-run lesson 3's grid on the new model before switching.** The same prompt on a new model is a new experiment; a banner style that took two rounds to settle can move.

`prices.py find` prints each entry's deprecation date in its last column, and it is worth running every quarter against the names your code uses.
