# lesson 7: the black-box cases of lesson 6, as a program the trace module can watch

example('cases', 'cases.py', [
    ('# cases.py\nfrom tickets import price\n',
     'It calls `price` from `tickets.py` directly, without the command line, so the trace module can watch '
     'which lines of `price` run.',
     'Chama o `price` do `tickets.py` diretamente, sem a linha de comando, para o módulo trace poder observar '
     'quais linhas do `price` rodam.'),
    ('\nCASES = [\n    (35, False, "thu", "16:59", 2800),\n    (35, False, "thu", "17:00", 3600),\n    (20, True, "thu", "20:00", 1800),\n    (11, False, "thu", "20:00", 1800),\n    (12, False, "thu", "20:00", 3600),\n    (35, False, "wed", "20:00", 1800),\n]\n',
     'The six cases from lesson 6’s table, each with the price it should give, in centavos.',
     'Os seis casos da tabela da aula 6, cada um com o preço que deveria dar, em centavos.'),
    ('\nfor age, student, day, time, expected in CASES:\n    got = price(age, student, day, time)\n    print("ok  " if got == expected else "FAIL", age, student, day, time, got)\n',
     'Runs each case and prints `ok` or `FAIL` beside it. A program that checks another program’s answers '
     'against expected ones is a test, and lesson 15 gives this kind a proper home.',
     'Roda cada caso e imprime `ok` ou `FAIL` ao lado. Um programa que confere as respostas de outro contra '
     'respostas esperadas é um teste, e a aula 15 dá a esse tipo uma casa de verdade.'),
])
