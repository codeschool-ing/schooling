---
title: "Obsessão por primitivos: dê um tipo ao conceito"
version: 1
---

**Obsessão por primitivos é usar os tipos embutidos da linguagem para ideias que o domínio já
batizou.** Um `int` que guarda dinheiro, um `str` que guarda um tipo de item, uma tupla cuja quinta
posição por acaso é o tipo. Cada um funciona, e cada um deixa as regras daquela ideia espalhadas por
quem mexe no valor. `report.py` tem dois casos claros.

O primeiro é o dinheiro. `total` e `f` são inteiros simples de centavos, e nada impede alguém de
somar uma multa a um número de dias, ou de imprimi-la sem `money()`. As regras do conceito, *são
centavos, somam com outro dinheiro, imprimem como reais*, moram na cabeça de quem o usa.

O segundo é a linha. `row[4]` é o tipo e `row[6]` é a data de devolução, e a única documentação é a
ordem dos valores em `LOANS`. Insira um campo no começo e todo índice do arquivo fica errado por um,
em silêncio.

## Trocar primitivo por objeto

O movimento de Fowler (*replace primitive with object*) é criar uma classe pequena para o conceito,
mudar as regras para dentro dela e trocar quem chama para usá-la. Para dinheiro, essa classe é um
objeto de valor do tipo que a lição 12 construiu: congelado, comparado por valor, com a aritmética
de que precisa e mais nada. Para a linha, um `NamedTuple` dá nome a cada posição sem deixar de ser
tupla, então quem passa tuplas simples continua intocado:

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\nfrom typing import NamedTuple\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]", "note": "Dois imports a mais, os dois da biblioteca padrão."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Money:\n    cents: int\n\n    def __add__(self, other: \"Money\") -> \"Money\":\n        return Money(self.cents + other.cents)\n\n    def times(self, n: int) -> \"Money\":\n        return Money(self.cents * n)\n\n    def __str__(self) -> str:\n        return f\"R$ {self.cents // 100},{self.cents % 100:02d}\"\n\n\nDAILY_FINE = Money(50)", "note": "`money()` virou `Money.__str__`: a formatação foi morar no tipo que ela formata. Dinheiro soma com dinheiro e multiplica por uma contagem; não existe `Money + int`, então somar dias a reais agora é um erro em vez de um número errado."},
 {"code": "\n\nclass Row(NamedTuple):\n    name: str\n    phone: str\n    email: str\n    title: str\n    kind: str\n    lent_on: date\n    returned_on: date | None", "note": "As posições ganham nome. Um `NamedTuple` continua sendo tupla, então `Row._make(t)` embrulha qualquer tupla de `LOANS` sem ficar copiando os valores."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on\n\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"", "note": "Intocadas. O tipo ainda é uma string, um terceiro primitivo deixado para a seção sobre switches."},
 {"code": "\n\ndef days_late(row, today):\n    end = row.returned_on or today\n    return (end - due_date(row.kind, row.lent_on)).days", "note": "`row[6]` e `row[4]` viraram `row.returned_on` e `row.kind`. Um erro de digitação num nome é um `AttributeError` na primeira execução; um índice errado era uma resposta errada."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = Money(0)\n    for row in map(Row._make, loans):\n        d = days_late(row, today)\n        if d > 0:\n            fine = DAILY_FINE.times(d)\n            total = total + fine\n            out.append(f\"{row.name} <{row.email}>: {label(row.kind)} '{row.title}', {d} days late, {fine}\")\n    out.append(f\"total: {total}\")\n    return \"\\n\".join(out)", "note": "A interface é mantida: quem chama continua passando tuplas. Cada uma é embrulhada na entrada, e `{fine}` na f-string chama `Money.__str__`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

Sem nome de arquivo, o `unittest` procura todo `test*.py` do diretório, que aqui é um só:

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest -v
test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (test_report.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## Por que uma classe de duas linhas vale a pena

A classe `Money` é curta e o arquivo ficou mais longo que antes, o que parece prejuízo. Conte do
outro jeito. **Toda regra sobre dinheiro agora tem uma casa**, e quem quiser saber como valores são
impressos ou somados abre uma classe. A próxima regra que a biblioteca acrescentar, recusar valores
negativos ou dividir uma multa em parcelas, tem um lugar óbvio para ir. E erros que eram silenciosos
ficam barulhentos: `Money(50) + 3` para com `AttributeError: 'int' object has no attribute 'cents'`
em vez de produzir quieto um número que não quer dizer nada.

O mesmo raciocínio vale para os identificadores, e-mails e telefones da linha, que continuam strings
simples. Se merecem tipos depende de carregarem regras. Um telefone que a biblioteca só imprime pode
continuar string; um que ela valida, normaliza e disca mereceu uma classe. **Embrulhe um primitivo
quando ele tiver comportamento para guardar, não por ritual.**

## O mesmo movimento na sua linguagem

| linguagem | um tipo de valor pequeno | um registro com nomes para a linha |
|---|---|---|
| Python | `@dataclass(frozen=True) class Money` | `class Row(NamedTuple)` ou uma dataclass congelada |
| Java | `record Money(long cents)` com métodos | `record Row(String name, ...)` |
| Go | `type Money struct{ cents int64 }` com métodos, ou `type Money int64` | uma `struct` com campos nomeados |
| TypeScript | uma `class Money` com campo privado, ou um tipo `number` com marca (branded) | uma `interface` ou `type` com propriedades nomeadas |

O `type Money int64` do Go merece uma nota: é um tipo novo que o compilador não mistura com um
`int64` simples sem conversão, e pode ter métodos, então dá quase toda a proteção com quase nenhum
código. A tipagem estrutural do TypeScript deixaria qualquer `number` passar por um apelido simples,
e é por isso que o tipo com marca existe.
