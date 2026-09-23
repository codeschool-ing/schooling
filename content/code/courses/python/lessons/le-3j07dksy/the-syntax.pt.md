---
title: Dois-pontos, uma seta, e nada cobrado
version: 2
---

```python
def greet(name: str, times: int = 1) -> str:
    return f"hello, {name} " * times
```

Dois-pontos e um tipo depois de cada parâmetro, uma seta e um tipo antes dos dois-pontos que
terminam o cabeçalho. Um padrão vem depois da anotação: `times: int = 1`.

## Variáveis também

```python
rows: list[dict] = []
total: float = 0.0
path: Path                 # declared, not yet assigned
```

A última é uma anotação sem valor — válida, e útil no topo de um corpo de classe ou onde a
atribuição acontece dentro de um desvio.

## Nada é conferido em tempo de execução

```python
greet(3)          # runs; the annotation is not consulted
```

**O Python guarda as anotações e não age sobre elas.** `greet(3)` produz `hello, 3 ` — a f-string
formatou um inteiro sem reclamar. A falha, quando existe, acontece depois e em outro lugar.

Essa é a frase mais importante desta aula. Uma anotação de tipo é um recado para quem lê, para o
editor e para o verificador, e é a aula 15 que a lê.

## Onde as anotações ficam

```python
greet.__annotations__      # {'name': str, 'times': int, 'return': str}
```

Um dicionário na função. O `@dataclass` da aula 6 lia exatamente isso para saber quais eram os
campos — que é o único lugar deste curso em que uma anotação faz algo em tempo de execução.

## Referências para a frente

```python
class Node:
    def parent(self) -> "Node": ...       # a string, because Node is not finished yet
```

A classe não existe enquanto o corpo dela está sendo lido, então o nome vai entre aspas. O `from
__future__ import annotations` no topo do arquivo torna toda anotação preguiçosa e tira essa
necessidade — e vale num arquivo com muitas delas.

## E a que evitar

```python
def f(x: "whatever I feel like") -> "who knows": ...
```

Qualquer expressão é aceita, porque nada confere. Um verificador vai reclamar; o Python não.
