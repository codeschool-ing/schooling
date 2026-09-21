---
title: Dois-pontos, uma seta, e nada cobrado
version: 1
---

```python
def saudar(nome: str, vezes: int = 1) -> str:
    return f"olá, {nome} " * vezes
```

Dois-pontos e um tipo depois de cada parâmetro, uma seta e um tipo antes dos dois-pontos que
terminam o cabeçalho. Um padrão vem depois da anotação: `vezes: int = 1`.

## Variáveis também

```python
linhas: list[dict] = []
total: float = 0.0
caminho: Path              # declarada, ainda não atribuída
```

A última é uma anotação sem valor — válida, e útil no topo de um corpo de classe ou onde a
atribuição acontece dentro de um desvio.

## Nada é conferido em tempo de execução

```python
saudar(3)         # roda; a anotação não é consultada
```

**O Python guarda as anotações e não age sobre elas.** `saudar(3)` produz `olá, 3 ` — a f-string
formatou um inteiro sem reclamar. A falha, quando existe, acontece depois e em outro lugar.

Essa é a frase mais importante desta aula. Uma anotação de tipo é um recado para quem lê, para o
editor e para o verificador, e é a aula 15 que a lê.

## Onde as anotações ficam

```python
saudar.__annotations__     # {'nome': str, 'vezes': int, 'return': str}
```

Um dicionário na função. O `@dataclass` da aula 6 lia exatamente isso para saber quais eram os
campos — que é o único lugar deste curso em que uma anotação faz algo em tempo de execução.

## Referências para a frente

```python
class No:
    def pai(self) -> "No": ...        # uma string, porque No ainda não terminou
```

A classe não existe enquanto o corpo dela está sendo lido, então o nome vai entre aspas. O `from
__future__ import annotations` no topo do arquivo torna toda anotação preguiçosa e tira essa
necessidade — e vale num arquivo com muitas delas.

## E a que evitar

```python
def f(x: "o que eu quiser") -> "vai saber": ...
```

Qualquer expressão é aceita, porque nada confere. Um verificador vai reclamar; o Python não.
