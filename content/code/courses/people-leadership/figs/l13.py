"""Lesson 13: three directions of growth."""
from figures import Fig, T, figure


@figure('l13-directions', 13)
def directions():
    f = Fig('l13-directions', 720, 300, T(
        'A person at the centre, with four arrows. Up, dashed: the next level, which comes a handful '
        'of times in a career. Out to the left: scope, owning more of the system, like Paula taking '
        'on calendar sync. Down: depth, becoming the person who knows, like Fábio and the database. '
        'Out to the right: visibility, work other people can see, like Diego writing up his retry '
        'design for the whole engineering group.',
        'Uma pessoa no centro, com quatro setas. Para cima, tracejada: o próximo nível, que vem '
        'poucas vezes numa carreira. Para a esquerda: escopo, ser dona de mais do sistema, como a '
        'Paula assumindo a sincronização de calendário. Para baixo: profundidade, virar a pessoa que '
        'sabe, como o Fábio e o banco de dados. Para a direita: visibilidade, trabalho que outras '
        'pessoas veem, como o Diego documentando o design de novas tentativas para toda a engenharia.'))
    cx, cy = 360, 150
    f.circle(cx, cy, 42, fill='--panel', stroke='--paper-dim', width=1.6)
    f.text(cx, cy, T('a person', 'uma pessoa'), size=11, weight='600')
    f.arrow([(cx, cy - 46), (cx, 40)], stroke='--paper-dim', dash='5 4')
    f.text(cx, 26, T('the next level: a handful of times in a career',
                     'o próximo nível: poucas vezes numa carreira'), size=11, fill='--paper-dim',
           italic=True)
    f.arrow([(cx - 46, cy), (200, cy)], stroke='--phosphor', width=1.6)
    f.text(130, cy - 18, T('scope', 'escopo'), size=13, weight='600', fill='--phosphor')
    f.lines(130, cy + 10, [T('more of the system', 'mais do sistema'),
                           T('Paula: calendar sync', 'Paula: calendário')], size=10.5)
    f.arrow([(cx, cy + 46), (cx, 230)], stroke='--amber', width=1.6)
    f.text(cx, 248, T('depth', 'profundidade'), size=13, weight='600', fill='--amber')
    f.text(cx, 268, T('the person who knows · Fábio: the database',
                      'a pessoa que sabe · Fábio: o banco de dados'), size=10.5)
    f.arrow([(cx + 46, cy), (520, cy)], stroke='--paper', width=1.6)
    f.text(600, cy - 18, T('visibility', 'visibilidade'), size=13, weight='600')
    f.lines(600, cy + 10, [T('work others can see', 'trabalho que outros veem'),
                           T('Diego: the retry write-up', 'Diego: o texto das tentativas')],
            size=10.5)
    return f, T('Promotion is one direction, and the rarest. The other three are available every month.',
                'Promoção é uma direção, e a mais rara. As outras três estão disponíveis todo mês.')
