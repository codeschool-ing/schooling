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
      "note": "Toda execução é a da aula 9: a mesma semente, SGD a 0,1, lotes de 32. Só mudam o número de imagens de treino e o número de épocas. O `digits.py` embaralhou as imagens antes de dividi-las, então as 135 primeiras são 135 ao acaso. `every=epochs + 1` deixa o `fit` calado."
    },
    {
      "code": "print(\"more epochs, all 1,077 images\")\nlast = None\nfor epoch, _, val_loss, val_acc in run(1077, 128):\n    if epoch in (1, 2, 4, 8, 16, 32, 64, 128):\n        gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n        print(f\"  {epoch:3d} epochs  {epoch * 1077:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n        last = val_acc",
      "note": "Uma execução de 128 épocas, lida a cada duplicação. Cada linha tem o dobro da aritmética da linha de cima, e a última coluna é o que essa duplicação comprou, em pontos percentuais."
    },
    {
      "code": "print(\"more images, 30 epochs\")\nlast = None\nfor images in (135, 270, 540, 1077):\n    val_acc = run(images, 30)[-1][3]\n    gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n    print(f\"  {images:4d} images  {images * 30:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n    last = val_acc\n\nprint(\"the same arithmetic as 1,077 images for 30 epochs, spent on fewer images\")\nfor images, epochs in ((270, 120), (135, 240)):\n    print(f\"  {images:4d} images for {epochs} epochs: val acc {run(images, epochs)[-1][3]:.3f}\")",
      "note": "Depois o outro jeito de gastar mais: as mesmas 30 épocas sobre o dobro de imagens a cada vez. As duas últimas execuções gastam exatamente a aritmética da execução completa, 1.077 imagens por 30 épocas, num quarto e num oitavo das imagens, passando por elas mais vezes."
    }
  ]
}
```
