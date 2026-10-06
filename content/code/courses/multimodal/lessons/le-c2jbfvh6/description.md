---
title: Describing a picture in words
version: 1
---

A **vision-language model** (VLM) reads an image and a text prompt together and answers in text. It has no fixed list: it was trained on enormous numbers of pictures paired with captions and documents, and it answers in the open vocabulary of a language model. GPT-4o, Gemini and Claude all take images this way, and so do open models such as Qwen2.5-VL and Llama 3.2 Vision (lesson 11).

That one difference changes what you can ask. A detector says `book 0.51`. A VLM can be asked *"what kind of document is this, who sent it, and what is the total?"* and answer in a sentence, or in JSON. It reads text, so it does OCR's job too, and it understands layout, so it does not need to be told about rows. It can describe the cover of *Dom Casmurro*, which the detector could not name at all.

**No VLM runs in this lab**, and none was reachable from the machine the course was recorded on. Here is what such a description looks like, written by the course for this picture and not produced by any model. It shows the kind of answer you get, and the kind of mistake to look for:

> *A book cover with a dark blue background. At the top right is a pale yellow full moon. The title DOM CASMURRO is printed in large cream serif letters, with the author's name, Machado de Assis, beneath it. Below is a dark building with two lit windows, and at the bottom the words "Marginalia Classics". The style is flat and minimalist, suggesting a night scene.*

Everything in that description can be checked against what the lab drew, because `build_media.py` says exactly what is on the cover. The moon, the title, the author and the publisher line are there. **"A dark building" is an interpretation**: the drawing is a dark rectangle with two gold rectangles in it, and *building*, *window* and *night scene* are the reader's story, which is often what you want from a description and never what you want from extraction.

## How to check a description

A description is the hardest output in this course to verify, because it is prose and there is no single right answer. Three checks catch most of the trouble:

1. **Cross-check the facts that something else can read.** If the description quotes text, OCR the same image and compare. The title and author are on the cover; Tesseract reads them in milliseconds.
2. **Ask for what is checkable.** "List every piece of text on the cover, exactly as written" is verifiable. "Describe the mood of the cover" is not, and should never feed anything automatic.
3. **Watch for the plausible addition.** A VLM's typical error is not nonsense: it is the detail that a cover like this *usually* has. A barcode, a price, a subtitle. Anything you did not expect to be there deserves a look before it is trusted.

Lesson 8 sends images to a VLM through OpenAI's API, in the lab's stand-in, and asks for its answer as JSON checked against a schema.
