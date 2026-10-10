# lesson 8

@figure('l08-map', 8)
def l08_map(lang):
    t = {
        'en': dict(cust='customer or box office', ask1='day, time, ages', ask2='age, day, time', ret='price',
                   store='writes a row', read='adds up tickets', report='nightly seats report', who='Célia',
                   q1='arrow: same form both sides?', q2='store: only when it should?', q3='reader: same meaning?',
                   label='A box-and-arrow map. A customer or the box office sends day, time and ages to orders.py. '
                         'orders.py sends age, day and time to tickets.py and gets a price back. orders.py writes a row '
                         'into the orders table in aurora.db. The nightly seats report adds up the tickets column and is '
                         'read by Célia. Three questions are attached: at an arrow, same form both sides; at the store, '
                         'only when it should; at the reader, same meaning.',
                   cap='Everything a grey-box tester needs to know about the order program, and none of it is code. '
                       'The defect in this lesson sat between the store and the reader.'),
        'pt': dict(cust='cliente ou bilheteria', ask1='dia, horário, idades', ask2='idade, dia, horário', ret='preço',
                   store='grava uma linha', read='soma os ingressos', report='relatório de assentos da noite', who='Célia',
                   q1='seta: mesmo formato dos dois lados?', q2='armazém: só quando deve?', q3='leitor: mesmo sentido?',
                   label='Um mapa de caixas e setas. Um cliente ou a bilheteria manda dia, horário e idades para o orders.py. '
                         'O orders.py manda idade, dia e horário para o tickets.py e recebe um preço de volta. O orders.py '
                         'grava uma linha na tabela orders do aurora.db. O relatório de assentos da noite soma a coluna '
                         'tickets e é lido pela Célia. Três perguntas estão presas: na seta, mesmo formato dos dois lados; '
                         'no armazém, só quando deve; no leitor, mesmo sentido.',
                   cap='Tudo o que quem testa como caixa cinza precisa saber sobre o programa de pedidos, e nada disso é '
                       'código. O defeito desta aula ficava entre o armazém e o leitor.'),
    }[lang]
    f = Fig('l08-map', 680, 300, t['label'])
    box(f, 20, 40, 150, 44, [t['cust']], size=10)
    box(f, 250, 40, 150, 44, ['orders.py'], stroke='--phosphor', size=11, mono=True, weights=['600'])
    box(f, 500, 40, 150, 44, ['tickets.py'], size=11, mono=True, weights=['600'])
    arrow(f, 171, 62, 249, 62)
    f.text(210, 52, t['ask1'], size=9)
    arrow(f, 401, 56, 499, 56)
    f.text(450, 46, t['ask2'], size=9)
    arrow(f, 499, 72, 401, 72, stroke='--paper-dim')
    f.text(450, 84, t['ret'], size=9, fill='--paper-dim')
    # store
    box(f, 250, 150, 150, 44, ['aurora.db · orders'], size=10.5, mono=True)
    arrow(f, 325, 85, 325, 149)
    f.text(332, 118, t['store'], size=9, anchor='start')
    box(f, 500, 150, 150, 44, [t['report']], size=9.5, stroke='--amber')
    arrow(f, 401, 172, 499, 172, stroke='--amber')
    f.text(450, 162, t['read'], size=9, fill='--amber')
    f.text(575, 210, t['who'], size=9.5, fill='--paper-dim')
    # questions
    for i, q in enumerate([t['q1'], t['q2'], t['q3']]):
        f.text(20, 236 + i * 18, f'{i + 1} · {q}', size=9.5, anchor='start', fill='--paper-dim')
    return f, t['cap']
