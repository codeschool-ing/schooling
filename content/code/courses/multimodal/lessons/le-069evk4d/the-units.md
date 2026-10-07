---
title: Four units, and none of them is bytes
version: 2
---

`ai-models` lesson 6 read LiteLLM's sheet for text models, where everything is priced per token. The multimodal entries use more units than that. The same sheet, at the commit lesson 3's `prices.py` pins:

```
ana@lab:~/mm$ python prices.py show gpt-4o | grep -E "^(input|output)_cost_per_token "
input_cost_per_token                       2.5e-06
output_cost_per_token                      1e-05
ana@lab:~/mm$ python prices.py show gemini/gemini-2.5-flash | grep -E "^(input_cost_per_token|input_cost_per_audio_token|output_cost_per_token) "
input_cost_per_audio_token                 1e-06
input_cost_per_token                       3e-07
output_cost_per_token                      2.5e-06
ana@lab:~/mm$ python prices.py show whisper-1 | grep -E "cost_per_second"
input_cost_per_second                      0.0001
output_cost_per_second                     0.0001
ana@lab:~/mm$ python prices.py show tts-1 | grep -E "cost_per_character"
input_cost_per_character                   1.5e-05
ana@lab:~/mm$ python prices.py show gpt-image-1 | grep -E "^(input|output)_cost_per_(image_)?token "; python prices.py show high/1024-x-1024/gpt-image-1 | grep input_cost_per_image
input_cost_per_image_token                 1e-05
input_cost_per_token                       5e-06
output_cost_per_image_token                4e-05
input_cost_per_image                       0.167
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
