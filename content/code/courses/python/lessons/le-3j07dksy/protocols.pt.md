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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Nomear uma classe exige aquela classe ou uma subclasse, então qualquer coisa escrita em outro lugar é recusada por melhor que sirva. Um Protocol compara os métodos, então os mesmos três objetos são aceitos sem importar nada e sem herdar de nada.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"182\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">por nome — tem de herdar</text> <rect x=\"20\" y=\"36\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"182\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">class Escritor</text> <rect x=\"20\" y=\"92\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SeuEscritor(Escritor)</text> <path d=\"M182 86 L182 72\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"20\" y=\"136\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"182\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">io.StringIO</text> <rect x=\"20\" y=\"180\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"182\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">um dublê de teste de quatro linhas</text> <text x=\"182\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">os dois sem seta não herdam de nada nosso</text> <text x=\"558\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">por forma — tem de ter o método</text> <rect x=\"396\" y=\"36\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">write(self, texto: str) -&gt; int</text> <rect x=\"396\" y=\"92\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SeuEscritor(Escritor)</text> <rect x=\"396\" y=\"136\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">io.StringIO</text> <rect x=\"396\" y=\"180\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">um dublê de teste de quatro linhas</text> <text x=\"558\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">os três: cada um deles tem o método</text> </svg>", "caption": "Um Protocol não abre mão da tipagem pato — ele a anota. A conferência compara os métodos, e não a ascendência."}
```

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
