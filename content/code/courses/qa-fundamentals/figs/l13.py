# lesson 13

@figure('l13-board', 13)
def l13_board(lang):
    t = {
        'en': dict(cols=['ready', 'building', 'waiting for test', 'testing', 'done'],
                   cards=[['receipt shows the seat', 'child price on the sign'], ['refund button'],
                          ['session list sorted', 'Wednesday banner', 'report total in bold'],
                          ['matinée on holidays'], []],
                   queue='nobody is working on these',
                   label='A Kanban board with five columns: ready, building, waiting for test, testing and done. Ready '
                         'holds two cards, building one, waiting for test three, testing one, done none. The waiting '
                         'for test column is highlighted, with a note: nobody is working on these.',
                   cap='Cine Aurora’s first board. Drawing the wait as a column of its own is what showed the queue.'),
        'pt': dict(cols=['a fazer', 'construindo', 'esperando teste', 'testando', 'pronto'],
                   cards=[['recibo mostra o assento', 'meia infantil na placa'], ['botão de reembolso'],
                          ['lista de sessões ordenada', 'faixa da quarta', 'total do relatório em negrito'],
                          ['matinê nos feriados'], []],
                   queue='ninguém está trabalhando nestes',
                   label='Um quadro Kanban com cinco colunas: a fazer, construindo, esperando teste, '
                         'testando e pronto. A fazer tem dois cartões, construindo um, esperando teste '
                         'três, testando um, pronto nenhum. A coluna esperando teste está destacada, com uma nota: '
                         'ninguém está trabalhando nestes.',
                   cap='O primeiro quadro do Cine Aurora. Desenhar a espera como coluna própria foi o que mostrou a '
                       'fila.'),
    }[lang]
    f = Fig('l13-board', 680, 230, t['label'])
    for i, col in enumerate(t['cols']):
        x = 10 + i * 134
        hot = i == 2
        f.rect(x, 10, 126, 190, stroke='--amber' if hot else '--wire', fill='--ink', rx=6,
               width=1.6 if hot else 1.2)
        f.text(x + 63, 28, col, size=9.5, weight='600', fill='--amber' if hot else '--paper')
        for k, c in enumerate(t['cards'][i]):
            box(f, x + 8, 44 + k * 42, 110, 34, [c], size=8.5)
    f.text(10 + 2 * 134 + 63, 216, t['queue'], size=9, fill='--amber')
    return f, t['cap']


@figure('l13-limits', 13)
def l13_limits(lang):
    t = {
        'en': dict(rows=[('9 cards on the board', '3 weeks'), ('6 cards on the board', '2 weeks')],
                   out='3 a week reach done', law='time on the board = cards ÷ throughput',
                   label='Little’s law drawn twice. Above, nine cards on the board and three a week reaching done: '
                         'each card spends three weeks on the board. Below, six cards and the same three a week: '
                         'two weeks. Nobody works faster; there are fewer cards waiting.',
                   cap='Same people, same speed, fewer cards in progress: every card comes out sooner.'),
        'pt': dict(rows=[('9 cartões no quadro', '3 semanas'), ('6 cartões no quadro', '2 semanas')],
                   out='3 por semana chegam ao pronto', law='tempo no quadro = cartões ÷ vazão',
                   label='A lei de Little desenhada duas vezes. Em cima, nove cartões no quadro e três por semana '
                         'chegando ao pronto: cada cartão passa três semanas no quadro. Embaixo, seis cartões e as '
                         'mesmas três por semana: duas semanas. Ninguém trabalha mais rápido; há menos cartões '
                         'esperando.',
                   cap='Mesmas pessoas, mesma velocidade, menos cartões em andamento: todo cartão sai mais cedo.'),
    }[lang]
    f = Fig('l13-limits', 680, 180, t['label'])
    f.text(340, 20, t['law'], size=10.5, weight='600', fill='--phosphor')
    for r, (cards, weeks) in enumerate(t['rows']):
        y = 50 + r * 70
        n = 9 if r == 0 else 6
        f.rect(10, y - 6, 400, 50, stroke='--wire', fill='--ink', rx=6)
        for k in range(n):
            f.rect(20 + k * 42, y + 2, 32, 24, stroke='--wire', fill='--panel', rx=3)
        f.text(210, y + 36, cards, size=9, fill='--paper-dim')
        arrow(f, 412, y + 19, 470, y + 19)
        box(f, 476, y, 90, 38, [weeks], size=11, weights=['600'],
            stroke='--amber' if r == 0 else '--phosphor', fills=['--amber' if r == 0 else '--phosphor'])
    f.text(441, 104, t['out'], size=9, fill='--paper-dim')
    return f, t['cap']


