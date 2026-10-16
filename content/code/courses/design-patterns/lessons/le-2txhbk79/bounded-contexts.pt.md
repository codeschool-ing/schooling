---
title: "Contextos delimitados: onde uma palavra deixa de querer dizer uma coisa"
version: 1
---

**Um contexto delimitado (*bounded context*) é a fronteira dentro da qual um modelo, e a linguagem
que vem com ele, vale sem exceções.** Lá dentro, *livro* quer dizer uma coisa. Lá fora, *livro* pode
querer dizer outra, e isso é permitido. A fronteira é traçada de propósito, no código, para que os
dois significados nunca dividam uma classe.

A ideia errada é o modelo corporativo único: uma só classe `Book` que o sistema inteiro compartilha,
com todo campo de que alguém já precisou. Começa razoável e cresce. O catálogo acrescenta
`subjects`, o empréstimo acrescenta `barcode` e `on_loan_to`, as aquisições acrescentam `supplier` e
`unit_cents`. Logo metade dos campos é `None` em qualquer uso, ninguém sabe dizer se `Book` é um
título ou um exemplar na estante, e uma mudança pedida pelas aquisições precisa da revisão do
empréstimo. **Um modelo para todo mundo vira um modelo certo para ninguém.**

## Três livros

Pergunte a três pessoas da biblioteca o que é um livro. A catalogadora diz: uma obra com ISBN,
título, autores e assuntos. Quem está no balcão de empréstimo diz: a coisa com etiqueta de código de
barras, que está na estante ou com alguém. Quem encomenda dos fornecedores diz: uma linha num pedido,
com fornecedor, preço e quantidade. As três estão certas, dentro do próprio trabalho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-three-books\" aria-label=\"Três contextos delimitados lado a lado, cada um uma fronteira tracejada com a própria classe chamada Book. Em acquisitions, Book tem isbn, supplier, unit_cents e quantity, e o método total_cents. No catálogo, Book tem isbn, title, authors e subjects, e o método citation. Em lending, Book tem barcode, isbn, loan_days e on_loan_to, e o método lend. Os três se ligam só pelo campo isbn, que uma linha abaixo das três caixas conecta; um Book do catálogo corresponde a muitos Books de lending, um por exemplar.\"><rect x=\"20.0\" y=\"14.0\" width=\"200.0\" height=\"172.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">aquisições</text><text x=\"120.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">&quot;uma linha num pedido&quot;</text><rect x=\"50.0\" y=\"66.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"77.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M50.0 88.5 L190.0 88.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"58.0\" y=\"99.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">isbn</text><text x=\"58.0\" y=\"114.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">supplier</text><text x=\"58.0\" y=\"128.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">unit_cents</text><text x=\"58.0\" y=\"143.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">quantity</text><path d=\"M50.0 154.5 L190.0 154.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"58.0\" y=\"165.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">total_cents()</text><rect x=\"260.0\" y=\"14.0\" width=\"200.0\" height=\"172.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">catálogo</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">&quot;uma obra com ISBN&quot;</text><rect x=\"290.0\" y=\"66.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"77.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M290.0 88.5 L430.0 88.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"298.0\" y=\"99.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">isbn</text><text x=\"298.0\" y=\"114.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title</text><text x=\"298.0\" y=\"128.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">authors</text><text x=\"298.0\" y=\"143.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">subjects</text><path d=\"M290.0 154.5 L430.0 154.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"298.0\" y=\"165.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">citation()</text><rect x=\"500.0\" y=\"14.0\" width=\"200.0\" height=\"172.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"600.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">empréstimo</text><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">&quot;a coisa com código de barras&quot;</text><rect x=\"530.0\" y=\"66.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"77.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M530.0 88.5 L670.0 88.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"99.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">barcode</text><text x=\"538.0\" y=\"114.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">isbn</text><text x=\"538.0\" y=\"128.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loan_days</text><text x=\"538.0\" y=\"143.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">on_loan_to</text><path d=\"M530.0 154.5 L670.0 154.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"165.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend()</text><path d=\"M120.0 186.0 L120.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M360.0 186.0 L360.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M600.0 186.0 L600.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M120.0 210.0 L600.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ligados só pelo ISBN, nunca por compartilhar a classe</text><text x=\"660.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">muitos por ISBN</text></svg>", "caption": "Uma palavra, três modelos. Cada contexto fica com o Book que a sua gente quer dizer, e o ISBN é a única coisa em comum."}
```

Então cada contexto ganha o próprio `Book`, no próprio módulo. Três arquivos curtos:

```python
# catalogue.py
from dataclasses import dataclass


