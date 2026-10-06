---
title: Finding objects: boxes, classes and scores
version: 1
---

An **object detector** answers a different question from OCR: *what is in this picture, and where?* For each thing it finds it returns a box, a label and a score. MediaPipe's detector with the EfficientDet-Lite0 model is small (14 MB in the lab) and fast enough for a phone:

```python
"""Every object MediaPipe's detector reports above a threshold, with its box in pixels."""
import sys

import mediapipe as mp

import mmlab

threshold = float(sys.argv[1])
with mmlab.detector(score=threshold) as det:
    for path in sys.argv[2:]:
        found = det.detect(mp.Image.create_from_file(path)).detections
        print(f"{path}: {len(found)} above {threshold}")
        for d in found:
            c, b = d.categories[0], d.bounding_box
            print(f"  {c.category_name:10} {c.score:.2f}  x={b.origin_x} y={b.origin_y} w={b.width} h={b.height}")
```

```
ana@lab:~/mm$ python detect.py 0.3 media/cat_and_dog.jpg media/cover-b39.png media/invoice-0931.png 2>/dev/null
media/cat_and_dog.jpg: 2 above 0.3
  cat        0.78  x=72 y=162 w=252 h=191
  dog        0.76  x=303 y=27 w=249 h=345
media/cover-b39.png: 0 above 0.3
media/invoice-0931.png: 1 above 0.3
  book       0.51  x=0 y=0 w=1239 h=1754
ana@lab:~/mm$ python detect.py 0.05 media/cat_and_dog.jpg media/cover-b39.png 2>/dev/null
media/cat_and_dog.jpg: 2 above 0.05
  cat        0.78  x=72 y=162 w=252 h=191
  dog        0.76  x=303 y=27 w=249 h=345
media/cover-b39.png: 0 above 0.05
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"The frame of the photograph cat_and_dog.jpg, 640 by 416 pixels, with the two boxes the detector returned drawn to scale: a box labelled cat 0.78 from x 72 to 324 and y 162 to 353, low on the left, and a box labelled dog 0.76 from x 303 to 552 and y 27 to 372, tall on the right. The two boxes overlap a little. The photograph itself is not reproduced.\"><rect x=\"40\" y=\"20\" width=\"480.0\" height=\"312.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"346.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">640 x 416</text><rect x=\"94.0\" y=\"141.5\" width=\"189.0\" height=\"143.25\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"100.0\" y=\"153.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cat 0.78</text><rect x=\"267.25\" y=\"40.25\" width=\"186.75\" height=\"258.75\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"273.25\" y=\"52.25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">dog 0.76</text><text x=\"46\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(0, 0)</text><text x=\"540\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A box is four numbers:</text><text x=\"540\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">where it starts, x and y,</text><text x=\"540\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and its width and height,</text><text x=\"540\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the image's pixels.</text><text x=\"540\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">The label is one of 80</text><text x=\"540\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">classes from COCO.</text><text x=\"540\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">The score is how sure</text><text x=\"540\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the model is, not how</text><text x=\"540\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">right it is.</text></svg>", "caption": "What a detector returns: where, what, and how sure. Nothing about the photograph beyond that."}
```

On the photograph it is good: a cat and a dog, each with a box that fits, both scored above 0.75. On the lab's two drawings it shows what it is.

**The cover of *Dom Casmurro* got nothing**, even with the threshold lowered to 0.05. The cover is flat colour, a moon and a window. The model was trained on photographs, and a flat drawing of a window is not something it ever learned to call anything.

**The invoice got `book`, at 0.51, with a box the size of the whole page.** The detector has a fixed list of things it can say, and every answer is one of them:

```
ana@lab:~/mm$ unzip -p /opt/multimodal/share/efficientdet_lite0.tflite labels.txt | grep -vc "^???"
80
ana@lab:~/mm$ unzip -p /opt/multimodal/share/efficientdet_lite0.tflite labels.txt | grep -v "^???" | sed -n "62,76p" | tr "\n" " "; echo
toilet tv laptop mouse remote keyboard cell phone microwave oven toaster sink refrigerator book clock vase 
```

Eighty classes, from the COCO dataset it was trained on: people, vehicles, animals, kitchen things, furniture, and a handful of objects like `book`, `clock` and `vase`. There is no `invoice`, `document`, `page` or `paper`. When the detector meets a page of text, the nearest thing it knows is a book, and it says so with middling confidence.

This is called a **closed vocabulary**, and it is the defining limit of a classic detector. It does not know that it does not know. A score of 0.51 means the model's internal evidence for `book` was moderate. It does not mean "probably a book", and certainly not "a 51% chance this is a book". Scores are useful for ranking one model's answers against each other, and the threshold you keep is a decision you test on your own pictures.

## When a detector is the right tool

When the classes you care about are in its list, or you can train it on yours (MediaPipe's Model Maker retrains this model on pictures you label), a detector is cheap, fast, runs on the device and returns geometry. You get *where*, which a sentence from a vision-language model does not give you in a form a program can use. Counting people in a queue, finding the product in a customer's photo before cropping it, blurring every face before an image is stored: all of these are detector jobs.

When the question is open (*what is wrong with this book?*) the closed list is the wrong instrument, and the next section is about the instrument with no list.
