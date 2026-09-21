---
title: O que ele precisa FAZER, em vez do que precisa SER
version: 1
---

```python
from typing import Protocol

class Escritor(Protocol):
    def write(self, texto: str) -> int: ...

def relatar(saida: Escritor, linhas: list[dict]) -> None:
    saida.write(formatar(linhas))
```

O `relatar` aceita qualquer coisa com um método `write(str) -> int`. Um arquivo, um `io.StringIO`,
um invólucro de socket, um dublê de teste que você escreveu em quatro linhas — **e nenhum deles
precisa importar o `Escritor` nem herdar de nada.**

## Por que este é o pythônico

A tipagem pato sempre foi a resposta da linguagem: se tem o método, funciona. Toda anotação até
aqui foi o oposto — nomear uma classe e exigir aquela classe ou uma subclasse.

Um `Protocol` anota a tipagem pato em vez de abrir mão dela. A conferência é ESTRUTURAL: o
verificador compara os métodos, e não a ascendência.

## Onde ele ganha o lugar

```python
class TemClose(Protocol):
    def close(self) -> None: ...
```

- uma função que recebe "algo com um `read`"
- um dublê de teste, que agora não precisa de classe base nem de biblioteca de mock
- uma fronteira entre dois módulos, onde o argumento de composição da aula 6 se aplica

## Os que já estão escritos

```python
from typing import SupportsInt, SupportsFloat
from collections.abc import Iterable, Sized
```

`Iterable` e `Sized` são protocolos com outro nome — é por isso que `Iterable[str]` aceita um
gerador, um conjunto e uma lista sem que nenhum deles tenha relação com os outros.

## `runtime_checkable`

```python
@runtime_checkable
class Escritor(Protocol): ...

isinstance(f, Escritor)     # agora permitido — e ele confere só os NOMES
```

Um `isinstance` contra um protocolo precisa do decorador, e ele confere que os métodos existem, e
não o que eles recebem ou devolvem. Útil, e mais fraco que o que o verificador faz.

## E o custo

Um `Protocol` é mais um nome num arquivo. Para dois métodos usados num lugar, a classe que você já
tem é mais simples — isto é para a fronteira que você quer poder substituir.
