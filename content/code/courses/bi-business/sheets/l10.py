"""Lesson 10: one week of deliveries measured three ways (and the card's fourth),
the online sales tree with a campaign that brings the wrong visitors, and twelve
weeks of the card's rate to set a target against. Figures: the KPI card, the tree."""
import book as B

LESSON = 'le-kgvm2p47'

# One week of home deliveries from the Contagem warehouse, 2 to 8 February 2026.
# (order, kind, promised days, days taken or None if cancelled, status)
ORDERS = [
    (5101, 'parcel', 2, 2, 'delivered'),
    (5102, 'furniture', 7, 6, 'delivered'),
    (5103, 'parcel', 2, 1, 'delivered'),
    (5104, 'parcel', 2, 3, 'delivered'),
    (5105, 'furniture', 10, 8, 'delivered'),
    (5106, 'parcel', 2, 2, 'delivered'),
    (5107, 'furniture', 7, None, 'cancelled on day 1'),
    (5108, 'parcel', 2, 2, 'delivered'),
    (5109, 'furniture', 7, 9, 'delivered'),
    (5110, 'parcel', 2, 1, 'delivered'),
    (5111, 'furniture', 10, None, 'cancelled on day 12'),
    (5112, 'furniture', 7, 7, 'delivered'),
    (5113, 'parcel', 2, 2, 'delivered'),
    (5114, 'furniture', 10, 9, 'delivered'),
]
STATUS_PT = {'delivered': 'entregue', 'cancelled on day 1': 'cancelado no dia 1',
             'cancelled on day 12': 'cancelado no dia 12'}
KIND_PT = {'parcel': 'pacote', 'furniture': 'móvel'}

# The card's own rate, week by week, for the twelve weeks before (ISO weeks 46 of 2025 to 5 of 2026).
WEEKS = [78.4, 81.2, 76.4, 83.0, 79.5, 80.8, 74.1, 82.6, 79.9, 81.7, 77.3, 84.0]

# Varanda's online shop in 2025: visits, conversion (percent), average ticket (reais).
VISITS, CONV, TICKET = 3568000, 1.25, 350


def deliveries():
    rows = [['Order', 'Kind', 'Promised', 'Took', 'Status', 'On promise', 'In 2 days']]
    for k, (o, kind, p, t, s) in enumerate(ORDERS, start=2):
        rows.append([o, kind, p, '' if t is None else t, s,
                     f'=IF(D{k}="",0,IF(D{k}<=C{k},1,0))',
                     f'=IF(D{k}="",0,IF(D{k}<=2,1,0))'])
    n = len(rows)
    got = B.report('lesson 10 — one week of deliveries, measured four ways', rows,
                   ['F2', 'G2', 'F5', 'F8', 'G3', 'G6'],
                   [f'=COUNT(C2:C{n})', f'=COUNT(D2:D{n})', f'=SUM(F2:F{n})', f'=SUM(G2:G{n})',
                    f'=ROUND(SUM(F2:F{n})/COUNT(D2:D{n})*100,1)',
                    f'=ROUND(SUM(G2:G{n})/COUNT(D2:D{n})*100,1)',
                    f'=ROUND(SUM(F2:F{n})/COUNT(C2:C{n})*100,1)',
                    f'=ROUND(SUM(F2:F{n})/(COUNT(D2:D{n})+1)*100,1)',
                    f'=ROUND((SUM(F2:F{n})+1)/(COUNT(D2:D{n})+1)*100,1)'])  # a drill: 5104 on time
    return got


def tree():
    rows = [['', 'Now', 'Campaign'],
            ['Visits', VISITS, '=B2*1.25'],
            ['Conversion %', CONV, 1],
            ['Average ticket', TICKET, TICKET],
            ['Sales', '=B2*B3/100*B4', '=C2*C3/100*C4'],
            ['Orders', '=B2*B3/100', '=C2*C3/100']]
    return B.report('lesson 10 — the online sales tree, 2025, and a campaign', rows,
                    ['B5', 'B6', 'C2', 'C5', 'C6'],
                    ['=ROUND((C5/B5-1)*100,1)', '=ROUND((C6/B6-1)*100,1)',
                     '=B2*1.375/100*B4', '=ROUND((B2*1.375/100*B4/B5-1)*100,1)',
                     '=ROUND((B2*1.5/100*B4/B5-1)*100,1)'])


