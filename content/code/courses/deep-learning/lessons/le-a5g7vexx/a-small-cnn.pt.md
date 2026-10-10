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

Uma comparação com a rede densa da aula 9 só vale alguma coisa se as duas forem treinadas do mesmo
jeito, e se o tamanho da rede não estiver fazendo o trabalho. Por isso o programa abaixo treina três: a
da aula 9, uma densa alargada até ter mais ou menos tantos parâmetros quanto a convolucional, e o
`cnn.py`. Ele precisa do `digits.py` da aula 1 e do `tdigits.py` e do `loop.py` da aula 9 ao lado. O
`tdigits.load(images=True)` entrega as mesmas imagens como grades 1 por 8 por 8 em vez de filas de 64.
Salve como `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: lesson 9's dense network, a wider one, and cnn.py, trained the same way on the same digits.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits"
    },
    {
      "code": "def run(name, make, images):\n    torch.manual_seed(0)\n    model = make()\n    train, val, _ = tdigits.load(images=images)\n    print(f\"{name}: {sum(p.numel() for p in model.parameters())} parameters\")\n    loop.fit(model, torch.optim.Adam(model.parameters(), lr=1e-3), train, val, epochs=30, every=10)\n    return model",
      "note": "Uma receita para as três: a mesma semente antes de os pesos serem criados, a mesma divisão, Adam a 0,001, lotes de 32, 30 épocas. `images` diz se os dígitos chegam como filas de 64 ou como grades 1 por 8 por 8."
    },
    {
      "code": "run(\"dense, lesson 9\", lambda: nn.Sequential(nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, 10)), False)\nrun(\"dense, 512 wide\", lambda: nn.Sequential(nn.Linear(64, 512), nn.ReLU(), nn.Linear(512, 10)), False)",
      "note": "A rede da aula 9 como era, e a mesma forma com 512 unidades ocultas em vez de 64, o que lhe dá mais ou menos tantos parâmetros quanto a rede convolucional."
    },
    {
      "code": "net = run(\"convolutional\", cnn.make_cnn, True)\nprint(sum(p.numel() for p in net[:4].parameters()), \"of them in the two convolutions\")\ntorch.save(net.state_dict(), \"cnn.pt\")",
      "note": "`net[:4]` são as quatro primeiras camadas, as duas convoluções e os seus ReLUs. Os pesos treinados são salvos para a última seção."
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

**Contra a rede da aula 9, a convolucional ganha com folga**: 0,983 no conjunto de validação contra
0,953, e já estava em 0,953 na época 10. Mas ela tem 38.282 parâmetros contra 4.810 da densa, e essa
diferença sozinha poderia explicar o resultado.

**A rede densa mais larga responde a isso, e tira a maior parte da diferença.** Com 38.410 parâmetros, mais ou
menos o mesmo orçamento, ela chega a 0,978. Nesses dígitos, a maior parte dos três pontos veio do
tamanho, e o que sobra para a convolução é meio ponto, com uma execução de cada. A perda de validação
dela ainda é a menor das três, 0,0633 contra 0,0742, então a rede convolucional também é a mais
confiante quando acerta; mas uma diferença tão pequena cabe no que outra semente poderia mover, e a
aula 18 trata de separar uma coisa da outra.

O motivo é o tamanho da imagem. **Um dígito 8 por 8 tem 64 pixels, poucos o bastante para uma camada
densa bancar um peso de cada um deles para cada unidade**, e as formas que ela precisa aprender têm
poucos lugares onde ficar. A seção sobre canais mostrou onde isso acaba: numa fotografia 224 por 224, a
camada densa custa 120.847.089.664 parâmetros e a convolução 448. A convolução se paga à medida que as
imagens crescem, e é por isso que as redes da aula 12 são convolucionais; aqui ela já empata com uma
rede densa do seu tamanho tendo só 4.800 parâmetros na parte que olha a imagem.

Mais uma coisa a notar na transcrição: a perda de treino da rede convolucional caiu para 0,0070, muito
abaixo da perda de validação. Ela quase decorou as 1.077 imagens de treino, que é o assunto da aula 7.
