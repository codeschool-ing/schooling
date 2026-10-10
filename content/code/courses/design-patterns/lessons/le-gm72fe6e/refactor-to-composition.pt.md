---
title: Refatorar uma hierarquia em partes
version: 1
---

**Para transformar uma hierarquia em composição, encontre o que varia entre as subclasses e mova
cada uma dessas coisas para uma parte que o pai guarda; depois apague as subclasses.** Feito em passos pequenos, com os testes rodando depois de cada um, o programa se comporta
igual em todos os passos. A lição 14 trata de refatoração em geral; esta seção é uma refatoração,
feita uma vez, de ponta a ponta.

O jeito tentador é escrever a versão por composição do zero, ao lado da antiga, e trocar. Isso
funciona para um arquivo deste tamanho e falha em código de verdade, porque a hierarquia antiga
guarda decisões que ninguém lembra de ter tomado, e uma reescrita as perde em silêncio. Passos que
mantêm os testes verdes carregam todas as decisões para o outro lado.

## A hierarquia como foi encontrada

Alguém construiu os empréstimos por subclasses, um eixo de cada vez. Primeiro vieram os filmes,
depois a tarifa de estudante, depois a tarifa de estudante para filmes:

```python
# loans.py
from datetime import date, timedelta


class Loan:
    days = 14

    def __init__(self, title: str, lent_on: date):
        self.title = title
        self.due = lent_on + timedelta(days=self.days)

    def fine(self, returned_on: date) -> int:
        return max((returned_on - self.due).days, 0) * 50


class FilmLoan(Loan):
    days = 7


class StudentLoan(Loan):
    def fine(self, returned_on: date) -> int:
        return max((returned_on - self.due).days - 3, 0) * 50


class StudentFilmLoan(FilmLoan):
    def fine(self, returned_on: date) -> int:
        return max((returned_on - self.due).days - 3, 0) * 50


def open_loan(title: str, lent_on: date, film: bool = False, student: bool = False) -> Loan:
    if film and student:
        return StudentFilmLoan(title, lent_on)
    if film:
        return FilmLoan(title, lent_on)
    if student:
        return StudentLoan(title, lent_on)
    return Loan(title, lent_on)
```

Quatro classes para dois eixos, e `StudentFilmLoan.fine` é uma cópia de `StudentLoan.fine`, porque
precisava do pai do filme por causa de `days` e do método do estudante por causa da multa, e a
herança simples oferece um pai só. Essa cópia é a explosão de classes começando.

## Primeiro, fixe o comportamento

Antes de mexer em qualquer coisa, registre o que o código faz agora, pela única porta que todo mundo
usa, `open_loan`. Esses testes não ligam para quais classes existem, e é isso que os deixa
sobreviver à refatoração.

```python
# test_loans.py
import unittest
from datetime import date

from loans import open_loan

LENT = date(2026, 3, 2)
BACK = date(2026, 3, 21)


class OpenLoanTest(unittest.TestCase):
    def test_book_for_an_adult(self):
        self.assertEqual(open_loan("Dom Casmurro", LENT).fine(BACK), 250)

    def test_film_for_an_adult(self):
        self.assertEqual(open_loan("Bacurau", LENT, film=True).fine(BACK), 600)

    def test_book_for_a_student(self):
        self.assertEqual(open_loan("Iracema", LENT, student=True).fine(BACK), 100)

    def test_film_for_a_student(self):
        loan = open_loan("Aquarius", LENT, film=True, student=True)
        self.assertEqual(loan.fine(BACK), 450)

    def test_back_early_costs_nothing(self):
        self.assertEqual(open_loan("Vidas Secas", LENT).fine(date(2026, 3, 10)), 0)
```

```
ana@laptop:~/patterns/composition$ python3 -m unittest -v test_loans.py
test_back_early_costs_nothing (test_loans.OpenLoanTest.test_back_early_costs_nothing) ... ok
test_book_for_a_student (test_loans.OpenLoanTest.test_book_for_a_student) ... ok
test_book_for_an_adult (test_loans.OpenLoanTest.test_book_for_an_adult) ... ok
test_film_for_a_student (test_loans.OpenLoanTest.test_film_for_a_student) ... ok
test_film_for_an_adult (test_loans.OpenLoanTest.test_film_for_an_adult) ... ok

----------------------------------------------------------------------
Ran 5 tests in 0.000s

OK
```

