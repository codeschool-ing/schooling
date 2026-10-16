---
title: Posições e fatias, em uma e duas dimensões
version: 1
---

**Um índice escolhe elementos pela posição; uma fatia escolhe uma sequência deles e devolve uma
view.** Em uma dimensão o NumPy indexa exatamente como uma lista Python. Em duas ele recebe um índice
por eixo, separados por vírgula, dentro de um só par de colchetes, e é nessa vírgula que estão quase
todos os hábitos novos.

O notebook desta aula lê o tempo e as datas, como as duas últimas aulas:

```python
import numpy as np

weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
dates = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=0, dtype=str)
rain, temp = weather[:, 0], weather[:, 1]
weeks = temp[:364].reshape(52, 7)
```

## Uma dimensão

```python
temp[0], temp[-1], temp[:3], temp[-3:], temp[::91]
```

```
(np.float64(29.9),
 np.float64(32.2),
 array([29.9, 30. , 30.7]),
 array([31. , 31.3, 32.2]),
 array([29.9, 29.2, 27.8, 31.1, 32.2]))
```

A posição 0 é o primeiro dia; `-1` conta do fim. Uma fatia `início:fim:passo` **inclui o início e
para antes do fim**, então `temp[:3]` são as posições 0, 1 e 2, e deixar um limite de fora quer
dizer "desde o começo" ou "até o fim". `temp[::91]` pega um dia a cada 91, uma leitura por trimestre.

## Duas dimensões

```python
weeks[3, 4], weeks[3], weeks[:, 4][:3], weeks[:2, :3]
```

```
(np.float64(30.0),
 array([30.8, 30.2, 29.5, 29.4, 30. , 30.4, 30.5]),
 array([30.8, 31.3, 31.4]),
 array([[29.9, 30. , 30.7],
        [31.3, 30.7, 30.5]]))
```

| expressão | dá | formato |
|---|---|---|
| `weeks[3, 4]` | um número: semana 3, posição 4 | `()` |
| `weeks[3]` | a semana 3 inteira | `(7,)` |
| `weeks[:, 4]` | a posição 4 de toda semana, todo domingo | `(52,)` |
| `weeks[:2, :3]` | as duas primeiras semanas, seus três primeiros dias | `(2, 3)` |

**`weeks[3, 4]` e `weeks[3][4]` dão o mesmo número e não são a mesma operação.** A primeira é uma
consulta com dois índices. A segunda cria `weeks[3]`, uma view da linha, e depois a indexa. Para ler,
a diferença é velocidade. Para escrever, é a diferença entre mudar a tabela e, em alguns casos, mudar
um temporário que é jogado fora; a seção sobre escrever por um índice, adiante, é esse caso, e a aula
11 é o mesmo caso no pandas.

Uma fatia mantém o eixo que fatia; um inteiro o remove. `weeks[3]` é `(7,)` mas `weeks[3:4]` é
`(1, 7)`, uma semana ainda numa tabela:

```python
weeks[3].shape, weeks[3:4].shape
```

```
((7,), (1, 7))
```

A aula 6 acrescentaria: se você pretende fazer broadcasting do resultado contra algo, essa diferença
decide se ele se alinha.
