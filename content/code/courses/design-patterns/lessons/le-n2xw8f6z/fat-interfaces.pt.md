---
title: O que uma interface gorda custa
version: 1
---

**Uma interface gorda é uma que promete mais do que alguns de seus implementadores conseguem
entregar ou do que alguns de seus clientes precisam.** A primeira metade quebra a substituição,
porque um implementador que não consegue fazer algo tem de recusar. A segunda metade espalha a
mudança, porque um cliente preso a métodos que nunca chama é afetado quando eles mudam. A lição 3
encontrou a primeira metade sem dar nome a ela.

É tentador acreditar que uma interface ampla é generosa: ofereça tudo, e cada cliente pega o que
quiser. O problema é que um tipo é uma promessa nos dois sentidos. Uma classe que diz implementar
uma interface promete todos os métodos dela, e um cliente que pede uma interface pode receber
qualquer coisa que faça essa promessa.

## Três sintomas

| sintoma | onde você já viu |
|---|---|
| implementadores que levantam `NotImplementedError` ou recusam um método | `ReferenceBook.lend` na lição 3 |
| dublês de teste que precisam simular métodos que o teste nunca toca | `OneTitle` na seção anterior |
| uma mudança num método forçando recompilações ou edições em clientes sem relação | a impressora de Martin na Xerox |

Os três vêm de uma causa só: a interface ganhou o formato do **implementador**, a coisa que por acaso
tinha todos aqueles métodos, em vez do formato dos clientes que a usam.

## O livro de referência de novo

A lição 3 terminou com um veredito sobre `ReferenceBook`: ele não é emprestável, e a hierarquia
dizia que era. A hierarquia dizia isso porque `Item` guardava duas promessas ao mesmo tempo, *posso
ser descrito* e *posso ser emprestado*, e todo item tinha de fazer as duas. Segregá-las significa
duas declarações: uma classe para o que todo item tem, e um protocolo para a capacidade que só
alguns itens têm.

```schooling-example
{"language": "python", "file": "items.py", "parts": [
 {"code": "# items.py\nfrom datetime import date, timedelta\nfrom typing import Protocol, runtime_checkable\n\n\nclass Item:\n    def __init__(self, title: str):\n        self.title = title\n\n    def describe(self) -> str:\n        return self.title", "note": "O que todo item da biblioteca tem: um título e um jeito de se descrever. Nada sobre empréstimo."},
 {"code": "\n\n@runtime_checkable\nclass Lendable(Protocol):\n    title: str\n\n    def lend(self, on: date) -> date: ...", "note": "A capacidade, declarada à parte. `runtime_checkable` deixa `isinstance` perguntar se um objeto tem o formato; normalmente um protocolo serve só para verificadores de tipos."},
 {"code": "\n\nclass Book(Item):\n    def lend(self, on: date) -> date:\n        return on + timedelta(days=14)\n\n\nclass Film(Item):\n    def lend(self, on: date) -> date:\n        return on + timedelta(days=7)", "note": "Livros e filmes são itens e também têm `lend`, então satisfazem `Lendable` sem citá-lo."},
 {"code": "\n\nclass ReferenceBook(Item):\n    def describe(self) -> str:\n        return f\"{self.title}, reading room only\"", "note": "O livro de referência é um item e não diz ser emprestável. Não tem nada a recusar."},
 {"code": "\n\ndef catalogue_page(items: list[Item]) -> None:\n    for item in items:\n        print(\"*\", item.describe())\n\n\ndef check_out(items: list[Lendable], on: date) -> None:\n    for item in items:\n        print(f\"{item.title:<22} due {item.lend(on)}\")", "note": "Cada cliente pede o que usa. A página do catálogo aceita qualquer `Item`; o balcão aceita só o que pode ser emprestado."},
 {"code": "\n\nif __name__ == \"__main__\":\n    book, film, dictionary = Book(\"Dom Casmurro\"), Film(\"Central do Brasil\"), ReferenceBook(\"Aurélio\")\n    catalogue_page([book, film, dictionary])\n    check_out([book, film], date(2026, 3, 2))\n    print([isinstance(x, Lendable) for x in (book, film, dictionary)])"}
]}
```

```
ana@laptop:~/patterns/solid-2$ python3 items.py
* Dom Casmurro
* Central do Brasil
* Aurélio, reading room only
Dom Casmurro           due 2026-03-16
Central do Brasil      due 2026-03-09
[True, True, False]
```

Os três aparecem na página do catálogo, dois são emprestados, e a última linha confirma o formato: o
livro e o filme são `Lendable`, o dicionário não. **Nada neste programa recusa coisa alguma, porque
nada afirma o que não consegue fazer.** O teste de contrato da lição 3 agora rodaria sobre coisas
`Lendable`, e `ReferenceBook` nunca estaria na lista dele.

## De onde a interface gorda costuma vir

Interfaces gordas raramente são projetadas. Elas são extraídas: alguém tem uma classe com quinze
métodos, precisa de uma interface para testes ou para uma segunda implementação, e levanta os quinze
numa só. A interface então descreve a classe, e todo cliente herda a superfície inteira da classe.

A alternativa é perguntar a cada cliente o que ele chama e dar um nome a essa lista. Para o catálogo
isso dá três nomes, e eles são o assunto da próxima seção. **Uma interface pertence mais ao cliente
que a usa do que à classe que a implementa**, e essa também é a primeira metade da inversão de
dependência, duas seções adiante.
