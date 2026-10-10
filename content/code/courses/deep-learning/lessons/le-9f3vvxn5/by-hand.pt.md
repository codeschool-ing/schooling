---
title: A rede 2-2-1, número por número
version: 1
---

O grafo da seção anterior é um desenho, e um desenho pode estar errado. **Este programa calcula
cada número dele, só com NumPy e as quatro regras.** Cada linha do backward pass é uma regra aplicada
a um nó, na ordem inversa da que o forward pass seguiu. Salve como `~/dl/byhand.py`:

```schooling-example
{
  "language": "python",
  "file": "byhand.py",
  "parts": [
    {
      "code": "\"\"\"byhand: a 2-2-1 network, forward and backward, one number at a time.\"\"\"\nimport numpy as np\n\nx = np.array([1.0, 2.0])\ny = 1.0\nW1 = np.array([[0.5, -0.5],\n               [0.25, 0.25]])\nb1 = np.array([0.0, -1.0])\nW2 = np.array([1.5, 1.0])\nb2 = 0.25",
      "note": "Duas entradas, duas unidades ocultas, uma saída, e cada peso escrito por extenso. Foram escolhidos para que a conta possa ser seguida à mão, e para que a unidade oculta 2 dê negativa."
    },
    {
      "code": "z = x @ W1 + b1\nh = np.maximum(0, z)\nout = h @ W2 + b2\nL = (out - y) ** 2\nprint(\"forward   z\", z, \" h\", h, \" out\", out, \" L\", L)",
      "note": "O forward pass da aula 1, seguido do erro quadrático da aula 2. Cada array intermediário fica guardado com nome próprio."
    },
    {
      "code": "d_out = 2 * (out - y)\ndW2 = h * d_out\ndb2 = d_out",
      "note": "O backward pass começa na perda. `d_out` é quanto a perda se mexe por unidade de saída. Um peso da última camada recebe isso vezes o valor que ele multiplicou, e o viés recebe o mesmo sem mudança."
    },
    {
      "code": "dh = W2 * d_out\ndz = dh * (z > 0)\ndW1 = np.outer(x, dz)\ndb1 = dz\ndx = W1 @ dz\nprint(\"backward  d_out\", d_out, \" dW2\", dW2, \" db2\", db2)\nprint(\"          dh\", dh, \" dz\", dz, \" db1\", db1)\nprint(\"          dW1\", dW1.tolist(), \" dx\", dx)",
      "note": "Uma camada para trás. Cada saída oculta recebe `d_out` vezes o peso que a levou adiante. O ReLU só deixa passar onde `z` era positivo. Depois, a mesma regra de cima: o gradiente de um peso é a entrada dele vezes o gradiente que chega à sua unidade."
    },
    {
      "code": "lr = 0.05\nW1, b1, W2, b2 = W1 - lr * dW1, b1 - lr * db1, W2 - lr * dW2, b2 - lr * db2\nout = np.maximum(0, x @ W1 + b1) @ W2 + b2\nprint(\"one step  out\", round(out, 4), \" L\", round((out - y) ** 2, 4))",
      "note": "Para que servem os gradientes: um passo do gradient descent da aula 2 nos nove números de uma vez, e o forward pass de novo."
    }
  ]
}
```

```
ana@vm:~/dl$ python byhand.py
forward   z [ 1. -1.]  h [1. 0.]  out 1.75  L 0.5625
backward  d_out 1.5  dW2 [1.5 0. ]  db2 1.5
          dh [2.25 1.5 ]  dz [2.25 0.  ]  db1 [2.25 0.  ]
          dW1 [[2.25, 0.0], [4.5, 0.0]]  dx [1.125  0.5625]
one step  out 0.6381  L 0.131
```

Leia as linhas do backward de cima para baixo, porque é nessa ordem que foram calculadas.

- `d_out` é 1,5: o dobro do erro de 0,75. O viés da saída o recebe sem mudança, `db2`.
- `dW2` é `[1.5 0.]`. Cada peso da saída recebe 1,5 vezes o valor oculto que ele multiplicou, e
  `h2` era 0, então o peso que sai de `h2` não recebe nada.
- `dh` é `[2.25 1.5]`: 1,5 vezes cada peso da saída. As duas saídas ocultas mudariam a perda se
  se mexessem.
- `dz` é `[2.25 0.]`. O ReLU deixa passar o 2,25 e barra o 1,5, porque `z2` era -1. É esta linha
  que torna a unidade 2 impossível de treinar com esta entrada.
- `dW1` é `[[2.25, 0.0], [4.5, 0.0]]`: as linhas são as entradas, as colunas são as unidades
  ocultas. O peso que sai de `x2` recebe o dobro do que sai de `x1`, porque `x2` é o dobro, e a
  coluna da unidade morta é toda zero.
- `dx` é `[1.125 0.5625]`: a soma na bifurcação de cada entrada, que só uma rede mais profunda
  usaria.

**A última linha é a razão de tudo isso.** Um passo de gradient descent com taxa de 0,05 moveu os
nove números de uma vez, e a perda caiu de 0,5625 para 0,131. A saída foi de 1,75 para 0,6381,
passando do alvo de 1 para o outro lado: um passo desse tamanho ultrapassa o alvo nesta entrada, que
é a taxa de aprendizado da aula 2 em ação de novo.

Vale contar o custo. O forward pass fez um produto por peso, e o backward pass fez uns dois: um para
o gradiente do peso e outro para passar o gradiente adiante. **Obter os nove gradientes custou mais ou
menos dois forward passes, onde a cutucada teria custado dezoito.** A aula 9 monta esta mesma rede no
PyTorch, e os gradientes automáticos dele imprimem estes mesmos números.
