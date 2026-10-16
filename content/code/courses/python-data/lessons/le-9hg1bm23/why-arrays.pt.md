---
title: Por que um array, se o Python tem listas
version: 1
---

**Uma lista Python guarda referências a objetos espalhados pela memória; um array NumPy guarda os
próprios números, lado a lado, todos de um tipo.** Tudo em que o NumPy é bom decorre dessa única
diferença: velocidade, armazenamento compacto e aritmética sobre uma coluna inteira de uma vez.
Tudo em que ele é rigoroso decorre dela também.

Comece um notebook para esta aula em `pydata` e leia o tempo do ano, duas colunas numéricas,
direto num array:

```python
import numpy as np

weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
weather[:3]
```
```
array([[ 0. , 29.9],
       [ 6.8, 30. ],
       [ 7.9, 30.7]])
```

`genfromtxt` lê um arquivo de texto com números num array. `usecols=(1, 2)` pega a chuva e a
temperatura e deixa a data, que não é número; `skip_header=1` pula a linha de nomes. O que volta é
uma tabela de números sem nome de coluna nenhum: o pandas, a partir da aula 9, é que os acrescenta.

```python
weather.shape, weather.dtype
```
```
((365, 2), dtype('float64'))
```

Trezentas e sessenta e cinco linhas, duas colunas, cada valor um float de 64 bits. Os seis dias sem
leitura de chuva não impediram o arquivo de carregar. Cada campo vazio virou `nan`, **not a
number**, um valor float especial que o NumPy consegue guardar porque a coluna é de floats:

```python
rain = weather[:, 0]
np.isnan(rain).sum()
```
```
np.int64(6)
```

`weather[:, 0]` é a primeira coluna, todas as linhas; a aula 7 trata dessa notação. `np.isnan` faz
a pergunta a todos os valores de uma vez e responde com um array de `True` e `False`, e o `.sum()`
conta os `True`. **Nenhum laço foi escrito**, e é desse hábito que esta parte do curso trata.

## O que a lista custa

As mesmas 365 leituras de chuva, como lista Python e como array:

```python
import sys

as_list = rain.tolist()
list_bytes = sys.getsizeof(as_list) + sum(sys.getsizeof(x) for x in as_list)
list_bytes, rain.nbytes
```
```
(11736, 2920)
```

A lista precisa de um ponteiro por elemento mais um objeto `float` do Python inteiro para cada
leitura, com tipo e contagem de referências; o array precisa de oito bytes por leitura e mais nada.
**Umas quatro vezes menor**, e a diferença é a mesma com um milhão de linhas. O segundo ganho é
maior e é o assunto da aula 5: aritmética sobre um array roda como um único laço em código
compilado, em vez de 365 voltas pelo interpretador.

O preço é o rigor. Todo elemento de um array tem o mesmo tipo, decidido quando o array é criado, e o
array não cresce no lugar: não existe um `append` que acrescente barato. Uma lista é um recipiente;
um array é um bloco de números com um formato.
