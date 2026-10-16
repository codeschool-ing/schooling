---
title: O mapa vira um Scenario Outline
version: 1
---

**Quando muitos exemplos têm a mesma forma, o Gherkin escreve a forma uma vez e os exemplos como tabela: um
Scenario Outline (esboço de cenário).** Cada linha da tabela vira um cenário próprio quando roda. É o passo de
formulação da aula 16, para uma regra cujos exemplos só diferem nos números.

Os cartões verdes do mapa viram duas tabelas, uma por regra, porque cada tabela diz do que ela é exemplo. Salve isto
em `~/aurora` como `features/prices.feature`:

```
# features/prices.feature
Feature: Ticket prices
  R$ 36,00 from 17:00, R$ 28,00 before. Students, customers aged 60 and
  over and children under 12 pay half. Wednesdays are half price. Half
  price is the most any ticket is reduced.

  Scenario Outline: one ticket
    Given a customer aged <age> who <is> a student
    And a <day> session at <time>
    When they buy a ticket
    Then they pay R$ <price>

    Examples: the age line
      | age | is     | day | time  | price |
      | 59  | is not | thu | 20:00 | 36,00 |
      | 60  | is not | thu | 20:00 | 18,00 |
      | 61  | is not | thu | 20:00 | 18,00 |

    Examples: Wednesday with another discount
      | age | is     | day | time  | price |
      | 35  | is not | wed | 20:00 | 18,00 |
      | 35  | is     | wed | 20:00 | 18,00 |
      | 8   | is not | wed | 15:00 | 14,00 |
```

As palavras entre sinais de menor e maior são preenchidas a partir de cada linha. A descrição abaixo de `Feature:` é
a regra da Joana, as cinco frases, com *aged 60 and over* (60 anos ou mais) onde a primeira versão dizia *over 60*
(mais de 60): o mapa é onde isso foi decidido, e o arquivo de feature é onde fica escrito de vez.

## Os passos

Quatro frases pedem quatro definições de passo, em `features/steps/prices_steps.py`. Elas chamam o `price` e o
`brl` da aula 1, então os testes de aceitação rodam o mesmo código que a bilheteria rodaria:

```schooling-example
{"language": "python", "file": "features/steps/prices_steps.py", "parts": [{"code": "# features/steps/prices_steps.py\nfrom behave import given, when, then\nfrom tickets import brl, price\n", "note": "A regra de preço e o formatador do `tickets.py` da aula 1, as mesmas funções que a linha de comando usa."}, {"code": "\n\n@given(\"a customer aged {age:d} who {is_} a student\")\ndef a_customer(context, age, is_):\n    context.age = age\n    context.student = is_ == \"is\"\n", "note": "O cliente: uma idade, e se é estudante. A tabela escreve `is` ou `is not`, para a frase ler bem nas duas linhas, e o passo transforma isso em `True` ou `False`."}, {"code": "\n\n@given(\"a {day} session at {time}\")\ndef a_session(context, day, time):\n    context.day, context.time = day, time\n", "note": "A sessão, guardada exatamente como escrita: o dia e o horário seguem como texto, do jeito que a bilheteria os digita."}, {"code": "\n\n@when(\"they buy a ticket\")\ndef they_buy(context):\n    context.paid = brl(price(context.age, context.student, context.day, context.time))\n", "note": "A ação chama a regra de verdade e guarda o preço como o cliente o veria, `R$ 18,00`."}, {"code": "\n\n@then(\"they pay R$ {amount}\")\ndef they_pay(context, amount):\n    assert context.paid == f\"R$ {amount}\", context.paid\n", "note": "O resultado compara texto com texto, então uma falha imprime o preço que o programa cobrou, em reais."}]}
```

## A primeira execução

A história ainda não foi construída. Os testes de aceitação dela rodam mesmo assim, porque no ATDD uma história
começa vermelha:

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
      ASSERT FAILED: R$ 36,00


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
      ASSERT FAILED: R$ 9,00


  Scenario Outline: one ticket -- @2.3 Wednesday with another discount  # features/prices.feature:23
    Given a customer aged 8 who is not a student                        # features/steps/prices_steps.py:6
    And a wed session at 15:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 14,00                                              # features/steps/prices_steps.py:22
      ASSERT FAILED: R$ 7,00



Failing scenarios:
  features/prices.feature:16  one ticket -- @1.2 the age line
  features/prices.feature:22  one ticket -- @2.2 Wednesday with another discount
  features/prices.feature:23  one ticket -- @2.3 Wednesday with another discount

0 features passed, 1 failed, 0 skipped
3 scenarios passed, 3 failed, 0 skipped
21 steps passed, 3 failed, 0 skipped
Took 0min 0.002s
```

Três linhas passam e três falham, e cada falha é um defeito conhecido de uma aula anterior, agora escrito nos termos
da Joana. O cliente de sessenta anos da aula 1 paga R$ 36,00. O estudante numa quarta da aula 6 paga R$ 9,00, e a
criança na matinê de quarta paga R$ 7,00. As linhas que passam também importam: as de 59 e 61 prendem a linha pelos
dois lados, e o adulto na quarta mostra que o desconto de quarta em si funciona.

Repare como as falhas são relatadas: *one ticket -- @1.2 the age line* é o nome do esboço, depois o nome da tabela e
a linha. Uma tabela com um bom nome torna a falha legível para a pessoa que escolheu os exemplos.
