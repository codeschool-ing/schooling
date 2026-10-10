"""Lesson 15: an anchored scale."""
from figures import Fig, T, figure


@figure('l15-scale', 15)
def scale():
    f = Fig('l15-scale', 720, 250, T(
        'A four-step scale for the question about explaining a trade-off. Each step adds one '
        'observable thing to the one before. Step 1: no real example, or technical terms. Step 2: '
        'a real example. Step 3: explained in the listener’s terms, with the trade-off as a choice '
        'between outcomes. Step 4: adapted when not understood, and knows what was decided.',
        'Uma escala de quatro degraus para a pergunta sobre explicar um trade-off. Cada degrau '
        'acrescenta uma coisa observável à anterior. Degrau 1: sem exemplo real, ou em termos '
        'técnicos. Degrau 2: um exemplo real. Degrau 3: explicado nos termos de quem ouve, com o '
        'trade-off como escolha entre resultados. Degrau 4: adaptou quando não foi entendido, e sabe '
        'o que foi decidido.'))
    steps = [('1', [T('no real example,', 'sem exemplo real,'), T('or technical terms', 'ou em termos técnicos')]),
             ('2', [T('+ a real example', '+ um exemplo real')]),
             ('3', [T('+ in the listener’s terms,', '+ nos termos de quem ouve,'),
                    T('trade-off as outcomes', 'trade-off como resultados')]),
             ('4', [T('+ adapted when not followed,', '+ adaptou se não entenderam,'),
                    T('knows what was decided', 'sabe o que foi decidido')])]
    for i, (n, lines) in enumerate(steps):
        x = 30 + i * 170
        y = 170 - i * 35
        h = 60 + i * 35
        col = '--phosphor' if i >= 2 else '--paper-dim'
        f.rect(x, y, 158, h, stroke=col, fill='--panel', width=1.5, rx=4)
        f.text(x + 18, y + 18, n, size=15, weight='600', fill=col if col != '--paper-dim' else '--paper')
        f.lines(x + 79, y + 44, lines, size=10.5, gap=15)
    f.text(30, 24, T('each step adds one thing an interviewer can observe',
                     'cada degrau acrescenta uma coisa que quem entrevista consegue observar'),
           size=11, anchor='start', fill='--paper-dim', italic=True)
    return f, T('Two interviewers hearing the same answer should land on the same step, or one apart.',
                'Duas pessoas ouvindo a mesma resposta deveriam chegar ao mesmo degrau, ou a um de distância.')
