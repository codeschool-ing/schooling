---
title: a-slow-transform
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "warp.py",
  "parts": [
    {
      "code": "\"\"\"warp: a transform that costs real work for every image read, as decoding and augmenting a photograph does.\"\"\"\nimport torch\nimport torch.nn.functional as F",
      "note": "Tudo aqui é aritmética comum de tensores, do `torch.nn.functional`: nenhuma biblioteca de transformações de imagem, e nada de dormir para fingir um custo."
    },
    {
      "code": "class Warp:\n    \"\"\"Turn a flat 8x8 digit into a 32x32 image, bent by a smooth random field, with noise added.\"\"\"\n\n    def __init__(self, size=32, work=128, strength=0.08, noise=0.05):\n        self.size, self.work, self.strength, self.noise = size, work, strength, noise\n        self.base = F.affine_grid(torch.eye(2, 3)[None], [1, 1, work, work], align_corners=False)\n\n    def __call__(self, img):\n        w = self.work\n        big = F.interpolate(img.reshape(1, 1, 8, 8), size=(w, w), mode=\"bicubic\", align_corners=False)\n        field = F.interpolate(2 * torch.rand(1, 2, 4, 4) - 1, size=(w, w), mode=\"bicubic\", align_corners=False)\n        bent = F.grid_sample(big, self.base + self.strength * field.permute(0, 2, 3, 1),\n                             mode=\"bicubic\", align_corners=False)\n        small = F.interpolate(bent, size=(self.size, self.size), mode=\"bilinear\", antialias=True, align_corners=False)\n        return small[0] + self.noise * torch.randn(1, self.size, self.size)",
      "note": "Quatro passos para cada imagem. Ampliar o dígito 8x8 para 128x128 por interpolação bicúbica; fazer um campo aleatório suave a partir de números aleatórios 4x4; mover cada pixel ao longo desse campo com o `grid_sample`, que entorta os traços como duas pessoas escrevem um mesmo dígito de jeitos diferentes; reduzir o resultado para 32x32 com antialiasing e somar um pouco de ruído. Trabalhar em 128 e reduzir é o que um pipeline de verdade faz com uma foto grande, e é daí que vem o custo."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "slow.py",
  "parts": [
    {
      "code": "\"\"\"slow: what the warp costs per image against a plain read, and what it makes of digit 0.\"\"\"\nimport time\n\nimport torch\n\nfrom dset import Digits\nfrom warp import Warp\n\ntorch.manual_seed(0)\nplain, warped = Digits(\"train\"), Digits(\"train\", transform=Warp())\nfor name, ds in ((\"plain\", plain), (\"warped\", warped)):\n    start = time.perf_counter()\n    for i in range(len(ds)):\n        ds[i]\n    per = (time.perf_counter() - start) / len(ds)\n    print(f\"{name:6s} {per * 1e6:7.1f} microseconds an image, {per * len(ds):.3f} s for all {len(ds)}\")",
      "note": "Cada item do conjunto de treino lido uma vez, com e sem a transformação, cronometrado com `time.perf_counter`. Ler um item simples é indexar dois tensores que já estão na memória."
    },
    {
      "code": "img, label = warped[0]\nprint(\"item 0:\", tuple(img.shape), \" label\", label.item(), \" read again, same image:\", torch.equal(img, warped[0][0]))",
      "note": "O mesmo índice lido duas vezes. A transformação roda a cada leitura e sorteia números aleatórios novos toda vez."
    },
    {
      "code": "RAMP = \" .:-=+*#%@\"\n\n\ndef rows(picture):\n    \"\"\"A 32x32 picture as 16 lines of characters, two pixel rows to a line.\"\"\"\n    shades = picture.reshape(16, 2, 32).mean(dim=1).clamp(0, 1)\n    return [\"\".join(RAMP[int(v * 9.99)] for v in row) for row in shades]",
      "note": "Uma figura no terminal: cada brilho de 0 a 1 vira um de dez caracteres, de um espaço até `@`. Duas linhas de pixels dividem uma linha de texto porque um caractere tem quase o dobro de altura que de largura."
    },
    {
      "code": "original = plain[0][0].reshape(8, 8).repeat_interleave(4, dim=0).repeat_interleave(4, dim=1)\npanels = [rows(original), rows(warped[0][0][0]), rows(warped[0][0][0])]\nfor line in zip(*panels):\n    print(\"  \".join(line))",
      "note": "Três painéis lado a lado: o dígito 8x8 original com cada pixel repetido quatro vezes, depois duas leituras do mesmo item entortado."
    }
  ]
}
```
