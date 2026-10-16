---
title: Os cenários crescem, o código acompanha
version: 1
---

**Depois que os passos existem, um exemplo novo custa algumas linhas de Gherkin e nenhum código.** É aí que o BDD
começa a se pagar: o time pode acrescentar os casos que a descoberta produziu nas palavras que usou para
discuti-los.

## Os exemplos da aula 15, como cenários

A Lia escreve os outros dois exemplos da aula 15 na feature, nas palavras da Joana e não nos nomes dos testes. O
código em minúsculas e os espaços colados vão num cenário só, porque a Célia os descreveu como uma coisa só: *o
código é lido do jeito que for digitado.*

```
# features/coupons.feature
Feature: Coupons
  A customer with a coupon code pays less for the order.

  Scenario: PIPOCA takes five reais off
    Given an order of R$ 36,00
    When the customer uses the code "PIPOCA"
    Then the order costs R$ 31,00

  Scenario: a code the cinema did not issue changes nothing
    Given an order of R$ 36,00
    When the customer uses the code "XYZ"
    Then the order costs R$ 36,00

  Scenario: the code is read however it is typed
    Given an order of R$ 28,00
    When the customer uses the code " pipoca "
    Then the order costs R$ 23,00
```

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

  Scenario: a code the cinema did not issue changes nothing  # features/coupons.feature:10
    Given an order of R$ 36,00                               # features/steps/coupons_steps.py:6
    When the customer uses the code "XYZ"                    # features/steps/coupons_steps.py:11
    Then the order costs R$ 36,00                            # features/steps/coupons_steps.py:16

  Scenario: the code is read however it is typed  # features/coupons.feature:15
    Given an order of R$ 28,00                    # features/steps/coupons_steps.py:6
    When the customer uses the code " pipoca "    # features/steps/coupons_steps.py:11
    Then the order costs R$ 23,00                 # features/steps/coupons_steps.py:16

1 feature passed, 0 failed, 0 skipped
3 scenarios passed, 0 failed, 0 skipped
9 steps passed, 0 failed, 0 skipped
Took 0min 0.001s
```

Três cenários, nove passos, nenhuma definição de passo nova: os padrões da seção anterior casaram com cada linha.

## Uma regra nova chega como cenário

Para a estreia de um filme brasileiro em novembro, a Joana quer um segundo código: *ESTREIA tira R$ 10,00.* Num
time de BDD a regra nova entra no projeto como exemplo, antes de alguém mudar o código. A Lia a acrescenta à
feature com a Joana olhando:

```
# features/coupons.feature
Feature: Coupons
  A customer with a coupon code pays less for the order.

  Scenario: PIPOCA takes five reais off
    Given an order of R$ 36,00
    When the customer uses the code "PIPOCA"
    Then the order costs R$ 31,00

  Scenario: a code the cinema did not issue changes nothing
    Given an order of R$ 36,00
    When the customer uses the code "XYZ"
    Then the order costs R$ 36,00

  Scenario: the code is read however it is typed
    Given an order of R$ 28,00
    When the customer uses the code " pipoca "
    Then the order costs R$ 23,00

  Scenario: ESTREIA takes ten reais off
    Given an order of R$ 36,00
    When the customer uses the code "ESTREIA"
    Then the order costs R$ 26,00
```

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

  Scenario: a code the cinema did not issue changes nothing  # features/coupons.feature:10
    Given an order of R$ 36,00                               # features/steps/coupons_steps.py:6
    When the customer uses the code "XYZ"                    # features/steps/coupons_steps.py:11
    Then the order costs R$ 36,00                            # features/steps/coupons_steps.py:16

  Scenario: the code is read however it is typed  # features/coupons.feature:15
    Given an order of R$ 28,00                    # features/steps/coupons_steps.py:6
    When the customer uses the code " pipoca "    # features/steps/coupons_steps.py:11
    Then the order costs R$ 23,00                 # features/steps/coupons_steps.py:16

  Scenario: ESTREIA takes ten reais off       # features/coupons.feature:20
    Given an order of R$ 36,00                # features/steps/coupons_steps.py:6
    When the customer uses the code "ESTREIA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 26,00             # features/steps/coupons_steps.py:16
      ASSERT FAILED: 3600



Failing scenarios:
  features/coupons.feature:20  ESTREIA takes ten reais off

0 features passed, 1 failed, 0 skipped
3 scenarios passed, 1 failed, 0 skipped
11 steps passed, 1 failed, 0 skipped
Took 0min 0.001s
```

Leia a falha do jeito que a aula 15 ensinou: o cenário nomeado em *Failing scenarios*, o passo que falhou, e
`ASSERT FAILED: 3600`, o total que o código de fato produziu, impresso pelo texto depois da vírgula no `assert`.
ESTREIA é um código desconhecido para o programa atual, então não muda nada. O cenário está vermelho porque a regra
é nova, que é exatamente o que um cenário novo deve fazer.

A mudança do Rafael é uma entrada na tabela da refatoração da aula 15:

```python
# coupons.py
COUPONS = {"PIPOCA": 500, "ESTREIA": 1000}


def apply(code, total):
    off = COUPONS.get(code.strip().upper(), 0)
    return total - off
```

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

  Scenario: a code the cinema did not issue changes nothing  # features/coupons.feature:10
    Given an order of R$ 36,00                               # features/steps/coupons_steps.py:6
    When the customer uses the code "XYZ"                    # features/steps/coupons_steps.py:11
    Then the order costs R$ 36,00                            # features/steps/coupons_steps.py:16

  Scenario: the code is read however it is typed  # features/coupons.feature:15
    Given an order of R$ 28,00                    # features/steps/coupons_steps.py:6
    When the customer uses the code " pipoca "    # features/steps/coupons_steps.py:11
    Then the order costs R$ 23,00                 # features/steps/coupons_steps.py:16

  Scenario: ESTREIA takes ten reais off       # features/coupons.feature:20
    Given an order of R$ 36,00                # features/steps/coupons_steps.py:6
    When the customer uses the code "ESTREIA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 26,00             # features/steps/coupons_steps.py:16

1 feature passed, 0 failed, 0 skipped
4 scenarios passed, 0 failed, 0 skipped
12 steps passed, 0 failed, 0 skipped
Took 0min 0.001s
```

## Onde dá errado

Times que adotam ferramentas de BDD sem as conversas costumam falhar dos mesmos poucos jeitos, e quem testa muitas
vezes é a primeira pessoa a perceber:

- **cenários escritos depois do código**, por quem desenvolve, para descrever o que foi construído: a ferramenta
  está lá, a descoberta não, e os cenários concordam com o código por construção;
- **cenários que ninguém de fora do time lê**: se a Joana nunca vê o arquivo de feature, a linguagem compartilhada
  é dividida por duas pessoas;
- **cenários como roteiros de teste**: passos imperativos, dezenas de casos, cada preço do quadro, até o arquivo de
  feature virar uma suíte de regressão com sintaxe a mais;
- **passos que escondem o exemplo**: *Given a standard order* não diz nada a quem lê; *Given an order of R$ 36,00*
  é o exemplo.

Nenhum desses é problema do Gherkin. Cada um é a prática da descoberta faltando, e a próxima aula é sobre a reunião
em que a descoberta acontece.
