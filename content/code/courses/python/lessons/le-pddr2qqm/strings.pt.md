---
title: Texto é uma sequência, e não pode ser alterado
version: 2
---

```python
name = "Ada"
name = 'Ada'
```

Aspas simples e duplas são idênticas. Escolha a que evita escapar: `"it's"` não precisa de barra
invertida, e `'ele disse "oi"'` também não.

## Escapes

`\n` é quebra de linha, `\t` tabulação, `\\` uma barra invertida, `\"` uma aspa dentro do mesmo tipo
de aspa.

```python
print("first\nsecond")
```
```
first
second
```

**Uma string crua desliga tudo isso**, e é por isso que caminhos do Windows e expressões regulares
se escrevem com um `r` na frente:

```python
r"C:\Users\ada"     # not an escape sequence in sight
```

A aula 10 usa isso em todo padrão.

## Aspas triplas

Três aspas abrem uma string que pode correr por várias linhas, e as quebras fazem parte dela. Esta é
também a sintaxe que a aula 1 encontrou como docstring — a mesma literal, numa posição que lhe dá um
segundo trabalho.

## Imutável

```python
>>> name = "Ada"
>>> name[0] = "E"
TypeError: 'str' object does not support item assignment
```

**Uma string não pode ser alterada no lugar.** Todo método que parece editar uma na verdade devolve
uma string nova:

```python
>>> name.upper()
'ADA'
>>> name
'Ada'
```

`name` ficou intacto. Para ficar com o resultado é preciso atribuir: `name = name.upper()`. Isso pega
todo mundo uma vez, e depois nunca mais.

## Os dois operadores

`+` junta, `*` repete:

```python
>>> "ab" + "cd"
'abcd'
>>> "-" * 20
'--------------------'
```

**Juntar dentro de um laço é a ferramenta errada.** Cada `+` constrói uma string nova inteira, então
mil deles são mil cópias. `"".join(partes)` é o que se usa, e está na próxima seção.

## Índice e comprimento

```python
>>> "Python"[0]
'P'
>>> "Python"[-1]
'n'
>>> len("Python")
6
```

Contando do zero, e índices negativos contam do fim. Fatiamento é seção da aula 3, porque é a mesma
sintaxe para toda sequência e strings são uma.
