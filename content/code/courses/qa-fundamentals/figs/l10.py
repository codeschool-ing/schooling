# lesson 10

@figure('l10-spiral', 10)
def l10_spiral(lang):
    t = {
        'en': dict(q=['1 · determine objectives', '2 · identify and resolve risks', '3 · develop and test',
                      '4 · plan the next iteration'],
                   cost='cost so far grows outwards',
                   label='A spiral starting at the centre and winding outwards through four quadrants: top left, '
                         'determine objectives; top right, identify and resolve risks; bottom right, develop and test; '
                         'bottom left, plan the next iteration. A note says the cost so far grows outwards.',
                   cap='Boehm’s spiral. Each turn crosses all four quadrants; the second, choosing by risk, is what '
                       'separates it from plain repetition.'),
        'pt': dict(q=['1 · definir objetivos', '2 · identificar e resolver riscos', '3 · desenvolver e testar',
                      '4 · planejar a próxima iteração'],
                   cost='o custo até aqui cresce para fora',
                   label='Uma espiral que começa no centro e se abre para fora por quatro quadrantes: em cima à esquerda, '
                         'definir objetivos; em cima à direita, identificar e resolver riscos; embaixo à direita, '
                         'desenvolver e testar; embaixo à esquerda, planejar a próxima iteração. Uma nota diz que o custo '
                         'até aqui cresce para fora.',
                   cap='A espiral de Boehm. Cada volta atravessa os quatro quadrantes; o segundo, escolher pelo risco, é o '
                       'que a separa de mera repetição.'),
    }[lang]
    f = Fig('l10-spiral', 640, 330, t['label'])
    cx, cy = 320, 168
    f.line(cx - 250, cy, cx + 250, cy, stroke='--wire', width=1)
    f.line(cx, 24, cx, 312, stroke='--wire', width=1)
    pts = []
    for i in range(0, 721 + 360):
        a = math.radians(i) + math.pi
        r = 6 + i * 0.12
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a) * 0.95))
    d = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts)
    f.path(d, stroke='--phosphor', width=1.8)
    f.text(28, 30, t['q'][0], size=10, anchor='start', weight='600')
    f.text(612, 30, t['q'][1], size=10, anchor='end', weight='600', fill='--amber')
    f.text(612, 306, t['q'][2], size=10, anchor='end', weight='600')
    f.text(28, 306, t['q'][3], size=10, anchor='start', weight='600')
    f.text(cx + 8, 18, t['cost'], size=9, anchor='start', fill='--paper-dim')
    return f, t['cap']


