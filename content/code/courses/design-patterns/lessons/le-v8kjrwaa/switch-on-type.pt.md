---
title: "Switch sobre tipo: troque o condicional por polimorfismo"
version: 1
---

**Um `if` sobre um código de tipo não é problema. O mesmo `if` em dois lugares é a promessa de que o
próximo tipo novo vai ser acrescentado num deles e esquecido no outro.** `due_date` e `label`
desviam os dois em `kind == "book"` e `kind == "film"`, e o conhecimento *que tipos existem e como
cada um se comporta* está dividido entre eles. Uma terceira função, digamos uma que decide se um
item pode ser renovado, ganharia uma terceira cópia.

O movimento é **trocar condicional por polimorfismo** (*replace conditional with polymorphism*), a
ideia dos avisos da lição 1 aplicada a código que já existe: uma classe por tipo, cada uma
respondendo às perguntas que os ramos respondiam, e quem chama perguntando ao objeto em vez de
testar o código.

## Primeiro, alargue a rede

As seções anteriores nunca tocaram nos ramos `else`, e a rede de segurança nunca chegou a eles: os
dois testes usam livros e filmes. Este movimento reescreve esses ramos, então a rede precisa
cobri-los antes. Acrescente um terceiro teste de caracterização com um tipo que não é nenhum dos
dois, rode contra o código como está, e veja passar:

