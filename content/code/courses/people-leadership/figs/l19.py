"""Lesson 19: a diagnostic sequence for underperformance."""
from figures import Fig, T, figure


@figure('l19-diagnostic', 19)
def diagnostic():
    f = Fig('l19-diagnostic', 720, 330, T(
        'Six questions in sequence, top to bottom. One: are the expectations clear? Two: do they have '
        'what they need? Three: could they do it if their life depended on it? Four: does anything '
        'reward doing it badly, or punish doing it well? Five: is something outside work getting in the '
        'way? Six, last: is it motivation? A bracket marks the first two as the manager’s own part.',
        'Seis perguntas em sequência, de cima para baixo. Um: as expectativas estão claras? Dois: a '
        'pessoa tem o que precisa? Três: conseguiria fazer se a vida dependesse disso? Quatro: algo '
        'recompensa fazer mal, ou pune fazer bem? Cinco: algo fora do trabalho está atrapalhando? Seis, '
        'por último: é motivação? Uma chave marca as duas primeiras como a parte da própria gestora.'))
    qs = [T('are the expectations clear?', 'as expectativas estão claras?'),
          T('do they have what they need?', 'a pessoa tem o que precisa?'),
          T('could they do it if their life depended on it?', 'conseguiria se a vida dependesse disso?'),
          T('does anything reward doing it badly?', 'algo recompensa fazer mal?'),
          T('is something outside work in the way?', 'algo fora do trabalho atrapalha?'),
          T('only then: is it motivation?', 'só então: é motivação?')]
    x, w, h = 150, 420, 38
    for i, q in enumerate(qs):
        y = 20 + i * (h + 12)
        col = '--amber' if i == 5 else ('--phosphor' if i < 2 else '--paper-dim')
        f.rect(x, y, w, h, stroke=col, fill='--panel', width=1.5, rx=4)
        f.text(x + 20, y + h / 2, str(i + 1), size=13, weight='600', anchor='start', mono=True)
        f.text(x + 48, y + h / 2, q, size=11.5, anchor='start')
        if i < 5:
            f.arrow([(x + w / 2, y + h + 1), (x + w / 2, y + h + 11)], stroke='--paper-dim')
    f.path(f'M{x - 12} 22 L{x - 22} 22 L{x - 22} {20 + 2 * (h + 12) - 14} L{x - 12} {20 + 2 * (h + 12) - 14}',
           stroke='--phosphor', width=1.4)
    f.lines(x - 30, 20 + (2 * (h + 12) - 12) / 2, [T('the manager’s', 'a parte da'), T('own part', 'gestora')],
            size=10.5, anchor='end', fill='--phosphor')
    f.lines(x + w + 14, 20 + 5 * (h + 12) + h / 2, [T('the conclusion', 'a conclusão a que'),
                                                     T('managers reach first', 'se chega primeiro')],
            size=10.5, anchor='start', fill='--paper-dim', italic=True)
    return f, T('After Mager and Pipe. The order puts the causes a manager is least inclined to look for first.',
                'A partir de Mager e Pipe. A ordem põe primeiro as causas que a gestora tem menos vontade de procurar.')
