---
title: Avisos de multa atrás de um Notifier
version: 1
---

**O projeto invertido tem três arquivos com três trabalhos: as regras e o protocolo de que são
donas, os adaptadores que se encaixam no protocolo, e um arquivo curto que liga um ao outro.** As
regras não importam nada do código da própria biblioteca. Os adaptadores importam o protocolo das
regras. Só o arquivo de ligação conhece os dois.

Você pode esperar que a versão invertida seja mais longa e mais abstrata que a óbvia. Ela tem
algumas linhas a mais. Não é mais abstrata: todo nome nela é uma palavra que a biblioteca usa, e o
único protocolo tem um método.

## As regras, com o protocolo de que precisam

```schooling-example
{"language": "python", "file": "notices.py", "parts": [
 {"code": "# notices.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\nfrom typing import Protocol", "note": "Só biblioteca padrão. Nada aqui fala de e-mail, SMS ou papel."},
 {"code": "\n\nclass Notifier(Protocol):\n    def notify(self, member: str, text: str) -> None: ...", "note": "A porta. Ela mora neste módulo porque as regras são donas dela: o nome e o único método são o que as regras querem, e não o que algum gateway oferece."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    member: str\n    lent_on: date", "note": "Um empréstimo como as regras o veem."},
 {"code": "\n\nclass OverdueNotices:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def __init__(self, notifier: Notifier):\n        self.notifier = notifier", "note": "As regras recebem um notificador. Elas não constroem um, então não têm como depender de qual."},
 {"code": "\n    def send(self, loans: list[Loan], today: date) -> int:\n        sent = 0\n        for loan in loans:\n            late = (today - loan.lent_on - timedelta(days=self.LOAN_DAYS)).days\n            if late > 0:\n                cents = late * self.DAILY_FINE\n                self.notifier.notify(loan.member, f\"'{loan.title}' is {late} days late, {cents} cents so far\")\n                sent += 1\n        return sent", "note": "A regra inteira: quem está atrasado, quanto, quanto custa, e que essa pessoa é avisada. Devolve quantos avisos saíram, que é o que quem chama ou um teste quer saber."}
]}
```

## Os adaptadores

```python
# adapters.py
from notices import Notifier


class EmailNotifier(Notifier):
    def __init__(self, addresses: dict[str, str]):
        self.addresses = addresses

    def notify(self, member: str, text: str) -> None:
        print(f"e-mail to {self.addresses[member]}: {text}")


class SmsNotifier(Notifier):
    def __init__(self, phones: dict[str, str]):
        self.phones = phones

    def notify(self, member: str, text: str) -> None:
        print(f"SMS to {self.phones[member]}: {text}")
```

O print faz o papel dos gateways de verdade, como `ConsoleMailer` fez na lição 3. Cada adaptador
cita `Notifier` como pai. Um protocolo do Python não exige isso, e as classes se encaixariam só pelo
formato; citá-lo deixa a direção visível no código, como faria o `implements` do Java.

## As ligações

```python
# main.py
from datetime import date

from adapters import EmailNotifier
from notices import Loan, OverdueNotices

LOANS = [
    Loan("Dom Casmurro", "Bia", date(2026, 3, 2)),
    Loan("Iracema", "Caio", date(2026, 3, 20)),
    Loan("Vidas Secas", "Duda", date(2026, 3, 9)),
]

if __name__ == "__main__":
    notifier = EmailNotifier({
        "Bia": "bia@example.org",
        "Caio": "caio@example.org",
        "Duda": "duda@example.org",
    })
    sent = OverdueNotices(notifier).send(LOANS, date(2026, 4, 1))
    print(sent, "notices sent")
```

```
ana@laptop:~/patterns/solid-2$ python3 main.py
e-mail to bia@example.org: 'Dom Casmurro' is 16 days late, 800 cents so far
e-mail to duda@example.org: 'Vidas Secas' is 9 days late, 450 cents so far
2 notices sent
```

Iracema foi emprestado em 20 de março e só vence em 3 de abril, então dois dos três empréstimos
recebem aviso.

## As setas, lidas nos arquivos

A direção de uma dependência é um fato que dá para verificar sem diagrama. Liste os imports:

```
ana@laptop:~/patterns/solid-2$ grep -n import notices.py adapters.py main.py
notices.py:2:from dataclasses import dataclass
notices.py:3:from datetime import date, timedelta
notices.py:4:from typing import Protocol
adapters.py:2:from notices import Notifier
main.py:2:from datetime import date
main.py:4:from adapters import EmailNotifier
main.py:5:from notices import Loan, OverdueNotices
```

`notices.py` importa três módulos padrão e nada deste diretório. `adapters.py` importa de
`notices.py`: **o detalhe depende da regra, e essa é a inversão.** `main.py` importa os dois, porque
decidir que adaptador as regras recebem é o trabalho dele. Mandar todos os avisos por SMS é uma
mudança só em `main.py`.

## As regras, testadas sem nada atrás

Como as regras são donas da porta, um teste pode entregar a elas qualquer coisa com um método
`notify`:

```python
# test_notices.py
import unittest
from datetime import date

from notices import Loan, OverdueNotices


class Recording:
    def __init__(self):
        self.sent: list[tuple[str, str]] = []

    def notify(self, member: str, text: str) -> None:
        self.sent.append((member, text))


class OverdueNoticesTest(unittest.TestCase):
    def test_only_late_loans_get_a_notice(self):
        notifier = Recording()
        loans = [Loan("Iracema", "Caio", date(2026, 3, 20)),
                 Loan("Vidas Secas", "Duda", date(2026, 3, 9))]
        sent = OverdueNotices(notifier).send(loans, date(2026, 4, 1))
        self.assertEqual(sent, 1)
        self.assertEqual(notifier.sent, [("Duda", "'Vidas Secas' is 9 days late, 450 cents so far")])
```

```
ana@laptop:~/patterns/solid-2$ python3 -m unittest -v test_notices.py
test_only_late_loans_get_a_notice (test_notices.OverdueNoticesTest.test_only_late_loans_get_a_notice) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

O teste importa só `notices.py`; `adapters.py` poderia ser apagado e ele continuaria passando. O
tempo na linha `Ran` vai ser diferente na sua máquina. Em Java o mesmo teste implementaria a
interface `Notifier` numa classe pequena, em Go seria uma struct com um método `Notify`, e em
TypeScript um objeto literal; nas quatro, o teste não precisa de nada que envie coisa alguma.
