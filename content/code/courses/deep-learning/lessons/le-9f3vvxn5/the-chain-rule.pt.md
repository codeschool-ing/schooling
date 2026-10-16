---
title: A regra da cadeia, numa unidade
version: 1
---

A aula 2 achou a inclinação da perda mexendo um pouco num peso e medindo a perda de novo. Isso
funciona para um peso. **Uma rede tem milhares, e cutucar um por vez custa dois forward passes por
peso a cada passo.** A rede 64-16-10 conferida mais adiante nesta aula tem 1.210 pesos, então um
único passo precisaria de 2.420 forward passes sobre o lote.

O backpropagation obtém todas essas inclinações com um forward pass e um backward pass. Não é uma
aproximação, nem um truque dos frameworks. **É a regra da cadeia do cálculo, aplicada numa ordem que
nunca calcula nada duas vezes.**

## Três passos, três derivadas locais

Uma unidade já mostra a ideia inteira. Com uma entrada `x`, um peso `w` e um viés `b`, ela calcula
em três passos, e a perda é o erro quadrático da aula 2 contra o alvo `y`:

```
z = w·x + b        a = sigmoid(z)        L = (a − y)²
```

Cada passo tem uma derivada que só sabe daquele passo. A do quadrado é `2(a − y)`. A da sigmoid é
`a(1 − a)`, que pode ser lida da própria saída. A da soma, em relação a `w`, é `x`. A regra da cadeia
diz que a derivada do todo é o produto das partes:

```
dL/dw = dL/da · da/dz · dz/dw
```

Salve como `~/dl/chain.py` e rode:

```schooling-example
{
  "language": "python",
  "file": "chain.py",
  "parts": [
    {
      "code": "\"\"\"chain: one unit, three steps, and the derivative of the loss through all of them.\"\"\"\nimport numpy as np\n\nx, y = 1.5, 1.0\nw, b = 0.8, -0.5",
      "note": "Uma entrada, a resposta que ela deveria dar, e uma unidade com um peso e um viés. A pergunta é como a perda muda quando `w` se mexe."
    },
    {
      "code": "def loss(w):\n    z = w * x + b\n    a = 1 / (1 + np.exp(-z))\n    return (a - y) ** 2",
      "note": "O cálculo inteiro como função de `w`: uma soma, uma sigmoid, um erro quadrático. Ela existe só para a conferência do final."
    },
    {
      "code": "z = w * x + b\na = 1 / (1 + np.exp(-z))\nL = (a - y) ** 2\nprint(f\"forward:  z = {z:.4f}   a = {a:.4f}   L = {L:.4f}\")",
      "note": "O forward pass, guardando cada valor intermediário. O backward pass precisa deles: cada derivada local é calculada no ponto por onde o forward passou."
    },
    {
      "code": "dL_da = 2 * (a - y)\nda_dz = a * (1 - a)\ndz_dw = x\nprint(f\"local:    dL/da = {dL_da:.4f}   da/dz = {da_dz:.4f}   dz/dw = {dz_dw:.4f}\")\nprint(f\"chain:    dL/dw = {dL_da * da_dz * dz_dw:.6f}\")",
      "note": "Três derivadas locais, cada uma sabendo só do próprio passo: a do quadrado, a da sigmoid (`a·(1−a)`, lida da própria saída) e a da soma, que é a entrada. A regra da cadeia as multiplica."
    },
    {
      "code": "h = 1e-6\nprint(f\"nudge w:  dL/dw = {(loss(w + h) - loss(w - h)) / (2 * h):.6f}\")",
      "note": "A conferência da aula 2: mexer `w` um milionésimo para cada lado e medir a perda. Não precisa de cálculo, e custa dois forward passes inteiros para um único peso."
    }
  ]
}
```

```
ana@vm:~/dl$ python chain.py
forward:  z = 0.7000   a = 0.6682   L = 0.1101
local:    dL/da = -0.6636   da/dz = 0.2217   dz/dw = 1.5000
chain:    dL/dw = -0.220701
nudge w:  dL/dw = -0.220701
```

**O produto e a cutucada concordam em seis casas decimais**, em -0,220701. O sinal é a parte útil: a
unidade devolve 0,6682 onde o alvo é 1, então um `w` maior baixaria a perda, e o gradient descent vai
mover `w` para cima.

Duas coisas no programa importam para tudo o que vem depois. **Cada derivada local é calculada num
valor que o forward pass produziu**: `a` para o quadrado e para a sigmoid, `x` para a soma. Então o
forward pass guarda os valores intermediários, e o backward pass os lê. E o fator da sigmoid aqui é
0,2217. Ele nunca passa de 0,25, e a última seção desta aula mostra o que isso faz quando dez deles
são multiplicados.
