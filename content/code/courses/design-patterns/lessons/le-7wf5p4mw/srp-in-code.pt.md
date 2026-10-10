---
title: Dividir uma classe pelos seus atores
version: 1
---

**Para aplicar o princípio da responsabilidade única, liste quem pede mudanças numa classe, depois
dê a cada um deles um trecho de código próprio e uma função pequena que junta os trechos.** O
comportamento continua exatamente igual. O que muda é onde o próximo pedido vai cair.

O erro a evitar é dividir por tamanho. Uma classe longa não está necessariamente fazendo dois
trabalhos, e uma curta pode estar fazendo três. A classe desta seção tem menos de vinte linhas e
responde a três pessoas diferentes.

## Um relatório com três donos

Toda manhã a biblioteca manda ao setor de multas uma lista dos empréstimos atrasados. Uma classe faz
isso:

```python
# report_service.py
from datetime import date, timedelta


class ReportService:
    def __init__(self, loans: list[tuple[str, str, date]]):
        self.loans = loans

    def run(self, today: date) -> None:
        lines, total = [], 0
        for title, member, lent_on in self.loans:
            late = (today - (lent_on + timedelta(days=14))).days
            if late > 0:
                total += late * 50
                lines.append(f"{title:<16}{member:<20}{late * 50:>6}")
        lines.append(f"{'total':<36}{total:>6}")
        print("To: fines@example.org")
        print("Subject: overdue loans on", today.isoformat())
        print()
        print("\n".join(lines))


if __name__ == "__main__":
    ReportService([
        ("Dom Casmurro", "bia@example.org", date(2026, 3, 2)),
        ("Iracema", "caio@example.org", date(2026, 3, 20)),
        ("Vidas Secas", "duda@example.org", date(2026, 3, 9)),
    ]).run(date(2026, 4, 1))
```

```
ana@laptop:~/patterns/solid-1$ python3 report_service.py
To: fines@example.org
Subject: overdue loans on 2026-04-01

Dom Casmurro    bia@example.org        800
Vidas Secas     duda@example.org       450
total                                 1250
```

Leia `run` e pergunte quem pediria que cada linha mudasse. O 14 e o 50 são do **setor de multas**.
As larguras das colunas e a linha de total são de quem **lê** o relatório, a coordenadora do
balcão, que já pediu uma planilha. O `To:` e o `Subject:` são da **TI**, que um dia vai trocar o
print por um servidor de e-mail de verdade. Três atores, um método, e uma mudança para qualquer um
deles significa editar o código de que os outros dois dependem.

## O mesmo relatório, em três partes

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Dom Casmurro\", \"bia@example.org\", date(2026, 3, 2)),\n    (\"Iracema\", \"caio@example.org\", date(2026, 3, 20)),\n    (\"Vidas Secas\", \"duda@example.org\", date(2026, 3, 9)),\n]", "note": "Os mesmos três empréstimos, guardados no módulo para o próximo programa poder reaproveitá-los."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Overdue:\n    title: str\n    member: str\n    cents: int", "note": "O que as partes passam umas para as outras: um empréstimo atrasado e a multa dele. Um valor pequeno é a fronteira entre elas."},
 {"code": "\n\nclass FineCalculator:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def overdue(self, loans: list[tuple[str, str, date]], today: date) -> list[Overdue]:\n        rows = []\n        for title, member, lent_on in loans:\n            late = (today - (lent_on + timedelta(days=self.LOAN_DAYS))).days\n            if late > 0:\n                rows.append(Overdue(title, member, late * self.DAILY_FINE))\n        return rows", "note": "A parte do setor de multas. Conhece as regras e nada de colunas ou e-mail."},
 {"code": "\n\nclass TextReport:\n    def render(self, rows: list[Overdue]) -> str:\n        lines = [f\"{r.title:<16}{r.member:<20}{r.cents:>6}\" for r in rows]\n        lines.append(f\"{'total':<36}{sum(r.cents for r in rows):>6}\")\n        return \"\\n\".join(lines)", "note": "A parte de quem lê. Transforma linhas em texto e não sabe como uma multa é calculada."},
 {"code": "\n\nclass ConsoleMailer:\n    def send(self, to: str, subject: str, body: str) -> None:\n        print(\"To:\", to)\n        print(\"Subject:\", subject)\n        print()\n        print(body)", "note": "A parte da TI. O print faz o papel de um servidor de e-mail, e trocá-lo não mexe em nada acima."},
 {"code": "\n\ndef send_overdue_report(today: date, calculator: FineCalculator, report, mailer) -> None:\n    rows = calculator.overdue(LOANS, today)\n    mailer.send(\"fines@example.org\", f\"overdue loans on {today.isoformat()}\", report.render(rows))", "note": "Duas linhas que juntam as partes. Esta função é dona da ordem dos passos e de nenhum detalhe deles."},
 {"code": "\n\nif __name__ == \"__main__\":\n    send_overdue_report(date(2026, 4, 1), FineCalculator(), TextReport(), ConsoleMailer())"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 report.py
To: fines@example.org
Subject: overdue loans on 2026-04-01

Dom Casmurro    bia@example.org        800
Vidas Secas     duda@example.org       450
total                                 1250
```

A mesma saída, byte por byte. Dividir pelos atores é uma refatoração: nada do que o usuário vê
muda.

## A planilha da coordenadora

Agora chega o pedido: a coordenadora quer linhas que possa colar numa planilha. Com as partes
separadas, é uma parte nova e mais nada:

```python
# csv_report.py
from datetime import date

from report import ConsoleMailer, FineCalculator, Overdue, send_overdue_report


class CsvReport:
    def render(self, rows: list[Overdue]) -> str:
        lines = ["title,member,cents"]
        lines += [f"{r.title},{r.member},{r.cents}" for r in rows]
        return "\n".join(lines)


if __name__ == "__main__":
    send_overdue_report(date(2026, 4, 1), FineCalculator(), CsvReport(), ConsoleMailer())
```

```
ana@laptop:~/patterns/solid-1$ python3 csv_report.py
To: fines@example.org
Subject: overdue loans on 2026-04-01

title,member,cents
Dom Casmurro,bia@example.org,800
Vidas Secas,duda@example.org,450
```

`report.py` não foi editado, então as regras de multa e o código de e-mail não podem ter sido
quebrados por essa mudança. **É isso que o princípio compra: o pedido de um ator chega só ao código
desse ator.** Um teste de `FineCalculator` agora consegue verificar multas comparando listas de
valores `Overdue`, sem saída para interpretar e sem e-mail para interceptar.

Repare também que o relatório em CSV foi acrescentado sem editar nada. Esse é o próximo princípio,
chegando antes da hora porque a divisão abriu espaço para ele.

## Até onde dividir

Três atores deram três partes. Uma quarta classe para a linha de total, ou uma por coluna,
responderia à mesma coordenadora que `TextReport` e não compraria nada. Em Java ou Go essas três
seriam normalmente três arquivos, ou três tipos num pacote; em Python um módulo com três classes
pequenas é normal. O princípio liga para que código muda junto, não para quantos arquivos ele ocupa.
