---
title: A Dataset answers one question
version: 1
---

Lesson 9's `fit` held the whole training set as two tensors and cut batches out of them with
`order[start:start + batch_size]`. That works for 1,077 images of 64 `float32` numbers each, which
come to 275,712 bytes. **It stops working the day the data is a folder of photographs**:
a million files do not fit in memory, each one has to be opened and decoded, and most training
programs also change every image a little before using it.

PyTorch splits that work in two. A **`Dataset`** knows how many items there are and how to produce
item number `i`, and nothing else. A **`DataLoader`**, the next section's subject, decides which
items go together, in what order, and who does the work. The dataset does not know about batches,
and the loader does not know about files.

Here is the digits set as a dataset. Save it as `~/dl/dset.py`; it reads its numbers through the
`tdigits.py` from lesson 9, and every program in this lesson imports it:

```schooling-example
{
  "language": "python",
  "file": "dset.py",
  "parts": [
    {
      "code": "\"\"\"dset: lesson 1's digits as a PyTorch Dataset, with an optional transform applied to each image as it is read.\"\"\"\nfrom torch.utils.data import Dataset\n\nimport tdigits",
      "note": "A `Dataset` is the class PyTorch's loader knows how to read. This one takes its numbers from `tdigits.py`, the module lesson 9 showed, so the images are the same 1,077, 360 and 360."
    },
    {
      "code": "class Digits(Dataset):\n    def __init__(self, split=\"train\", transform=None):\n        sets = dict(zip((\"train\", \"val\", \"test\"), tdigits.load()))\n        self.x, self.y = sets[split]\n        self.transform = transform\n\n    def __len__(self):\n        return len(self.y)\n\n    def __getitem__(self, i):\n        img = self.x[i]\n        if self.transform is not None:\n            img = self.transform(img)\n        return img, self.y[i]",
      "note": "Two methods make a dataset: `__len__` says how many items there are, and `__getitem__` hands back item `i` as an (image, label) pair. The transform, when there is one, runs inside `__getitem__`, once for every image every time it is read."
    }
  ]
}
```

**Two methods are the whole contract.** `__len__` returns 1,077 for the training set, and
`__getitem__(i)` returns one image and its label. Where the item comes from is the dataset's own
business: here it is a row of a tensor already in memory, and in a folder of photographs it would
be a file opened and decoded on the spot. The `transform` argument is the place for work done to
each image as it is read, and the section on a slow transform fills it.

Then read it by hand, the way a loader will. Save as `~/dl/firstset.py`:

```schooling-example
{
  "language": "python",
  "file": "firstset.py",
  "parts": [
    {
      "code": "\"\"\"firstset: the Dataset read by hand, one item at a time, the way a DataLoader reads it.\"\"\"\nimport torch\nfrom torch.utils.data import TensorDataset\n\nimport tdigits\nfrom dset import Digits",
      "note": "`TensorDataset` is PyTorch's own dataset for tensors already in memory. It is here to be compared with `Digits`."
    },
    {
      "code": "train = Digits(\"train\")\nimg, label = train[0]\nprint(\"length:\", len(train), \" item 0:\", tuple(img.shape), img.dtype, \" label\", label.item())\nx, y = tdigits.load()[0]\nsame = TensorDataset(x, y)\nprint(\"TensorDataset:\", len(same), \" same item 0:\", torch.equal(same[0][0], img))",
      "note": "`len(train)` calls `__len__`, and `train[0]` calls `__getitem__(0)`. The item is one image of 64 pixels and its label, not a batch."
    },
    {
      "code": "try:\n    train[1077]\nexcept IndexError as e:\n    print(\"item 1077:\", e)",
      "note": "Asking past the end raises `IndexError`, which is what a Python sequence does too."
    }
  ]
}
```

```
ana@vm:~/dl$ python firstset.py
length: 1077  item 0: (64,) torch.float32  label 6
TensorDataset: 1077  same item 0: True
item 1077: index 1077 is out of bounds for dimension 0 with size 1077
```

Item 0 is one image of 64 pixels, `float32`, with the label 6: one item, not a batch. PyTorch's own
`TensorDataset` wraps tensors that are already in memory, and its item 0 is the same image, so for
data like the digits a class of your own buys nothing yet. It starts paying for itself when
`__getitem__` has work to do. Asking for item 1077 raises `IndexError`, as a list would.

This kind of dataset is called **map-style**: any index, in any order. PyTorch also has an
`IterableDataset` that only hands out items one after another, for data that arrives as a stream
and cannot be indexed. Everything in this course is map-style.
