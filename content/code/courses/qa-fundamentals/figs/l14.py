# lesson 14

@figure('l14-loops', 14)
def l14_loops(lang):
    t = {
        'en': dict(loops=[('release', 'months'), ('iteration', 'weeks'), ('customer tests', 'days'),
                          ('continuous integration', 'hours'), ('unit tests, test first', 'minutes'),
                          ('pair programming', 'seconds')],
                   catch=['the wrong thing built', 'a slip in one line'],
                   label='Six nested loops of feedback in Extreme Programming, from the outside in: release, months; '
                         'iteration, weeks; customer tests, days; continuous integration, hours; unit tests written '
                         'test first, minutes; pair programming, seconds. The outer loops catch the wrong thing being '
                         'built; the inner ones catch a slip in one line.',
                   cap='XP’s practices as loops of feedback. Each one is a way of finding out sooner, and each catches '
                       'a different size of mistake.'),
        'pt': dict(loops=[('entrega', 'meses'), ('iteração', 'semanas'), ('testes do cliente', 'dias'),
                          ('integração contínua', 'horas'), ('testes de unidade, antes do código', 'minutos'),
                          ('programação em par', 'segundos')],
                   catch=['construir a coisa errada', 'um deslize numa linha'],
                   label='Seis laços de feedback aninhados na Programação Extrema, de fora para dentro: entrega, '
                         'meses; iteração, semanas; testes do cliente, dias; integração contínua, horas; testes de '
                         'unidade escritos antes do código, minutos; programação em par, segundos. Os laços de fora '
                         'pegam a coisa errada sendo construída; os de dentro pegam um deslize numa linha.',
                   cap='As práticas do XP como laços de feedback. Cada uma é um jeito de descobrir mais cedo, e cada uma '
                       'pega um tamanho diferente de erro.'),
    }[lang]
    f = Fig('l14-loops', 680, 270, t['label'])
    strokes = ['--wire', '--wire', '--amber', '--phosphor', '--phosphor', '--phosphor']
    for i, (name, when) in enumerate(t['loops']):
        x, y = 10 + i * 46, 10 + i * 36
        w, h = 660 - i * 92, 216 - i * 36
        if i == 5:
            box(f, x, y, w, h, [name, when], size=9.5, weights=['600', None], fills=['--paper', '--paper-dim'],
                stroke=strokes[i], rx=12)
        else:
            f.rect(x, y, w, h, stroke=strokes[i], fill='--ink' if i % 2 == 0 else '--panel', rx=12)
            f.text(x + 12, y + 14, name, size=9.5, anchor='start', weight='600')
            f.text(x + w - 12, y + 14, when, size=9, anchor='end', fill='--paper-dim')
    f.text(14, 250, '← ' + t['catch'][0], size=9, anchor='start', fill='--amber')
    f.text(666, 250, t['catch'][1] + ' →', size=9, anchor='end', fill='--phosphor')
    return f, t['cap']


@figure('l14-train', 14)
def l14_train(lang):
    t = {
        'en': dict(train='an Agile Release Train: 50 to 125 people', teams=['prices', 'seats', 'website',
                                                                            'box office', 'reports'],
                   system='System Team: shared environment, end-to-end checks',
                   pi='one Planning Interval, 8 to 12 weeks', planning='PI Planning', its=['iteration 1', 'iteration 2',
                                                                                          'iteration 3', 'iteration 4'],
                   ip='innovation and planning', demo='System Demo',
                   label='Above, an Agile Release Train of five teams, prices, seats, website, box office and reports, '
                         'with a System Team under them that runs the shared environment and the end-to-end checks. '
                         'Below, one Planning Interval of eight to twelve weeks: PI Planning at the start, four '
                         'iterations each ending in a System Demo, and an innovation and planning iteration at the end.',
                   cap='Many teams, one schedule. The System Demo shows the integrated product every iteration, not each '
                       'team’s piece.'),
        'pt': dict(train='um Agile Release Train: de 50 a 125 pessoas', teams=['preços', 'assentos', 'site',
                                                                               'bilheteria', 'relatórios'],
                   system='System Team: ambiente compartilhado, verificações de ponta a ponta',
                   pi='um Planning Interval, de 8 a 12 semanas', planning='PI Planning',
                   its=['iteração 1', 'iteração 2', 'iteração 3', 'iteração 4'],
                   ip='inovação e planejamento', demo='System Demo',
                   label='Em cima, um Agile Release Train de cinco times, preços, assentos, site, bilheteria e '
                         'relatórios, com um System Team embaixo deles que cuida do ambiente compartilhado e das '
                         'verificações de ponta a ponta. Embaixo, um Planning Interval de oito a doze semanas: PI '
                         'Planning no começo, quatro iterações terminando cada uma num System Demo, e uma iteração de '
                         'inovação e planejamento no fim.',
                   cap='Muitos times, uma agenda só. O System Demo mostra o produto integrado a cada iteração, e não o '
                       'pedaço de cada time.'),
    }[lang]
    f = Fig('l14-train', 680, 260, t['label'])
    f.rect(10, 10, 660, 112, stroke='--phosphor', fill='--ink', rx=8, dash='4 3')
    f.text(24, 26, t['train'], size=10, anchor='start', weight='600', fill='--phosphor')
    for i, name in enumerate(t['teams']):
        box(f, 24 + i * 128, 40, 118, 32, [name], size=9.5)
    box(f, 24, 80, 630, 30, [t['system']], size=9.5, stroke='--amber', fills=['--amber'], weights=['600'])
    f.text(340, 144, t['pi'], size=10, weight='600')
    box(f, 10, 160, 86, 40, [t['planning']], size=9, weights=['600'], stroke='--phosphor')
    for i, it in enumerate(t['its']):
        x = 104 + i * 112
        box(f, x, 160, 104, 40, [it], size=9)
        f.circle(x + 104, 214, 4, fill='--amber')
    box(f, 552, 160, 118, 40, [t['ip']], size=8.5, dash='3 2')
    f.text(330, 234, '● ' + t['demo'], size=9, fill='--amber')
    return f, t['cap']
