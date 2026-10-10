"""Lesson 22: five ways of handling conflict."""
from figures import Fig, T, figure


@figure('l22-modes', 22)
def modes():
    f = Fig('l22-modes', 720, 330, T(
        'Two axes: how much a person pushes for their own concern, from low to high, going up; and how '
        'much for the other person’s, from low to high, going right. Competing is high on own concern '
        'and low on the other’s. Collaborating is high on both. Avoiding is low on both. Accommodating is '
        'low on own concern and high on the other’s. Compromising sits in the middle.',
        'Dois eixos: quanto uma pessoa defende a própria preocupação, de baixo a alto, subindo; e quanto '
        'defende a da outra pessoa, de baixo a alto, para a direita. Competir é alto na própria e baixo '
        'na da outra. Colaborar é alto nas duas. Evitar é baixo nas duas. Acomodar é baixo na própria e '
        'alto na da outra. Fazer concessões fica no meio.'))
    x0, y0, w, h = 160, 30, 420, 250
    f.rect(x0, y0, w, h, stroke='--wire', fill='--panel', rx=4)
    f.arrow([(x0, y0 + h + 14), (x0 + w, y0 + h + 14)], stroke='--paper-dim')
    f.text(x0 + w / 2, y0 + h + 32, T('pushing for the other’s concern', 'defender a preocupação da outra pessoa'),
           size=11, fill='--paper-dim')
    f.arrow([(x0 - 14, y0 + h), (x0 - 14, y0)], stroke='--paper-dim')
    f.lines(x0 - 24, y0 + h / 2, [T('pushing for', 'defender a'), T('your own', 'própria'),
                                  T('concern', 'preocupação')], size=11, anchor='end', fill='--paper-dim')
    pts = [(T('competing', 'competir'), 0.2, 0.15, '--amber'),
           (T('collaborating', 'colaborar'), 0.8, 0.15, '--phosphor'),
           (T('compromising', 'fazer concessões'), 0.5, 0.5, '--paper-dim'),
           (T('avoiding', 'evitar'), 0.2, 0.85, '--paper-dim'),
           (T('accommodating', 'acomodar'), 0.8, 0.85, '--paper-dim')]
    for name, fx, fy, col in pts:
        cx, cy = x0 + fx * w, y0 + fy * h
        f.rect(cx - 68, cy - 16, 136, 32, stroke=col, fill='--ink', width=1.5, rx=16)
        f.text(cx, cy, name, size=12, weight='600')
    return f, T('After Thomas and Kilmann. Each mode fits some situations; the harm comes from using one for everything.',
                'A partir de Thomas e Kilmann. Cada modo serve a algumas situações; o mal vem de usar um só para tudo.')
