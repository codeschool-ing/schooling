"""Lesson 17: patching."""
from figures import Fig, T, figure


@figure('l17-timeline', 17)
def timeline():
    f = Fig('l17-timeline', 720, 240, T(
        'A timeline of one update over thirty days. Day 0, the fix is published and enters the firm\'s '
        'repository. Day 1, ring one, the first few machines, gets it. Day 8, after a week without '
        'trouble, ring two, everything else, gets it in the Tuesday maintenance window. Day 30 is the '
        'due date from the vulnerability policy, with time to spare. A dashed line marks the faster '
        'path for a flaw being exploited: both rings within the seven days of a P1.',
        'Uma linha do tempo de uma atualização em trinta dias. Dia 0, a correção é publicada e entra no '
        'repositório do escritório. Dia 1, o anel um, as primeiras poucas máquinas, recebe. Dia 8, '
        'depois de uma semana sem problema, o anel dois, todo o resto, recebe na janela de manutenção de '
        'terça. O dia 30 é a data limite da política de vulnerabilidades, com folga. Uma linha tracejada '
        'marca o caminho mais rápido para uma falha sendo explorada: os dois anéis dentro dos sete dias '
        'de um P1.'))
    x0, x1, y = 60, 680, 120
    X = lambda d: x0 + d / 30 * (x1 - x0)
    f.line(x0, y, x1, y, stroke='--wire', width=1.5)
    for d in (0, 7, 14, 21, 30):
        f.line(X(d), y - 4, X(d), y + 4, stroke='--wire', width=1.2)
        f.text(X(d), y + 18, T(f'day {d}', f'dia {d}'), size=9.5, fill='--paper-dim')
    marks = [(0, T('fix published,', 'correção publicada,'), T('in the repository', 'no repositório'), '--paper'),
             (1, T('ring one', 'anel um'), T('a few machines', 'poucas máquinas'), '--phosphor'),
             (8, T('ring two, Tuesday', 'anel dois, terça'), T('window, everything else', 'janela, todo o resto'), '--phosphor'),
             (30, T('due date', 'data limite'), T('P2 policy', 'política P2'), '--amber')]
    for i, (d, a, b, c) in enumerate(marks):
        f.circle(X(d), y, 5, fill=c)
        ty = (36, 84, 36, 60)[i]
        anchor = 'end' if d == 30 else 'start'
        dx = -6 if d == 30 else 6
        f.line(X(d), y - 6, X(d), ty + 14, stroke=c, width=1)
        f.text(X(d) + dx, ty - 6, a, size=10, anchor=anchor, fill=c)
        f.text(X(d) + dx, ty + 8, b, size=9.5, anchor=anchor, fill='--paper-dim')
    f.path(f'M{X(0):.1f} 175 L{X(7):.1f} 175', stroke='--amber', width=1.4, dash='5 3', arrow=True)
    f.text(X(7) + 8, 175, T('exploited flaw (P1): both rings inside seven days',
                            'falha explorada (P1): os dois anéis dentro de sete dias'), size=9.5, anchor='start',
           fill='--amber')
    return f, T('The rings fit inside the deadline. For an exploited flaw they shrink to hours, not to nothing.',
                'Os anéis cabem dentro do prazo. Para uma falha explorada, encolhem para horas, não para nada.')


@figure('l17-rings', 17)
def rings():
    f = Fig('l17-rings', 720, 260, T(
        'Three nested rings. The innermost, ring one, holds desk and the IT team\'s own machines: failure '
        'is cheap and noticed quickly. The middle ring holds the ordinary workstations. The outer ring '
        'holds web, the portal, which the firm cannot afford to lose. An update moves outwards, one ring '
        'at a time, and stops if a ring reports trouble.',
        'Três anéis um dentro do outro. O de dentro, anel um, tem o desk e as máquinas da própria equipe '
        'de TI: falhar é barato e é notado rápido. O do meio tem as estações comuns. O de fora tem o web, '
        'o portal, que o escritório não pode perder. Uma atualização anda para fora, um anel por vez, e '
        'para se um anel informar problema.'))
    cx, cy = 230, 130
    for r, c in ((115, '--wire'), (80, '--wire'), (42, '--phosphor')):
        f.circle(cx, cy, r, fill=None, stroke=c, width=1.5)
    f.text(cx, cy - 6, T('ring one', 'anel um'), size=10.5, weight='600', fill='--phosphor')
    f.text(cx, cy + 10, 'desk', size=10, mono=True)
    f.text(cx, cy - 58, T('workstations', 'estações'), size=10, fill='--paper-dim')
    f.text(cx, cy - 96, 'web', size=10.5, mono=True, weight='600')
    f.line(cx + 45, cy, cx + 160, cy, stroke='--paper-dim', width=1.3, arrow=True)
    rows = [(T('ring one', 'anel um'), T('failure is cheap and noticed fast', 'falhar é barato e notado rápido')),
            (T('middle', 'meio'), T('ordinary workstations', 'estações comuns')),
            (T('outer', 'fora'), T('what the firm cannot lose', 'o que o escritório não pode perder'))]
    for i, (a, b) in enumerate(rows):
        f.text(420, 80 + i * 40, a, size=10.5, anchor='start', weight='600')
        f.text(420, 96 + i * 40, b, size=9.5, anchor='start', fill='--paper-dim')
    f.text(420, 215, T('an update moves outwards, and stops on trouble', 'a atualização anda para fora, e para se der problema'),
           size=10, anchor='start', fill='--phosphor')
    return f, T('Each ring is a smaller bet than the next one.', 'Cada anel é uma aposta menor que o seguinte.')
