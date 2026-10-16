"""Lesson 17: scores by interviewer across a round."""
from figures import Fig, T, figure


@figure('l17-calibration', 17)
def calibration():
    f = Fig('l17-calibration', 720, 280, T(
        'A dot chart with four interviewers in rows and scores from 1 to 4 across. Each row has six '
        'dots, one per candidate in the final round. Yara’s, Helena’s and Renata’s dots spread across '
        'the lower part of the scale too. Diego’s sit at 3 and 4 only, and are higher than the others’ for five of the six '
        'candidates.',
        'Um gráfico de pontos com quatro entrevistadoras nas linhas e notas de 1 a 4 na horizontal. '
        'Cada linha tem seis pontos, um por candidata da rodada final. Os pontos da Yara, da Helena e da '
        'Renata também se espalham pela parte baixa da escala. Os do Diego ficam só em 3 e 4, e são mais altos que os dos outros '
        'para cinco das seis candidatas.'))
    rows = [('Diego', [3, 3, 3, 4, 4, 4], '--amber'),
            ('Yara', [2, 4, 1, 3, 3, 2], '--paper-dim'),
            ('Helena', [2, 2, 1, 2, 3, 2], '--paper-dim'),
            ('Renata', [2, 3, 2, 3, 2, 3], '--paper-dim')]
    x0, x1, y0, rh = 160, 620, 50, 50

    def X(s):
        return x0 + (s - 1) / 3 * (x1 - x0)

    for s in range(1, 5):
        f.line(X(s), y0 - 10, X(s), y0 + 4 * rh - 20, stroke='--wire', width=1, dash='3 4')
        f.text(X(s), y0 + 4 * rh, str(s), size=12, weight='600', mono=True)
    f.text((x0 + x1) / 2, y0 + 4 * rh + 22, T('score on the rubric, six candidates per row',
                                               'nota na escala, seis candidatas por linha'),
           size=10.5, fill='--paper-dim', italic=True)
    for i, (name, scores, col) in enumerate(rows):
        y = y0 + i * rh
        f.text(x0 - 30, y + 10, name, size=12, anchor='end', weight='600')
        counts, total = {}, {v: scores.count(v) for v in scores}
        for s in scores:
            k = counts.get(s, 0)
            counts[s] = k + 1
            f.circle(X(s) + (k - (total[s] - 1) / 2) * 12, y + 10, 5.5,
                     fill='--amber' if col == '--amber' else '--phosphor')
    return f, T('Diego’s 3 and Helena’s 3 may not mean the same thing. The pattern is invisible from inside one debrief.',
                'O 3 do Diego e o 3 da Helena podem não significar a mesma coisa. O padrão é invisível de dentro de uma conversa de decisão.')
