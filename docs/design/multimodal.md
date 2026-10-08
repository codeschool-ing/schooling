---
format: 5
course: multimodal
---

# multimodal

**Multimodal AI: Image, Audio and Video** · `co-v9td5x1b` · 50 h declared · intermediate · 14 lessons · `ai` · paid

## Reach

In **1 track** — `ai`(13).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `ai-models` — providers, keys and quotas, which matter more here than anywhere because the calls are expensive.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 14 |
| **hours per lesson** | **3.57** |
| section budget | ~107, about 7.6 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **the student's own computer** (C-38): open speech and vision models run locally — Whisper, Piper, `qwen2.5vl:3b` and `llama3.2:3b` through Ollama — built by lesson 1's `setup.sh`; image generation answers from a stand-in the course prints whole, because Ollama draws only on macOS. **An API key with a bill attached is optional**, and the most expensive calls in the category are the ones a student would pay for with one |
| browser · database | no · no |
| exercises **blocked** | **~350 (70%), and the cost per blocked exercise is the highest in the catalogue** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~45 — frames sampled from a video, a spectrogram split by speaker, an image prompt and its result varied one axis at a time |

## Ageing

**Severe.** Lesson 9 names DALL-E and NanoBanana; lesson 8 the OpenAI Vision API; lesson 10 Whisper; lesson 12 LangChain and LlamaIndex. Image and audio models are replaced faster than text ones.

## Flags

**1 ·** **Every other blocked exercise in the sweep costs a machine that is already running. These cost money per attempt.** A student generating an image, transcribing audio or reading a video pays a metered call each time, and *retrying is the whole pedagogy* — lesson 3 is prompt, style and limits, which is learnt by varying one thing and looking again. **A per-attempt cost that rises with how much a student practises is a new shape**, and it is worse than `deep-learning`'s GPU because there is no cheaper local substitute for most of it. *Since the retrofit to C-38 and C-40, there is one for everything but drawing: the course's models run on the student's machine, and only image generation is a stand-in.*

**2 ·** **And the course knows: lesson 13 is *"Cost, file size and upload limits"*.** Third time in the sweep that a course teaches a cost its students cannot incur — after the vendor data family and `bigdata`. That is now a pattern worth naming rather than a coincidence: **the subjects that most need a real bill to be understood are the ones a sandbox can least provide.**

**3 ·** **Lesson 14 is accessibility, and it is the platform's own obligation.** Captions, audio description and transcription — `VIDEO.md` has to answer the same question for this school's own videos, and `tools/a11y-test` runs against its interface. A course teaching the rule while the platform is held to it is worth writing from the inside.
