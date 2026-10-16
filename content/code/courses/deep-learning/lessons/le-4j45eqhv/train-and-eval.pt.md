---
title: Modo de treino e modo de avaliação
version: 1
---

A camada de batch norm se comporta de um jeito no treino e de outro na avaliação, e **o bug clássico
é prever com a rede ainda em modo de treino**. O `fit.evaluate` da aula 5 troca o modo por você, então
todo número de validação deste curso até aqui foi honesto. Um programa que serve um modelo, e prevê
uma imagem por vez conforme os pedidos chegam, não tem ninguém para trocar o modo se você não escrever
a linha. Salve como `~/dl/predict.py`:

```schooling-example
{
  "language": "python",
  "file": "predict.py",
  "parts": [
    {
      "code": "\"\"\"predict: single images through a network with batch norm, in both modes.\"\"\"\nimport numpy as np\n\nimport digits\nfrom batchnorm import BatchNorm\nfrom fit import evaluate, fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 64, rng), BatchNorm(64), ReLU(), Linear(64, 10, rng))\nfit(net, SGD(net.params(), 0.1), train, val, epochs=10, every=10)\nx, y = val",
      "note": "Uma rede pequena com uma camada de batch norm, treinada por dez épocas. O `fit` avalia com o `evaluate`, que passa a rede para o modo de avaliação e de volta, então a acurácia que ele imprime é a honesta."
    },
    {
      "code": "def one_at_a_time(training):\n    net.mode(training)\n    for i in range(5):\n        logits = net.forward(x[i:i + 1])\n        print(f\"  label {y[i]}  predicted {logits.argmax()}  first logits {np.round(logits[0, :3], 2)}\")",
      "note": "O que um programa que serve o modelo faz: chega uma imagem, e ela é prevista sozinha. `x[i:i + 1]` mantém o formato de lote, uma linha de 64."
    },
    {
      "code": "bn = net.layers[1]\nprint(\"running variance, first three features:\", np.round(bn.running_var[:3], 4))\nprint(\"evaluation mode, one image per batch:\")\none_at_a_time(False)\nprint(\"training mode, one image per batch:\")\none_at_a_time(True)\nprint(\"running variance, first three features:\", np.round(bn.running_var[:3], 4))\nprint(\"val loss and accuracy now:\", np.round(evaluate(net, *val), 3))",
      "note": "As mesmas cinco imagens duas vezes, primeiro no modo certo e depois no errado. A variância acumulada e o resultado na validação são impressos de novo no fim, para ver se o modo errado deixou alguma coisa para trás."
    }
  ]
}
```

```
ana@vm:~/dl$ python predict.py
epoch  10  train loss 0.1144  val loss 0.1380  val acc 0.953
running variance, first three features: [0.1114 0.1146 0.1297]
evaluation mode, one image per batch:
  label 4  predicted 4  first logits [-2.31  1.26 -2.72]
  label 3  predicted 3  first logits [-1.96  0.94  2.3 ]
  label 0  predicted 0  first logits [ 8.08 -4.02  0.83]
  label 0  predicted 0  first logits [ 7.43 -3.98 -0.93]
  label 3  predicted 3  first logits [-1.69 -0.37  3.39]
training mode, one image per batch:
  label 4  predicted 8  first logits [-0.35  0.27 -0.11]
  label 3  predicted 8  first logits [-0.35  0.27 -0.11]
  label 0  predicted 8  first logits [-0.35  0.27 -0.11]
  label 0  predicted 8  first logits [-0.35  0.27 -0.11]
  label 3  predicted 8  first logits [-0.35  0.27 -0.11]
running variance, first three features: [0.0658 0.0677 0.0766]
val loss and accuracy now: [0.166 0.939]
```

**No modo de avaliação as cinco imagens saem certas**: 4, 3, 0, 0 e 3. No modo de treino todas são um
8, com os mesmos três logits até o último dígito, `[-0.35 0.27 -0.11]`. O motivo é aritmética. Um lote
de uma imagem tem essa imagem como média e 0 como variância, então o `xhat` é 0 em todo atributo e a
camada devolve o `beta`, o mesmo vetor qualquer que seja a imagem. Tudo depois dela calcula então a
mesma resposta.

**O segundo estrago é mais discreto, e sobrevive à chamada.** No modo de treino a camada também
atualiza as médias acumuladas, e um lote de um tem variância 0. Cada uma das cinco chamadas levou a
variância acumulada 10% do caminho em direção a zero, e a do primeiro atributo caiu de 0,1114 para
0,0658. Ninguém treinou a rede, e mesmo assim a perda de validação subiu de 0,138 para 0,166 e a
acurácia caiu de 0,953 para 0,939. Cinco previsões fizeram isso. Um servidor respondendo milhares em
modo de treino apagaria as estatísticas por completo.

Três hábitos evitam isso:

- passe para o modo de avaliação antes de qualquer previsão, validação incluída, e de volta para o
  modo de treino antes do próximo passo, como o `fit.evaluate` faz;
- no PyTorch a troca é `model.eval()` e `model.train()`, e a aula 9 encontra o mesmo bug lá;
- **desconfie do modo quando uma resposta depender do que mais está no lote**. Um modelo cuja previsão
  para uma imagem muda quando as imagens ao redor mudam está medindo o lote, e só o modo de treino faz
  isso.

A mesma flag desliga o dropout da aula 7, então uma rede com qualquer uma das duas camadas tem dois
comportamentos, e só um deles serve para prever.
