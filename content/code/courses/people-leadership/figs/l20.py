"""Lesson 20: the shape of an improvement plan."""
from figures import Fig, T, figure


@figure('l20-plan', 20)
def plan():
    f = Fig('l20-plan', 720, 280, T(
        'A timeline of six weeks. At week zero, the written plan: the gap, the expectation, the support, '
        'the check-ins and the consequences. Every week, a check-in with a written summary the person '
        'can correct. Pairing on estimates in the first three weeks. At the end, three possible '
        'outcomes: met, and the plan closes; partly met, and one extension is possible if there is a '
        'specific reason; not met, and a decision about the employment follows.',
        'Uma linha do tempo de seis semanas. Na semana zero, o plano escrito: a lacuna, a expectativa, o '
        'apoio, os acompanhamentos e as consequências. Toda semana, um acompanhamento com um resumo '
        'escrito que a pessoa pode corrigir. Pareamento nas estimativas nas três primeiras semanas. No '
        'fim, três desfechos possíveis: cumprido, e o plano fecha; cumprido em parte, e uma prorrogação '
        'é possível se houver um motivo específico; não cumprido, e segue uma decisão sobre o vínculo.'))
    x0, x1, y = 70, 470, 120
    f.line(x0, y, x1, y, stroke='--paper-dim', width=1.6)
    f.rect(x0 - 50, y - 70, 100, 44, stroke='--phosphor', fill='--panel', rx=4)
    f.lines(x0, y - 48, [T('the written', 'o plano'), T('plan', 'escrito')], size=11, weight='600')
    f.line(x0, y - 26, x0, y - 6, stroke='--phosphor', width=1.4)
    for w in range(7):
        x = x0 + w * (x1 - x0) / 6
        f.circle(x, y, 6 if w else 7, fill='--phosphor' if w == 0 else '--paper-dim')
        f.text(x, y + 22, T(f'week {w}', f'sem. {w}'), size=10, fill='--paper-dim')
        if w:
            f.line(x, y - 6, x, y - 20, stroke='--paper-dim', width=1)
    f.text((x0 + x1) / 2 + 35, y - 32, T('weekly check-in, written summary', 'acompanhamento semanal, resumo escrito'),
           size=10.5)
    f.rect(x0 + (x1 - x0) / 6 - 6, y + 38, (x1 - x0) / 2 + 12, 22, stroke='--amber', fill='--panel', rx=3)
    f.text(x0 + (x1 - x0) / 6 + (x1 - x0) / 4, y + 49, T('pairing on estimates', 'pareamento nas estimativas'),
           size=10)
    outs = [(T('met', 'cumprido'), T('the plan closes', 'o plano fecha'), '--phosphor', 40),
            (T('partly met', 'em parte'), T('one extension, with a reason', 'uma prorrogação, com motivo'), '--paper-dim', 120),
            (T('not met', 'não cumprido'), T('a decision follows', 'segue uma decisão'), '--amber', 200)]
    for name, sub, col, oy in outs:
        f.arrow([(x1 + 8, y), (530, oy + 20)], stroke='--paper-dim')
        f.rect(535, oy, 165, 42, stroke=col, fill='--panel', width=1.5, rx=4)
        f.text(617, oy + 14, name, size=11.5, weight='600')
        f.text(617, oy + 30, sub, size=10)
    return f, T('Two honest outcomes, and a third that is honest only once and only with a reason.',
                'Dois desfechos honestos, e um terceiro que só é honesto uma vez e com um motivo.')
