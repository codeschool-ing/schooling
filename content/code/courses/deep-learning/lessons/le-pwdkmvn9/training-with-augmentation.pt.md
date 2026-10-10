---
title: Treinar com augmentation, e com a errada
version: 1
---

As duas seções anteriores dão a um programa o que ele precisa: transformações que sorteiam por
imagem, e um teste de quais delas são seguras. **Esta treina a CNN com 100 imagens quatro vezes:
uma sem augmentation, uma com a segura, e duas com as que o `preserve.py` desaconselhou.** O
`loop.fit` recebe um conjunto fixo de tensores, então o programa traz uma cópia do laço dele com uma
linha a mais. Salve como `~/dl/augtrain.py`:

```schooling-example
{
  "language": "python",
  "file": "augtrain.py",
  "parts": [
    {
      "code": "\"\"\"augtrain: the CNN on 100 training images, with four kinds of augmentation.\"\"\"\nimport torch\nimport torch.nn.functional as F\nfrom torchvision.transforms import v2\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), val, _ = tdigits.load(images=True)\nfew = torch.cat([torch.nonzero(y == d).flatten()[:10] for d in range(10)])\nx, y = x[few], y[few]",
      "note": "Dez imagens de treino de cada dígito, cem ao todo, avaliadas contra a validação inteira. A augmentation pesa mais quando faltam dados, e a aula 7 mediu o mesmo regime de 100 imagens."
    },
    {
      "code": "BILINEAR = v2.InterpolationMode.BILINEAR\nAUGMENTS = {\n    \"none\": v2.Identity(),\n    \"shift and turn\": v2.RandomAffine(degrees=15, translate=(0.125, 0.125), interpolation=BILINEAR),\n    \"mirror\": v2.RandomHorizontalFlip(),\n    \"any turn\": v2.RandomRotation(180, interpolation=BILINEAR),\n}",
      "note": "Quatro políticas. `Identity` não muda nada e é a referência. A segunda é a do `augment.py`. `RandomHorizontalFlip` espelha metade das imagens, e `RandomRotation(180)` gira cada uma por um ângulo qualquer."
    },
    {
      "code": "def fit(model, augment, epochs, seed):\n    \"\"\"loop.fit's loop, with every image of every batch augmented on its own.\"\"\"\n    opt = torch.optim.Adam(model.parameters(), lr=1e-3)\n    g = torch.Generator().manual_seed(seed)\n    for epoch in range(epochs):\n        order = torch.randperm(len(y), generator=g)\n        for start in range(0, len(y), 32):\n            idx = order[start:start + 32]\n            batch = torch.stack([augment(img) for img in x[idx]])\n            loss = F.cross_entropy(model(batch), y[idx])\n            opt.zero_grad()\n            loss.backward()\n            opt.step()\n    return loop.evaluate(model, *val)",
      "note": "O laço do `loop.py`, com uma linha a mais: cada imagem do lote passa sozinha pela transformação, então cada uma sorteia a própria mudança. A validação nunca passa por augmentation: o `loop.evaluate` lê as imagens como são."
    },
    {
      "code": "print(f\"{len(y)} training images, {len(val[1])} validation images, 150 epochs\")\nfor name, augment in AUGMENTS.items():\n    accs = []\n    for seed in (0, 1, 2):\n        torch.manual_seed(seed)\n        accs.append(fit(cnn.make_cnn(), augment, epochs=150, seed=seed)[1])\n    print(f\"{name:15s} val acc \" + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "Três sementes por política, porque com 100 imagens uma execução sozinha diz pouco. A semente fixa os pesos iniciais, a ordem dos lotes e cada sorteio das transformações."
    }
  ]
}
```

```
PENDING augtrain
```

Leia as linhas contra a primeira.

**A augmentation segura ajudou, pouco e com constância.** Sem augmentation as três sementes deram
0,886, 0,933 e 0,917; com deslocamentos e giros pequenos deram 0,931, 0,928 e 0,942. A pior execução
com augmentation fica acima da pior sem, e a dispersão encolheu. Com 100 imagens o ganho é de uns
dois pontos; uma rede que precisa aprender uma forma com dez exemplos é a que mais ganha ao ver cada
um deles em mais de uma posição.

**As duas inseguras fizeram estrago, na proporção do quanto mentiam.** Espelhar metade das imagens
levou a rede para entre 0,819 e 0,858, porque um 2, um 3 ou um 7 espelhado entrou com o próprio
rótulo. Girar por qualquer ângulo derrubou para entre 0,669 e 0,706, já que todo 6 e todo 9 foi
ensinado como os dois, e todo dígito precisou ser aprendido em toda orientação a partir de dez
exemplos.

Duas coisas que esta execução não mostra, ditas com clareza. **A augmentation não faz a rede ver as
imagens de validação de outro jeito**: a validação é lida como foi desenhada, e o ganho vem só do que
o treino aprendeu. E com as 1.077 imagens de treino a diferença seria menor, porque os dados já
trazem mais da variação que a transformação imita; é com poucos dados que a augmentation vale o que
custa.
