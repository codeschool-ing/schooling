---
title: Aglomerados de dados e inveja de funcionalidade
version: 1
---

**Dois cheiros que apontam para a mesma coisa que falta: uma classe que deveria existir e não
existe.** Um aglomerado de dados (*data clump*) é um grupo de valores que sempre andam juntos.
Inveja de funcionalidade (*feature envy*) é uma função que passa o tempo nos dados de outro objeto
em vez dos próprios. Os dois dizem que certos dados e o comportamento que os usa foram parar em
lugares diferentes, e os dois se resolvem juntando-os.

## O aglomerado

`name`, `phone` e `email` ficam lado a lado em toda linha, e qualquer função que precisasse contatar
um membro receberia os três. O teste de Fowler para um aglomerado é apagar um dos valores na cabeça
e perguntar se os outros ainda fazem sentido sozinhos. Um telefone sem a pessoa a quem pertence não
serve para nada, então os três são uma coisa só: um membro. **Quando valores só fazem sentido
juntos, eles são um objeto que ainda não ganhou nome.**

O mesmo vale, um nível acima, para o resto da linha. Um título, um tipo e duas datas são um
empréstimo, e o `Row` da seção anterior é um empréstimo sem comportamento.

## A inveja

`days_late(row, today)` lê `row.returned_on`, `row.kind` e `row.lent_on`, e mais nada além de
`today`. É uma pergunta sobre um empréstimo, feita de fora do empréstimo. A f-string em `report`
faz o mesmo com o membro: tira `name` e `email` e cola os dois em `Bia Souza <bia@example.org>`, um
formato que é um fato sobre como a biblioteca escreve o contato de um membro, onde quer que ele
apareça.

O movimento para a inveja é **mover função** (*move function*): ponha a função no objeto cujos dados
ela usa. Aí quem chama para de pedir os campos e pede ao objeto, que é o que o velho conselho *tell,
don't ask* quer dizer.

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]\n\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n\n    def __add__(self, other: \"Money\") -> \"Money\":\n        return Money(self.cents + other.cents)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n)\n\n    def __str__(self) -> str:\n        return f\"R$ {self.cents // 100},{self.cents % 100:02d}\"\n\n\nDAILY_FINE = Money(50)", "note": "Os dados e `Money` estão como a seção anterior deixou. `NamedTuple` não é mais importado: `Row` sumiu."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Member:\n    name: str\n    phone: str\n    email: str\n\n    def contact(self) -> str:\n        return f\"{self.name} <{self.email}>\"", "note": "O aglomerado, com nome. O jeito de escrever o contato de um membro se mudou para junto dos campos que ele usa, então a próxima tela que precisar chama `contact()` em vez de copiar a f-string."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on\n\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"", "note": "Ainda os dois switches sobre uma string. São o último cheiro, e o da próxima seção."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    member: Member\n    title: str\n    kind: str\n    lent_on: date\n    returned_on: date | None", "note": "`Row` virou `Loan`, e um empréstimo tem um membro em vez de três strings soltas: composição, como na lição 1."},
 {"code": "\n    @classmethod\n    def from_row(cls, row: tuple) -> \"Loan\":\n        name, phone, email, title, kind, lent_on, returned_on = row\n        return cls(Member(name, phone, email), title, kind, lent_on, returned_on)", "note": "O único lugar que sabe a ordem da tupla antiga. Se um dia quem chama passar a mandar empréstimos, só este método sai."},
 {"code": "\n    def days_late(self, today: date) -> int:\n        end = self.returned_on or today\n        return (end - due_date(self.kind, self.lent_on)).days", "note": "A função invejosa, de volta para casa. O corpo é o mesmo com `row.` trocado por `self.`, e é assim que se vê que ela sempre foi sobre um empréstimo."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = Money(0)\n    for loan in map(Loan.from_row, loans):\n        d = loan.days_late(today)\n        if d > 0:\n            fine = DAILY_FINE.times(d)\n            total = total + fine\n            out.append(f\"{loan.member.contact()}: {label(loan.kind)} '{loan.title}', {d} days late, {fine}\")\n    out.append(f\"total: {total}\")\n    return \"\\n\".join(out)", "note": "`report` agora pergunta ao empréstimo o quanto ele está atrasado e ao membro como escrever o contato dele. O que ele ainda faz sozinho é o trabalho do próprio relatório: decidir quais empréstimos aparecem e somar o total."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

Os mesmos dois testes, a mesma saída. A ordem dos movimentos importa aqui, e vale explicitar,
porque uma refatoração deste tamanho é justamente onde as pessoas dão um passo grande. Introduza
`Member` e monte-o em `report`, rode. Introduza `Loan` com `from_row`, ainda guardando o tipo como
string, rode. Mova `days_late` para `Loan` e troque o único lugar que a chama, rode. Acrescente
`contact()` e troque a f-string, rode. Quatro execuções verdes, e qualquer uma poderia ter sido um
commit.

## Quando não é inveja

Uma função que lê os campos de outro objeto nem sempre está no lugar errado. `report` lê o membro, o
empréstimo e a multa, e esse é o propósito dele: um relatório existe para combinar coisas que
pertencem a outros objetos. O cheiro é uma função que é *quase toda* sobre um outro objeto e ficaria
mais natural como método dele. Dois padrões separam dados de comportamento de propósito: uma
strategy (lição 6) mantém um algoritmo à parte para poder trocá-lo, e um visitor percorre uma
estrutura sem morar nela. **Inveja é um desencontro entre onde um comportamento mora e do que ele
trata**, não uma regra de que toda função só pode usar os próprios campos.
