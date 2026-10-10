# lesson 3: what the sixty-year-old's defect costs after a month in production

example('overcharge', 'overcharge.py', [
    ('# overcharge.py\nimport random\nfrom tickets import brl, price\n',
     'It uses the shop’s own `price` and `brl` from `tickets.py`, so it charges exactly what the shop would. '
     'Keep both files in `~/aurora`.',
     'Usa o `price` e o `brl` da própria loja, do `tickets.py`, então cobra exatamente o que a loja cobraria. '
     'Deixe os dois arquivos em `~/aurora`.'),
    ('\nDAYS = ["thu", "fri", "sat", "sun", "mon", "tue", "wed"]\nSESSIONS = ["14:00", "16:30", "19:00", "21:30"]\n',
     'A week starting on a Thursday, which is the day new films open in Brazil, and the four sessions of '
     'one screen.',
     'Uma semana começando na quinta, que é o dia em que os filmes estreiam no Brasil, e as quatro sessões '
     'de uma sala.'),
    ('\nrng = random.Random(30)\nsold = tickets = extra = 0\nfor n in range(30):\n    day = DAYS[n % 7]\n    for _ in range(120):\n        age = rng.randint(15, 80)\n        time = rng.choice(SESSIONS)\n        paid = price(age, False, day, time)\n        sold += 1\n',
     'Thirty days of 120 online sales each, to customers aged 15 to 80, none of them students. The sales '
     'are invented, from a fixed seed, so every run makes the same month and your numbers match these.',
     'Trinta dias de 120 vendas online cada, para clientes de 15 a 80 anos, nenhum estudante. As vendas são '
     'inventadas, a partir de uma semente fixa, então toda execução produz o mesmo mês e os seus números '
     'batem com estes.'),
    ('        if age == 60 and day != "wed":\n            tickets += 1\n            extra += paid - paid // 2\n',
     'A sixty-year-old should have paid half. On a Wednesday everybody pays half anyway, so the defect costs '
     'them nothing that day and is not counted.',
     'Quem tem sessenta anos deveria ter pago meia. Na quarta todo mundo paga meia de qualquer jeito, então o '
     'defeito não custa nada nesse dia e não é contado.'),
    ('\nprint(sold, "tickets sold in 30 days")\nprint(tickets, "of them to a sixty-year-old, outside a Wednesday")\nprint(brl(extra), "charged too much")\n',
     'The three numbers a manager would ask for.',
     'Os três números que uma gerente pediria.'),
])
