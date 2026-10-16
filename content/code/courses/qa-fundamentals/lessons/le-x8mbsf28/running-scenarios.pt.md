---
title: Fazendo um cenário rodar
version: 1
---

**Um cenário roda quando cada um dos passos dele está ligado a um pequeno pedaço de código, uma definição de
passo.** O behave lê o arquivo de feature e, para cada linha, procura uma função cujo padrão case com ela. Rode-o
em `~/aurora`, onde está `features/`, com a feature da seção anterior e mais nada por enquanto:

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # None
    When the customer uses the code "PIPOCA" # None
    Then the order costs R$ 31,00            # None


You can implement step definitions for undefined steps with these snippets:

from behave.api.pending_step import StepNotImplementedError
@given(u'an order of R$ 36,00')
def step_impl(context):
    raise StepNotImplementedError(u'Given an order of R$ 36,00')


@when(u'the customer uses the code "PIPOCA"')
def step_impl(context):
    raise StepNotImplementedError(u'When the customer uses the code "PIPOCA"')


@then(u'the order costs R$ 31,00')
def step_impl(context):
    raise StepNotImplementedError(u'Then the order costs R$ 31,00')



Errored scenarios:
  features/coupons.feature:5  PIPOCA takes five reais off

0 features passed, 0 failed, 1 error, 0 skipped
0 scenarios passed, 0 failed, 1 error, 0 skipped
0 steps passed, 0 failed, 0 skipped, 3 undefined
Took 0min 0.000s
```

Nada falhou, porque nada rodou. O behave lista os três passos como **undefined** (indefinidos) e imprime um
esqueleto para cada um. Leia o resumo no fim: zero passaram, zero falharam, um erro, três indefinidos. Um passo
indefinido é o jeito do behave dizer que a frase é entendida por pessoas e ainda não pela máquina.

## As definições de passo

O Rafael escreve as três definições num segundo arquivo, `features/steps/coupons_steps.py`, onde o behave procura
por elas:

```schooling-example
{"language": "python", "file": "features/steps/coupons_steps.py", "parts": [{"code": "# features/steps/coupons_steps.py\nfrom behave import given, when, then\nfrom coupons import apply\n", "note": "Os três decoradores do behave, um por palavra-chave, e o `apply` da aula 15: os cenários rodam o mesmo código que os testes de unidade. `And` e `But` não precisam de decorador próprio; herdam a palavra-chave do passo de cima."}, {"code": "\n\n@given(\"an order of R$ {reais:d},{cents:d}\")\ndef an_order(context, reais, cents):\n    context.total = reais * 100 + cents\n", "note": "O padrão é a frase, com as partes que variam entre chaves. `:d` quer dizer número inteiro, então `R$ 36,00` dá `reais` 36 e `cents` 0. `context` é um objeto que o behave entrega a cada passo de um cenário, então um valor guardado no `Given` está lá para o `When` e o `Then`."}, {"code": "\n\n@when('the customer uses the code \"{code}\"')\ndef uses_code(context, code):\n    context.total = apply(code, context.total)\n", "note": "A ação: o que estiver entre as aspas é o código, espaços incluídos, e o total é trocado pelo que o `apply` devolve."}, {"code": "\n\n@then(\"the order costs R$ {reais:d},{cents:d}\")\ndef costs(context, reais, cents):\n    assert context.total == reais * 100 + cents, context.total\n", "note": "O resultado. `assert` faz o passo falhar se a comparação for falsa, e o que vem depois da vírgula, aqui o total obtido, é o que o behave imprime quando falha."}]}
```

Cada decorador guarda um padrão, e as partes entre `{…}` são capturadas. Como os padrões nomeiam os reais e os
centavos em vez de um preço fixo, essas três funções casam com *qualquer* total de pedido e *qualquer* código, e
esse é o ponto: as frases são reutilizáveis, e os próximos cenários não vão precisar de código novo. Rode o behave
de novo:

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

1 feature passed, 0 failed, 0 skipped
1 scenario passed, 0 failed, 0 skipped
3 steps passed, 0 failed, 0 skipped
Took 0min 0.000s
```

Verde, com cada passo mostrado ao lado da linha de código que o rodou. Essa segunda coluna é útil quando um passo
casa com uma função que você não esperava.

## Quem escreve o quê

Veja onde o trabalho foi parar. O arquivo de feature está nas palavras do Cine Aurora, legível pela Joana e pela
Célia, e foi formulado pela Lia a partir da conversa. As definições de passo estão em Python e são de quem
desenvolve. O código do cupom é o da aula 15, intocado: o behave chama o mesmo `apply` que os testes de unidade
chamam.

Essa divisão é toda a arquitetura das ferramentas de BDD, e ela tem um custo. Cada passo é um padrão que alguém
precisa manter, e um time que escreve passos sem cuidado acaba com quarenta jeitos um pouco diferentes de dizer
*an order of*, cada um com sua função. O remédio é a linguagem compartilhada da primeira seção: se todo mundo diz
*an order of R$ 36,00* do mesmo jeito, um passo serve a todo cenário que precisa de um pedido.
