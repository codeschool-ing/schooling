---
title: Funções de ativação, em sete pontos
version: 1
---

A função que uma unidade aplica à sua soma é a sua **ativação**. O perceptron usava um degrau. Quase
nada usa um hoje, e o motivo é o assunto das duas próximas aulas: o treinamento ajusta cada peso
conforme o quanto uma pequena mudança nele mudaria a saída, e a saída de um degrau não muda nada sob
uma pequena mudança, a não ser no único ponto em que ela salta.

Quatro funções, calculadas nas mesmas sete entradas. Salve como `~/dl/activations.py`:

```python
# activations.py: four functions a unit can apply to its sum, at the same seven points
import numpy as np

z = np.array([-3.0, -1.0, -0.1, 0.0, 0.1, 1.0, 3.0])
functions = {
    "step":    (z > 0).astype(float),
    "sigmoid": 1 / (1 + np.exp(-z)),
    "tanh":    np.tanh(z),
    "relu":    np.maximum(0, z),
}
print("z       " + " ".join(f"{v:6.1f}" for v in z))
for name, out in functions.items():
    print(f"{name:7s} " + " ".join(f"{v:6.3f}" for v in out))
```

```
ana@vm:~/dl$ python activations.py
z         -3.0   -1.0   -0.1    0.0    0.1    1.0    3.0
step     0.000  0.000  0.000  0.000  1.000  1.000  1.000
sigmoid  0.047  0.269  0.475  0.500  0.525  0.731  0.953
tanh    -0.995 -0.762 -0.100  0.000  0.100  0.762  0.995
relu     0.000  0.000  0.000  0.000  0.100  1.000  3.000
```

Leia a tabela por coluna, como uma unidade a veria.

| | o que faz | onde você a encontra |
| --- | --- | --- |
| **step** (degrau) | salta de 0 para 1 no zero; entre -0,1 e 0,1 não diz nada sobre os 0,2 de diferença | o perceptron, e a história |
| **sigmoid** | espreme qualquer soma entre 0 e 1, passando por 0,5 no zero; em 3 já está em 0,953, e mais adiante quase não se mexe | a última camada de um classificador de sim ou não, lida como probabilidade |
| **tanh** | a mesma forma de S, entre -1 e 1 e centrada no zero | dentro de redes recorrentes, aula 14 |
| **ReLU** | zero para qualquer negativo, a própria entrada para qualquer positivo | entre as camadas de quase toda rede desde mais ou menos 2012 |

**As pontas planas da sigmoid e da tanh são o problema que elas carregam.** Onde a curva é plana, uma
mudança na soma não muda nada na saída, e a aula 3 mede o que isso faz com uma rede profunda: o sinal
que treina as primeiras camadas encolhe cada vez que atravessa uma, até as primeiras camadas pararem
de aprender. O ReLU não tem ponta plana do lado positivo. É também a função mais barata que um
processador sabe calcular, o que importa quando ela roda bilhões de vezes.

A fraqueza dele é o outro lado. Uma unidade cuja soma é negativa para toda entrada devolve zero para
tudo, não recebe sinal para mudar e fica assim: uma unidade *morta*. Variantes como Leaky ReLU e GELU
dão ao lado negativo uma inclinação pequena em vez de nenhuma. A GELU é a que fica dentro dos
transformers da aula 15.

**Por que ter uma função, afinal?** A seção depois da próxima responde com uma medida: sem uma,
qualquer número de camadas é exatamente uma camada.
