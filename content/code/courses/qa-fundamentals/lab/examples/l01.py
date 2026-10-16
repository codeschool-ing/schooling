# lesson 1: the program every later lesson tests

example('tickets', 'tickets.py', [
    ('# tickets.py\nimport sys\n\nEVENING = 3600\nMATINEE = 2800\n',
     'The two full prices, in centavos: R$ 36,00 for an evening session and R$ 28,00 for a matinée. '
     'Money is kept as a whole number of centavos, because a fraction of a real cannot be paid.',
     'Os dois preços cheios, em centavos: R$ 36,00 para uma sessão da noite e R$ 28,00 para uma matinê. '
     'O dinheiro fica guardado como um número inteiro de centavos, porque uma fração de real não se paga.'),
    ('\n\ndef price(age, student, day, time):\n    if time < "17:00":\n        full = MATINEE\n    else:\n        full = EVENING\n',
     '`price` takes four facts about one ticket and answers what it costs. First the session: one '
     'starting before 17:00 is a matinée.',
     '`price` recebe quatro fatos sobre um ingresso e responde quanto ele custa. Primeiro a sessão: a '
     'que começa antes das 17:00 é matinê.'),
    ('    half = False\n    if student:\n        half = True\n    if age > 60:\n        half = True\n    if age < 12:\n        half = True\n',
     'Then who is buying. Three kinds of customer pay half: a student, an older person, a child. '
     'Each `if` is one line of the requirement turned into code.',
     'Depois, quem está comprando. Três tipos de cliente pagam meia: estudante, pessoa idosa, criança. '
     'Cada `if` é uma linha do requisito virada código.'),
    ('    if day == "wed":\n        full = full // 2\n    if half:\n        return full // 2\n    return full\n',
     'Wednesday is half price for everybody. `//` divides and drops what is left over, which on these '
     'prices is nothing.',
     'Quarta-feira é meia para todo mundo. `//` divide e descarta o resto, que nestes preços é zero.'),
    ('\n\ndef brl(cents):\n    return f"R$ {cents // 100},{cents % 100:02d}"\n',
     'Turns 1800 centavos into the text `R$ 18,00`, the way a Brazilian receipt writes it.',
     'Transforma 1800 centavos no texto `R$ 18,00`, do jeito que um recibo brasileiro escreve.'),
    ('\n\nif __name__ == "__main__":\n    age, student, day, time = sys.argv[1:]\n    print(brl(price(int(age), student == "yes", day, time)))\n',
     'What runs when you type the command. The four words after `python tickets.py` are the age, '
     '`yes` or `no` for a student, the day as three letters and the session time.',
     'O que roda quando você digita o comando. As quatro palavras depois de `python tickets.py` são a '
     'idade, `yes` ou `no` para estudante, o dia em três letras e o horário da sessão.'),
])
