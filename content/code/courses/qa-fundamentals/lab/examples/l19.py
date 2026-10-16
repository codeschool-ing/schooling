# lesson 19: a partial oracle, checking relations rather than expected prices

example('relations', 'relations.py', [
    ('# relations.py\nfrom tickets import price\n\nTIMES = ["9:30", "11:00", "15:00", "16:59", "17:00", "20:00"]\n',
     'The price rule from lesson 17, and a spread of session times in the order they happen in a day, written the way '
     'the schedule writes them.',
     'A regra de preço da aula 17, e uma série de horários de sessão na ordem em que acontecem num dia, escritos do '
     'jeito que a programação os escreve.'),
    ('\nfound = 0\nfor day in ("thu", "wed", "sun"):\n    for age in (35, 70):\n',
     'Three days, one of them Wednesday, and two ages, one of them past the age line: every combination gets both '
     'relations checked.',
     'Três dias, um deles quarta, e duas idades, uma delas acima da linha da idade: cada combinação passa pelas duas '
     'relações.'),
    ('        prices = [price(age, False, day, t) for t in TIMES]\n        for i in range(len(TIMES) - 1):\n            if prices[i] > prices[i + 1]:\n                found += 1\n                print(f"{day}, age {age}: {TIMES[i]} costs {prices[i]}, but the later {TIMES[i + 1]} costs {prices[i + 1]}")\n',
     'The first relation: walking through the day, a price may stay the same or go up, never down. No price is '
     'written anywhere; only the comparison between neighbours.',
     'A primeira relação: andando pelo dia, um preço pode ficar igual ou subir, nunca descer. Nenhum preço está '
     'escrito em lugar nenhum; só a comparação entre vizinhos.'),
    ('        for time in TIMES:\n            if price(age, True, day, time) > price(age, False, day, time):\n                found += 1\n                print(f"{day}, age {age}, {time}: a student pays more than a non-student")\n',
     'The second relation: the same customer, as a student and not, at the same session. Being a student may lower '
     'the price or leave it alone, never raise it.',
     'A segunda relação: o mesmo cliente, estudante ou não, na mesma sessão. Ser estudante pode baixar o preço ou '
     'deixá-lo igual, nunca aumentar.'),
    ('print(found, "broken relations")\n',
     'The count at the end, so a run where nothing breaks still says what it checked.',
     'A contagem no fim, para uma execução em que nada quebra ainda dizer o que conferiu.'),
])
