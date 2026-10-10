---
title: The real thing, with ImageNet's weights
version: 1
---

Everything above borrowed from a network this course trained itself, on 528 small images. **In
practice the body comes from somebody else, trained on millions of photographs, and you download
it.** torchvision ships the architectures and, for each one, the address of weights trained on
ImageNet: 1.28 million photographs in 1,000 classes.

This machine cannot reach the server those weights live on, so the download is shown below and
**was not run for this course**. What torchvision knows about the weights without fetching them
is real, and printing it says most of what matters. Save as `~/dl/weights.py`:

```schooling-example
{
  "language": "python",
  "file": "weights.py",
  "parts": [
    {
      "code": "\"\"\"weights: what torchvision knows about a pretrained model, without downloading it.\"\"\"\nfrom torchvision.models import ResNet18_Weights, resnet18\n\nw = ResNet18_Weights.DEFAULT\nprint(w, \"from\", w.url)",
      "note": "Every pretrained model in torchvision has an enum of weights beside it. `DEFAULT` names the best set available, and the enum carries the address of the file without fetching it."
    },
    {
      "code": "print(f\"{w.meta['num_params']:,} parameters, {w.meta['_file_size']} MB,\",\n      \"ImageNet top-1\", w.meta[\"_metrics\"][\"ImageNet-1K\"][\"acc@1\"])\nprint(len(w.meta[\"categories\"]), \"classes, the first three:\", w.meta[\"categories\"][:3])",
      "note": "The metadata that ships inside torchvision: the size, the accuracy the weights reached on ImageNet's validation set, and the names of the classes the original head was trained to tell apart."
    },
    {
      "code": "print(\"the head:\", resnet18(weights=None).fc)\nprint(w.transforms())",
      "note": "`weights=None` builds the architecture with random weights, so nothing is fetched. Its last layer is the head that a transfer replaces. `transforms()` is the preprocessing the weights were trained with."
    }
  ]
}
```

```
PENDING weights
```

Three things in that output decide how you use the file.

**The head speaks ImageNet.** `Linear(in_features=512, out_features=1000)` maps the body's 512
features to the 1,000 classes, which start with a fish, another fish and a shark. For your own
problem it goes, exactly as `transfer.py` replaced the head of `base.pt`.

**The input has to look like ImageNet's.** `ImageClassification` resizes the shorter side to 256
pixels, cuts the central 224 by 224, and normalises each colour channel with ImageNet's own mean
and standard deviation: `mean=[0.485, 0.456, 0.406]` and `std=[0.229, 0.224, 0.225]`, one number
for red, green and blue. The body learnt its filters on inputs scaled that way, and an image
scaled any other way reaches them shifted. **Always build the preprocessing from
`weights.transforms()`**, rather than writing the numbers by hand.

**The numbers in `meta` are the starting point**, not your result: 69.758% top-1 is what this file
scored on ImageNet's validation set, and a model on your images will score whatever your images
allow.

## What the transfer looks like, not run

The same feature extraction as `transfer.py`, on a pretrained ResNet-18. **Not run for this
course**: the first line downloads the 44.661 MB file from `download.pytorch.org`, which this lab
cannot reach.

```python
import torch.nn as nn
from torchvision.models import ResNet18_Weights, resnet18

weights = ResNet18_Weights.DEFAULT
model = resnet18(weights=weights)            # downloads the file once, then reads it from a cache
for p in model.parameters():
    p.requires_grad = False
model.fc = nn.Linear(model.fc.in_features, 5)   # a new head for five classes of your own

preprocess = weights.transforms()            # resize, crop, scale to [0, 1], normalise
```

The training loop that follows is the one you already have, with the photographs passed through
`preprocess`, plus any augmentation, before they reach the model. Training only `model.fc` on a
processor is practical; the forward pass through the frozen body is the slow part, and it can be
done once for every image and the 512 features kept.

**The 8 by 8 digits would be a poor fit for this body.** It expects three colour channels at 224
pixels; a digit would have to be copied into three channels and blown up 28 times, and the filters
learnt on fur, grass and windows would be looking for things the digit does not have. Borrowing
helps when the old images and the new ones share their small parts, which is why this lesson
pretrained on digits. Lesson 17 starts from `base.pt` again and asks what changes when the body is
allowed to learn too.
