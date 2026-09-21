---
title: Uma função como tipo, e receber o mais largo que você aceita
version: 1
---

```python
from collections.abc import Callable

def aplicar(itens: list[str], fn: Callable[[str], int]) -> list[int]:
    return [fn(x) for x in itens]
```

`Callable[[tipos dos argumentos], tipo de retorno]`. Os colchetes de dentro são a lista de
argumentos, mesmo com um argumento só, e `Callable[..., int]` é "quaisquer argumentos, devolve um
int" para quando você não se importa.

## Receba o tipo mais largo que você aceita

```python
def total(linhas: list[dict]) -> int: ...       # uma lista, e só uma lista
def total(linhas: Iterable[dict]) -> int: ...   # uma lista, uma tupla, um conjunto, um gerador
```

Se o corpo só itera, diga `Iterable`. Um chamador com um gerador então funciona — e a aula 11
gastou uma aula inteira sobre por que o chamador pode ter um.

| você faz | anote |
| --- | --- |
| itera uma vez | `Iterable[X]` |
| itera, indexa, ou tira `len` | `Sequence[X]` |
| busca por chave | `Mapping[K, V]` |
| e também ALTERA | `list[X]`, `dict[K, V]` |

**Os mutáveis são uma promessa que você faz a quem chama**, e não só uma exigência: receber uma
`list` diz que você talvez acrescente nela.

## E devolva o tipo mais específico que você promete

```python
def nomes(linhas: Iterable[dict]) -> list[str]:      # sim
def nomes(linhas: Iterable[dict]) -> Iterable[str]:  # por quê?
```

Largo na entrada, estreito na saída. Quem chama então sabe que dá para indexar o resultado, e você
não prometeu nada que não quis.

## De onde eles vêm

Do `collections.abc` desde a 3.9 — `Iterable`, `Sequence`, `Mapping`, `Callable`, `Iterator`. Os
mesmos nomes existem no `typing` e são a grafia obsoleta.

## `Iterator` contra `Iterable`

A distinção da aula 11, nas anotações: uma função geradora devolve um `Iterator[X]`, e algo que dá
para percorrer de novo é um `Iterable[X]`.

```python
def linhas(caminho: Path) -> Iterator[str]:
    with open(caminho, encoding="utf-8") as f:
        yield from f
```