def history():
    rows = [['Week', 'On promise %']] + [[k + 1, w] for k, w in enumerate(WEEKS)]
    n = len(rows)
    return B.report('lesson 10 — twelve weeks of the card\'s rate', rows, [],
                    [f'=MIN(B2:B{n})', f'=MAX(B2:B{n})', f'=MEDIAN(B2:B{n})',
                     f'=ROUND(AVERAGE(B2:B{n}),1)'])


def card():
    rows = [
        (('name', 'nome'), ('Delivered on promise', 'Entregue no prazo prometido')),
        (('objective', 'objetivo'), ('keep the date we give the customer', 'cumprir a data que damos ao cliente')),
        (('numerator', 'numerador'), ('orders delivered by the promised day', 'pedidos entregues até o dia prometido')),
        (('denominator', 'denominador'), ('delivered + cancelled after the promise', 'entregues + cancelados após o prazo')),
        (('excluded', 'excluídos'), ('cancelled before the promised day', 'cancelados antes do dia prometido')),
        (('unit', 'unidade'), ('percent of orders, one decimal', 'porcentagem de pedidos, uma casa')),
        (('source', 'fonte'), ('ERP orders + carrier delivery records', 'pedidos do ERP + registros da transportadora')),
        (('owner', 'dono'), ('Caio Barreto, operations', 'Caio Barreto, operações')),
        (('frequency', 'frequência'), ('weekly, Monday by 9:00', 'semanal, segunda até as 9h')),
        (('target', 'meta'), ('85 by December 2026', '85 até dezembro de 2026')),
        (('action', 'ação'), ('below 76 two weeks running: review carriers', 'abaixo de 76 duas semanas: rever transportadoras')),
    ]
    top, rh = 54, 24
    h = top + rh * len(rows) + 46
    f = B.Fig('l10-card', 720, h, (
        'A KPI card drawn as a form with eleven fields: name, objective, numerator, denominator, '
        'excluded, unit, source, owner, frequency, target and the threshold that triggers action, '
        'filled in for delivered on promise at Varanda.',
        'Um cartão de KPI desenhado como formulário de onze campos: nome, objetivo, numerador, '
        'denominador, excluídos, unidade, fonte, dono, frequência, meta e o limite que dispara a '
        'ação, preenchido para entregue no prazo prometido na Varanda.'))
    f.rect(20, 14, 680, h - 28, fill='--panel', stroke='--phosphor')
    f.text(40, 40, ('KPI card', 'Cartão de KPI'), size=14, weight=600)
    f.text(680, 40, ('written before anybody computes it', 'escrito antes de alguém calcular'),
           size=11, anchor='end', fill='--paper-dim')
    for k, (field, value) in enumerate(rows):
        y = top + rh * k
        f.line(40, y, 680, y, stroke='--wire', sw=1)
        f.text(40, y + 17, field, size=12, fill='--paper-dim')
        f.text(190, y + 17, value, size=12, weight=600 if k == 0 else None)
    y = top + rh * len(rows)
    f.line(40, y, 680, y, stroke='--wire', sw=1)
    f.text(40, y + 22, ('Fields 3 to 5 are the definition; 8 to 11 make it somebody\'s job.',
                        'Os campos 3 a 5 são a definição; 8 a 11 fazem dele o trabalho de alguém.'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'The card for the delivery KPI, as the lesson builds it. The numerator, the denominator and '
        'what is excluded are the three lines two people most often fill in differently.',
        'O cartão do KPI de entregas, como a aula o monta. Numerador, denominador e o que fica de '
        'fora são as três linhas que duas pessoas mais preenchem de jeitos diferentes.'))