```python
# test_report.py
import unittest
from datetime import date
from pathlib import Path

from report import LOANS, report

ON_TIME = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Vidas Secas", "book", date(2026, 3, 2), date(2026, 3, 16))]
MAGAZINE = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Piauí", "magazine", date(2026, 3, 20), date(2026, 3, 23))]


class ReportCharacterisation(unittest.TestCase):
    def test_the_march_report(self):
        approved = Path("approved.txt").read_text()
        self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)

    def test_a_month_with_nobody_late(self):
        self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "total: R$ 0,00")

    def test_a_kind_that_is_neither_book_nor_film(self):
        self.assertEqual(report(MAGAZINE, date(2026, 3, 31)),
                         "Eva Rocha <eva@example.org>: item 'Piauí', 3 days late, R$ 1,50\ntotal: R$ 1,50")


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py -v
test_a_kind_that_is_neither_book_nor_film (__main__.ReportCharacterisation.test_a_kind_that_is_neither_book_nor_film) ... ok
test_a_month_with_nobody_late (__main__.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (__main__.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

Leia o que o teste novo fixa: **uma revista vence no dia em que é emprestada**, então três dias fora
custam 150 centavos. Isso é quase certamente um bug, um `else` em que ninguém pensou. Ele fica
registrado exatamente como é, anotado na lista para as bibliotecárias, e é deixado em paz.
Corrigi-lo dentro de uma refatoração faria a suíte de testes não conseguir mais distinguir as duas
mudanças.

## Uma classe por tipo

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\nfrom typing import Protocol\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]\n\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n\n    def __add__(self, other: \"Money\") -> \"Money\":\n        return Money(self.cents + other.cents)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n)\n\n    def __str__(self) -> str:\n        return f\"R$ {self.cents // 100},{self.cents % 100:02d}\"\n\n\nDAILY_FINE = Money(50)\n\n\n@dataclass(frozen=True)\nclass Member:\n    name: str\n    phone: str\n    email: str\n\n    def contact(self) -> str:\n        return f\"{self.name} <{self.email}>\"", "note": "Tudo acima dos tipos está como a seção anterior deixou."},
 {"code": "\n\nclass Kind(Protocol):\n    label: str\n\n    def due(self, lent_on: date) -> date: ...", "note": "O que todo tipo precisa responder: o rótulo, e a data de vencimento para um dado dia de empréstimo. As duas perguntas que os dois switches respondiam."},
 {"code": "\n\nclass Book:\n    label = \"book\"\n\n    def due(self, lent_on: date) -> date:\n        return lent_on + timedelta(days=14)\n\n\nclass Film:\n    label = \"film (DVD)\"\n\n    def due(self, lent_on: date) -> date:\n        return lent_on + timedelta(days=7)", "note": "Cada ramo de cada cadeia foi para a classe de que tratava. Tudo sobre um filme agora está num lugar só."},
 {"code": "\n\nclass OtherItem:\n    label = \"item\"\n\n    def due(self, lent_on: date) -> date:\n        return lent_on", "note": "Os dois ramos `else`, mantidos com fidelidade, bug incluído: vence no dia em que foi emprestado. O terceiro teste é o que prova que ele foi mantido."},
 {"code": "\n\nKINDS: dict[str, Kind] = {\"book\": Book(), \"film\": Film()}", "note": "As strings continuam chegando de quem chama, então sobra uma consulta de string para objeto. É a única, na borda, em vez de um switch em cada função que se importa."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    member: Member\n    title: str\n    kind: Kind\n    lent_on: date\n    returned_on: date | None\n\n    @classmethod\n    def from_row(cls, row: tuple) -> \"Loan\":\n        name, phone, email, title, kind, lent_on, returned_on = row\n        return cls(Member(name, phone, email), title, KINDS.get(kind, OtherItem()), lent_on, returned_on)\n\n    def days_late(self, today: date) -> int:\n        end = self.returned_on or today\n        return (end - self.kind.due(self.lent_on)).days", "note": "Um empréstimo guarda um objeto `Kind` em vez de uma string, e pede a ele a data de vencimento. `due_date()` e `label()` sumiram."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = Money(0)\n    for loan in map(Loan.from_row, loans):\n        d = loan.days_late(today)\n        if d > 0:\n            fine = DAILY_FINE.times(d)\n            total = total + fine\n            out.append(f\"{loan.member.contact()}: {loan.kind.label} '{loan.title}', {d} days late, {fine}\")\n    out.append(f\"total: {total}\")\n    return \"\\n\".join(out)\n\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))", "note": "`label(loan.kind)` virou `loan.kind.label`. Fora isso, `report` não mudou neste passo."}
]}
```

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py -v
test_a_kind_that_is_neither_book_nor_film (__main__.ReportCharacterisation.test_a_kind_that_is_neither_book_nor_film) ... ok
test_a_month_with_nobody_late (__main__.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (__main__.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

E a comparação que abriu a lição, feita uma última vez à mão:

```
ana@laptop:~/patterns/refactoring$ python3 report.py | diff - approved.txt && echo identical
identical
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l14-kinds\" aria-label=\"Antes e depois de trocar o condicional por polimorfismo. À esquerda, antes: duas funções, due_date e label, cada uma com a mesma cadeia de testes sobre a string do tipo: book, film, qualquer outra coisa. À direita, depois: Loan tem um Kind, desenhado com um losango do lado de Loan. Kind é um protocolo com um label e um método due. Book, Film e OtherItem o implementam. Um dicionário, KINDS, transforma a string que chega num Kind uma vez, quando o empréstimo é montado.\"><defs><marker id=\"l14-kinds-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">antes: um switch, escrito duas vezes</text><rect x=\"30.0\" y=\"44.0\" width=\"220.0\" height=\"71.1\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"54.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">due_date(kind, lent_on)</text><path d=\"M30.0 65.8 L250.0 65.8\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"38.0\" y=\"76.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">if kind == &quot;book&quot;: +14</text><text x=\"38.0\" y=\"90.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">elif kind == &quot;film&quot;: +7</text><text x=\"38.0\" y=\"104.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">else: +0</text><rect x=\"30.0\" y=\"156.0\" width=\"220.0\" height=\"71.1\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"166.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">label(kind)</text><path d=\"M30.0 177.8 L250.0 177.8\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"38.0\" y=\"188.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">if kind == &quot;book&quot;: &quot;book&quot;</text><text x=\"38.0\" y=\"202.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">elif kind == &quot;film&quot;: ...</text><text x=\"38.0\" y=\"216.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">else: &quot;item&quot;</text><text x=\"140.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">um tipo novo: achar as duas cadeias</text><path d=\"M290.0 14.0 L290.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"505.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">depois: cada tipo responde por si</text><rect x=\"315.0\" y=\"44.0\" width=\"150.0\" height=\"92.9\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"54.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M315.0 65.8 L465.0 65.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"323.0\" y=\"76.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">member</text><text x=\"323.0\" y=\"90.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">title</text><text x=\"323.0\" y=\"104.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">kind: Kind</text><path d=\"M315.0 115.1 L465.0 115.1\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"323.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">days_late()</text><rect x=\"560.0\" y=\"52.0\" width=\"130.0\" height=\"79.1\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"62.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"625.0\" y=\"76.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">Kind</text><path d=\"M560.0 87.5 L690.0 87.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"98.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">label</text><path d=\"M560.0 109.3 L690.0 109.3\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"120.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">due(lent_on)</text><path d=\"M465.0 84.0 L560.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M465.0 84.0 L474.0 89.5 L483.0 84.0 L474.0 78.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><rect x=\"410.0\" y=\"200.0\" width=\"90.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><path d=\"M455.0 200.0 L455.0 178.0 L625.0 178.0 L625.0 131.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M625.0 131.1 L632.0 143.1 L618.0 143.1 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"510.0\" y=\"200.0\" width=\"90.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"555.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Film</text><path d=\"M555.0 200.0 L555.0 178.0 L625.0 178.0 L625.0 131.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M625.0 131.1 L632.0 143.1 L618.0 143.1 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"610.0\" y=\"200.0\" width=\"90.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">OtherItem</text><path d=\"M655.0 200.0 L655.0 178.0 L625.0 178.0 L625.0 131.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M625.0 131.1 L632.0 143.1 L618.0 143.1 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"315.0\" y=\"245.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">KINDS: str → Kind</text><path d=\"M390.0 245.0 L390.0 138.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-kinds-dp-ah-paper-dim)\"></path><text x=\"398.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">usado uma vez, em from_row</text><text x=\"560.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">um tipo novo: uma classe, uma entrada</text></svg>", "caption": "O conhecimento do que cada tipo faz sai dos switches e vai para os tipos."}
```

## O que isso comprou, e quando uma tabela basta

Acrescentar um tipo agora é uma classe e uma entrada em `KINDS`, e nada mais no arquivo se mexe. Uma
regra de renovação seria um método em `Kind`, e o verificador de tipos apontaria todo tipo que não o
tivesse. Esse é o princípio aberto/fechado da lição 3, alcançado refatorando em vez de projetado de
antemão.

Seja honesto sobre este caso, porém. `Book` e `Film` diferem só em dois valores, um número de dias e
um rótulo, e uma tabela os carregaria com menos código:
`{"book": (14, "book"), "film": (7, "film (DVD)")}`. **O polimorfismo se paga quando os ramos guardam
comportamento diferente**, não dados diferentes: um livro de referência que se recusa a ser
emprestado, um filme cujo vencimento pula os dias em que a biblioteca está fechada. Até lá, um
dicionário de valores é o projeto mais simples, e levar os ramos para um deles é uma refatoração tão
legítima quanto esta. As classes daqui são a versão a buscar no dia em que um ramo ganhar código de
verdade.

O relatório imprime o que imprimia no começo, byte a byte, e todo passo do caminho rodou verde. O
arquivo é mais longo que o original, e cada pergunta que um leitor possa trazer agora tem um lugar
para olhar: como o dinheiro é impresso, como um membro é escrito, quando cada tipo vence, quais
empréstimos aparecem.
