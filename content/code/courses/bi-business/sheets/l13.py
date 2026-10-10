"""Lesson 13: nothing to compute. Two drawings: the power-interest map of the
delivery dashboard project, and the same KPI at four levels of detail for the four
people who read it."""
import book as B

LESSON = 'le-nrrjm08w'


def grid():
    f = B.Fig('l13-map', 720, 470, (
        'A two by two grid. The vertical axis is power over the project, the horizontal axis is '
        'interest in it. Top right, manage closely: Caio Barreto and Tiago Ramos. Top left, keep '
        'satisfied: Helena Prado and Otávio Lins. Bottom right, keep informed: Marcos and the store '
        'managers, with Bruno Teixeira. Bottom left, monitor: Renata Sá and the carriers. An arrow '
        'moves the store managers up and to the right, labelled: once their bonus depends on it.',
        'Uma grade dois por dois. O eixo vertical é o poder sobre o projeto, o horizontal é o '
        'interesse nele. Em cima à direita, gerenciar de perto: Caio Barreto e Tiago Ramos. Em cima '
        'à esquerda, manter satisfeito: Helena Prado e Otávio Lins. Embaixo à direita, manter '
        'informado: Marcos e os gerentes de loja, com Bruno Teixeira. Embaixo à esquerda, '
        'monitorar: Renata Sá e as transportadoras. Uma seta leva os gerentes de loja para cima e '
        'para a direita, com a legenda: quando o bônus deles depender disso.'))
    L, T, W, H = 70, 20, 300, 190      # each quadrant
    quads = [
        (L, T, ('keep satisfied', 'manter satisfeito'), '--amber',
         [('Helena Prado, CEO', 'Helena Prado, CEO'), ('Otávio Lins, CFO', 'Otávio Lins, CFO')]),
        (L + W + 10, T, ('manage closely', 'gerenciar de perto'), '--phosphor',
         [('Caio Barreto, operations', 'Caio Barreto, operações'),
          ('Tiago Ramos, the data', 'Tiago Ramos, os dados')]),
        (L, T + H + 10, ('monitor', 'monitorar'), '--wire',
         [('Renata Sá, marketing', 'Renata Sá, marketing'), ('the carriers', 'as transportadoras')]),
        (L + W + 10, T + H + 10, ('keep informed', 'manter informado'), '--phosphor',
         [('Marcos, deliveries', 'Marcos, entregas'),
          ('store managers, Bruno too', 'gerentes de loja, e o Bruno')]),
    ]
    for x, y, title, stroke, names in quads:
        f.rect(x, y, W, H, fill='--panel', stroke=stroke)
        f.text(x + 16, y + 28, title, size=14, weight=600)
        for k, n in enumerate(names):
            f.text(x + 16, y + 62 + 26 * k, n, size=12)
    # the move
    f.arrow(L + W + 160, T + H + 136, L + W + 200, T + H - 40, stroke='--amber', sw=2)
    f.text(L + W + 206, T + H - 6, ('once their bonus', 'quando o bônus deles'), size=11,
           fill='--paper-dim')
    f.text(L + W + 206, T + H + 8, ('depends on it', 'depender disso'), size=11, fill='--paper-dim')
    # axes
    f.arrow(40, T + 2 * H + 10, 40, T, stroke='--paper-dim')
    f.text(30, T + H + 5, ('power', 'poder'), size=12, anchor='end', fill='--paper-dim')
    f.arrow(L, T + 2 * H + 30, L + 2 * W + 10, T + 2 * H + 30, stroke='--paper-dim')
    f.text(L + W + 5, T + 2 * H + 50, ('interest', 'interesse'), size=12, anchor='middle',
           fill='--paper-dim')
    B.place(LESSON, f, (
        'Varanda\'s delivery dashboard project on the power-interest map. The quadrant says how '
        'much of your time each person gets; the arrow is the reason to redraw it whenever '
        'something about the number changes.',
        'O projeto do painel de entregas da Varanda no mapa de poder e interesse. O quadrante diz '
        'quanto do seu tempo cada pessoa recebe; a seta é o motivo para redesenhá-lo sempre que '
        'algo no número mudar.'))