## Os passos

1. Dê nome ao que varia. Comparando as quatro classes, duas coisas mudam: a duração do empréstimo
   (`days`) e a regra de multa (com ou sem três dias de carência). Todo o resto é comum.
2. Dê ao pai um campo para cada uma. `Loan.__init__` recebe `days` e uma `policy`, e `fine`
   pergunta à regra. As regras já existem como partes: `PerDay` e `GraceDays` em `fines.py`, de duas
   seções atrás. Rode os testes.
3. Faça a fábrica passar partes em vez de escolher uma classe. `open_loan` calcula a duração e a
   regra e constrói um `Loan` simples. Rode os testes.
4. Apague as subclasses, que nada mais constrói. Rode os testes.

Este é o arquivo no fim do passo 4, com `fines.py` ao lado, no mesmo diretório:

```python
# loans.py
from datetime import date, timedelta

from fines import FinePolicy, GraceDays, PerDay

STANDARD = PerDay(50)


class Loan:
    def __init__(self, title: str, lent_on: date, days: int, policy: FinePolicy):
        self.title = title
        self.due = lent_on + timedelta(days=days)
        self.policy = policy

    def fine(self, returned_on: date) -> int:
        return self.policy.fine((returned_on - self.due).days)


def open_loan(title: str, lent_on: date, film: bool = False, student: bool = False) -> Loan:
    days = 7 if film else 14
    policy = GraceDays(3, STANDARD) if student else STANDARD
    return Loan(title, lent_on, days, policy)
```

```
ana@laptop:~/patterns/composition$ python3 -m unittest -v test_loans.py
test_back_early_costs_nothing (test_loans.OpenLoanTest.test_back_early_costs_nothing) ... ok
test_book_for_a_student (test_loans.OpenLoanTest.test_book_for_a_student) ... ok
test_book_for_an_adult (test_loans.OpenLoanTest.test_book_for_an_adult) ... ok
test_film_for_a_student (test_loans.OpenLoanTest.test_film_for_a_student) ... ok
test_film_for_an_adult (test_loans.OpenLoanTest.test_film_for_an_adult) ... ok

----------------------------------------------------------------------
Ran 5 tests in 0.000s

OK
```

