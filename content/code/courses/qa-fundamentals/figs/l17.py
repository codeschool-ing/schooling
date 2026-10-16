# lesson 17

@figure('l17-loops', 17)
def l17_loops(lang):
    t = {
        'en': dict(outer='outer loop: the story', inner='inner loop: TDD, many times',
                   a=['acceptance test', 'agreed, fails'], b=['acceptance test', 'passes: done'],
                   tdd=['red', 'green', 'refactor'],
                   label='Two loops. The outer loop is the story: it starts with an acceptance test that the team agreed '
                         'and that fails, and ends when the acceptance test passes and the story is done. Inside it, '
                         'the inner loop is TDD, red, green, refactor, run many times to build the parts.',
                   cap='ATDD around TDD. The outer test is agreed with the product owner; the inner ones are the '
                       'developer’s.'),
        'pt': dict(outer='laço de fora: a história', inner='laço de dentro: TDD, muitas vezes',
                   a=['teste de aceitação', 'combinado, falha'], b=['teste de aceitação', 'passa: pronto'],
                   tdd=['vermelho', 'verde', 'refatorar'],
                   label='Dois laços. O laço de fora é a história: começa com um teste de aceitação que o time combinou '
                         'e que falha, e termina quando o teste de aceitação passa e a história fica pronta. Dentro '
                         'dele, o laço de dentro é o TDD, vermelho, verde, refatorar, rodado muitas vezes para construir '
                         'as partes.',
                   cap='ATDD em volta do TDD. O teste de fora é combinado com a dona do produto; os de dentro são de '
                       'quem desenvolve.'),
    }[lang]
    f = Fig('l17-loops', 660, 220, t['label'])
    f.rect(10, 10, 640, 200, stroke='--amber', fill='--ink', rx=10, dash='5 3')
    f.text(24, 28, t['outer'], size=10, anchor='start', weight='600', fill='--amber')
    box(f, 24, 80, 130, 50, t['a'], size=9.5, weights=['600', None], stroke='--amber', fills=['--paper', '--amber'])
    box(f, 506, 80, 130, 50, t['b'], size=9.5, weights=['600', None], stroke='--phosphor', fills=['--paper', '--phosphor'])
    f.rect(180, 48, 300, 140, stroke='--phosphor', fill='--panel', rx=10)
    f.text(330, 64, t['inner'], size=9.5, weight='600', fill='--phosphor')
    for i, s in enumerate(t['tdd']):
        box(f, 196 + i * 94, 110, 80, 32, [s], size=9.5, fill='--ink')
        if i < 2:
            arrow(f, 277 + i * 94, 126, 289 + i * 94, 126)
    f.path('M440 144 C 440 175, 236 175, 236 146', stroke='--paper-dim', width=1.2, arrow=True)
    arrow(f, 156, 105, 178, 105)
    arrow(f, 482, 105, 504, 105)
    return f, t['cap']


@figure('l17-map', 17)
def l17_map(lang):
    t = {
        'en': dict(story='older customers and students pay half, without stacking with Wednesday',
                   rules=[('60 and over pay half', ['59 pays R$ 36,00', '60 pays R$ 18,00', '61 pays R$ 18,00']),
                          ('half is the most', ['adult, Wed: R$ 18,00', 'student, Wed: R$ 18,00',
                                                 'child, Wed 15:00: R$ 14,00'])],
                   q='is a session ever typed as 9:30?', who='Lia asks Célia',
                   keys=['story: a yellow card', 'rule: blue', 'example: green', 'question: red'],
                   label='An example map. At the top, the story card: older customers and students pay half, without '
                         'stacking with Wednesday. Two rule cards under it. Rule one, 60 and over pay half, with three '
                         'examples: 59 pays R$ 36,00, 60 pays R$ 18,00, 61 pays R$ 18,00. Rule two, half is the most, '
                         'with three examples: an adult on Wednesday pays R$ 18,00, a student on Wednesday R$ 18,00, a '
                         'child at a Wednesday 15:00 session R$ 14,00. To the right, one question card: is a session '
                         'ever typed as 9:30? Lia asks Célia.',
                   cap='Cine Aurora’s map for one story. The six examples are its acceptance tests; the question has an '
                       'owner and no answer yet.'),
        'pt': dict(story='idosos e estudantes pagam meia, sem somar com a quarta',
                   rules=[('60 ou mais pagam meia', ['59 paga R$ 36,00', '60 paga R$ 18,00', '61 paga R$ 18,00']),
                          ('meia é o máximo', ['adulto, qua: R$ 18,00', 'estudante, qua: R$ 18,00',
                                               'criança, qua 15:00: R$ 14,00'])],
                   q='alguém digita uma sessão como 9:30?', who='a Lia pergunta à Célia',
                   keys=['história: cartão amarelo', 'regra: azul', 'exemplo: verde', 'pergunta: vermelho'],
                   label='Um mapa de exemplos. No topo, o cartão da história: idosos e estudantes pagam meia, sem somar '
                         'com a quarta. Dois cartões de regra embaixo. Regra um, 60 ou mais pagam meia, com três '
                         'exemplos: 59 paga R$ 36,00, 60 paga R$ 18,00, 61 paga R$ 18,00. Regra dois, meia é o máximo, '
                         'com três exemplos: um adulto na quarta paga R$ 18,00, um estudante na quarta R$ 18,00, uma '
                         'criança numa sessão de quarta às 15:00 R$ 14,00. À direita, um cartão de pergunta: alguém '
                         'digita uma sessão como 9:30? A Lia pergunta à Célia.',
                   cap='O mapa do Cine Aurora para uma história. Os seis exemplos são os testes de aceitação dela; a '
                       'pergunta tem dono e ainda não tem resposta.'),
    }[lang]
    f = Fig('l17-map', 680, 300, t['label'])
    box(f, 10, 10, 470, 36, [t['story']], size=9.5, weights=['600'], stroke='--amber', fill='--ink')
    for i, (rule, exs) in enumerate(t['rules']):
        x = 10 + i * 240
        box(f, x, 62, 230, 34, [rule], size=9.5, weights=['600'], stroke='--phosphor', fills=['--phosphor'])
        for k, e in enumerate(exs):
            box(f, x + 10, 106 + k * 42, 210, 34, [e], size=9)
    box(f, 500, 62, 170, 70, [t['q'], t['who']], size=9, stroke='--amber', dash='4 3',
        fills=['--amber', '--paper-dim'], weights=['600', None])
    strokes = ['--amber', '--phosphor', '--wire', '--amber']
    for i, (k, st) in enumerate(zip(t['keys'], strokes)):
        y = 200 + i * 22
        f.rect(504, y - 7, 18, 14, stroke=st, fill='--panel', rx=2, dash='3 2' if i == 3 else None)
        f.text(530, y, k, size=9, anchor='start', fill='--paper-dim')
    return f, t['cap']
