---
title: dataset
version: 1
---

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