@dataclass(frozen=True)
class Book:
    isbn: str
    title: str
    authors: tuple[str, ...]
    subjects: tuple[str, ...]

    def citation(self) -> str:
        return f"{', '.join(self.authors)}. {self.title}."
```

```python
# lending.py
from dataclasses import dataclass


@dataclass
class Book:
    barcode: str
    isbn: str
    loan_days: int = 14
    on_loan_to: str | None = None

    def lend(self, member: str) -> None:
        if self.on_loan_to is not None:
            raise ValueError(f"copy {self.barcode} is out to {self.on_loan_to}")
        self.on_loan_to = member
```

```python
# acquisitions.py
from dataclasses import dataclass


@dataclass(frozen=True)
class Book:
    isbn: str
    supplier: str
    unit_cents: int
    quantity: int

    def total_cents(self) -> int:
        return self.unit_cents * self.quantity
```

E um quarto que leva um título pelos três. Ele importa os módulos pelo nome e escreve
`lending.Book` e `catalogue.Book` por extenso, para ficar sempre claro de que livro se trata:

```python
# tour.py
import acquisitions
import catalogue
import lending

ISBN = "978-65-5555-001-6"

ordered = acquisitions.Book(ISBN, "Livraria Paulista", unit_cents=4990, quantity=2)
described = catalogue.Book(ISBN, "Vidas Secas", ("Graciliano Ramos",), ("Brazilian fiction", "drought"))
copies = [lending.Book("C-0107", ISBN), lending.Book("C-0108", ISBN)]

print("acquisitions:", ordered.quantity, "copies,", ordered.total_cents(), "cents")
print("catalogue:   ", described.citation())
copies[0].lend("Bia")
for copy in copies:
    print("lending:     ", copy.barcode, "out to", copy.on_loan_to)
print("shared:      ", {ordered.isbn, described.isbn, copies[0].isbn})
```

```
ana@laptop:~/patterns/ddd-strategic$ python3 tour.py
acquisitions: 2 copies, 9980 cents
catalogue:    Graciliano Ramos. Vidas Secas.
lending:      C-0107 out to Bia
lending:      C-0108 out to None
shared:       {'978-65-5555-001-6'}
```

Uma linha de pedido para dois exemplares, 9980 centavos. Uma entrada de catálogo. Dois livros do
empréstimo, um com Bia e outro na estante. A única coisa que os três têm em comum é o ISBN, e a
última linha mostra que é a mesma string em todos. É assim que contextos se referem uns aos outros:
**por um identificador estável, nunca compartilhando o objeto.** O catálogo pode acrescentar amanhã
um campo para o tradutor, e o empréstimo nem vai notar.

Repare no que o `Book` do empréstimo é de fato: um exemplar, muitos por ISBN. O pessoal do
empréstimo continua chamando de livro, e dentro do contexto do empréstimo essa é a palavra certa.
Renomeá-lo para `Copy` em todo lugar para agradar às catalogadoras faria o código do empréstimo
falar uma língua que o balcão não fala.

## Uma fronteira no código, não necessariamente na rede

Um contexto delimitado é uma fronteira de significado. Ele não precisa ser um serviço separado, um
banco separado ou uma equipe separada, embora possa ser qualquer um desses. Num só programa, é um
módulo ou um pacote com a regra de que os outros não mexem nas suas classes:

| linguagem | a fronteira usual de um contexto num só programa |
|---|---|
| Python | um pacote; os outros contextos importam só o que o `__init__.py` dele expõe |
| Java | um pacote, ou um módulo JPMS cujo `module-info.java` exporta um único pacote de API |
| Go | um pacote, com um diretório `internal/` que outros pacotes não conseguem importar |
| TypeScript | um pacote do workspace, ou uma pasta com um `index.ts` que os outros importam |

O `internal/` do Go é o mais rígido dos quatro, porque o compilador recusa o import. Nos outros a
linha é uma convenção, mantida por revisão ou por uma regra de lint, a mesma troca que a lição 1
encontrou com o sublinhado do Python.