@figure('l13-cfd', 13)
def l13_cfd(lang):
    t = {
        'en': dict(bands=['done', 'testing', 'waiting for test', 'building', 'ready'], x='working day', y='cards',
                   label='A cumulative flow diagram over twenty working days. Five bands are stacked from the bottom: '
                         'done, testing, waiting for test, building and ready. Done grows steadily. Testing, building '
                         'and ready stay the same thickness. The waiting for test band starts thin and swells to about '
                         'four and a half cards by day twenty.',
                   cap='March at Cine Aurora. One band swelling while its neighbours stay thin is a queue growing, '
                       'and it is visible before anybody complains.'),
        'pt': dict(bands=['pronto', 'testando', 'esperando teste', 'construindo', 'a fazer'],
                   x='dia útil', y='cartões',
                   label='Um diagrama de fluxo cumulativo ao longo de vinte dias úteis. Cinco faixas empilhadas de '
                         'baixo para cima: pronto, testando, esperando teste, construindo e a fazer. Pronto '
                         'cresce sem parar. Testando, construindo e a fazer mantêm a espessura. A faixa '
                         'esperando teste começa fina e incha até cerca de quatro cartões e meio no dia vinte.',
                   cap='Março no Cine Aurora. Uma faixa inchando enquanto as vizinhas continuam finas é uma fila '
                       'crescendo, e ela aparece antes de alguém reclamar.'),
    }[lang]
    f = Fig('l13-cfd', 680, 270, t['label'])
    p = Plot(f, 60, 20, 520, 220, 0, 20, 0, 22)
    curves = [lambda d: 0.6 * d, lambda d: 1 + 0.6 * d, lambda d: 1.5 + 0.8 * d,
              lambda d: 2.5 + 0.8 * d, lambda d: 5 + 0.8 * d]
    fills = ['--phosphor-dim', '--phosphor', '--amber', '--wire', '--scan']
    days = list(range(0, 21))
    for i in range(5):
        lo = (lambda d: 0) if i == 0 else curves[i - 1]
        hi = curves[i]
        pts = [(p.sx(d), p.sy(hi(d))) for d in days] + [(p.sx(d), p.sy(lo(d))) for d in reversed(days)]
        dpath = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + ' Z'
        f.path(dpath, stroke=fills[i], width=1, fill=fills[i], opacity=0.55 if i != 2 else 0.8)
    for g in [0, 5, 10, 15, 20]:
        y = p.sy(g)
        f.text(p.x0 - 8, y, str(g), size=9.5, anchor='end', fill='--paper-dim')
    p.xaxis([0, 5, 10, 15, 20], label=t['x'])
    f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1.2)
    f.text(p.x0, p.y0 - 8, t['y'], size=10, anchor='start', weight='600')
    for i, (m, b) in enumerate(zip([6, 12.5, 15.25, 18, 19.9], t['bands'])):
        f.text(p.x1 + 10, p.sy(m), b, size=9.5, anchor='start',
               fill='--amber' if i == 2 else '--paper', weight='600' if i == 2 else None)
    return f, t['cap']


