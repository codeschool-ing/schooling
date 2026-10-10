---
title: Tensors, and the memory behind them
version: 1
---

Eight lessons have trained networks in NumPy, writing every backward pass by hand. **PyTorch's
tensor is the NumPy array with two things added**: it knows which device holds its numbers, and it
can record the operations that made it so that their gradients can be worked out. Everything else,
the indexing, the broadcasting and the `@` for a matrix product, works the way lessons 1 to 8 used
it.

The two are close enough to cross over in one call each way, and that closeness hides the first
surprises. Save this as `~/dl/tensors.py`; it reads the data through the `digits.py` from lesson 1:

```schooling-example
{
  "language": "python",
  "file": "tensors.py",
  "parts": [
    {
      "code": "\"\"\"tensors: shape, dtype and device, the trip from NumPy and back, and a view.\"\"\"\nimport numpy as np\nimport torch\nimport torch.nn as nn\n\nimport digits\n\n(x, y), _, _ = digits.load()\nt = torch.from_numpy(x)\nlabels = torch.from_numpy(y)\nprint(\"images:\", t.shape, t.dtype, t.device)\nprint(\"labels:\", labels.shape, labels.dtype)",
      "note": "Three attributes describe every tensor: its shape, the type of its numbers, and the device that holds them. The digits arrive as lesson 1's `digits.py` made them, `float32` images and `int64` labels."
    },
    {
      "code": "print(\"from Python numbers:\", torch.tensor([1, 2]).dtype, torch.tensor([0.5, 2.0]).dtype)\nprint(\"from NumPy's default:\", torch.from_numpy(np.zeros(3)).dtype)\ntry:\n    nn.Linear(3, 2)(torch.from_numpy(np.zeros((1, 3))))\nexcept RuntimeError as e:\n    print(\"float64 into a layer:\", e)",
      "note": "PyTorch's own default for a decimal is `float32`, while NumPy's is `float64`, and `from_numpy` keeps whatever NumPy had. A layer's weights are `float32`, and it refuses to multiply them by anything else."
    },
    {
      "code": "x[0, 3] = 7.0\nprint(\"changed in NumPy, read from the tensor:\", t[0, 3].item())\ncopy = torch.tensor(x)\nx[0, 3] = 0.0\nprint(\"the tensor:\", t[0, 3].item(), \" the copy:\", copy[0, 3].item())",
      "note": "`from_numpy` does not copy: the array and the tensor are two names for the same memory, so a change through one is seen through the other. `torch.tensor` makes a copy that goes its own way."
    },
    {
      "code": "img = t[0].view(8, 8)\nprint(\"view\", tuple(img.shape), \" same memory:\", img.data_ptr() == t.data_ptr())\nprint(\"strides of t:\", t.stride(), \" of t.T:\", t.T.stride(), \" t.T contiguous:\", t.T.is_contiguous())\ntry:\n    t.T.view(-1)\nexcept RuntimeError as e:\n    print(\"view of t.T:\", str(e).split(\" (\")[0])\nprint(\"reshape of t.T, same memory:\", t.T.reshape(-1).data_ptr() == t.data_ptr())",
      "note": "A view is a new shape over the same numbers. The stride says how many numbers to skip for one step along each dimension; a transpose only swaps the strides, and a row of the result is no longer one stretch of memory, so `view` refuses it and `reshape` copies."
    },
    {
      "code": "device = \"cuda\" if torch.cuda.is_available() else \"cpu\"\nprint(\"device:\", device, \" moved:\", t.to(device).device)",
      "note": "The usual line at the top of a training program: use the graphics card if there is one. On this machine there is none, and `.to(\"cpu\")` on a tensor already there returns it unchanged."
    }
  ]
}
```

```
PENDING tensors
```

## Three attributes

**Shape, dtype and device are the first three things to print when something does not fit.** The
images are `[1077, 64]` and `float32`, the labels `[1077]` and `int64`, and both live on the `cpu`.
The labels are integers on purpose: the loss reads them as class numbers, one per image, as lesson
4's cross-entropy did.

The dtype is where NumPy and PyTorch disagree. A Python decimal becomes `float32` in PyTorch and
`float64` in NumPy, and `from_numpy` keeps NumPy's choice, so an array built with `np.zeros` arrives
as `float64`. A layer's weights are `float32`, and the product refuses to mix them:
`mat1 and mat2 must have the same dtype, but got Double and Float`. `digits.py` converted with
`astype(np.float32)` in lesson 1, which is why the digits never meet this error. Data from anywhere
else needs the same conversion, or `.float()` on the tensor.

## One block of memory, several names

**`torch.from_numpy` does not copy.** The tensor and the array share their memory, so the 7.0
written into the array was read back from the tensor. `torch.tensor(x)` copies, and the copy kept
its 7.0 when the array was set back to zero.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" aria-label=\"A NumPy array x, the tensor t made from it with from_numpy, and the 8 by 8 view of t&#x27;s first row all point at one block of memory. A tensor made with torch.tensor points at a second block of its own.\"><rect x=\"20\" y=\"20\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">x</text><text x=\"196\" y=\"36\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(1077, 64)</text><text x=\"36\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">NumPy array</text><path d=\"M210 44 L318 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M310.0 91.9 L318 92 L312.5 86.2\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"20\" y=\"82\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">t</text><text x=\"196\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(1077, 64)</text><text x=\"36\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tensor</text><path d=\"M210 106 L318 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M311.1 96.0 L318 92 L310.3 89.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"20\" y=\"144\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">img</text><text x=\"196\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(8, 8)</text><text x=\"36\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">view of image 0</text><path d=\"M210 168 L318 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M313.8 98.8 L318 92 L310.2 93.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"320\" y=\"50\" width=\"340\" height=\"84\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M362.5 50 L362.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M405.0 50 L405.0 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M447.5 50 L447.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M490.0 50 L490.0 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M532.5 50 L532.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M575.0 50 L575.0 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M617.5 50 L617.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"490\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one block of memory: 1,077 × 64 float32 numbers</text><text x=\"490\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">same numbers, no copy</text><rect x=\"20\" y=\"186\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\">copy</text><text x=\"196\" y=\"202\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(1077, 64)</text><text x=\"36\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">torch.tensor(x)</text><path d=\"M210 210 L318 210\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M310.6 213.1 L318 210 L310.6 206.9\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"320\" y=\"190\" width=\"340\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a copy, its own memory</text></svg>", "caption": "Three names, one block of memory. A change made through any of them is seen through the other two; only `torch.tensor` makes a block of its own."}
```

A view goes one step further: the same numbers under a different shape. `t[0].view(8, 8)` is the
first image as a grid, and its memory starts where `t`'s does. Two numbers per dimension make this
possible, the size and the stride, which says how far to jump in memory for one step along that
dimension. `t` has strides `(64, 1)`: 64 numbers to the next image, 1 to the next pixel.

A transpose is also a view: it swaps the strides to `(1, 64)` and moves nothing. The price is that
a row of `t.T` is no longer one stretch of memory, which PyTorch calls not contiguous, and `view`
refuses to flatten it. `reshape` does the same job and copies when it has to, which is why its
result does not share `t`'s memory. **Sharing is what makes a view free, and it is also why writing
through one changes the others**, as the 7.0 did.

## The device

The last line is the one every training program starts with, picking the graphics card when there
is one. There is none here, so the answer is `cpu`. Asking for a card anyway fails at once:

```
PENDING cuda
```

On a machine with an NVIDIA card and its driver, the same line puts the tensor in the card's memory,
and every operation on it runs there. A model and its data have to be on the same device, and
moving them is lesson 10's subject. This course runs everything on the processor.
