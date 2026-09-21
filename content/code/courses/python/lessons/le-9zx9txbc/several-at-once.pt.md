---
title: Dois num `with`, e a quantidade que você não sabe
version: 1
---

```python
with open(orig, encoding="utf-8") as a, open(dest, "w", encoding="utf-8") as b:
    b.write(a.read())
```

Vírgulas. Os dois entram da esquerda para a direita, os dois saem da direita para a esquerda, e o
segundo não entra se o primeiro levantar erro.

## A forma entre parênteses

```python
with (
    open(orig, encoding="utf-8") as a,
    open(dest, "w", encoding="utf-8") as b,
):
    ...
```

Desde o Python 3.10, o que torna uma linha longa legível sem uma barra invertida.

## Aninhar é a mesma coisa com mais indentação

```python
with open(orig) as a:
    with open(dest, "w") as b:
```

Comportamento idêntico. Use a forma com vírgula; guarde o aninhamento para quando algo entre as
duas linhas precisar acontecer.

## `ExitStack`, para a quantidade que você não sabe

```python
from contextlib import ExitStack

with ExitStack() as pilha:
    arquivos = [pilha.enter_context(open(p, encoding="utf-8")) for p in caminhos]
    juntar(arquivos)
```

Todo arquivo é fechado na saída, em ordem inversa, termine o bloco como terminar. Esta é a
resposta quando a contagem vem do dado e não do código — e escrever isso com um `try`/`finally` e
uma lista é a versão que vaza os que foram abertos antes da falha.

O `pilha.callback(func, arg)` registra um desfazer arbitrário, para uma coisa que não tem
gerenciador próprio.

## A ordem importa

As saídas rodam ao contrário, que é o que você quer: o que foi aberto por último é desfeito
primeiro, e um gerenciador pode contar com os de fora ainda vivos enquanto ele arruma.