@figure('l10-two-ways', 10)
def l10_two_ways(lang):
    t = {
        'en': dict(rows=['incremental', 'iterative'], cols=['week 2', 'week 6', 'week 10'],
                   parts=['prices', 'orders', 'seat map', 'payment'], rough='rough', better='better', done='done',
                   label='Two rows of three snapshots, at weeks 2, 6 and 10. Incremental: at week 2 only prices exist, '
                         'finished; at week 6 prices and orders; at week 10 prices, orders and the seat map, with payment '
                         'still missing. Iterative: at week 2 all four parts exist, rough; at week 6 all four are better; at '
                         'week 10 all four are done.',
                   cap='Incrementally, part of the shop is finished and part does not exist. Iteratively, all of it '
                       'exists and none of it is finished. Most teams slice thin and do both.'),
        'pt': dict(rows=['incremental', 'iterativo'], cols=['semana 2', 'semana 6', 'semana 10'],
                   parts=['preços', 'pedidos', 'assentos', 'pagamento'], rough='rascunho', better='melhor', done='pronto',
                   label='Duas fileiras de três retratos, nas semanas 2, 6 e 10. Incremental: na semana 2 só existem os '
                         'preços, prontos; na semana 6 preços e pedidos; na semana 10 preços, pedidos e assentos, ainda sem '
                         'pagamento. Iterativo: na semana 2 as quatro partes existem, em rascunho; na semana 6 as quatro estão '
                         'melhores; na semana 10 as quatro estão prontas.',
                   cap='Incrementalmente, parte da loja está pronta e parte não existe. Iterativamente, tudo existe e nada '
                       'está pronto. A maioria dos times corta fatias finas e faz os dois.'),
    }[lang]
    f = Fig('l10-two-ways', 660, 260, t['label'])
    x0, cw, y0, rh = 120, 176, 40, 104
    for j, c in enumerate(t['cols']):
        f.text(x0 + j * cw + cw / 2, 22, c, size=10, weight='600')
    for i, r in enumerate(t['rows']):
        y = y0 + i * rh
        f.text(x0 - 10, y + 44, r, size=10.5, anchor='end', weight='600')
        for j in range(3):
            x = x0 + j * cw
            f.rect(x + 4, y, cw - 8, rh - 12, stroke='--wire', fill='--ink', rx=4)
            for k, p in enumerate(t['parts']):
                bx, by = x + 12 + (k % 2) * 78, y + 8 + (k // 2) * 42
                if i == 0:
                    exists = k <= j
                    if exists:
                        box(f, bx, by, 72, 34, [p, t['done']], stroke='--phosphor', size=9,
                            fills=['--paper', '--phosphor'])
                    else:
                        f.rect(bx, by, 72, 34, stroke='--wire', fill='--ink', dash='3 3')
                else:
                    state = [t['rough'], t['better'], t['done']][j]
                    st = ['--paper-dim', '--wire', '--phosphor'][j]
                    box(f, bx, by, 72, 34, [p, state], stroke=st, size=9,
                        fills=['--paper', '--phosphor' if j == 2 else '--paper-dim'], dash=None if j else '3 2')
    return f, t['cap']


@figure('l10-regression', 10)
def l10_regression(lang):
    t = {
        'en': dict(turns=['turn 1', 'turn 2', 'turn 3', 'turn 4'], parts=['prices', 'orders', 'seat map', 'half is the most'],
                   new='new checks', old='checks run again',
                   label='Four columns, one per turn. Each column stacks the checks run in that turn: turn 1, prices; turn '
                         '2, prices again and orders new; turn 3, prices and orders again and the seat map new; turn 4, '
                         'prices, orders and seat map again and the rule half is the most new. The stack of checks run '
                         'again grows by one block each turn.',
                   cap='The checks for the first turn run in every turn after it. Regression testing grows with the system, '
                       'which is why it is the first testing teams automate.'),
        'pt': dict(turns=['volta 1', 'volta 2', 'volta 3', 'volta 4'], parts=['preços', 'pedidos', 'assentos', 'meia é o máximo'],
                   new='conferências novas', old='conferências rodadas de novo',
                   label='Quatro colunas, uma por volta. Cada coluna empilha as conferências rodadas naquela volta: volta 1, '
                         'preços; volta 2, preços de novo e pedidos novo; volta 3, preços e pedidos de novo e assentos novo; '
                         'volta 4, preços, pedidos e assentos de novo e a regra meia é o máximo nova. A pilha de conferências '
                         'rodadas de novo cresce um bloco a cada volta.',
                   cap='As conferências da primeira volta rodam em toda volta depois dela. O teste de regressão cresce com o '
                       'sistema, e é por isso que é o primeiro teste que os times automatizam.'),
    }[lang]
    f = Fig('l10-regression', 600, 280, t['label'])
    base, bh, bw = 230, 40, 110
    for j, turn in enumerate(t['turns']):
        x = 40 + j * 130
        for k in range(j + 1):
            y = base - (k + 1) * (bh + 4)
            new = k == j
            box(f, x, y, bw, bh, [t['parts'][k]], stroke='--amber' if new else '--wire',
                fill='--panel', size=9.5, fills=['--amber' if new else '--paper-dim'])
        f.text(x + bw / 2, base + 16, turn, size=10, weight='600')
    f.rect(40, 258, 12, 12, stroke='--amber', fill='--panel', rx=2)
    f.text(58, 264, t['new'], size=9.5, anchor='start', fill='--amber')
    f.rect(220, 258, 12, 12, stroke='--wire', fill='--panel', rx=2)
    f.text(238, 264, t['old'], size=9.5, anchor='start', fill='--paper-dim')
    return f, t['cap']
