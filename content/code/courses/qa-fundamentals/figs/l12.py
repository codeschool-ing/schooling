# lesson 12

@figure('l12-sprint', 12)
def l12_sprint(lang):
    t = {
        'en': dict(backlog='product backlog', planning='sprint planning', sb='sprint backlog',
                   daily='daily scrum, every day', review='sprint review', retro='retrospective', inc='increment',
                   sprint='the sprint: two weeks', tests=['questions, how to test', 'what waits for testing',
                                                          'Célia tries it', 'why was it possible?'],
                   dod=['meets the definition', 'of done'],
                   label='The Scrum cycle. The product backlog feeds sprint planning, which produces the sprint backlog. '
                         'Inside a two-week sprint, the daily scrum happens every day. The sprint ends with the sprint '
                         'review, then the retrospective, and produces an increment that meets the definition of done. '
                         'Under each event, the tester’s contribution: at planning, questions and how to test; at the '
                         'daily scrum, what waits for testing; at the review, Célia tries it; at the retrospective, why '
                         'was it possible.',
                   cap='The events of a sprint, with what testing brings to each. The increment only counts if it meets '
                       'the definition of done.'),
        'pt': dict(backlog='backlog do produto', planning='planejamento da sprint', sb='backlog da sprint',
                   daily='daily, todo dia', review='revisão da sprint', retro='retrospectiva', inc='incremento',
                   sprint='a sprint: duas semanas', tests=['perguntas, como testar', 'o que espera teste',
                                                           'a Célia experimenta', 'por que foi possível?'],
                   dod=['cumpre a definição', 'de pronto'],
                   label='O ciclo do Scrum. O backlog do produto alimenta o planejamento da sprint, que produz o backlog da '
                         'sprint. Dentro de uma sprint de duas semanas, a daily acontece todo dia. A sprint termina com a '
                         'revisão da sprint, depois a retrospectiva, e produz um incremento que cumpre a definição de '
                         'pronto. Sob cada evento, a contribuição de quem testa: no planejamento, perguntas e como testar; '
                         'na daily, o que espera teste; na revisão, a Célia experimenta; na retrospectiva, por que foi '
                         'possível.',
                   cap='Os eventos de uma sprint, com o que o teste traz a cada um. O incremento só conta se cumprir a '
                       'definição de pronto.'),
    }[lang]
    f = Fig('l12-sprint', 680, 205, t['label'])
    box(f, 10, 50, 110, 40, [t['backlog']], size=9.5)
    arrow(f, 121, 70, 139, 70)
    box(f, 140, 50, 110, 40, [t['planning']], size=9.5, weights=['600'])
    f.rect(270, 30, 270, 160, stroke='--phosphor', fill='--ink', rx=8, dash='4 3')
    f.text(405, 46, t['sprint'], size=9.5, fill='--phosphor', weight='600')
    arrow(f, 251, 70, 285, 70)
    box(f, 286, 56, 100, 32, [t['sb']], size=9)
    box(f, 400, 56, 126, 32, [t['daily']], size=9, weights=['600'])
    box(f, 286, 120, 110, 36, [t['review']], size=9.5, weights=['600'])
    box(f, 410, 120, 116, 36, [t['retro']], size=9.5, weights=['600'])
    arrow(f, 397, 138, 409, 138)
    arrow(f, 541, 138, 555, 138)
    box(f, 556, 108, 116, 60, [t['inc'], t['dod'][0], t['dod'][1]], stroke='--amber', size=9,
        weights=['600', None, None], fills=['--paper', '--amber', '--amber'])
    for (x, y), s in zip([(195, 108), (463, 104), (341, 172), (468, 172)], t['tests']):
        f.text(x, y, s, size=9, fill='--paper-dim', anchor='middle')
    return f, t['cap']


@figure('l12-done', 12)
def l12_done(lang):
    t = {
        'en': dict(dod='definition of done: every story', items=['reviewed', 'criteria tested', 'old checks pass',
                                                                 'explored', 'answers written', 'releasable'],
                   stories=['students pay half', 'older customers pay half', 'coupons'],
                   ac='acceptance criteria: this story only',
                   label='A large frame labelled definition of done, every story, lists six conditions: reviewed, criteria '
                         'tested, old checks pass, explored, answers written, releasable. Inside it sit three stories: '
                         'students pay half, older customers pay half, coupons. Each story carries its own small box of '
                         'acceptance criteria, for that story only.',
                   cap='The definition of done is one bar for every story; acceptance criteria are what one story has to '
                       'do. A story meets both, or it is not done.'),
        'pt': dict(dod='definição de pronto: toda história', items=['revisada', 'critérios testados', 'conferências antigas passam',
                                                                    'explorada', 'respostas escritas', 'entregável'],
                   stories=['estudantes pagam meia', 'idosos pagam meia', 'cupons'],
                   ac='critérios de aceitação: só desta história',
                   label='Uma moldura grande chamada definição de pronto, toda história, lista seis condições: revisada, '
                         'critérios testados, conferências antigas passam, explorada, respostas escritas, entregável. Dentro '
                         'dela estão três histórias: estudantes pagam meia, idosos pagam meia, cupons. Cada história leva a '
                         'sua própria caixinha de critérios de aceitação, só daquela história.',
                   cap='A definição de pronto é uma régua só para toda história; os critérios de aceitação são o que uma '
                       'história precisa fazer. Uma história cumpre os dois, ou não está pronta.'),
    }[lang]
    f = Fig('l12-done', 660, 250, t['label'])
    f.rect(10, 10, 640, 230, stroke='--phosphor', fill='--ink', rx=8, width=1.6)
    f.text(24, 30, t['dod'], size=10.5, anchor='start', weight='600', fill='--phosphor')
    for i, it in enumerate(t['items']):
        f.text(24 + (i % 3) * 210, 50 + (i // 3) * 14, '✓ ' + it, size=9, anchor='start', fill='--paper-dim')
    for j, s in enumerate(t['stories']):
        x = 30 + j * 205
        box(f, x, 80, 185, 44, [s], size=10, weights=['600'])
        f.rect(x + 12, 132, 161, 70, stroke='--amber', fill='--panel', rx=4, dash='3 2')
        for k in range(3):
            f.line(x + 24, 150 + k * 16, x + 160, 150 + k * 16, stroke='--wire', width=1)
    f.text(330, 222, t['ac'], size=9.5, fill='--amber')
    return f, t['cap']
