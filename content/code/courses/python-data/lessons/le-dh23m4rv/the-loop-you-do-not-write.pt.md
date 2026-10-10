---
title: O laço que você não escreve mais
version: 1
---

**No NumPy você escreve a operação uma vez, para o array inteiro, e o laço acontece em código
compilado por baixo.** É isso que "vetorizado" quer dizer, e é o hábito que separa o código que usa
o NumPy do código que só o importa.

Comece o notebook desta aula com o tempo de novo:

```python
import numpy as np

weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
rain, temp = weather[:, 0], weather[:, 1]
```

Um colega em Lisboa quer as temperaturas em Fahrenheit. O laço que um programador Python escreve
primeiro:

```python
fahrenheit = []
for t in temp:
    fahrenheit.append(t * 9 / 5 + 32)
fahrenheit[:3]
```
```
[np.float64(85.82), np.float64(86.0), np.float64(87.26)]
```

E a mesma coisa, vetorizada:

```python
(temp * 9 / 5 + 32)[:3]
```
```
array([85.82, 86.  , 87.26])
```

Os mesmos números. A diferença está no que a segunda não faz: não busca cada valor, não o embrulha
num objeto Python, não chama `*` pelo interpretador nem anexa numa lista, 365 vezes. `temp * 9` é
**uma** chamada a código compilado que percorre o bloco de floats uma vez. A versão com laço também
devolve números embrulhados como `np.float64`, um objeto Python cada, o que dá uma pista do
trabalho que ela faz.

## Quanto mais rápido

Com 365 valores os dois são instantâneos. A diferença aparece no tamanho que os dados reais têm.
Eis um ano de leituras repetido mil vezes, 365.000 valores, e o `%timeit` do IPython, que roda
uma linha muitas vezes e a mede. `-o` guarda a medida numa variável e `-q` a deixa quieta, para que a
última linha mostre as duas médias em milissegundos e quantas vezes uma é mais rápida:

```python
big = np.tile(temp, 1000)
loop = %timeit -o -q [t * 9 / 5 + 32 for t in big]
vec = %timeit -o -q big * 9 / 5 + 32
round(loop.average * 1000, 1), round(vec.average * 1000, 2), round(loop.average / vec.average)
```

```
(97.9, 0.69, 142)
```

`np.tile` repete um array ponta a ponta. A list comprehension, que já é o jeito mais rápido de
escrever um laço em Python, leva por volta de um décimo de segundo; a linha vetorizada leva menos de um
milissegundo, **mais de cem vezes mais rápida** na máquina em que isto foi gravado. Os seus tempos
vão diferir. A distância vem de onde o laço roda, no interpretador ou em código compilado, e isso
é igual em toda máquina.

Velocidade é o argumento que se cita. O argumento melhor é que a linha vetorizada **diz o que
calcula**: uma conversão, aplicada a uma coluna. Não há índice, acumulador nem `append` para errar.
