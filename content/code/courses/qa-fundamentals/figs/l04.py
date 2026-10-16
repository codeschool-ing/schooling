# lesson 4

@figure('l04-refutes', 4)
def l04_refutes(lang):
    t = {
        'en': dict(runs=['adult, Sun 15:00', 'child, Sun 9:30', 'adult, 9:30', 'adult, 10:00', 'adult, 09:30'],
                   prices=['R$ 28,00', 'R$ 18,00', 'R$ 36,00', 'R$ 28,00', 'R$ 28,00'],
                   hyps=['1 · it is Sunday', '2 · early hours count as evening', '3 · the way the time is written'],
                   ok='fits', no='refuted',
                   label='A grid of three hypotheses against five runs. Runs: adult on Sunday at 15:00, R$ 28,00; child '
                         'on Sunday at 9:30, R$ 18,00; adult at 9:30, R$ 36,00; adult at 10:00, R$ 28,00; adult at 09:30, '
                         'R$ 28,00. Hypothesis 1, it is Sunday, is refuted by the first run. Hypothesis 2, early hours '
                         'count as evening, is refuted by the 10:00 run and the 09:30 run. Hypothesis 3, the way the time '
                         'is written, fits every run.',
                   cap='Each run was chosen because some hypothesis predicted a different price for it. Only the third '
                       'survives all five, which is what makes it worth opening the code for.'),
        'pt': dict(runs=['adulto, dom 15:00', 'criança, dom 9:30', 'adulto, 9:30', 'adulto, 10:00', 'adulto, 09:30'],
                   prices=['R$ 28,00', 'R$ 18,00', 'R$ 36,00', 'R$ 28,00', 'R$ 28,00'],
                   hyps=['1 · é o domingo', '2 · horas cedo contam como noite', '3 · o jeito de escrever o horário'],
                   ok='bate', no='refutada',
                   label='Uma grade de três hipóteses contra cinco execuções. Execuções: adulto no domingo às 15:00, '
                         'R$ 28,00; criança no domingo às 9:30, R$ 18,00; adulto às 9:30, R$ 36,00; adulto às 10:00, '
                         'R$ 28,00; adulto às 09:30, R$ 28,00. A hipótese 1, é o domingo, é refutada pela primeira '
                         'execução. A hipótese 2, horas cedo contam como noite, é refutada pela execução das 10:00 e pela '
                         'das 09:30. A hipótese 3, o jeito de escrever o horário, bate com todas.',
                   cap='Cada execução foi escolhida porque alguma hipótese previa um preço diferente para ela. Só a '
                       'terceira sobrevive às cinco, e é isso que faz valer a pena abrir o código.'),
    }[lang]
    # which cells refute: hypothesis index -> run indexes
    refute = {0: {0}, 1: {3, 4}, 2: set()}
    f = Fig('l04-refutes', 680, 230, t['label'])
    x0, cw, y0, rh = 210, 92, 64, 44
    for j, (r, p) in enumerate(zip(t['runs'], t['prices'])):
        cx = x0 + j * cw + cw / 2
        f.text(cx, 22, r, size=9.5, weight='600')
        f.text(cx, 40, p, size=9.5, fill='--paper-dim', mono=True)
    for i, h in enumerate(t['hyps']):
        y = y0 + i * rh
        survive = not refute[i]
        f.text(x0 - 10, y + rh / 2, h, size=10, anchor='end', weight='600',
               fill='--phosphor' if survive else '--paper')
        for j in range(5):
            x = x0 + j * cw
            bad = j in refute[i]
            f.rect(x + 3, y + 3, cw - 6, rh - 6, stroke='--amber' if bad else '--wire',
                   fill='--panel', width=1.6 if bad else 1)
            f.text(x + cw / 2, y + rh / 2, t['no'] if bad else t['ok'], size=9.5,
                   fill='--amber' if bad else '--paper-dim', weight='600' if bad else None)
    return f, t['cap']
