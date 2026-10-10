---
title: O passo para a frente, com um peso
version: 1
---

A aula 1 terminou com uma rede cujos pesos foram escritos à mão. Ninguém treina uma rede de verdade
assim. **Treinar é um programa procurando esses números**, e a busca precisa de três coisas que esta
aula constrói uma de cada vez: uma previsão, uma medida de quanto ela erra e uma regra para saber
para que lado andar. O modelo aqui tem um único peso, então cada uma das três pode ser impressa e
conferida a olho.

O **passo para a frente** (*forward pass*) é a conta que vai da entrada até a previsão, com os pesos
parados. No `layer.py` da aula 1 era `x @ W + b` seguido de ReLU. Aqui é `w * x`: uma reta que passa
pelo zero e cuja inclinação é o peso. O nome diz para onde os números correm, da entrada para a
frente, camada a camada, e a aula 3 manda algo de volta no sentido contrário.

Os dados são dez pontos, feitos por um programa curto o bastante para ler de uma vez. Salve-o como
`~/dl/points.py`:

```python
# points.py: ten points, made by a straight line plus noise that never changes
import numpy as np

x = np.arange(1, 11) / 10
noise = np.random.default_rng(0).normal(0, 0.2, 10)
y = (2 * x + 1 + noise).round(2)
```

O `x` vai de 0,1 a 1,0. Cada `y` é uma reta de inclinação 2 que cruza o zero na altura 1, mais um
ruído de um gerador com semente fixa, então toda máquina recebe os mesmos dez valores. Arredondar
para duas casas deixa a aritmética da próxima seção pequena o bastante para fazer à mão. **O modelo
não sabe nada disso.** Ele vê dez pares de números.

Agora o passo para a frente, para o peso que você passar na linha de comando. Salve como
`~/dl/forward.py`:

```python
# forward.py: the model's prediction for every point, at the weight you give it
import sys

from points import x, y

w = float(sys.argv[1])
prediction = w * x
for xi, yi, pi in zip(x, y, prediction):
    print(f"x {xi:.1f}   y {yi:.2f}   w*x {pi:.2f}   error {pi - yi:+.2f}")
```

```
ana@vm:~/dl$ python forward.py 2
x 0.1   y 1.23   w*x 0.20   error -1.03
x 0.2   y 1.37   w*x 0.40   error -0.97
x 0.3   y 1.73   w*x 0.60   error -1.13
x 0.4   y 1.82   w*x 0.80   error -1.02
x 0.5   y 1.89   w*x 1.00   error -0.89
x 0.6   y 2.27   w*x 1.20   error -1.07
x 0.7   y 2.66   w*x 1.40   error -1.26
x 0.8   y 2.79   w*x 1.60   error -1.19
x 0.9   y 2.66   w*x 1.80   error -0.86
x 1.0   y 2.75   w*x 2.00   error -0.75
```

Com `w = 2`, exatamente a inclinação com que os pontos foram feitos, **toda previsão fica baixa
demais**, por algo entre 0,75 e 1,26. Uma reta presa ao zero não consegue somar o 1 sobre o qual os
pontos foram construídos, então a inclinação certa erra os dez. O peso que erra menos está em outro
lugar, e achá-lo é o resto desta aula.

Duas coisas a notar no programa. A previsão é calculada para os dez pontos numa operação só,
`w * x` num array, o hábito que o produto de matrizes da aula 1 começou. E nada nele aprende. Um
passo para a frente só responde; aprender é o que acontece entre dois deles.
