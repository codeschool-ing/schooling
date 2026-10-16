"""Lesson 11: Caju's ladder, two tracks."""
from figures import Fig, T, figure


@figure('l11-ladder', 11)
def ladder():
    f = Fig('l11-ladder', 720, 330, T(
        'Caju’s engineering ladder as two columns. On the left, the individual-contributor track '
        'rises from E1, junior engineer, through E2, engineer, E3, senior engineer, E4, staff '
        'engineer, to E5, principal engineer. On the right, the management track starts with M1, '
        'engineering manager, drawn beside E3 and E4, and M2, manager of managers, beside E4 and E5. '
        'A dashed line at E3 marks the level every engineer is expected to reach; above it, levels '
        'are optional.',
        'A escada de engenharia da Caju em duas colunas. À esquerda, a trilha de contribuição '
        'individual sobe de E1, engenharia júnior, por E2, engenharia, E3, engenharia sênior, E4, '
        'staff, até E5, principal. À direita, a trilha de gestão começa em M1, gestão de engenharia, '
        'desenhada ao lado de E3 e E4, e M2, gestão de gestores, ao lado de E4 e E5. Uma linha '
        'tracejada em E3 marca o nível que toda pessoa engenheira deve alcançar; acima dele, os '
        'níveis são opcionais.'))
    levels = [('E1', T('junior engineer', 'engenharia júnior')), ('E2', T('engineer', 'engenharia')),
              ('E3', T('senior engineer', 'engenharia sênior')), ('E4', T('staff engineer', 'staff')),
              ('E5', T('principal engineer', 'principal'))]
    x, w, h, base = 120, 220, 44, 290
    for i, (code, name) in enumerate(levels):
        y = base - (i + 1) * (h + 6)
        col = '--phosphor' if i == 2 else '--paper-dim'
        f.rect(x, y, w, h, stroke=col, fill='--panel', width=1.5, rx=4)
        f.text(x + 16, y + h / 2, code, size=13, weight='600', anchor='start', mono=True)
        f.text(x + 60, y + h / 2, name, size=11.5, anchor='start')
    f.text(x + w / 2, 18, T('individual contributor', 'contribuição individual'), size=12,
           weight='600')
    m = [('M1', T('engineering', 'gestão de'), T('manager', 'engenharia'), 2, 3, 395),
         ('M2', T('manager of', 'gestão de'), T('managers', 'gestores'), 3, 4, 550)]
    for code, n1, n2, lo, hi, mx in m:
        ytop = base - (hi + 1) * (h + 6)
        ybot = base - lo * (h + 6) - 6
        f.rect(mx, ytop + 4, 140, ybot - ytop - 8, stroke='--amber', fill='--panel', width=1.5, rx=4)
        f.text(mx + 70, (ytop + ybot) / 2 - 16, code, size=13, weight='600', mono=True)
        f.lines(mx + 70, (ytop + ybot) / 2 + 8, [n1, n2], size=11.5)
    f.text(542, 18, T('management', 'gestão'), size=12, weight='600')
    y3 = base - 4 * (h + 6) + h + 3
    f.line(30, y3, 350, y3, stroke='--phosphor', width=1.2, dash='5 4')
    f.text(30, y3 + 14, T('expected of', 'esperado'), size=10, anchor='start', fill='--paper-dim',
           italic=True)
    f.text(30, y3 + 27, T('everybody', 'de todos'), size=10, anchor='start', fill='--paper-dim',
           italic=True)
    f.text(30, y3 - 8, T('optional above', 'opcional acima'), size=10, anchor='start',
           fill='--paper-dim', italic=True)
    return f, T('M1 sits beside E3 and E4, not above them: managing is a different job at about the same level of responsibility.',
                'M1 fica ao lado de E3 e E4, não acima: gerenciar é outro trabalho, com mais ou menos o mesmo nível de responsabilidade.')
