---
title: Gradiente descendente, passo a passo
version: 1
---

A regra sai dos sinais: **ande contra a inclinação.** Inclinação negativa quer dizer passo para a
direita, positiva quer dizer passo para a esquerda, e terreno mais íngreme quer dizer passo mais
longo. Numa linha, é `w = w - lr * slope`, em que `lr`, a **taxa de aprendizado** (*learning
rate*), diz quanto andar por unidade de inclinação. Repita até a inclinação ser zero. Isso é o
**gradiente descendente**, e toda rede deste curso é treinada por alguma versão dele.

Salve como `~/dl/descent.py`:

```schooling-example
{
  "language": "python",
  "file": "descent.py",
  "parts": [
    {
      "code": "# descent.py: gradient descent on one weight, printed step by step\nimport numpy as np\n\nfrom points import x, y"
    },
    {
      "code": "w, lr = 0.0, 1.0\nfor step in range(12):\n    loss = np.mean((w * x - y) ** 2)\n    grad = np.mean(2 * x * (w * x - y))\n    print(f\"step {step:2d}   w {w:.4f}   loss {loss:.4f}   slope {grad:+.4f}\")\n    w = w - lr * grad",
      "note": "Uma volta do laço é um passo: a perda e a inclinação no peso atual, impressas, e depois a atualização. A última linha é o gradiente descendente. A aula 3 trata de calcular `grad` quando há milhares de pesos, e a aula 5 de escolher o passo."
    },
    {
      "code": "best = np.sum(x * y) / np.sum(x * x)\nprint(f\"closed form   w {best:.4f}\")",
      "note": "O fundo achado por álgebra: iguale a inclinação a zero e resolva para `w`. A descida deve chegar ao mesmo número."
    }
  ]
}
```

```
ana@vm:~/dl$ python descent.py
step  0   w 0.0000   loss 4.7918   slope -2.6378
step  1   w 2.6378   loss 0.5126   slope -0.6067
step  2   w 3.2445   loss 0.2863   slope -0.1395
step  3   w 3.3840   loss 0.2743   slope -0.0321
step  4   w 3.4161   loss 0.2737   slope -0.0074
step  5   w 3.4235   loss 0.2736   slope -0.0017
step  6   w 3.4252   loss 0.2736   slope -0.0004
step  7   w 3.4256   loss 0.2736   slope -0.0001
step  8   w 3.4257   loss 0.2736   slope -0.0000
step  9   w 3.4257   loss 0.2736   slope -0.0000
step 10   w 3.4257   loss 0.2736   slope -0.0000
step 11   w 3.4257   loss 0.2736   slope -0.0000
closed form   w 3.4257
```

**O primeiro passo é o mais longo**, de 0 para 2,6378: a inclinação em 0 é -2,6378 e a taxa é 1,
então o passo é a inclinação com o sinal trocado. Cada passo seguinte é mais curto, porque a
inclinação diminui conforme o peso se aproxima do fundo: 0,6067, depois 0,1395, depois 0,0321. No
passo 8 o peso parou de se mexer na quarta casa, em 3,4257, com uma perda de 0,2736.

**A última linha confere.** Para este modelo, o fundo também pode ser achado por álgebra. Iguale a
inclinação a zero, `mean(2x(w*x - y)) = 0`, e resolva para `w`: dá `Σxy / Σx²`, que é 3,4257, o
número a que oito passos de descida chegaram. Essa fórmula é a reta de mínimos quadrados que passa
pelo zero: o critério que o `machine-learning` usou para ajustar uma regressão linear.

Então por que descer, se a álgebra chega lá numa linha? Porque a álgebra só existe para modelos cuja
perda é uma parábola nos pesos. Ponha um ReLU entre duas camadas e não há fórmula para o fundo, mas
ainda há uma inclinação em cada ponto, e a descida não precisa de mais nada. O preço é que a descida
acha um fundo perto de onde começou, que nem sempre é o mais baixo que existe. Para uma rede não
se conhece nada melhor, então o treino aceita esse preço.

**Repare no que é 3,4257: o melhor que este modelo consegue, não a inclinação com que os pontos foram
feitos.** Os pontos vieram de uma reta de inclinação 2 na altura 1, e uma reta presa ao zero precisa
se inclinar mais para chegar perto deles. Uma inclinação de 3,43 é a que erra menos, e os 0,2736 que
sobram são uma perda que nenhum peso consegue baixar. A última seção desta aula dá ao modelo o
parâmetro que falta.
