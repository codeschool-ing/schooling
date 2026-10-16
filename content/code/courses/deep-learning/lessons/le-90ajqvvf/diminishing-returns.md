---
title: stub
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "returns.py",
  "parts": [
    {
      "code": "\"\"\"returns: what more epochs, and more data, buy lesson 9's MLP.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\n(x, y), val, _ = tdigits.load()\n\n\ndef run(images, epochs):\n    \"\"\"Lesson 9's recipe on the first `images` training images; the history of every epoch.\"\"\"\n    torch.manual_seed(0)\n    model = make_mlp()\n    opt = torch.optim.SGD(model.parameters(), lr=0.1)\n    return loop.fit(model, opt, (x[:images], y[:images]), val, epochs, every=epochs + 1)",
      "note": "Every run is lesson 9's: the same seed, SGD at 0.1, batches of 32. Only the number of training images and the number of epochs change. `digits.py` shuffled the images before splitting them, so the first 135 are a random 135. `every=epochs + 1` keeps `fit` quiet."
    },
    {
      "code": "print(\"more epochs, all 1,077 images\")\nlast = None\nfor epoch, _, val_loss, val_acc in run(1077, 128):\n    if epoch in (1, 2, 4, 8, 16, 32, 64, 128):\n        gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n        print(f\"  {epoch:3d} epochs  {epoch * 1077:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n        last = val_acc",
      "note": "One run of 128 epochs, read at every doubling. Each line has twice the arithmetic of the line above it, and the last column is what that doubling bought, in percentage points."
    },
    {
      "code": "print(\"more images, 30 epochs\")\nlast = None\nfor images in (135, 270, 540, 1077):\n    val_acc = run(images, 30)[-1][3]\n    gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n    print(f\"  {images:4d} images  {images * 30:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n    last = val_acc\n\nprint(\"the same arithmetic as 1,077 images for 30 epochs, spent on fewer images\")\nfor images, epochs in ((270, 120), (135, 240)):\n    print(f\"  {images:4d} images for {epochs} epochs: val acc {run(images, epochs)[-1][3]:.3f}\")",
      "note": "Then the other way to spend more: the same 30 epochs on twice as many images each time. The last two runs spend exactly the arithmetic of the full run, 1,077 images for 30 epochs, on a quarter and an eighth of the images, going round them more often."
    }
  ]
}
```
