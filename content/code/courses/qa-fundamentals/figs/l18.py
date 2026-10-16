# lesson 18

@figure('l18-whys', 18)
def l18_whys(lang):
    t = {
        'en': dict(problem='9:30 session charged the evening price',
                   whys=['"9:30" compared with "17:00" as text', 'assumed a two-digit hour',
                         'every example had two digits', 'nobody asked Célia how she types times',
                         'planning never asks where an input comes from'],
                   act='action: planning asks where each input comes from',
                   label='The five whys as a chain going down. The problem: the 9:30 session was charged the evening '
                         'price. Why one: 9:30 was compared with 17:00 as text. Why two: Rafael assumed a two-digit '
                         'hour. Why three: every example had two digits. Why four: nobody asked Célia how she types '
                         'times. Why five: planning never asks where an input comes from. The action: planning asks '
                         'where each input comes from.',
                   cap='Each answer becomes the next question. The chain stops at a cause the team can change, and that '
                       'would prevent more than this one defect.'),
        'pt': dict(problem='sessão das 9:30 cobrada pelo preço da noite',
                   whys=['"9:30" comparado com "17:00" como texto', 'supôs uma hora de dois dígitos',
                         'todo exemplo tinha dois dígitos', 'ninguém perguntou à Célia como ela digita',
                         'o planejamento não pergunta de onde vem cada entrada'],
                   act='ação: o planejamento pergunta de onde vem cada entrada',
                   label='Os cinco porquês como uma cadeia descendo. O problema: a sessão das 9:30 foi cobrada pelo '
                         'preço da noite. Porquê um: 9:30 foi comparado com 17:00 como texto. Porquê dois: o Rafael supôs '
                         'uma hora de dois dígitos. Porquê três: todo exemplo tinha dois dígitos. Porquê quatro: ninguém '
                         'perguntou à Célia como ela digita os horários. Porquê cinco: o planejamento não pergunta de '
                         'onde vem cada entrada. A ação: o planejamento pergunta de onde vem cada entrada.',
                   cap='Cada resposta vira a próxima pergunta. A cadeia para numa causa que o time pode mudar, e que '
                       'preveniria mais do que este defeito.'),
    }[lang]
    f = Fig('l18-whys', 620, 330, t['label'])
    box(f, 150, 8, 320, 30, [t['problem']], size=9.5, weights=['600'], stroke='--amber', fills=['--amber'])
    for i, w in enumerate(t['whys']):
        y = 52 + i * 46
        f.text(140, y + 14, f'{"why" if lang == "en" else "por quê"} {i + 1}', size=9, anchor='end', fill='--paper-dim')
        box(f, 150, y, 320, 30, [w], size=9.5, fill='--panel')
        arrow(f, 310, y - 13, 310, y - 1)
    box(f, 110, 292, 400, 30, [t['act']], size=9.5, weights=['600'], stroke='--phosphor', fills=['--phosphor'])
    arrow(f, 310, 277, 310, 291)
    return f, t['cap']


@figure('l18-fishbone', 18)
def l18_fishbone(lang):
    t = {
        'en': dict(head=['student pays', 'R$ 9,00 on a', 'Wednesday'],
                   bones=[('requirements', ['no sentence on combining']), ('process', ['no combination cases',
                                                                                        'review alone, a day late']),
                          ('people', ['new to pricing']), ('tools', ['no automated price checks']),
                          ('environment', ['test sessions on Thursdays']), ('measurement', ['report hides discounts'])],
                   label='An Ishikawa diagram. At the head, on the right: a student pays R$ 9,00 on a Wednesday. Six bones '
                         'join the spine. Requirements: no sentence on combining. Process: no combination cases, and a '
                         'review alone, a day late. People: new to pricing. Tools: no automated price checks. '
                         'Environment: test sessions on Thursdays. Measurement: the report hides discounts.',
                   cap='Six categories, several causes, one defect. Removing any one of them would have stopped it '
                       'earlier.'),
        'pt': dict(head=['estudante paga', 'R$ 9,00 numa', 'quarta'],
                   bones=[('requisitos', ['nada sobre combinar']), ('processo', ['sem casos de combinação',
                                                                                  'revisão sozinha, um dia depois']),
                          ('pessoas', ['novo em preços']), ('ferramentas', ['sem verificação automática']),
                          ('ambiente', ['sessões de teste às quintas']), ('medição', ['relatório esconde descontos'])],
                   label='Um diagrama de Ishikawa. Na cabeça, à direita: um estudante paga R$ 9,00 numa quarta. Seis '
                         'espinhas ligam-se à coluna. Requisitos: nada sobre combinar descontos. Processo: sem casos de '
                         'combinação, e revisão sozinha, um dia depois. Pessoas: novo em preços. Ferramentas: sem '
                         'verificação automática de preços. Ambiente: sessões de teste às quintas. Medição: o relatório '
                         'esconde descontos.',
                   cap='Seis categorias, várias causas, um defeito. Tirar qualquer uma delas o teria parado mais cedo.'),
    }[lang]
    f = Fig('l18-fishbone', 680, 300, t['label'])
    f.line(20, 150, 540, 150, stroke='--paper', width=2)
    box(f, 545, 112, 125, 76, t['head'], size=10, weights=['600', '600', '600'], stroke='--amber',
        fills=['--amber', '--amber', '--amber'])
    xs = [215, 370, 520]
    for i, (name, causes) in enumerate(t['bones']):
        top = i < 3
        x = xs[i % 3]
        y0 = 40 if top else 260
        f.line(x - 60, y0, x, 150, stroke='--wire', width=1.6)
        f.text(x - 60, y0 + (-14 if top else 16), name, size=10, weight='600', fill='--phosphor')
        for k, c in enumerate(causes):
            yy = (70 + k * 34) if top else (230 - k * 34)
            f.text(x - 56 + (yy - y0) * 60 / (150 - y0) - 4, yy, c, size=9, anchor='end', fill='--paper')
    return f, t['cap']
