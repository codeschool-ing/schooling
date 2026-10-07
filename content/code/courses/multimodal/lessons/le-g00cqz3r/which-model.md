---
title: DALL-E, and the names that replaced it
version: 1
---

This lesson's title names **DALL-E**, and the course was designed when that was the name of OpenAI's image model. It is no longer the name to write in code. LiteLLM's sheet, read with lesson 3's `prices.py`, lists the image models it files under OpenAI like this:

```
@@sheet-openai@@
```

**There is no `dall-e-3` among OpenAI's own entries any more**; the name survives in the sheet only under other providers that resell it. What OpenAI lists is the GPT image family, from `gpt-image-1` to `gpt-image-2.5`, with dated snapshots such as `gpt-image-2-2026-04-21`. And `gpt-image-1` itself carries a **deprecation date of 23 October 2026**, seventeen days after the lab's calendar.

Three habits follow, and they matter more in image generation than anywhere else in this course, because image models are replaced faster than text ones:

1. **Name a dated snapshot** (`gpt-image-1.5-2025-12-16`) in production, so that the model does not change under you, and an alias (`gpt-image-1.5`) only where you want the newest.
2. **Keep the model name in one place**, read from configuration, so that moving off a deprecated model is a one-line change and a test run, not a search through the code.
3. **Re-run lesson 3's grid on the new model before switching.** The same prompt on a new model is a new experiment; a banner style that took two rounds to settle can move.

`prices.py find` prints each entry's deprecation date in its last column, and it is worth running every quarter against the names your code uses.
