---
title: `int()`, `float()`, `str()` — e onde eles recusam
version: 2
---

```python
>>> int("41")
41
>>> float("3.14")
3.14
>>> str(41)
'41'
```

Cada um recebe um valor e devolve um novo daquele tipo. Eles não alteram nada no lugar, e não há o
que alterar: números e strings são imutáveis.

## Onde o `int()` recusa

```python
>>> int("forty-one")
ValueError: invalid literal for int() with base 10: 'forty-one'
```

**Essa recusa é a funcionalidade.** Uma conversão que produzisse `0` em silêncio poria um número
errado dentro do seu programa sem nada para ler. A mensagem até cita o que ela recebeu.

Ele também recusa uma string decimal:

```python
>>> int("3.14")
ValueError: invalid literal for int() with base 10: '3.14'
```

`int(float("3.14"))` são os dois passos, e é honesto sobre serem dois.

## O `int()` trunca; o `round()` arredonda

```python
>>> int(3.9)
3
>>> int(-3.9)
-3
>>> round(3.9)
4
```

O `int()` joga a parte fracionária fora, em direção ao zero. O `round()` faz o que se espera, com uma
exceção famosa: ele arredonda a metade para o número **par** — `round(0.5)` é `0` e `round(1.5)` é
`2`. É o arredondamento bancário, é deliberado, e impede que uma coluna longa de metades escorregue
para cima.

## `bool()`

Segue a tabela de veracidade exatamente: `bool("")` é `False`, `bool("0")` é `True`.

## `str()` contra `repr()`

```python
>>> str("ada")
'ada'
>>> repr("ada")
"'ada'"
```

O `str` é para uma pessoa; o `repr` é para você, e mostra as aspas. O `print` usa `str`, o REPL usa
`repr`, e é por isso que uma string no prompt aparece entre aspas e a mesma string impressa não. A
aula 6 é onde você escreve os dois para as suas próprias classes.

## Capturando a recusa

```python
try:
    age = int(raw)
except ValueError:
    print(f"{raw!r} is not a whole number")
```

Isso é matéria da aula 8 por inteiro, e é a forma certa para qualquer coisa que uma pessoa digitou. O
`!r` na f-string é o `repr`, que põe aspas no valor para uma string vazia ficar visível em vez de
invisível.
