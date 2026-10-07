---
title: The Hub's multimodal tasks
version: 2
---

`ai-models` lesson 12 introduced the Hugging Face Hub: models, datasets, the task taxonomy, and community models next to the ones the big labs publish. This section only adds the multimodal half of that taxonomy, because the Hub's **task** label is the fastest way to find a model for a job in this course.

| the Hub's task | input → output | the lesson that does this job |
|---|---|---|
| `automatic-speech-recognition` | audio → text | 7 and 10 (Whisper) |
| `text-to-speech` | text → audio | 6 (Piper) |
| `voice-activity-detection` | audio → speech or not | 5 (Silero) |
| `object-detection` | image → boxes and labels | 2 (EfficientDet) |
| `image-to-text` | image → caption | 2 |
| `image-text-to-text` | image and text → text | 2 and 8 (vision-language models) |
| `document-question-answering` | document image and question → answer | 2 |
| `text-to-image` | text → image | 3 and 9 |
| `zero-shot-image-classification` | image and candidate labels → scores | 2 |
| `video-text-to-text` | video and text → text | 4 |
| `any-to-any` | several in, several out | 1 (native multimodal models) |

Two task names deserve a closer look.

**`image-text-to-text` is where the vision-language models are**: open models such as Qwen2.5-VL, Llama 3.2 Vision, Gemma 3 and SmolVLM, of very different sizes. SmolVLM's smallest versions run on a laptop; the large ones need a graphics card with tens of gigabytes. Qwen2.5-VL is the family of `qwen2.5vl:3b`, the vision model this course runs through Ollama, which fetches it from its own registry rather than from the Hub.

**`zero-shot-image-classification` is the open-vocabulary cousin of lesson 2's detector.** A CLIP-style model scores an image against labels you write at request time ("a damaged book", "an invoice", "a cat"), so the closed list of 80 COCO classes stops being a limit. It is cheap and fast, and it answers *which of these*, never *what is this*.

Every model page shows its task, its licence, the number of downloads and, for many, a **model card**: the next section's subject.
