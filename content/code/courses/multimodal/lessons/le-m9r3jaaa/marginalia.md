---
title: Five jobs at Marginalia
version: 1
---

The shop this course works for is Marginalia, the online bookshop whose help centre was searched by meaning in `embeddings-vectors`, answered from in `rag` and handed to an agent in `agents-mcp`. It does not exist, and its media is made by a program in this lesson. It has five jobs that a person does today and that a multimodal model could take over, and they are the course's thread.

| the job | today | the lessons |
|---|---|---|
| read supplier invoices into the stock system | somebody types them | 2 and 8 |
| keep a searchable record of support calls | nobody does; the calls are lost | 5, 7 and 10 |
| caption and describe the "how to return a book" video | not done, which shuts out deaf and blind customers | 4 and 14 |
| make banners for the weekly newsletter | a freelancer, when there is budget | 3 and 9 |
| answer the phone with order status | the same person who answers the e-mail | 6 |

Here is a first taste of three of them, each from a real model running on your machine. The first eight seconds of a support call, through Whisper; the invoice, through Tesseract; and a photograph and the invoice, through MediaPipe's object detector. Two short programs, and the third reader is the `tesseract` command itself.

`listen.py`, Whisper:

```python
"""The first eight seconds of the support call, through Whisper base."""
import mmlab

samples = mmlab.read_audio("media/call-1042.wav")
text, lang = mmlab.transcribe(mmlab.whisper("base"), samples[: 8 * mmlab.RATE])
print(lang, "|", text)
```

`look.py`, the detector:

```python
"""What MediaPipe's object detector finds in each picture named on the command line."""
import sys

import mediapipe as mp

import mmlab

with mmlab.detector() as det:
    for path in sys.argv[1:]:
        found = det.detect(mp.Image.create_from_file(path)).detections
        print(path, [(d.categories[0].category_name, round(d.categories[0].score, 2)) for d in found] or "nothing")
```

```
ana@lab:~/mm$ python listen.py
en | Good morning, you're through to Marginalia support. My name is Kau. How can it help? Hi Kau, I'm calling about Order M.
ana@lab:~/mm$ tesseract media/invoice-0931.png - 2>/dev/null | head -4
Lantern & Quill Distributors

Rua das Palmeiras 210, Campinas SP
billing@lanternquill.example.com
ana@lab:~/mm$ python look.py media/cat_and_dog.jpg media/invoice-0931.png
INFO: Created TensorFlow Lite XNNPACK delegate for CPU.
media/cat_and_dog.jpg [('cat', 0.78), ('dog', 0.76)]
media/invoice-0931.png [('book', 0.51)]
```

Each of the three answers looks fine at a glance, and each of them is wrong somewhere.

**The transcript** gets the shop's name right and the agent's name wrong: Caio becomes *Kau*, twice. It also stops in the middle of the order number, because eight seconds ended there. Lesson 7 measures how often this happens and what to do about names.

**Tesseract** read the first lines of the invoice perfectly. That is the clean copy. The scanned one, in lesson 2, is a different story.

**The detector** found a cat and a dog in the photograph, which is what it was trained on. It also looked at an invoice and said `book`, with 51% confidence. It is not exactly wrong: the page has the titles of four books on it. But the detector only knows 80 kinds of things, and when it sees something new it reaches for whichever of them is closest. That habit has a name in lesson 2, and every model in this course has it in some form.

None of this is a reason not to use the models. It is the reason every job in the table gets measured before anyone trusts it.
