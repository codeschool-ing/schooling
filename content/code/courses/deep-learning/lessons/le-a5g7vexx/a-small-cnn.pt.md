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
jeito, e se o tamanho da rede não estiver fazendo o trabalho. Por isso o programa abaixo treina três,
todas com a receita da aula 9: a da própria aula 9, do seu `mlp.py`; a mesma função pedindo 512
unidades ocultas, o que dá mais ou menos tantos parâmetros quanto a rede convolucional; e o `cnn.py`.
Ele precisa do `digits.py` da aula 1 e do `tdigits.py`, do `loop.py` e do `mlp.py` da aula 9 ao lado.
O `tdigits.load(images=True)` entrega as mesmas imagens como grades 1 por 8 por 8 em vez de filas de
64. Salve como `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: lesson 9's dense network, a wider one, and cnn.py, trained the same way on the same digits.\"\"\"\nimport torch\n\nimport cnn\nimport loop\nimport tdigits\nfrom mlp import make_mlp"
    },
    {
      "code": "def run(name, make, images):\n    torch.manual_seed(0)\n    model = make()\n    train, val, _ = tdigits.load(images=images)\n    print(f\"{name}: {sum(p.numel() for p in model.parameters())} parameters\")\n    loop.fit(model, torch.optim.SGD(model.parameters(), lr=0.1), train, val, epochs=30, every=10)\n    return model",
      "note": "Uma receita para as três, a da aula 9: a mesma semente antes de os pesos serem criados, a mesma divisão, SGD a 0,1, lotes de 32, 30 épocas. `images` diz se os dígitos chegam como filas de 64 ou como grades 1 por 8 por 8."
    },
    {
      "code": "run(\"dense, lesson 9\", make_mlp, False)\nrun(\"dense, 512 wide\", lambda: make_mlp(512), False)",
      "note": "A rede da aula 9 como era, com 32 unidades ocultas, e a mesma função pedindo 512, o que lhe dá mais ou menos tantos parâmetros quanto a rede convolucional."
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
dense, lesson 9: 2410 parameters
epoch  10  train loss 0.3170  val loss 0.3068  val acc 0.922
epoch  20  train loss 0.1661  val loss 0.2004  val acc 0.936
epoch  30  train loss 0.1205  val loss 0.1461  val acc 0.950
dense, 512 wide: 38410 parameters
epoch  10  train loss 0.2126  val loss 0.2165  val acc 0.936
epoch  20  train loss 0.1238  val loss 0.1642  val acc 0.944
epoch  30  train loss 0.0921  val loss 0.1223  val acc 0.961
convolutional: 38282 parameters
epoch  10  train loss 0.1558  val loss 0.1291  val acc 0.969
epoch  20  train loss 0.0249  val loss 0.1526  val acc 0.947
epoch  30  train loss 0.0055  val loss 0.0776  val acc 0.978
4800 of them in the two convolutions
```

A primeira rede termina exatamente onde a aula 9 a deixou, 0,950 no conjunto de validação, e essa é a
conferência de que a receita é a mesma. **Contra ela, a rede convolucional ganha com folga, com
0,978.** Mas ela tem 38.282 parâmetros contra 2.410 da densa, quase dezesseis vezes mais, e essa
diferença sozinha poderia explicar o resultado.

**A rede densa mais larga responde a isso.** Com 38.410 parâmetros, mais ou menos o mesmo orçamento,
ela chega a 0,961, com perda de validação de 0,1223 contra 0,0776 da rede convolucional. Então, dos 2,8
pontos entre a primeira e a última rede, o tamanho comprou 1,1 e a convolução os outros 1,7. Isso com
uma execução de cada, e a própria curva da rede convolucional mostra quanto uma execução pode oscilar:
0,969 na época 10, 0,947 na época 20, 0,978 na época 30. A aula 18 trata de separar uma diferença real
desse tipo de oscilação.

O motivo de a diferença não ser maior é o tamanho da imagem. **Um dígito 8 por 8 tem 64 pixels, poucos o
bastante para uma camada densa bancar um peso de cada um deles para cada unidade**, e as formas que ela
precisa aprender têm poucos lugares onde ficar. A seção sobre canais mostrou onde isso acaba: numa
fotografia 224 por 224, a camada densa custa 120.847.089.664 parâmetros e a convolução 448. A
convolução se paga à medida que as imagens crescem, e é por isso que as redes da aula 12 são
convolucionais; aqui ela já vence uma rede densa do seu tamanho tendo só 4.800 parâmetros na parte que
olha a imagem.

Mais uma coisa a notar na transcrição: a perda de treino da rede convolucional caiu para 0,0055, muito
abaixo da perda de validação. Ela quase decorou as 1.077 imagens de treino, que é o assunto da aula 7.
