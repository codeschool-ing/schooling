# lesson 6

@figure('l06-time-line', 6)
def l06_time_line(lang):
    t = {
        'en': dict(rows=['the rule', 'tickets.py, time as 09:30', 'tickets.py, time as 9:30'],
                   m='matinée', e='evening', note='no such times',
                   label='Three bands over a day from 00:00 to 24:00. The rule: matinée until 17:00, evening after. '
                         'tickets.py with times written with two digits for the hour, like 09:30: the same split, matinée '
                         'until 17:00 and evening after. tickets.py with times written with one digit, like 9:30: '
                         'midnight to 1:00 is matinée, 1:00 to 10:00 is evening, and there are no one-digit times after '
                         '10:00.',
                   cap='Comparing times as text agrees with the rule for every time written with two digits, and gets '
                       'every hour from 1 to 9 wrong when it is written with one. A black-box tester finds the third band '
                       'by asking how the time reaches the program.'),
        'pt': dict(rows=['a regra', 'tickets.py, horário como 09:30', 'tickets.py, horário como 9:30'],
                   m='matinê', e='noite', note='não existem esses horários',
                   label='Três faixas sobre um dia de 00:00 a 24:00. A regra: matinê até 17:00, noite depois. tickets.py '
                         'com horários escritos com dois dígitos na hora, como 09:30: a mesma divisão, matinê até 17:00 e '
                         'noite depois. tickets.py com horários escritos com um dígito, como 9:30: da meia-noite à 1:00 é '
                         'matinê, de 1:00 a 10:00 é noite, e não há horários de um dígito depois das 10:00.',
                   cap='Comparar horários como texto concorda com a regra para todo horário escrito com dois dígitos, e '
                       'erra toda hora de 1 a 9 quando ela é escrita com um. Quem testa como caixa preta acha a terceira '
                       'faixa perguntando como o horário chega ao programa.'),
    }[lang]
    f = Fig('l06-time-line', 680, 230, t['label'])
    x0, x1 = 220, 660
    sx = lambda h: x0 + (x1 - x0) * h / 24
    rows = [[(0, 17, 'm'), (17, 24, 'e')], [(0, 17, 'm'), (17, 24, 'e')],
            [(0, 1, 'm'), (1, 10, 'e'), (10, 24, None)]]
    for i, (name, segs) in enumerate(zip(t['rows'], rows)):
        y = 30 + i * 52
        f.text(x0 - 10, y + 15, name, size=10, anchor='end', weight='600', mono=(i > 0 and False))
        for a, b, k in segs:
            if k is None:
                f.rect(sx(a), y, sx(b) - sx(a), 30, stroke='--wire', fill='--ink', dash='3 3', rx=2)
                f.text((sx(a) + sx(b)) / 2, y + 15, t['note'], size=9.5, fill='--paper-dim')
                continue
            wrong = i == 2 and k == 'e'
            f.rect(sx(a), y, sx(b) - sx(a), 30, stroke='--amber' if wrong else ('--phosphor' if k == 'e' else '--wire'),
                   fill='--panel', rx=2, width=1.6 if wrong else 1.1)
            if sx(b) - sx(a) > 40:
                f.text((sx(a) + sx(b)) / 2, y + 15, t[k], size=10, fill='--amber' if wrong else '--paper')
    for h in [0, 6, 10, 12, 17, 24]:
        x = sx(h)
        f.line(x, 186, x, 192, stroke='--paper-dim', width=1)
        f.text(x, 204, f'{h:02d}:00', size=9, fill='--paper-dim', mono=True)
    f.line(x0, 186, x1, 186, stroke='--paper-dim', width=1)
    return f, t['cap']