def tree_fig(got):
    f = B.Fig('l10-tree', 720, 400, (
        'A KPI tree. At the top, online sales, a lagging result. Below it, multiplied together, '
        'visits, conversion and average ticket. Below each, what drives it: campaigns, search and '
        'email for visits; price, stock on the shelf, site speed and the delivery promise for '
        'conversion; the mix of products and items per order for the ticket. Each branch names '
        'an owner.',
        'Uma árvore de KPIs. No topo, as vendas online, um resultado atrasado. Abaixo, '
        'multiplicados, visitas, conversão e tíquete médio. Abaixo de cada um, o que o move: '
        'campanhas, busca e e-mail para as visitas; preço, estoque, velocidade do site e a promessa '
        'de entrega para a conversão; o mix de produtos e os itens por pedido para o tíquete. Cada '
        'ramo tem um dono.'))
    W = 200
    # top
    f.rect(260, 20, W, 62, fill='--panel', stroke='--amber')
    f.text(360, 44, ('online sales', 'vendas online'), size=14, anchor='middle', weight=600)
    f.text(360, 66, ('R$ 15.61 million in 2025', 'R$ 15,61 milhões em 2025'), size=11,
           anchor='middle', fill='--paper-dim')
    f.text(475, 44, ('lagging', 'atrasado'), size=11, fill='--paper-dim')
    mids = [
        (20, ('visits', 'visitas'), ('3,568,000', '3.568.000'), ('owner: Renata', 'dono: Renata')),
        (260, ('conversion', 'conversão'), ('1.25% of visits buy', '1,25% das visitas compram'),
         ('owners: Renata and Caio', 'donos: Renata e Caio')),
        (500, ('average ticket', 'tíquete médio'), ('R$ 350 per order', 'R$ 350 por pedido'),
         ('owner: Renata', 'dono: Renata')),
    ]
    for x, name, val, owner in mids:
        f.rect(x, 150, W, 78, fill='--panel', stroke='--phosphor')
        f.text(x + W / 2, 174, name, size=14, anchor='middle', weight=600)
        f.text(x + W / 2, 194, val, size=11, anchor='middle', fill='--paper-dim')
        f.text(x + W / 2, 214, owner, size=11, anchor='middle', fill='--paper-dim')
        f.line(x + W / 2, 150, x + W / 2, 116, stroke='--paper-dim')
    f.line(120, 116, 600, 116, stroke='--paper-dim')
    f.line(360, 116, 360, 84, stroke='--paper-dim')
    f.text(240, 138, '×', size=16, anchor='middle', mono=True)
    f.text(480, 138, '×', size=16, anchor='middle', mono=True)
    f.text(700, 138, ('leading', 'adiantados'), size=11, anchor='end', fill='--paper-dim')
    drivers = [
        (20, [('paid campaigns', 'campanhas pagas'), ('search', 'busca'), ('email', 'e-mail')]),
        (260, [('price', 'preço'), ('stock on the shelf', 'estoque disponível'),
               ('site speed', 'velocidade do site'), ('delivery promise', 'promessa de entrega')]),
        (500, [('product mix', 'mix de produtos'), ('items per order', 'itens por pedido')]),
    ]
    for x, items in drivers:
        f.line(x + W / 2, 230, x + W / 2, 262, stroke='--paper-dim')
        f.rect(x, 264, W, 112, fill='--ink', stroke='--wire', dash='4 3')
        for k, it in enumerate(items):
            f.text(x + 16, 290 + 22 * k, it, size=12)
    B.place(LESSON, f, (
        'Online sales as a tree. The result at the top arrives once a month; the three branches '
        'move daily, and the drivers under them are what somebody can actually change. Conversion '
        'has two owners because the delivery promise and the stock belong to operations.',
        'As vendas online como árvore. O resultado no topo chega uma vez por mês; os três ramos '
        'mexem todo dia, e o que está embaixo deles é o que alguém consegue de fato mudar. A '
        'conversão tem dois donos porque a promessa de entrega e o estoque são de operações.'))


def main():
    deliveries()
    got = tree()
    history()
    card()
    tree_fig(got)


if __name__ == '__main__':
    main()
