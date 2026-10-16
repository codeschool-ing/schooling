# lesson 16: the step definitions behind the coupon scenarios

example('steps', 'features/steps/coupons_steps.py', [
    ('# features/steps/coupons_steps.py\nfrom behave import given, when, then\nfrom coupons import apply\n',
     'behave’s three decorators, one per keyword, and lesson 15’s `apply`: the scenarios run the same code '
     'the unit tests run. `And` and `But` need no decorator of their own; they take the keyword of the step '
     'above.',
     'Os três decoradores do behave, um por palavra-chave, e o `apply` da aula 15: os cenários rodam o mesmo '
     'código que os testes de unidade. `And` e `But` não precisam de decorador próprio; herdam a palavra-chave do '
     'passo de cima.'),
    ('\n\n@given("an order of R$ {reais:d},{cents:d}")\ndef an_order(context, reais, cents):\n    context.total = reais * 100 + cents\n',
     'The pattern is the sentence, with the parts that vary in braces. `:d` means a whole number, so '
     '`R$ 36,00` gives `reais` 36 and `cents` 0. `context` is an object behave hands to every step of a '
     'scenario, so a value set in `Given` is there for `When` and `Then`.',
     'O padrão é a frase, com as partes que variam entre chaves. `:d` quer dizer número inteiro, então '
     '`R$ 36,00` dá `reais` 36 e `cents` 0. `context` é um objeto que o behave entrega a cada passo de um '
     'cenário, então um valor guardado no `Given` está lá para o `When` e o `Then`.'),
    ('\n\n@when(\'the customer uses the code "{code}"\')\ndef uses_code(context, code):\n    context.total = apply(code, context.total)\n',
     'The action: whatever is between the quotes is the code, spaces included, and the total is replaced by '
     'what `apply` returns.',
     'A ação: o que estiver entre as aspas é o código, espaços incluídos, e o total é trocado pelo que o '
     '`apply` devolve.'),
    ('\n\n@then("the order costs R$ {reais:d},{cents:d}")\ndef costs(context, reais, cents):\n    assert context.total == reais * 100 + cents, context.total\n',
     'The outcome. `assert` fails the step if the comparison is false, and the text after the comma, here the '
     'actual total, is what behave prints when it does.',
     'O resultado. `assert` faz o passo falhar se a comparação for falsa, e o que vem depois da vírgula, aqui o '
     'total obtido, é o que o behave imprime quando falha.'),
])