@figure('l13-lanes', 13)
def l13_lanes(lang):
    t = {
        'en': dict(cols=['building', 'waiting for test', 'testing', 'done'],
                   pol=['reviewed, checks pass', 'a tester pulled it', 'examples pass, explored', 'Célia saw it'],
                   lanes=['expedite', 'standard'], one='1 card at most',
                   urgent='wrong price on Sundays', cards=['refund button', 'session list sorted', 'receipt seat'],
                   blocked='blocked',
                   label='A Kanban board with four columns, building, waiting for test, testing and done, each with '
                         'its exit policy written under the name: reviewed and checks pass; a tester pulled it; '
                         'examples pass and explored; Célia saw it. Above the standard lane is an expedite lane, one '
                         'card at most, holding the card wrong price on Sundays in testing. In the standard lane, '
                         'the card session list sorted in testing carries a red blocked marker.',
                   cap='Policies at the top of each column, an expedite lane for the defect that cannot wait, and a '
                       'blocked card that stays where it is until the team deals with it.'),
        'pt': dict(cols=['construindo', 'esperando teste', 'testando', 'pronto'],
                   pol=['revisado, checagens passam', 'alguém do teste puxou', 'exemplos passam, explorado',
                        'a Célia viu'],
                   lanes=['urgente', 'padrão'], one='1 cartão no máximo',
                   urgent='preço errado aos domingos', cards=['botão de reembolso', 'lista de sessões ordenada',
                                                             'assento no recibo'],
                   blocked='bloqueado',
                   label='Um quadro Kanban com quatro colunas, construindo, esperando teste, testando e pronto, cada '
                         'uma com a política de saída escrita sob o nome: revisado e checagens passam; alguém do teste '
                         'puxou; exemplos passam e explorado; a Célia viu. Acima da faixa padrão há uma faixa urgente, '
                         'um cartão no máximo, com o cartão preço errado aos domingos em testando. Na faixa padrão, o '
                         'cartão lista de sessões ordenada em testando leva uma marca vermelha de bloqueado.',
                   cap='Políticas no topo de cada coluna, uma faixa urgente para o defeito que não pode esperar, e um '
                       'cartão bloqueado que fica onde está até o time cuidar dele.'),
    }[lang]
    f = Fig('l13-lanes', 680, 260, t['label'])
    x0 = 100
    for i, c in enumerate(t['cols']):
        x = x0 + i * 145
        f.rect(x, 10, 137, 240, stroke='--wire', fill='--ink', rx=6)
        f.text(x + 68.5, 26, c, size=9.5, weight='600')
        f.text(x + 68.5, 42, t['pol'][i], size=8.5, fill='--phosphor', italic=True)
    for xa, xb in [(10, 96)] + [(x0 + i * 145 + 4, x0 + i * 145 + 133) for i in range(4)]:
        f.line(xa, 56, xb, 56, stroke='--wire', width=1)
        f.line(xa, 120, xb, 120, stroke='--amber', width=1, dash='4 3')
    f.text(14, 76, t['lanes'][0], size=9.5, anchor='start', weight='600', fill='--amber')
    f.text(14, 92, t['one'], size=8.5, anchor='start', fill='--amber')
    f.text(14, 140, t['lanes'][1], size=9.5, anchor='start', weight='600')
    box(f, x0 + 2 * 145 + 10, 70, 117, 36, [t['urgent']], size=8.5, stroke='--amber')
    box(f, x0 + 10, 134, 117, 34, [t['cards'][0]], size=8.5)
    box(f, x0 + 2 * 145 + 10, 134, 117, 34, [t['cards'][1]], size=8.5)
    box(f, x0 + 3 * 145 + 10, 134, 117, 34, [t['cards'][2]], size=8.5)
    f.rect(x0 + 2 * 145 + 10, 172, 117, 18, stroke='--amber', fill='--ink', rx=3)
    f.text(x0 + 2 * 145 + 68.5, 181, t['blocked'], size=8.5, weight='600', fill='--amber')
    return f, t['cap']
