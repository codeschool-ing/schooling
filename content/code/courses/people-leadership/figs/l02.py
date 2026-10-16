"""Lesson 2: two shapes of the role."""
from figures import Fig, T, figure


@figure('l02-shapes', 2)
def shapes():
    f = Fig('l02-shapes', 720, 300, T(
        'Two overlapping areas. The tech lead, on the left, owns the technical direction, the '
        'design, the quality bar in review and technical unblocking, and still writes code. The '
        'engineering manager, on the right, owns hiring decisions, growth and feedback, '
        'performance, the team’s commitments to the company, its process and whether people stay. '
        'In the overlap sit four things both touch: estimates and plans, interviews, incidents, and '
        'who works on what.',
        'Duas áreas que se sobrepõem. A liderança técnica, à esquerda, é dona da direção técnica, '
        'do design, do padrão de qualidade na revisão e do desbloqueio técnico, e ainda escreve '
        'código. A gestão de engenharia, à direita, é dona das decisões de contratação, do '
        'crescimento e do feedback, do desempenho, dos compromissos do time com a empresa, do '
        'processo e de as pessoas ficarem. Na interseção ficam quatro coisas em que as duas mexem: '
        'estimativas e planos, entrevistas, incidentes e quem trabalha em quê.'))
    f.rect(30, 50, 400, 225, stroke='--phosphor', fill='--panel', width=1.6, rx=14)
    f.rect(290, 50, 400, 225, stroke='--amber', fill='--panel', width=1.6, rx=14)
    f.rect(290, 50, 140, 225, stroke=None, fill='--scan', rx=0)
    f.line(290, 50, 290, 275, stroke='--amber', width=1.6)
    f.line(430, 50, 430, 275, stroke='--phosphor', width=1.6)
    f.line(290, 50, 430, 50, stroke='--paper-dim', width=1.6)
    f.line(290, 275, 430, 275, stroke='--paper-dim', width=1.6)
    f.text(160, 30, T('tech lead', 'liderança técnica'), size=13, weight='600', fill='--phosphor')
    f.text(560, 30, T('engineering manager', 'gestão de engenharia'), size=13, weight='600',
           fill='--amber')
    f.text(360, 30, T('both touch', 'as duas mexem'), size=11, fill='--paper-dim', italic=True)
    left = [T('technical direction', 'direção técnica'), T('the design', 'o design'),
            T('the quality bar in review', 'o padrão na revisão'),
            T('technical unblocking', 'desbloqueio técnico'),
            T('still writes code', 'ainda escreve código')]
    right = [T('hiring decisions', 'decisões de contratação'),
             T('growth and feedback', 'crescimento e feedback'), T('performance', 'desempenho'),
             T('commitments to the company', 'compromissos com a empresa'),
             T('the team’s process', 'o processo do time'), T('whether people stay', 'as pessoas ficarem')]
    middle = [T('estimates', 'estimativas'), T('and plans', 'e planos'), '',
              T('interviews', 'entrevistas'), '', T('incidents', 'incidentes'), '',
              T('who works', 'quem trabalha'), T('on what', 'em quê')]
    for i, s in enumerate(left):
        f.text(50, 92 + i * 36, s, size=11, anchor='start')
    for i, s in enumerate(right):
        f.text(670, 86 + i * 33, s, size=11, anchor='end')
    for i, s in enumerate(middle):
        if s:
            f.text(360, 88 + i * 19, s, size=11, weight='600')
    return f, T('The two halves are rarely in dispute. The middle is where two people both act, and disagree in front of the team.',
                'As duas metades raramente estão em disputa. O meio é onde duas pessoas agem ao mesmo tempo, e discordam na frente do time.')
