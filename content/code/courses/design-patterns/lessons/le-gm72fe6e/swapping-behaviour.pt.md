---
title: Trocar o comportamento com o programa rodando
version: 1
---

**A classe de um objeto é fixada quando ele é criado; uma parte guardada num campo pode ser trocada
a qualquer momento.** Essa é a propriedade da composição que nenhuma herança cuidadosa consegue dar.
Um objeto feito de partes pode mudar o que faz sem mudar o que é.

A crença comum aqui é que herdar é o jeito de variar comportamento, e que uma regra de multa
diferente é, portanto, um tipo diferente de empréstimo: `StudentLoan(Loan)` sobrescrevendo `fine`.
Funciona até a regra precisar mudar para um empréstimo que já existe. A biblioteca declara uma
semana de anistia, e a multa de todo empréstimo aberto tem de virar zero, hoje, para os empréstimos
que já estão fora da biblioteca. Um objeto não consegue virar instância de outra classe (o Python
deixa você atribuir `__class__`, e ninguém deveria), então o projeto por subclasses tem de
reconstruir cada empréstimo. Com a regra num campo, a anistia é uma atribuição.

## Um empréstimo que guarda sua regra de multa

```schooling-example
{"language": "python", "file": "fines.py", "parts": [
 {"code": "# fines.py\nfrom datetime import date, timedelta\nfrom typing import Protocol\n\n\nclass FinePolicy(Protocol):\n    def fine(self, days_late: int) -> int: ...", "note": "O que uma regra de multa precisa oferecer: dados os dias de atraso, um número de centavos. Os dias de atraso podem ser negativos, para um empréstimo devolvido antes."},
 {"code": "\n\nclass PerDay:\n    def __init__(self, cents: int):\n        self.cents = cents\n\n    def fine(self, days_late: int) -> int:\n        return max(days_late, 0) * self.cents", "note": "A regra padrão da biblioteca, com o preço por dia como um valor em vez de uma constante embutida na classe."},
 {"code": "\n\nclass GraceDays:\n    def __init__(self, free: int, then: FinePolicy):\n        self.free = free\n        self.then = then\n\n    def fine(self, days_late: int) -> int:\n        return self.then.fine(days_late - self.free)", "note": "Estudantes têm três dias de carência. Esta regra não calcula multa nenhuma: ela desconta os dias livres e entrega o resto a outra regra. Partes podem guardar partes."},
 {"code": "\n\nclass Amnesty:\n    def fine(self, days_late: int) -> int:\n        return 0", "note": "A semana de anistia, como uma regra igual às outras."},
 {"code": "\n\nclass Loan:\n    def __init__(self, title: str, lent_on: date, days: int, policy: FinePolicy):\n        self.title = title\n        self.due = lent_on + timedelta(days=days)\n        self.policy = policy\n\n    def fine(self, returned_on: date) -> int:\n        return self.policy.fine((returned_on - self.due).days)", "note": "O empréstimo calcula o próprio atraso, porque isso é um fato sobre o empréstimo. Quanto o atraso custa é assunto da regra."},
 {"code": "\n\nif __name__ == \"__main__\":\n    standard = PerDay(50)\n    loans = [\n        Loan(\"Dom Casmurro\", date(2026, 3, 2), 14, standard),\n        Loan(\"Vidas Secas\", date(2026, 3, 2), 14, GraceDays(3, standard)),\n        Loan(\"Central do Brasil\", date(2026, 3, 10), 7, standard),\n    ]\n    back = date(2026, 3, 21)\n    for loan in loans:\n        print(f\"{loan.title:<18} due {loan.due}  fine {loan.fine(back):>3}\")", "note": "O livro de um adulto, o livro de um estudante e um filme, todos devolvidos em 21 de março."},
 {"code": "    for loan in loans:\n        loan.policy = Amnesty()\n    print(\"amnesty week:\", [loan.fine(back) for loan in loans])", "note": "Os mesmos três objetos, cada um com uma regra nova. Nada é reconstruído."}
]}
```

```
ana@laptop:~/patterns/composition$ python3 fines.py
Dom Casmurro       due 2026-03-16  fine 250
Vidas Secas        due 2026-03-16  fine 100
Central do Brasil  due 2026-03-17  fine 200
amnesty week: [0, 0, 0]
```

O adulto está cinco dias atrasado a 50 centavos, 250. O estudante também está cinco dias atrasado,
menos três de carência, 100. O filme vence um dia depois e custa 200. Depois a anistia: os mesmos
três empréstimos, os mesmos títulos e datas, e toda multa zero.

Veja o que `GraceDays` fez. É uma regra feita de outra regra, então a tarifa de estudante durante
um aumento de multa é `GraceDays(3, PerDay(75))`, escrita onde o empréstimo é criado, sem uma classe
chamada `StudentIncreasedFineLoan`. **É assim que a composição responde à explosão de classes: as
opções se combinam quando os objetos são construídos, e não quando as classes são escritas.**

## A mesma emenda deixa o empréstimo testável

Uma parte entregue de fora pode ser trocada por um teste tão facilmente quanto pela semana de
anistia. Para verificar que um empréstimo calcula o atraso direito, um teste entrega a ele uma regra
que anota o que lhe perguntaram e responde algo que nenhuma regra de verdade responderia:

```python
# test_fines.py
import unittest
from datetime import date

from fines import Loan


class Recording:
    def __init__(self):
        self.asked: list[int] = []

    def fine(self, days_late: int) -> int:
        self.asked.append(days_late)
        return 999


class LoanTest(unittest.TestCase):
    def test_passes_the_days_late_to_its_policy(self):
        policy = Recording()
        loan = Loan("Iracema", date(2026, 3, 2), 14, policy)
        self.assertEqual(loan.fine(date(2026, 3, 20)), 999)
        self.assertEqual(policy.asked, [4])
```

```
ana@laptop:~/patterns/composition$ python3 -m unittest -v test_fines.py
test_passes_the_days_late_to_its_policy (test_fines.LoanTest.test_passes_the_days_late_to_its_policy) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

O tempo na linha `Ran` depende da sua máquina e vai ser diferente deste. `Recording` é um dublê de
teste, o spy da lição 2 de `testing-cicd`, e não precisou de biblioteca de mock nenhuma: o empréstimo
aceita qualquer coisa que tenha um método `fine`. Com `fine` escrito numa subclasse, o teste teria
de calcular uma multa de verdade e deduzir o atraso a partir dela.

## Funções também são partes

`Amnesty` é uma classe com um método que ignora o argumento. Em Python, uma função simples poderia
fazer o mesmo papel, se `Loan` chamasse `self.policy(days)` em vez de `self.policy.fine(days)`; Go e
TypeScript passam funções com a mesma facilidade, e Java tem lambdas para interfaces de um método
só. A lição 6 mostra vários padrões encolhendo até virar uma função desse jeito. O projeto é o mesmo
nos dois casos: o empréstimo guarda o comportamento que varia, e esse comportamento pode ser
trocado.
