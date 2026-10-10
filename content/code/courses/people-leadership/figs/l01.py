"""Lesson 1: the loops get longer."""
import math

from figures import Fig, T, figure


@figure('l01-loops', 1)
def loops():
    f = Fig('l01-loops', 720, 300, T(
        'A logarithmic time axis from one second to one year, with six loops placed on it. A test '
        'run answers in about ten seconds and a code review in about four hours: the engineer’s '
        'loops, on the left. A deploy shows how users react in about two days. A piece of feedback '
        'shows whether behaviour changed in about three weeks. A hire shows whether it was right in '
        'about six months, and a promotion case is decided at the next cycle, also about six months '
        'away: the manager’s loops, on the right.',
        'Um eixo de tempo logarítmico de um segundo a um ano, com seis ciclos marcados. Um teste '
        'responde em uns dez segundos e uma revisão de código em umas quatro horas: os ciclos de '
        'quem programa, à esquerda. Um deploy mostra como os usuários reagem em uns dois dias. Um '
        'feedback mostra se o comportamento mudou em umas três semanas. Uma contratação mostra se '
        'deu certo em uns seis meses, e um caso de promoção é decidido no próximo ciclo, também a '
        'uns seis meses: os ciclos de quem gerencia, à direita.'))
    x0, x1 = 60, 680
    lo, hi = 0, math.log10(365 * 86400)

    def X(seconds):
        return x0 + (math.log10(seconds) - lo) / (hi - lo) * (x1 - x0)

    y = 200
    f.line(x0, y, x1, y, stroke='--paper-dim', width=1.4)
    for s, lab in [(1, T('1 second', '1 segundo')), (60, T('1 minute', '1 minuto')),
                   (3600, T('1 hour', '1 hora')), (86400, T('1 day', '1 dia')),
                   (7 * 86400, T('1 week', '1 semana')), (30 * 86400, T('1 month', '1 mês')),
                   (365 * 86400, T('1 year', '1 ano'))]:
        f.line(X(s), y - 5, X(s), y + 5, stroke='--paper-dim', width=1.2)
        f.text(X(s), y + 20, lab, size=10, fill='--paper-dim')
    pts = [
        (10, T('a test run', 'um teste'), 60, '--phosphor'),
        (4 * 3600, T('a code review', 'uma revisão'), 60, '--phosphor'),
        (2 * 86400, T('a deploy, as', 'um deploy, pelo'), 130, '--paper'),
        (21 * 86400, T('feedback', 'um feedback'), 95, '--amber'),
        (182 * 86400, T('a hire', 'uma contratação'), 60, '--amber'),
        (182 * 86400, T('a promotion case', 'um caso de promoção'), 76, None),
    ]
    for s, lab, h, col in pts:
        if col:
            f.line(X(s), y - 8, X(s), y - h + (24 if h == 130 else 10), stroke=col, width=1.4)
            f.circle(X(s), y, 5, fill=col)
        f.text(X(s), y - h, lab, size=10.5, fill='--paper', weight='600')
    f.text(X(2 * 86400), y - 130 + 14, T('users react', 'que os usuários fazem'), size=10.5,
           fill='--paper', weight='600')
    f.rect(x0, 252, X(86400) - x0, 26, stroke='--phosphor', fill='--panel', rx=3)
    f.text((x0 + X(86400)) / 2, 265, T('where an engineer learns', 'onde quem programa aprende'),
           size=10, fill='--paper')
    f.rect(X(7 * 86400), 252, x1 - X(7 * 86400), 26, stroke='--amber', fill='--panel', rx=3)
    f.text((X(7 * 86400) + x1) / 2, 265, T('where a manager learns', 'onde quem gerencia aprende'),
           size=10, fill='--paper')
    f.text(x0, 30, T('how long until the world tells you whether you were right',
                     'quanto tempo até o mundo dizer se você acertou'),
           size=11.5, anchor='start', fill='--paper', weight='600')
    return f, T('Orders of magnitude, not measurements. The loops a manager learns from are slower than an engineer’s by a factor of about a million.',
                'Ordens de grandeza, não medidas. Os ciclos com que quem gerencia aprende são mais lentos que os de quem programa por um fator de cerca de um milhão.')
