---
title: Pooling, que fica com a resposta mais forte
version: 1
---

Depois de uma convolução costuma vir uma camada que joga fora, de propósito, a maior parte da saída.
**O pooling corta cada mapa em blocos pequenos e fica com um número por bloco**: o maior, no max
pooling, ou a média, no average pooling. Com blocos 2 por 2, a altura e a largura caem pela metade, e
três de cada quatro números somem. Salve como `~/dl/pool.py`:

```schooling-example
{
  "language": "python",
  "file": "pool.py",
  "parts": [
    {
      "code": "\"\"\"pool: max and average pooling on a 4x4 map, and what a one-pixel shift does.\"\"\"\nimport torch\nimport torch.nn as nn\n\nm = torch.tensor([[1., 3., 0., 2.],\n                  [4., 2., 1., 0.],\n                  [0., 1., 5., 6.],\n                  [2., 0., 7., 1.]]).reshape(1, 1, 4, 4)\nprint(\"max:\\n\", nn.MaxPool2d(2)(m).reshape(2, 2))\nprint(\"average:\\n\", nn.AvgPool2d(2)(m).reshape(2, 2))\nprint(\"parameters in MaxPool2d(2):\", len(list(nn.MaxPool2d(2).parameters())))",
      "note": "Um mapa 4 por 4, como uma convolução o entregaria, cortado em quatro blocos 2 por 2. O max pooling fica com o maior número de cada bloco, o average pooling com a média deles."
    },
    {
      "code": "dot = torch.zeros(1, 1, 4, 4)\ndot[0, 0, 1, 0] = 1.0\nfor shift in (0, 1, 2):\n    moved = torch.roll(dot, shifts=shift, dims=3)\n    print(f\"dot moved {shift} right -> pooled\", nn.MaxPool2d(2)(moved).flatten().tolist())",
      "note": "Um único ponto aceso, deslocado na sua linha por 0, 1 e 2 pixels, e o que o max pooling faz de cada posição."
    }
  ]
}
```

```
ana@vm:~/dl$ python pool.py
max:
 tensor([[4., 2.],
        [2., 7.]])
average:
 tensor([[2.5000, 0.7500],
        [0.7500, 4.7500]])
parameters in MaxPool2d(2): 0
dot moved 0 right -> pooled [1.0, 0.0, 0.0, 0.0]
dot moved 1 right -> pooled [1.0, 0.0, 0.0, 0.0]
dot moved 2 right -> pooled [0.0, 1.0, 0.0, 0.0]
```

O bloco de cima à esquerda tem 1, 3, 4 e 2, então o max pooling fica com 4 e o average pooling com
2,5. **Uma camada de pooling não tem nada a aprender**: zero parâmetros, a mesma regra fixa em todo
lugar.

O motivo para querê-la está nas três últimas linhas. O ponto aceso andou um pixel para a direita e a
saída do pooling não mudou, porque ele continuou dentro do mesmo bloco 2 por 2. Deslocado dois pixels,
ele passou para o bloco seguinte e a saída andou junto. **O max pooling pergunta se uma característica
apareceu em algum lugar do bloco, não exatamente onde.** Um traço desenhado um pixel mais à esquerda
por outra mão dá a mesma resposta, e isso vale mais que a posição exata para distinguir um 6 de um 5.

O outro motivo é custo. Toda camada depois do pooling trabalha com um quarto dos números. Na rede desta
aula, o pooling transforma 32 mapas de 8 por 8 em 32 mapas de 4 por 4, e a camada densa que vem depois
lê 512 números em vez de 2.048.

O max pooling não é o único jeito de reduzir um mapa. Uma convolução com stride 2, da seção anterior,
também o divide pela metade, e aprende como ao fazer isso; muitas arquiteturas recentes usam isso no
lugar, e a ResNet da aula 12 usa os dois.
