---
title: Os três que não levantam erro
version: 1
---

Cada um destes produz uma resposta errada em vez de um erro, que é o que os torna dignos de uma
seção.

## Alterar uma lista enquanto a itera

```python
>>> xs = [1, 2, 3, 4]
>>> for x in xs:
...     if x % 2 == 0:
...         xs.remove(x)
>>> xs
[1, 3, 4]
```

O `4` sobreviveu. O laço guarda a própria posição; remover o `2` deslizou o `3` para a posição 1, e o
laço já tinha seguido para a posição 2.

**Itere uma cópia, ou construa uma lista nova:**

```python
xs = [x for x in xs if x % 2 != 0]      # a resposta de sempre
for x in xs[:]:                          # ou itere uma cópia
```

O mesmo vale para um dicionário — mudar o tamanho dele durante a iteração levanta `RuntimeError`, o
que ao menos é barulhento.

## O erro de um a mais

```python
for i in range(1, len(itens)):    # pula itens[0]
for i in range(len(itens) + 1):   # IndexError na última volta
```

Os dois vêm de calcular um índice. **`for item in itens` não tem como errar por um**, e o `enumerate`
também não.

## A variável que sobrevive ao laço

```python
for item in itens:
    ...
print(item)        # o último — ou NameError se itens estava vazia
```

O Python não tem escopo de bloco: a variável do laço permanece depois dele, guardando o que tinha por
último. Lê-la de propósito é legítimo e raro; lê-la sem querer é um defeito que funciona com toda
entrada não vazia e levanta erro com a vazia.

## E um que levanta, mais cedo ou mais tarde

```python
total = 0
for linha in linhas:
    total += linha["valor"]
```

Correto — até uma linha não ter `valor`. `linha.get("valor", 0)` é a decisão de tratar isso como
zero, dita em voz alta. A aula 8 é a outra resposta: capturar e dizer qual linha.
