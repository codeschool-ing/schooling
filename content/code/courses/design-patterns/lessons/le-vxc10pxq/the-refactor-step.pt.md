---
title: O passo de refatorar, o que todo mundo pula
version: 1
---

**O passo pulado com mais frequência é o terceiro, e pulá-lo transforma o TDD num jeito de produzir
código bagunçado depressa.** Vermelho e verde tratam de comportamento. Refatorar é onde o projeto
melhora, e é o único passo em que o código muda com a promessa explícita de que o comportamento não
muda. Os testes escritos nos dois primeiros passos são o que torna essa promessa verificável.

A calculadora passa em três testes e tem duas coisas em que um leitor tropeçaria. O `50` não tem
nome, então a próxima pessoa precisa adivinhar se são centavos, dias ou uma porcentagem. E a
contagem de dias de atraso está misturada com o dinheiro, então uma tela que quisesse dizer "3 dias
de atraso" teria de repetir a conta. Nenhuma das duas é bug. As duas são o motivo do passo de
refatorar.

## Um movimento, depois rodar

Dê nome ao número e tire a contagem de dias para uma função própria. É um único movimento, e os
testes rodam logo depois. Desta vez o arquivo roda sozinho, pelo `unittest.main()` no fim, que
imprime o mesmo relatório sem o `-m unittest`:

```python
# fines.py
from datetime import date

DAILY_FINE = 50  # cents


def days_late(due: date, returned: date) -> int:
    return max((returned - due).days, 0)


def fine(due: date, returned: date) -> int:
    return days_late(due, returned) * DAILY_FINE
```

```
ana@laptop:~/patterns/tdd$ python3 test_fines.py
...
----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

Os mesmos três testes, as mesmas respostas, um arquivo melhor. As anotações de tipo vieram no mesmo
movimento, e isso é aceitável porque não mudam nada do que roda.

## A rede pegando um deslize

Agora suponha que, ao extrair `days_late`, você tivesse digitado a subtração ao contrário, o deslize
mais comum em aritmética de datas:

```python
    return max((due - returned).days, 0)
```

```
ana@laptop:~/patterns/tdd$ python3 test_fines.py
FFF
======================================================================
FAIL: test_one_day_late_costs_50_cents (__main__.FineTest.test_one_day_late_costs_50_cents)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 13, in test_one_day_late_costs_50_cents
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)
AssertionError: 0 != 50

======================================================================
FAIL: test_returned_early_costs_nothing (__main__.FineTest.test_returned_early_costs_nothing)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 16, in test_returned_early_costs_nothing
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 14)), 0)
AssertionError: 100 != 0

======================================================================
FAIL: test_three_days_late_costs_150_cents (__main__.FineTest.test_three_days_late_costs_150_cents)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 10, in test_three_days_late_costs_150_cents
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)
AssertionError: 0 != 150

----------------------------------------------------------------------
Ran 3 tests in 0.001s

FAILED (failures=3)
```

Os três testes falham um segundo depois da mudança, e cada falha diz o caso que quebrou. **Este é o
momento de que o passo de refatorar depende**: o deslize é achado quando tem uma linha de idade e a
causa é a única coisa que mudou. A resposta certa é desfazer a edição e refazê-la, não começar a
raciocinar sobre qual sinal está certo. Se você tivesse feito cinco movimentos antes de rodar, a
mesma saída seria um quebra-cabeça.

## Os testes também são código

O arquivo de teste tem a própria duplicação: a data de vencimento está escrita três vezes, e cada
data de devolução obriga quem lê a contar dias num calendário para ver o que está sendo testado.
Refatore sob a mesma regra, deixando o código de produção como está, para que uma execução vermelha
só possa querer dizer que o teste quebrou:

```python
# test_fines.py
import unittest
from datetime import date, timedelta

from fines import fine

DUE = date(2026, 3, 16)


def returned(days_after_due: int) -> date:
    return DUE + timedelta(days=days_after_due)


class FineTest(unittest.TestCase):
    def test_three_days_late_costs_150_cents(self):
        self.assertEqual(fine(DUE, returned(3)), 150)

    def test_one_day_late_costs_50_cents(self):
        self.assertEqual(fine(DUE, returned(1)), 50)

    def test_returned_early_costs_nothing(self):
        self.assertEqual(fine(DUE, returned(-2)), 0)


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/tdd$ python3 test_fines.py
...
----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

`returned(3)` diz três dias de atraso sem calendário. Um teste é lido muito mais vezes do que é
escrito, em geral por alguém tentando descobrir o que o código deveria fazer, e o passo de refatorar
é onde ele fica legível.

## As regras do passo

- Refatore só no verde. Uma mudança feita com um teste vermelho mistura duas perguntas, e você não
  consegue dizer a qual delas uma falha posterior responde.
- Mude a estrutura, nunca o comportamento. Um caso novo é um teste novo e um vermelho novo, na
  próxima volta.
- Um movimento de cada vez, depois rode. Os testes levam uma fração de segundo; não há economia em
  juntar movimentos.
- Mude o código ou os testes num movimento, não os dois. Se os dois mudaram e a execução está verde,
  nada conferiu a mudança.

Cada movimento aqui tem nome no catálogo de refatorações de Martin Fowler: *extract function*,
*replace magic literal*. A lição 14 trata do catálogo direito, junto com os cheiros que dizem qual
movimento um trecho de código pede.
