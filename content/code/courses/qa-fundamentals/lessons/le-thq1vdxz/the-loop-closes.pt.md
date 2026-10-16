---
title: O laço se fecha, e o que fica aberto
version: 1
---

**A história é construída dentro do laço de fora: o Rafael trabalha até os exemplos combinados passarem, e então
ela está pronta.** Para a regra de preço, isso quer dizer duas mudanças no `tickets.py`. A linha da idade passa a ser
*60 ou mais*, e a quarta deixa de ser um segundo desconto em cima do primeiro: vira mais um motivo para meia, e meia
é o máximo que um ingresso pode ser reduzido.

```python
# tickets.py
import sys

EVENING = 3600
MATINEE = 2800


def price(age, student, day, time):
    if time < "17:00":
        full = MATINEE
    else:
        full = EVENING
    half = False
    if student:
        half = True
    if age >= 60:
        half = True
    if age < 12:
        half = True
    if day == "wed":
        half = True
    if half:
        return full // 2
    return full


def brl(cents):
    return f"R$ {cents // 100},{cents % 100:02d}"


if __name__ == "__main__":
    age, student, day, time = sys.argv[1:]
    print(brl(price(int(age), student == "yes", day, time)))
```

Duas linhas mudaram: `age > 60` virou `age >= 60`, e o `full = full // 2` das quartas virou `half = True`. Num time
de ATDD de verdade, cada uma teria seus próprios ciclos de TDD dentro do laço de fora, como a aula 15 mostrou; aqui o
ponto é o teste de fora:

```
lia@lab:~/aurora$ behave features/prices.feature
USING RUNNER: behave.runner:Runner
Feature: Ticket prices # features/prices.feature:2
  R$ 36,00 from 17:00, R$ 28,00 before. Students, customers aged 60 and
  over and children under 12 pay half. Wednesdays are half price. Half
  price is the most any ticket is reduced.
  Scenario Outline: one ticket -- @1.1 the age line  # features/prices.feature:15
    Given a customer aged 59 who is not a student    # features/steps/prices_steps.py:6
    And a thu session at 20:00                       # features/steps/prices_steps.py:12
    When they buy a ticket                           # features/steps/prices_steps.py:17
    Then they pay R$ 36,00                           # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @1.2 the age line  # features/prices.feature:16
    Given a customer aged 60 who is not a student    # features/steps/prices_steps.py:6
    And a thu session at 20:00                       # features/steps/prices_steps.py:12
    When they buy a ticket                           # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                           # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @1.3 the age line  # features/prices.feature:17
    Given a customer aged 61 who is not a student    # features/steps/prices_steps.py:6
    And a thu session at 20:00                       # features/steps/prices_steps.py:12
    When they buy a ticket                           # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                           # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @2.1 Wednesday with another discount  # features/prices.feature:21
    Given a customer aged 35 who is not a student                       # features/steps/prices_steps.py:6
    And a wed session at 20:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                                              # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @2.2 Wednesday with another discount  # features/prices.feature:22
    Given a customer aged 35 who is a student                           # features/steps/prices_steps.py:6
    And a wed session at 20:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                                              # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @2.3 Wednesday with another discount  # features/prices.feature:23
    Given a customer aged 8 who is not a student                        # features/steps/prices_steps.py:6
    And a wed session at 15:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 14,00                                              # features/steps/prices_steps.py:22

1 feature passed, 0 failed, 0 skipped
6 scenarios passed, 0 failed, 0 skipped
24 steps passed, 0 failed, 0 skipped
Took 0min 0.002s
```

Seis de seis. Nos termos do ATDD a história está pronta, e a Joana não precisa ler o código para saber: ela combinou
as seis linhas antes de o trabalho começar, e as seis linhas passam.

## As verificações que já existiam

Os cenários de cupom da aula 16 rodam no mesmo projeto. Rodar o behave sem nomear uma feature roda todas, e essa é a
verificação de que o código novo não quebrou o antigo. `--format progress` imprime um ponto por cenário em vez de
cada passo, que é como uma suíte desse tamanho costuma ser lida:

```
lia@lab:~/aurora$ behave --format progress
USING RUNNER: behave.runner:Runner
features/coupons.feature  ....
features/prices.feature  ......

2 features passed, 0 failed, 0 skipped
10 scenarios passed, 0 failed, 0 skipped
36 steps passed, 0 failed, 0 skipped
Took 0min 0.003s
```

Duas features, dez cenários. Esta é a suíte de regressão da aula 10, crescida a partir dos testes de aceitação de
cada história até aqui, e vai rodar a cada mudança daqui em diante.

## O que as tabelas verdes não dizem

As seis linhas dizem que a regra vale para os seis exemplos que os três amigos escolheram. Não dizem que o programa
está certo para toda entrada, e o mapa já mostrava uma coisa que elas deixam de fora: o cartão vermelho. Uma sessão
digitada como `9:30` ainda é comparada como texto, e ainda custa o preço da noite. Ninguém decidiu ainda se a
bilheteria algum dia digita isso, então não há linha para isso, e os testes de aceitação são honestos a respeito ao
não fingir.

Essa é a posição honesta em que o ATDD deixa quem testa. Os exemplos combinados estão cobertos, todo dia,
automaticamente. O que sobra é exatamente o que as aulas anteriores deram a quem testa: ser dono das perguntas em
aberto, explorar além dos casos combinados, e levar o que isso achar de volta aos próximos três amigos como exemplos
novos.