Os mesmos cinco testes, sem mudança, passam com os dois arquivos. **O arquivo de testes nunca citou
uma subclasse, e é só por isso que ele conseguiu provar que apagar quatro delas não mudou nada.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 330\" role=\"img\" data-fig=\"l02-refactor\" aria-label=\"Dois diagramas de classes de loans.py. À esquerda, antes: Loan com days = 14 e fine; FilmLoan põe days em 7 e StudentLoan sobrescreve fine, as duas apontando para Loan; StudentFilmLoan aponta para FilmLoan e sobrescreve fine com uma cópia do método de StudentLoan. Quatro classes, um método escrito duas vezes. À direita, depois: uma só classe Loan com title, due e policy, que tem um protocolo FinePolicy, desenhado com um losango cheio; PerDay e GraceDays implementam FinePolicy, e o próprio GraceDays tem outro FinePolicy, a regra a que repassa os dias restantes.\"><text x=\"190.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">antes: uma classe por combinação</text><rect x=\"125.0\" y=\"40.0\" width=\"130.0\" height=\"67.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M125.0 62.5 L255.0 62.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"133.0\" y=\"73.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">days = 14</text><path d=\"M125.0 85.0 L255.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"133.0\" y=\"96.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"20.0\" y=\"160.0\" width=\"110.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FilmLoan</text><path d=\"M20.0 182.5 L130.0 182.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"28.0\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">days = 7</text><rect x=\"220.0\" y=\"160.0\" width=\"120.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">StudentLoan</text><path d=\"M220.0 182.5 L340.0 182.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"228.0\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"20.0\" y=\"245.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"256.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">StudentFilmLoan</text><path d=\"M20.0 267.5 L160.0 267.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"28.0\" y=\"278.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><path d=\"M75.0 160.0 L75.0 135.0 L190.0 135.0 L190.0 107.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M190.0 107.5 L197.0 119.5 L183.0 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><path d=\"M280.0 160.0 L280.0 135.0 L190.0 135.0 L190.0 107.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M190.0 107.5 L197.0 119.5 L183.0 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><path d=\"M75.0 245.0 L75.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M75.0 205.0 L82.0 217.0 L68.0 217.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"172.0\" y=\"261.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">fine() copiado</text><text x=\"172.0\" y=\"274.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">de StudentLoan</text><path d=\"M390.0 20.0 L390.0 315.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"585.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">depois: um empréstimo tem sua regra</text><rect x=\"410.0\" y=\"50.0\" width=\"130.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M410.0 72.5 L540.0 72.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"418.0\" y=\"83.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title</text><text x=\"418.0\" y=\"98.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">due</text><text x=\"418.0\" y=\"112.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">policy</text><path d=\"M410.0 124.0 L540.0 124.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"418.0\" y=\"135.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"600.0\" y=\"60.0\" width=\"140.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"71.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"670.0\" y=\"85.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FinePolicy</text><path d=\"M600.0 97.0 L740.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"608.0\" y=\"108.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine(days_late)</text><path d=\"M540.0 85.0 L600.0 85.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M540.0 85.0 L549.0 90.5 L558.0 85.0 L549.0 79.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><rect x=\"560.0\" y=\"220.0\" width=\"90.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"231.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PerDay</text><path d=\"M560.0 242.5 L650.0 242.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"253.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cents</text><rect x=\"670.0\" y=\"220.0\" width=\"90.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"715.0\" y=\"231.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">GraceDays</text><path d=\"M670.0 242.5 L760.0 242.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"678.0\" y=\"253.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">free</text><text x=\"678.0\" y=\"268.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">then</text><path d=\"M605.0 220.0 L605.0 185.0 L670.0 185.0 L670.0 119.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M670.0 119.5 L677.0 131.5 L663.0 131.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M715.0 220.0 L715.0 185.0 L670.0 185.0 L670.0 119.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M670.0 119.5 L677.0 131.5 L663.0 131.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M760.0 262.0 L772.0 262.0 L772.0 90.0 L740.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M760.0 262.0 L769.0 267.5 L778.0 262.0 L769.0 256.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><text x=\"475.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">open_loan()</text><text x=\"475.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">escolhe as partes</text><text x=\"585.0\" y=\"305.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma opção nova é uma parte nova, não uma classe nova</text></svg>", "caption": "Os mesmos empréstimos antes e depois da refatoração. Os eixos que multiplicavam classes à esquerda viram campos com partes à direita.", "same": ["open_loan()"]}
```

## O que o formato novo compra

A regra de estudante duplicada sumiu: existe um `GraceDays`, e tanto o livro quanto o filme de um
estudante o guardam. Os eixos pararam de se multiplicar. Um terceiro tipo de item, com empréstimo de
21 dias, é um número novo em `open_loan`; um aumento de multa é `PerDay(75)`; a semana de anistia de
duas seções atrás funciona nesses empréstimos sem mudança, porque eles guardam a regra no mesmo
campo.

Uma escolha mudou de lugar, e vale notar para onde. A cadeia de `if` que escolhia uma classe virou
duas expressões pequenas que escolhem partes, ainda em `open_loan`. Decidir que partes um objeto
recebe tem de acontecer em algum lugar, e juntar isso numa função é o começo do que a lição 5 chama
de composition root.

`isinstance(loan, StudentLoan)` não responde mais nada, então qualquer código que fazia essa
pergunta tem de perguntar a uma parte. Procure esses testes antes do passo 4; neste arquivo não
havia nenhum, e os testes não teriam encontrado um em outro arquivo.
