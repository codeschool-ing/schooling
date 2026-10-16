# lesson 17: the step definitions behind the price outline

example('prices', 'features/steps/prices_steps.py', [
    ('# features/steps/prices_steps.py\nfrom behave import given, when, then\nfrom tickets import brl, price\n',
     'The price rule and the formatter from lesson 1’s `tickets.py`, the same functions the command line uses.',
     'A regra de preço e o formatador do `tickets.py` da aula 1, as mesmas funções que a linha de comando usa.'),
    ('\n\n@given("a customer aged {age:d} who {is_} a student")\ndef a_customer(context, age, is_):\n    context.age = age\n    context.student = is_ == "is"\n',
     'The customer: an age, and whether they are a student. The table writes `is` or `is not`, so the sentence '
     'reads naturally in both rows and the step turns it into `True` or `False`.',
     'O cliente: uma idade, e se é estudante. A tabela escreve `is` ou `is not`, para a frase ler bem nas duas '
     'linhas, e o passo transforma isso em `True` ou `False`.'),
    ('\n\n@given("a {day} session at {time}")\ndef a_session(context, day, time):\n    context.day, context.time = day, time\n',
     'The session, kept exactly as written: the day and the time are passed on as text, as the box office types '
     'them.',
     'A sessão, guardada exatamente como escrita: o dia e o horário seguem como texto, do jeito que a bilheteria '
     'os digita.'),
    ('\n\n@when("they buy a ticket")\ndef they_buy(context):\n    context.paid = brl(price(context.age, context.student, context.day, context.time))\n',
     'The action calls the real rule and keeps the price as the customer would see it, `R$ 18,00`.',
     'A ação chama a regra de verdade e guarda o preço como o cliente o veria, `R$ 18,00`.'),
    ('\n\n@then("they pay R$ {amount}")\ndef they_pay(context, amount):\n    assert context.paid == f"R$ {amount}", context.paid\n',
     'The outcome compares text with text, so a failure prints the price the program charged, in reais.',
     'O resultado compara texto com texto, então uma falha imprime o preço que o programa cobrou, em reais.'),
])
