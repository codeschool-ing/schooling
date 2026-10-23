"""Lesson 11: living documentation."""
from figures import Fig, T, figure


@figure('l11-diataxis', 11)
def diataxis():
    f = Fig('l11-diataxis', 720, 320, T(
        'The four kinds of document as a two-by-two grid. Across: practical steps on the left, '
        'theoretical knowledge on the right. Down: learning or studying at the top, working at the '
        'bottom. Tutorial: learning, practical. Explanation: studying, theoretical. How-to guide: '
        'working, practical. Reference: working, theoretical. Each cell carries a Carcará example.',
        'Os quatro tipos de documento numa grade de dois por dois. Na horizontal: passos práticos à '
        'esquerda, conhecimento teórico à direita. Na vertical: aprender ou estudar no alto, trabalhar '
        'embaixo. Tutorial: aprender, prático. Explicação: estudar, teórico. Guia prático: trabalhar, '
        'prático. Referência: trabalhar, teórico. Cada célula tem um exemplo da Carcará.'))
    cells = [(0, 0, T('Tutorial', 'Tutorial'), T('trace a purchase in', 'siga uma compra'), T('your first week', 'na primeira semana')),
             (1, 0, T('Explanation', 'Explicação'), T('why boarding', 'por que o embarque'), T('works offline', 'funciona sem rede')),
             (0, 1, T('How-to guide', 'Guia prático'), T('add a payment', 'adicionar um meio'), T('method', 'de pagamento')),
             (1, 1, T('Reference', 'Referência'), T('the container', 'o catálogo de'), T('catalogue', 'containers'))]
    x0, y0, w, h = 160, 40, 270, 120
    for cx, cy, n, a, b in cells:
        x = x0 + cx * (w + 10)
        y = y0 + cy * (h + 10)
        f.box(x + w / 2, y + h / 2, w, h, n, sub=[a, b], size=12, stroke='--phosphor')
    f.text(x0 + w / 2, 22, T('practical steps', 'passos práticos'), size=10, fill='--amber', italic=True)
    f.text(x0 + w * 1.5 + 10, 22, T('theoretical knowledge', 'conhecimento teórico'), size=10, fill='--amber', italic=True)
    f.text(150, y0 + h / 2, T('learning, studying', 'aprender, estudar'), size=10, anchor='end', fill='--amber', italic=True)
    f.text(150, y0 + h * 1.5 + 10, T('working', 'trabalhar'), size=10, anchor='end', fill='--amber', italic=True)
    f.text(x0 + w + 5, 310, T('reference decays silently: generate it or check it', 'a referência apodrece em silêncio: gere ou confira'),
           size=9.5, fill='--paper-dim')
    return f, T('A page that tries to be all four at once is the one that dies first, because no single kind of upkeep fits it.',
                'Uma página que tenta ser os quatro tipos ao mesmo tempo é a primeira a morrer, porque nenhum tipo de manutenção serve para ela.')


@figure('l11-page-life', 11)
def page_life():
    f = Fig('l11-page-life', 720, 260, T(
        'The life of a description page as a state machine. It starts as Draft, becomes Current when '
        'reviewed, and stays Current through a loop labelled verified by its owner on its cadence. From '
        'Current, three exits: Deleted, when nobody needs it; Archived, with a banner, when it explains '
        'a past state; Tombstone, a single line pointing to its replacement, when many pages link to it. '
        'A dashed transition from Current to itself labelled nobody decided leads to the state to avoid: '
        'dead but unmarked.',
        'A vida de uma página de descrição como máquina de estados. Começa como Rascunho, vira Vigente '
        'quando revisada, e continua Vigente num laço rotulado conferida pelo dono na sua cadência. De '
        'Vigente, três saídas: Apagada, quando ninguém precisa dela; Arquivada, com um aviso, quando '
        'explica um estado passado; Lápide, uma única linha apontando para a substituta, quando muitas '
        'páginas apontam para ela. Uma transição tracejada de Vigente rotulada ninguém decidiu leva ao '
        'estado a evitar: morta e sem marca.'))
    f.start(30, 110)
    f.arrow([(37, 110), (68, 110)], stroke='--paper', width=1.3)
    f.state(120, 110, 100, 40, T('Draft', 'Rascunho'))
    f.arrow([(170, 110), (248, 110)], stroke='--paper', width=1.3)
    f.text(209, 100, T('reviewed', 'revisada'), size=8.5)
    f.state(310, 110, 120, 44, T('Current', 'Vigente'))
    f.path('M280 88 C280 48, 340 48, 340 88', stroke='--paper', width=1.3, arrow=True)
    f.text(310, 40, T('verified on its cadence', 'conferida na cadência'), size=8.5)
    outs = [(580, 40, T('Deleted', 'Apagada'), T('nobody needs it', 'ninguém precisa')),
            (580, 110, T('Archived', 'Arquivada'), T('explains the past', 'explica o passado')),
            (580, 180, T('Tombstone', 'Lápide'), T('many links point here', 'muitos links apontam'))]
    for x, y, n, why in outs:
        f.state(x, y, 120, 40, n, stroke='--paper-dim')
        f.arrow([(370, 110 + (y - 110) * 0.15), (518, y)], stroke='--paper', width=1.2)
        f.text(448, y + (-8 if y <= 110 else 10) - (0 if y != 110 else 0), why, size=8.5,
               anchor='middle')
    f.state(310, 225, 160, 40, T('Dead, unmarked', 'Morta, sem marca'), stroke='--amber')
    f.arrow([(310, 132), (310, 203)], stroke='--amber', width=1.3, dash='5 3')
    f.text(318, 168, T('nobody decided', 'ninguém decidiu'), size=8.5, anchor='start', fill='--amber')
    return f, T('Three deliberate ends, and one that happens by default. The default is the one a reader believes.',
                'Três fins deliberados, e um que acontece por omissão. O de omissão é aquele em que o leitor acredita.')
