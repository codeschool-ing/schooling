---
title: Four units, and none of them is bytes
version: 1
---

`ai-models` lesson 6 read LiteLLM's sheet for text models, where everything is priced per token. The multimodal entries use more units than that. The same sheet, at the commit lesson 3's `prices.py` pins:

```
@@prices@@
```

| what is sent or made | unit | from the sheet | one example from this course |
|---|---|---|---|
| a picture to a chat model | input **tokens**, by a tile rule | gpt-4o: $2.50 per million | the cover at high detail, 765 tokens: $0.0019 |
| audio to a chat model | audio **tokens** | gemini-2.5-flash: $1.00 per million | depends on the provider's tokens per second |
| audio to a transcription model | **seconds** | whisper-1: $0.0001 per second | the 55.38-second call: $0.0055 |
| text to a speech model | **characters** | tts-1: $0.000015 per character | a 1,000-character reply: $0.015 |
| a generated image | per **image**, or image tokens | gpt-image-1 high, 1024 by 1024: $0.167 | lesson 9's arithmetic |

Two things follow from that table.

**The size of the file is in none of the units.** A transcription is billed by its seconds whether they arrive as a 1.7 MB WAV or a 120 KB Opus file; a picture is billed by its tokens, which come from its width and height after the provider resizes it, not from its bytes. Bytes matter for the limits and for the time a request takes, and the next three sections measure both, but they are not what the bill counts.

**Each unit needs its own estimate.** A budget written as "tokens per user" does not cover a speech model billed per character or a transcription billed per second. The sheet is the place to read every unit in one format, and `ai-models` lesson 6 already said what it is not: a bill. Prices change, and the provider's own usage page is what a shop reconciles against.
