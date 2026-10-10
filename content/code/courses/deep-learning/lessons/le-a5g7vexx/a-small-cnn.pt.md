---
title: Uma pequena rede convolucional contra a da aula 9
version: 1
---

As peças agora se encaixam numa dúzia de linhas. **Este é o `cnn.py`**, a rede que o resto desta aula
treina e à qual as aulas 12, 13, 17 e 19 voltam. Salve-o como `~/dl/cnn.py`:

```schooling-example
{
  "language": "python",
  "file": "cnn.py",
  "parts": [
    {
      "code": "\"\"\"cnn: a small convolutional network for 1x8x8 digits.\"\"\"\nimport torch.nn as nn",
      "note": "A rede de que as aulas 12, 13, 17 e 19 partem. É uma função que monta uma nova, então cada aula recebe pesos novos."
    },
    {
      "code": "def make_cnn(classes=10):\n    return nn.Sequential(\n        nn.Conv2d(1, 16, kernel_size=3, padding=1),   # 16 x 8 x 8\n        nn.ReLU(),\n        nn.Conv2d(16, 32, kernel_size=3, padding=1),  # 32 x 8 x 8\n        nn.ReLU(),\n        nn.MaxPool2d(2),                              # 32 x 4 x 4\n        nn.Flatten(),                                 # 512\n        nn.Linear(512, 64),\n        nn.ReLU(),\n        nn.Linear(64, classes),\n    )",
      "note": "Duas convoluções com um ReLU depois de cada uma, depois um max pooling, e os comentários dizem a forma do que sai de cada linha. O `Flatten` estende os 32 mapas de 4 por 4 em 512 números numa fila, e dali em diante é a rede densa da aula 9 com uma entrada mais larga. `classes` vale 10 para os dígitos e muda quando a aula 13 treina com cinco deles."
    }
  ]
}
```

O PyTorch descreve um modelo quando ele é impresso, e a descrição é um jeito rápido de conferir que as
camadas são as que você quis:

```
ana@vm:~/dl$ python -c "import cnn; print(cnn.make_cnn())"
Sequential(
  (0): Conv2d(1, 16, kernel_size=(3, 3), stride=(1, 1), padding=(1, 1))
  (1): ReLU()
  (2): Conv2d(16, 32, kernel_size=(3, 3), stride=(1, 1), padding=(1, 1))
  (3): ReLU()
  (4): MaxPool2d(kernel_size=2, stride=2, padding=0, dilation=1, ceil_mode=False)
  (5): Flatten(start_dim=1, end_dim=-1)
  (6): Linear(in_features=512, out_features=64, bias=True)
  (7): ReLU()
  (8): Linear(in_features=64, out_features=10, bias=True)
)
```

Para compará-la de forma justa com a rede densa da aula 9, treine as duas do mesmo jeito: a mesma
divisão, a mesma semente, Adam a 0,001, lotes de 32, 30 épocas. O programa precisa do `digits.py` da
aula 1 e do `tdigits.py` e do `loop.py` da aula 9 ao lado. O `tdigits.load(images=True)` entrega as
mesmas imagens como grades 1 por 8 por 8 em vez de filas de 64. Salve como `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: lesson 9's dense network against cnn.py, trained the same way on the same digits.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n\ndef count(model):\n    return sum(p.numel() for p in model.parameters())"
    },
    {
      "code": "torch.manual_seed(0)\nmlp = nn.Sequential(nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, 10))\ntrain, val, _ = tdigits.load()\nprint(f\"dense: {count(mlp)} parameters\")\nloop.fit(mlp, torch.optim.Adam(mlp.parameters(), lr=1e-3), train, val, epochs=30, every=10)",
      "note": "A rede da aula 9 como era: 64 pixels numa fila, 64 unidades ocultas, 10 saídas, Adam a 0,001."
    },
    {
      "code": "torch.manual_seed(0)\nnet = cnn.make_cnn()\ntrain, val, _ = tdigits.load(images=True)\nprint(f\"convolutional: {count(net)} parameters, {count(net[:4])} of them in the two convolutions\")\nloop.fit(net, torch.optim.Adam(net.parameters(), lr=1e-3), train, val, epochs=30, every=10)\ntorch.save(net.state_dict(), \"cnn.pt\")",
      "note": "As mesmas imagens como grades 1 por 8 por 8, a mesma semente, otimizador, taxa, tamanho de lote e épocas. `net[:4]` são as quatro primeiras camadas, as duas convoluções e os seus ReLUs. Os pesos treinados são salvos para a última seção."
    }
  ]
}
```

```
ana@vm:~/dl$ python compare.py
dense: 4810 parameters
epoch  10  train loss 0.3627  val loss 0.3510  val acc 0.922
epoch  20  train loss 0.1724  val loss 0.1889  val acc 0.944
epoch  30  train loss 0.1177  val loss 0.1471  val acc 0.953
convolutional: 38282 parameters, 4800 of them in the two convolutions
epoch  10  train loss 0.0985  val loss 0.1518  val acc 0.953
epoch  20  train loss 0.0180  val loss 0.0757  val acc 0.978
epoch  30  train loss 0.0070  val loss 0.0633  val acc 0.983
```

**A rede convolucional termina em 0,983 no conjunto de validação, contra 0,953 da densa**, e já estava
em 0,953 na época 10. A perda de validação dela, 0,0633, é menos da metade dos 0,1471 da rede densa.

As contagens de parâmetros merecem uma leitura cuidadosa, porque a rede convolucional tem 38.282 e a
densa 4.810, quase oito vezes menos. **A maior parte da diferença não está nas convoluções.** As duas
convoluções têm 4.800 parâmetros, mais ou menos o orçamento inteiro da rede densa; os outros 33.482
ficam nas camadas densas depois do `Flatten`, a maioria na `Linear(512, 64)`. O ganho veio de para onde
os parâmetros olham, não de haver mais deles.

Duas cautelas antes de ler mais do que isso. **É uma semente para cada rede**, e uma diferença de três
pontos entre execuções isoladas pode encolher ou crescer com outra; a aula 18 pergunta se uma diferença
é maior que a dispersão entre sementes. E a perda de treino da rede convolucional caiu para 0,0070,
muito abaixo da perda de validação: ela quase decorou as 1.077 imagens de treino, que é o assunto da
aula 7.
