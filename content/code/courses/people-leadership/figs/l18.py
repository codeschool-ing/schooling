"""Lesson 18: the first on-call shift, in three steps."""
from figures import Fig, T, figure


@figure('l18-oncall', 18)
def oncall():
    f = Fig('l18-oncall', 720, 270, T(
        'Three steps from left to right. Shadow: the new person is paged but the experienced '
        'engineer acts; Lucas with Yara in month two. Reverse shadow: the new person acts and the '
        'experienced engineer watches, ready to step in; Lucas with Yara in month three. Primary with '
        'a named backup: the new person is on call alone, with somebody who has agreed to answer at '
        'any hour; Lucas, with Diego as backup, after ninety days.',
        'Três degraus da esquerda para a direita. Sombra: a pessoa nova é acionada, mas quem tem '
        'experiência age; o Lucas com a Yara no segundo mês. Sombra invertida: a pessoa nova age e quem '
        'tem experiência observa, pronta para entrar; o Lucas com a Yara no terceiro mês. Titular com '
        'apoio nomeado: a pessoa nova fica de plantão sozinha, com alguém que aceitou atender a '
        'qualquer hora; o Lucas, com o Diego de apoio, depois dos noventa dias.'))
    steps = [
        (T('shadow', 'sombra'), [T('paged, watches;', 'é acionado, observa;'),
                                 T('Yara acts', 'a Yara age')], T('month 2', 'mês 2')),
        (T('reverse shadow', 'sombra invertida'), [T('acts; Yara watches,', 'age; a Yara observa,'),
                                                   T('ready to step in', 'pronta para entrar')],
         T('month 3', 'mês 3')),
        (T('primary, with backup', 'titular, com apoio'), [T('alone, Diego answers', 'sozinho, o Diego'),
                                                           T('at any hour', 'atende a qualquer hora')],
         T('after 90 days', 'depois de 90 dias')),
    ]
    for i, (name, lines, when) in enumerate(steps):
        x = 30 + i * 230
        y = 130 - i * 40
        f.rect(x, y, 200, 255 - y, stroke='--phosphor' if i == 2 else '--paper-dim', fill='--panel',
               width=1.5, rx=5)
        f.text(x + 100, y + 22, name, size=12.5, weight='600')
        f.lines(x + 100, y + 54, lines, size=11, gap=16)
        f.text(x + 100, 242, when, size=10.5, fill='--paper-dim', italic=True)
        if i < 2:
            f.arrow([(x + 204, y + 30), (x + 226, y - 10)], stroke='--paper-dim')
    f.text(30, 24, T('Lucas, never alone until each step was done with somebody',
                     'o Lucas, nunca sozinho até cada degrau ter sido feito com alguém'),
           size=11, anchor='start', fill='--paper-dim', italic=True)
    return f, T('The first primary week comes after the shadow and the reverse shadow, not instead of them.',
                'A primeira semana como titular vem depois da sombra e da sombra invertida, e não no lugar delas.')
