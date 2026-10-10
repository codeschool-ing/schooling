# lesson 11

@figure('l11-two-sprints', 11)
def l11_two_sprints(lang):
    t = {
        'en': dict(rows=['mini-waterfall', 'testing throughout'], build='build', test='test',
                   ask='ask', day='day', squeeze='everything arrives on day 9',
                   label='Two timelines of ten working days. Mini-waterfall: building fills days 1 to 8 and testing is '
                         'squeezed into days 9 and 10, with a note that everything arrives on day 9. Testing throughout: '
                         'on day 1 the tester asks questions, and from day 2 small pieces are built and each is tested '
                         'a day or two later, so build and test blocks alternate across the whole cycle.',
                   cap='The same two weeks. Above, the waterfall shrunk to a sprint; below, testing keeps pace with '
                       'building, and every defect is found while it is young.'),
        'pt': dict(rows=['minicascata', 'teste o tempo todo'], build='construir', test='testar',
                   ask='perguntar', day='dia', squeeze='tudo chega no dia 9',
                   label='Duas linhas do tempo de dez dias úteis. Minicascata: construir ocupa os dias 1 a 8 e o teste é '
                         'espremido nos dias 9 e 10, com uma nota de que tudo chega no dia 9. Teste o tempo todo: no dia 1 '
                         'quem testa faz perguntas, e a partir do dia 2 pedaços pequenos são construídos e cada um é testado '
                         'um ou dois dias depois, então blocos de construir e testar se alternam pelo ciclo inteiro.',
                   cap='As mesmas duas semanas. Em cima, a cascata encolhida para uma sprint; embaixo, o teste acompanha a '
                       'construção, e todo defeito é achado enquanto é novo.'),
    }[lang]
    f = Fig('l11-two-sprints', 660, 230, t['label'])
    x0, dw = 150, 49
    for d in range(10):
        f.text(x0 + d * dw + dw / 2, 22, f"{t['day']} {d + 1}", size=8.5, fill='--paper-dim')
    # row 1
    y = 40
    f.text(x0 - 10, y + 20, t['rows'][0], size=10, anchor='end', weight='600')
    box(f, x0, y, 8 * dw - 2, 40, [t['build']], size=10)
    box(f, x0 + 8 * dw, y, 2 * dw - 2, 40, [t['test']], stroke='--amber', size=10, fills=['--amber'])
    f.text(x0 + 8 * dw, y + 54, t['squeeze'], size=9, anchor='middle', fill='--amber')
    # row 2
    y = 130
    f.text(x0 - 10, y + 20, t['rows'][1], size=10, anchor='end', weight='600')
    box(f, x0, y, dw - 2, 40, [t['ask']], stroke='--phosphor', size=9, fills=['--phosphor'])
    seq = ['b', 'b', 't', 'b', 't', 'b', 't', 'b', 't']
    for i, k in enumerate(seq):
        x = x0 + (i + 1) * dw
        if k == 'b':
            box(f, x, y, dw - 2, 40, [t['build']], size=8.5)
        else:
            box(f, x, y, dw - 2, 40, [t['test']], stroke='--phosphor', size=8.5, fills=['--phosphor'])
    return f, t['cap']


@figure('l11-quadrants', 11)
def l11_quadrants(lang):
    t = {
        'en': dict(top='business-facing', bottom='technology-facing', left='supporting the team',
                   right='critiquing the product',
                   q=[['Q2', 'examples, story tests'], ['Q3', 'exploration, usability,', 'acceptance'],
                      ['Q1', 'unit and component tests'], ['Q4', 'performance, load,', 'security']],
                   label='A square divided into four quadrants. Columns: supporting the team on the left, critiquing the '
                         'product on the right. Rows: business-facing on top, technology-facing below. Top left, Q2: '
                         'examples and story tests. Top right, Q3: exploration, usability, acceptance. Bottom left, Q1: '
                         'unit and component tests. Bottom right, Q4: performance, load, security.',
                   cap='Marick’s quadrants, as Crispin and Gregory drew them. Many good tests are born on the right, '
                       'found by exploring, and kept on the left, as an example checked on every change.'),
        'pt': dict(top='voltados ao negócio', bottom='voltados à tecnologia', left='apoiando o time',
                   right='criticando o produto',
                   q=[['Q2', 'exemplos, testes de história'], ['Q3', 'exploração, usabilidade,', 'aceitação'],
                      ['Q1', 'testes de unidade e de componente'], ['Q4', 'desempenho, carga,', 'segurança']],
                   label='Um quadrado dividido em quatro quadrantes. Colunas: apoiando o time à esquerda, criticando o '
                         'produto à direita. Linhas: voltados ao negócio em cima, voltados à tecnologia embaixo. Em cima à '
                         'esquerda, Q2: exemplos e testes de história. Em cima à direita, Q3: exploração, usabilidade, '
                         'aceitação. Embaixo à esquerda, Q1: testes de unidade e de componente. Embaixo à direita, Q4: '
                         'desempenho, carga, segurança.',
                   cap='Os quadrantes de Marick, como Crispin e Gregory os desenharam. Muitos bons testes nascem à direita, '
                       'achados explorando, e ficam à esquerda, como um exemplo conferido a cada mudança.'),
    }[lang]
    f = Fig('l11-quadrants', 680, 300, t['label'])
    x0, y0, w, h = 150, 40, 190, 110
    f.text(x0 + w, 24, t['top'], size=10, weight='600')
    f.text(x0 + w, y0 + 2 * h + 22, t['bottom'], size=10, weight='600')
    f.text(x0 - 10, y0 + h, t['left'], size=10, weight='600', anchor='end')
    f.text(x0 + 2 * w + 10, y0 + h, t['right'], size=10, weight='600', anchor='start')
    for i, lines in enumerate(t['q']):
        x = x0 + (i % 2) * w
        y = y0 + (i // 2) * h
        f.rect(x + 3, y + 3, w - 6, h - 6, stroke='--phosphor' if i % 2 == 0 else '--amber', fill='--panel')
        f.text(x + w / 2, y + 30, lines[0], size=13, weight='600', mono=True,
               fill='--phosphor' if i % 2 == 0 else '--amber')
        for k, s in enumerate(lines[1:]):
            f.text(x + w / 2, y + 58 + k * 15, s, size=9.5)
    return f, t['cap']
