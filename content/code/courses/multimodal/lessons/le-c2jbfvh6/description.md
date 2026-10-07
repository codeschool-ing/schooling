---
title: Describing a picture in words
version: 1
---

A **vision-language model** (VLM) reads an image and a text prompt together and answers in text. It has no fixed list: it was trained on enormous numbers of pictures paired with captions and documents, and it answers in the open vocabulary of a language model. GPT-4o, Gemini and Claude all take images this way, and so do open models such as Qwen2.5-VL and Llama 3.2 Vision (lesson 11).

That one difference changes what you can ask. A detector says `book 0.51`. A VLM can be asked *"what kind of document is this, who sent it, and what is the total?"* and answer in a sentence, or in JSON. It reads text, so it does OCR's job too, and it understands layout, so it does not need to be told about rows. It can describe the cover of *Dom Casmurro*, which the detector could not name at all.

The course's vision model is `qwen2.5vl:3b`, the one `setup.sh` gave Ollama: Qwen2.5-VL with three billion parameters, small enough to answer on an ordinary computer in a minute or two. This program asks it one question about one picture. Lesson 8 takes the request apart; here only the answer matters.

`ask.py`:

```python
"""Ask the course's vision model one question about one picture, with the randomness turned down."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
kind = "png" if path.endswith(".png") else "jpeg"
picture = f"data:image/{kind};base64," + base64.b64encode(open(path, "rb").read()).decode()
reply = OpenAI().chat.completions.create(
    model="qwen2.5vl:3b", temperature=0, seed=1,
    messages=[{"role": "user", "content": [{"type": "text", "text": question},
                                           {"type": "image_url", "image_url": {"url": picture}}]}])
print(reply.choices[0].message.content)
```

```
ana@lab:~/mm$ python ask.py media/cover-b39.png "Describe this book cover."
The book cover for "Dom Casmurro" by Machado de Assis features a minimalist design with a deep navy blue background. The title "DOM CASMURRO" is prominently displayed in large, white, uppercase letters at the top of the cover. Below the title, the author's name, "Machado de Assis," is written in a smaller, white, uppercase font. 

In the center of the cover, there is a large, black rectangular shape with two gold-colored rectangles inside it, creating a striking contrast against the dark background. The gold rectangles are positioned horizontally, with the left one slightly to the left and the right one slightly to the right of the black rectangle.

At the bottom of the cover, the publisher's name, "Marginalia Classics," is written in a small, white, uppercase font. The overall design is clean and modern, with a focus on the title and author's name, making it easy to read and visually appealing.
ana@lab:~/mm$ python ask.py media/cover-b39.png "List every piece of text on the cover, exactly as written."
DOM CASMURRO
Machado de Assis
Marginalia Classics
exit 0
```

Everything in that description can be checked against what was drawn, because `make_media.py`'s `cover()` says exactly what is on the cover, shape by shape. The title, the author and the publisher's line are there, and the second question copied all three exactly, which is the easier job. The first answer did worse in three ways, and each is a kind of mistake to look for:

- **Something that is there went unsaid.** The cover has a pale moon in its top right corner, a fifth of the picture's width, and the description never mentions it.
- **Details were made up with confidence.** The letters are cream, not white; *Machado de Assis* and *Marginalia Classics* are in mixed case, not uppercase; the shop's line is a greyish blue. None of it matters much here, and all of it was stated as plainly as the parts that are right.
- **The shapes were left as shapes.** *A large, black rectangular shape with two gold-colored rectangles inside it* is accurate, and it is what the drawing is. A person would call it a house with two lit windows, which is an interpretation; the model did not offer one, and an interpretation is often what you want from a description and never what you want from extraction.

## How to check a description

A description is the hardest output in this course to verify, because it is prose and there is no single right answer. Three checks catch most of the trouble:

1. **Cross-check the facts that something else can read.** If the description quotes text, OCR the same image and compare. The title and author are on the cover; Tesseract reads them in milliseconds.
2. **Ask for what is checkable.** "List every piece of text on the cover, exactly as written" is verifiable. "Describe the mood of the cover" is not, and should never feed anything automatic.
3. **Watch for the plausible addition.** A VLM's typical error is not nonsense: it is the detail that a cover like this *usually* has. A barcode, a price, a subtitle. Anything you did not expect to be there deserves a look before it is trusted.

Lesson 8 sends pictures to the same model through OpenAI's API shape, and asks for its answer as JSON checked against a schema.
