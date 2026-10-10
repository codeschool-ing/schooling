# lesson 3

@figure('l03-two-curves', 3)
def l03_two_curves(lang):
    t = {
        'en': dict(phases=['requirements', 'design', 'code', 'test', 'after release'],
                   y='relative cost to fix, log scale', big='large, critical system: often 100 to 1',
                   small='small, non-critical system: about 5 to 1',
                   label='A chart with five phases on the horizontal axis: requirements, design, code, test, after '
                         'release. The vertical axis is the relative cost to fix a defect, on a log scale from 1 to 100. '
                         'One curve, for a large critical system, rises from 1 to 100. A second curve, for a small '
                         'non-critical system, rises from 1 to 5.',
                   cap='The two ratios from Boehm and Basili’s list of 2001. The first is the one everybody quotes; '
                       'the second sits in the next sentence of the same paper. The points between the ends are drawn '
                       'to show the shape, not measured.'),
        'pt': dict(phases=['requisitos', 'projeto', 'código', 'teste', 'depois da entrega'],
                   y='custo relativo da correção, escala log', big='sistema grande e crítico: muitas vezes 100 para 1',
                   small='sistema pequeno e não crítico: cerca de 5 para 1',
                   label='Um gráfico com cinco fases no eixo horizontal: requisitos, projeto, código, teste, depois da '
                         'entrega. O eixo vertical é o custo relativo de corrigir um defeito, em escala logarítmica de 1 a '
                         '100. Uma curva, para um sistema grande e crítico, sobe de 1 a 100. Uma segunda curva, para um '
                         'sistema pequeno e não crítico, sobe de 1 a 5.',
                   cap='As duas razões da lista de Boehm e Basili de 2001. A primeira é a que todo mundo cita; a segunda '
                       'está na frase seguinte do mesmo artigo. Os pontos entre as pontas estão desenhados para mostrar '
                       'a forma, não foram medidos.'),
    }[lang]
    f = Fig('l03-two-curves', 640, 300, t['label'])
    p = Plot(f, 80, 40, 560, 240, 0, 4, 0, 2)
    for v, lab in [(0, '1'), (math.log10(5), '5'), (1, '10'), (2, '100')]:
        y = p.sy(v)
        f.line(p.x0, y, p.x1, y, stroke='--wire', width=1)
        f.text(p.x0 - 8, y, lab, size=9.5, anchor='end', fill='--paper-dim')
    f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1.2)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    for i, ph in enumerate(t['phases']):
        f.text(p.sx(i), p.y1 + 14, ph, size=9.5, fill='--paper-dim')
    f.text(p.x0, p.y0 - 18, t['y'], size=10, anchor='start', weight='600')
    p.curve(lambda x: 2 * (x / 4) ** 1.6, 0, 4, stroke='--amber', width=2.2)
    p.curve(lambda x: math.log10(5) * (x / 4) ** 1.6, 0, 4, stroke='--phosphor', width=2.2)
    f.text(p.sx(0.15), p.sy(1.75), t['big'], size=9.5, anchor='start', fill='--amber', weight='600')
    f.text(p.sx(3.95), p.sy(0.13), t['small'], size=9.5, anchor='end', fill='--phosphor', weight='600')
    return f, t['cap']


@figure('l03-what-grows', 3)
def l03_what_grows(lang):
    t = {
        'en': dict(cols=['in the sentence', 'in review', 'in testing', 'after release'],
                   rows=['built on top', 'people who met it', 'context lost', 'steps to fix'],
                   cells=[['nothing', 'one line', 'a feature', 'the shop'],
                          ['the team', 'the team', 'the team', 'customers, Célia'],
                          ['none', 'none', 'some', 'most'],
                          ['a reply', 'an edit', 'report, fix, retest', 'all that, plus a release']],
                   label='A grid. Columns, left to right: found in the sentence, in review, in testing, after release. '
                         'Rows: what is built on top, who has met it, how much context is lost, how many steps the fix '
                         'needs. Built on top grows from nothing to one line, a feature and the whole shop. People who met '
                         'it stay the team until after release, when customers and Célia join. Context lost goes from none '
                         'to most. Steps to fix go from a reply to an edit, then report, fix and retest, then all that '
                         'plus a release. Cells shade darker to the right.',
                   cap='The four things that grow, for the sixty-year-old’s defect found at four moments. Every cell '
                       'in the right-hand column is a cost the fix itself does not show.'),
        'pt': dict(cols=['na frase', 'na revisão', 'no teste', 'depois da entrega'],
                   rows=['construído em cima', 'quem topou com ele', 'contexto perdido', 'passos da correção'],
                   cells=[['nada', 'uma linha', 'uma funcionalidade', 'a loja'],
                          ['o time', 'o time', 'o time', 'clientes, Célia'],
                          ['nenhum', 'nenhum', 'algum', 'quase todo'],
                          ['uma resposta', 'uma edição', 'relato, correção, reteste', 'tudo isso, mais uma entrega']],
                   label='Uma grade. Colunas, da esquerda para a direita: achado na frase, na revisão, no teste, depois '
                         'da entrega. Linhas: o que foi construído em cima, quem topou com ele, quanto contexto se perdeu, '
                         'quantos passos a correção exige. O construído em cima cresce de nada para uma linha, uma '
                         'funcionalidade e a loja inteira. Quem topou com ele continua sendo o time até depois da entrega, '
                         'quando clientes e a Célia entram. O contexto perdido vai de nenhum a quase todo. Os passos vão de '
                         'uma resposta a uma edição, depois relato, correção e reteste, depois tudo isso mais uma entrega. '
                         'As células escurecem para a direita.',
                   cap='As quatro coisas que crescem, para o defeito da pessoa de sessenta anos achado em quatro '
                       'momentos. Toda célula da coluna da direita é um custo que a correção em si não mostra.'),
    }[lang]
    f = Fig('l03-what-grows', 680, 250, t['label'])
    x0, y0, cw, rh = 130, 36, 136, 46
    fills = ['--ink', '--panel', '--scan', '--scan']
    for j, c in enumerate(t['cols']):
        f.text(x0 + j * cw + cw / 2, 22, c, size=10, weight='600')
    for i, r in enumerate(t['rows']):
        y = y0 + i * rh
        f.text(x0 - 10, y + rh / 2, r, size=10, anchor='end', weight='600')
        for j in range(4):
            x = x0 + j * cw
            f.rect(x + 2, y + 2, cw - 4, rh - 4, stroke='--amber' if j == 3 else '--wire',
                   fill=fills[j], width=1.4 if j == 3 else 1)
            f.text(x + cw / 2, y + rh / 2, t['cells'][i][j], size=9)
    return f, t['cap']
