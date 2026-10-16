---
title: O NumPy 2, e o código escrito para o NumPy 1
version: 1
---

**O NumPy 2 mudou duas coisas que você vai ver em todo notebook, e uma delas muda respostas.** A
maior parte do código que você acha na internet, e muito do que colegas escreveram antes de 2024,
foi escrita para o NumPy 1. Ele continua rodando. Eis um script de cinco linhas, `promote.py`,
gravado em `pydata`:

```py
import numpy as np

docks = np.array([14, 20, 12], dtype=np.uint8)
print(np.__version__, repr(docks.max()))
print(docks + 300)
```

Ele guarda três contagens de docas no menor tipo sem sinal, `uint8` (0 a 255), e soma 300 a cada
uma. Rodado no NumPy 1 que era o atual antes deste curso, num ambiente à parte como a aula 3 montou
um, e no NumPy 2 deste curso:

```
(.venv) ana@lab:~/oldnumpy$ python ~/pydata/promote.py
1.26.4 20
[314 320 312]
(.venv) ana@lab:~/pydata$ python promote.py
2.5.3 np.uint8(20)
Traceback (most recent call last):
  File "/home/ana/pydata/promote.py", line 5, in <module>
    print(docks + 300)
          ~~~~~~^~~~~
OverflowError: Python integer 300 out of bounds for uint8
```

## Como um número sozinho aparece agora

`docks.max()` devolve um número, e o NumPy 1 o imprimia como `20`. O NumPy 2 imprime
`np.uint8(20)`: **a representação agora diz o tipo**. É o mesmo valor e se comporta igual; só
parou de fingir ser um `int` do Python. Você vai ver `np.float64(30.5)` e `np.int64(167)` ao longo
de todo o curso sempre que a última linha de uma célula for um número sozinho vindo de um array.
`print` e `float()` devolvem o número puro quando você o quer.

## O que uma operação com um número Python faz agora

A segunda linha é a mudança de verdade. O NumPy 1 olhava o **valor** 300, via que não cabia em
`uint8` e, em silêncio, fazia o resultado de um tipo mais largo, `uint16`, e as somas saíam certas.
O NumPy 2 segue o **tipo** do array: um número Python entra no tipo do array, e se não puder ser
representado nele, é um erro e não uma promoção silenciosa. A regra tem nome, NEP 50, se você
precisar procurar.

Então `docks + 300` é um `OverflowError` no NumPy 2 e `[314 320 312]` no NumPy 1. Essa direção é a
segura: código que dependia da promoção antiga agora falha alto em vez de dar outro número. Os casos
mais quietos são misturas de tipos de array, e floats com floats do Python, em que o NumPy 2 pode
devolver um resultado num tipo mais estreito que o NumPy 1 devolvia. A correção em todos os casos é
a mesma: **escolha o dtype que você quer dizer**, com `astype` ou com o argumento `dtype=`, em vez
de contar com a promoção.

```python
docks = np.array([14, 20, 12], dtype=np.uint8)
docks.astype(np.int64) + 300
```
```
array([314, 320, 312])
```

Quando um código antigo se comporta estranho no NumPy 2, o guia de migração do próprio NumPy lista
cada mudança; esta seção mostra as duas que você vai encontrar primeiro.