def four_views():
    f = B.Fig('l13-views', 720, 420, (
        'Four small panels, each the same delivery KPI as one reader needs it. Helena, monthly: '
        'one number, 86.2% in May, with a line from February and the goal of 85. Caio, '
        'weekly: the rate by region, one bar each, against the action threshold of 76. Marcos, '
        'now: a list of today\'s orders at risk, with order number, route and hours left. Bruno, '
        'monthly: Contagem against the other stores, for furniture and for parcels separately.',
        'Quatro painéis pequenos, cada um o mesmo KPI de entregas como um leitor precisa. Helena, '
        'mensal: um número, 86,2% em maio, com uma linha desde fevereiro e o objetivo de 85. '
        'Caio, semanal: a taxa por região, uma barra cada, contra o limite de ação de 76. Marcos, '
        'agora: uma lista dos pedidos de hoje em risco, com número, rota e horas restantes. Bruno, '
        'mensal: Contagem contra as outras lojas, em móveis e em pacotes separados.'))
    W, H = 340, 190
    panels = [(20, 20), (360, 20), (20, 210), (360, 210)]
    heads = [(('Helena · monthly', 'Helena · mensal'), ('is the promise being kept?', 'a promessa está sendo cumprida?')),
             (('Caio · weekly', 'Caio · semanal'), ('where is it slipping?', 'onde está escorregando?')),
             (('Marcos · now', 'Marcos · agora'), ('which orders need me?', 'que pedidos precisam de mim?')),
             (('Bruno · monthly', 'Bruno · mensal'), ('how is my store doing?', 'como está a minha loja?'))]
    for (x, y), (who, q) in zip(panels, heads):
        f.rect(x, y, W - 20, H - 20, fill='--panel', stroke='--phosphor')
        f.text(x + 14, y + 24, who, size=13, weight=600)
        f.text(x + 14, y + 42, q, size=11, fill='--paper-dim')
    # Helena: one number and a trend
    x, y = 20, 20
    f.text(x + 14, y + 92, ('86.2%', '86,2%'), size=30, weight=600)
    f.text(x + 14, y + 114, ('May, goal 85 by December', 'maio, objetivo 85 até dezembro'), size=11,
           fill='--paper-dim')
    pts = [76.9, 78.1, 80.4, 86.2]
    px = [x + 180 + 37 * k for k in range(4)]
    py = [y + 140 - (v - 74) * 5 for v in pts]
    f.path('M' + ' L'.join(f'{a:.1f} {b:.1f}' for a, b in zip(px, py)), stroke='--phosphor', sw=2)
    f.line(x + 176, y + 140 - 11 * 5, x + 300, y + 140 - 11 * 5, stroke='--amber', sw=1, dash='4 3')
    f.text(x + 300, y + 140 - 11 * 5 - 6, ('goal', 'objetivo'), size=11, anchor='end', fill='--paper-dim')
    f.text(x + 180, y + 160, ('Feb', 'fev'), size=11, fill='--paper-dim')
    f.text(x + 292, y + 160, ('May', 'mai'), size=11, anchor='end', fill='--paper-dim')
    # Caio: bars by region against the threshold
    x, y = 360, 20
    regions = [(('Metro BH', 'BH e região'), 88), (('West', 'Oeste'), 84), (('East', 'Leste'), 79),
               (('Zona da Mata', 'Zona da Mata'), 74)]
    for k, (name, v) in enumerate(regions):
        by = y + 60 + 24 * k
        f.text(x + 14, by + 12, name, size=11)
        f.bar(x + 110, by, (v - 60) * 6, 14, fill='--amber' if v < 76 else '--phosphor')
        f.text(x + 116 + (v - 60) * 6, by + 12, str(v), size=11)
    f.line(x + 110 + 16 * 6, y + 54, x + 110 + 16 * 6, y + 160, stroke='--paper-dim', sw=1, dash='4 3')
    f.text(x + 112 + 16 * 6, y + 170, ('threshold 76', 'limite 76'), size=11, fill='--paper-dim')
    # Marcos: a list of orders
    x, y = 20, 210
    rows = [('6214', ('route 3', 'rota 3'), ('2 h left', 'faltam 2 h')),
            ('6230', ('route 3', 'rota 3'), ('3 h left', 'faltam 3 h')),
            ('6191', ('route 7', 'rota 7'), ('late', 'atrasado'))]
    for k, (o, r, left) in enumerate(rows):
        ry = y + 70 + 26 * k
        f.text(x + 14, ry, o, size=12, mono=True)
        f.text(x + 80, ry, r, size=12)
        f.text(x + 300, ry, left, size=12, anchor='end', weight=600 if k == 2 else None)
        f.line(x + 14, ry + 8, x + 300, ry + 8, stroke='--wire', sw=1)
    f.text(x + 14, y + 160, ('updated 10:42', 'atualizado às 10h42'), size=11, fill='--paper-dim')
    # Bruno: his store against the others, by kind
    x, y = 360, 210
    f.text(x + 14, y + 70, ('furniture', 'móveis'), size=11)
    f.text(x + 14, y + 120, ('parcels', 'pacotes'), size=11)
    for k, (mine, rest) in enumerate(((75, 72), (95, 91))):
        by = y + 58 + 50 * k
        f.bar(x + 100, by - 2, (mine - 50) * 4.4, 12, fill='--phosphor')
        f.text(x + 106 + (mine - 50) * 4.4, by + 9, ('Contagem ' + str(mine), 'Contagem ' + str(mine)),
               size=11)
        f.bar(x + 100, by + 14, (rest - 50) * 4.4, 12, fill='--wire')
        f.text(x + 106 + (rest - 50) * 4.4, by + 25, (('others ' + str(rest)), ('outras ' + str(rest))),
               size=11)
    f.text(x + 14, y + 160, ('February, by kind, never the bare total', 'fevereiro, por tipo, nunca o total nu'), size=11,
           fill='--paper-dim')
    B.place(LESSON, f, (
        'One KPI, four readers. The definition is the same in every panel; what changes is the '
        'level of detail, how often it is read, and the question it is shaped to answer.',
        'Um KPI, quatro leitores. A definição é a mesma em todos os painéis; o que muda é o nível '
        'de detalhe, a frequência de leitura e a pergunta que ele foi feito para responder.'))


def main():
    grid()
    four_views()


if __name__ == '__main__':
    main()
