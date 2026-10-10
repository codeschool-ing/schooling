---
title: Tamanho do lote, comparado com justiça
version: 1
---

Um lote maior dá uma estimativa melhor do gradiente, como a aula 5 mediu, então é fácil esperar que um
lote maior treine melhor. **Se treina ou não depende do que fica igual**: o número de épocas ou o
número de passos. As duas comparações dão respostas opostas, e as duas são verdadeiras.

Salve isto como `~/dl/batchsize.py`. Ele treina a mesma rede, a partir dos mesmos pesos iniciais, com
lotes de 1, 32 e 1.077, o conjunto de treino inteiro de uma vez, com a taxa fixa em 0,1:

```schooling-example
{
  "language": "python",
  "file": "batchsize.py",
  "parts": [
    {
      "code": "\"\"\"batchsize: one network trained at three batch sizes, for equal epochs or for equal steps.\"\"\"\nimport math\nimport sys\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nPLANS = {\"epochs\": [(1, 10), (32, 10), (1077, 10)],\n         \"steps\": [(1, 1), (32, 32), (1077, 1077)]}",
      "note": "Dois planos, escolhidos na linha de comando. `epochs` dá a cada tamanho de lote dez passadas pelos dados. `steps` dá a cada um cerca de 1.077 atualizações, o que leva uma época com lote 1 e 1.077 épocas com lote 1.077."
    },
    {
      "code": "for batch, epochs in PLANS[sys.argv[1]]:\n    rng = np.random.default_rng(0)\n    net = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\n    history = fit(net, SGD(net.params(), 0.1), train, val, epochs, batch_size=batch, every=epochs + 1)",
      "note": "Os mesmos pesos iniciais e a mesma taxa, 0,1, em toda execução, para que o tamanho do lote seja a única coisa que muda. `every=epochs + 1` deixa o `fit` calado."
    },
    {
      "code": "    steps = epochs * math.ceil(len(train[1]) / batch)\n    val_losses = [h[2] for h in history]\n    rises = sum(later > earlier for earlier, later in zip(val_losses, val_losses[1:]))\n    _, _, val_loss, val_acc = history[-1]\n    print(f\"batch {batch:4d}  {epochs:4d} epochs  {steps:5d} steps  {epochs * len(train[1]):7d} images  \"\n          f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}  val loss rose {rises}/{epochs - 1}\")",
      "note": "Duas contagens ao lado do resultado. `images` é quantas imagens passaram por um forward e um backward, que é o trabalho. `rose` conta as épocas cuja perda de validação saiu maior que a da época anterior, uma medida grosseira de quanto ruído a curva tem."
    }
  ]
}
```

## Épocas iguais

```
PENDING by-epochs
```

Toda execução processou as mesmas 10.770 imagens. **Por época, o lote pequeno ganha com folga**: 0,969
com lote 1, 0,933 com 32 e 0,436 com 1.077. O motivo está na coluna de passos. Dez épocas com lote 1
são 10.770 atualizações dos pesos; com 1.077 são 10, e dez passos a uma taxa de 0,1 não bastam para
chegar a lugar nenhum, por melhor que seja cada gradiente.

## Passos iguais

```
PENDING by-steps
```

Agora toda execução moveu os pesos cerca de 1.077 vezes, e **por passo o lote grande ganha**: 0,967
com 1.077 contra 0,958 com 32 e 0,936 com 1. Cada passo do lote inteiro seguiu o gradiente verdadeiro
do conjunto de treino todo, e cada passo do lote de 1 seguiu a opinião de uma imagem sobre ele. O preço
está na coluna de imagens: **o lote inteiro fez 1.077 vezes o trabalho do lote de 1**, mais de um
milhão de imagens pela rede para ganhar dele por três pontos.

Então nenhum tamanho ganha as duas comparações. Um lote pequeno tira mais de cada imagem, um lote
grande tira mais de cada passo, e a pergunta útil é quanto custa um passo. Num hardware de verdade um
lote é um produto de matrizes, como a aula 1 mostrou, e um processador ou uma placa de vídeo processa
32 linhas em bem menos de 32 vezes o tempo de uma. É por isso que ninguém treina com lote 1, e por isso
o lote costuma ser decidido pela memória do dispositivo e não pelo aprendizado. As aulas 10 e 19 medem
o tempo nesta máquina. Esta seção conta imagens em vez de segundos porque uma contagem sai igual em
qualquer computador.

## O ruído que dá para ver

A última coluna conta quantas vezes a perda de validação subiu de uma época para a seguinte. Com lote 1
ela subiu em **4 de 9** épocas, com 32 em 1 de 9, e com o lote inteiro em nenhuma: e nas 1.077 épocas
da execução de lote inteiro ela subiu **0 vezes em 1.076**. Com o conjunto de treino inteiro em cada
passo, a descida do gradiente com uma taxa pequena desce todas as vezes, e a curva sai lisa. Com uma
imagem por passo, todo passo mira um pouco errado, e a curva sai serrilhada.

**Uma curva serrilhada não é uma curva quebrada.** Com lote 1, as oscilações vieram junto com o melhor
resultado da tabela de épocas iguais. Quando a curva de uma execução real tem ruído, o tamanho do lote
é uma das primeiras coisas a olhar, antes de concluir que o treinamento está instável.
