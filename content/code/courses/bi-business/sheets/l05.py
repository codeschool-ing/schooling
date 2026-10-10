"""Lesson 5: Varanda as a company. The simplified 2025 income statement and its
margins, a sale on instalments, the online funnel, stock turns and days of
stock, deliveries on time, and staff turnover. The flows between the four
functions and the funnel are drawn."""
import book as B

LESSON = 'le-ckq1j34r'

# The income statement for 2025, thousands of reais. Sales are book.SALES_2025.
COGS = 55370
OPEX = [
    (('People', 'Pessoal'), 18750),
    (('Stores and rent', 'Lojas e aluguel'), 9800),
    (('Marketing', 'Marketing'), 4410),
    (('Warehouse and deliveries', 'Depósito e entregas'), 3920),
    (('Other', 'Outras'), 2890),
]

# The online shop's funnel, 2025.
VISITS, CARTS, ORDERS = 6480000, 498900, 124000
NEW_CUSTOMERS = 79600        # first ever online order placed in 2025 (41,200 of them in Jan-Jun)
ONLINE_MARKETING = 2150      # thousands of reais, part of the marketing line

# A store's own funnel: Contagem, 2025, from the door counter and the tills.
CONTAGEM_VISITORS, CONTAGEM_RECEIPTS = 211500, 51480

# Stock and deliveries.
AVG_STOCK = 9480             # thousands of reais at cost, average of the twelve month-ends
DELIVERIES, LATE = 14600, 949

# People.
HEADCOUNT = 410              # average over 2025
LEAVERS = 103
SCHEDULED_HOURS, ABSENT_HOURS = 870000, 23500


def income():
    sales = sum(B.SALES_2025)
    rows = [['Line', 'R$ thousand', 'Margin %'],
            ['Sales', sales, ''],
            ['Cost of goods sold', COGS, ''],
            ['Gross profit', '=B2-B3', '=ROUND(B4/B2*100,1)']]
    for (en, _), v in OPEX:
        rows.append([en, v, ''])
    n = len(rows)
    rows.append(['Operating expenses', f'=SUM(B5:B{n})', ''])
    rows.append(['Operating profit', f'=B4-B{n + 1}', f'=ROUND(B{n + 2}/B2*100,1)'])
    return B.report('lesson 5 — the income statement, 2025', rows,
                    ['B2', 'B4', 'C4', f'B{n + 1}', f'B{n + 2}', f'C{n + 2}'],
                    ['=ROUND(B3/B2*100,1)', '=ROUND(B5/B2*100,1)', '=ROUND(B11/B2*100,2)',
                     '=B6+B7+B8+B9', '=ROUND(B3*0.05,0)', '=ROUND(B6/B2*100,1)'])


def instalments():
    rows = [['Sofa price', 6000], ['Instalments', 10], ['Each', '=B1/B2']]
    return B.report('lesson 5 — a sofa on ten instalments', rows, ['B3'])


def funnel():
    rows = [['Step', 'Count'],
            ['Visits', VISITS], ['Carts', CARTS], ['Orders', ORDERS],
            ['Online sales (R$ thousand)', B.ONLINE_2025],
            ['New customers', NEW_CUSTOMERS], ['Online marketing (R$ thousand)', ONLINE_MARKETING]]
    return B.report('lesson 5 — the online funnel, 2025', rows, [],
                    ['=ROUND(B3/B2*100,1)',            # visits to carts
                     '=ROUND(B4/B3*100,1)',            # carts to orders
                     '=ROUND(B4/B2*100,1)',            # visits to orders: conversion
                     '=ROUND(B5*1000/B4,2)',           # average ticket, reais
                     '=ROUND(B7*1000/B6,2)'])          # acquisition cost per new customer


def store():
    sales = dict((n, v) for n, _, v in B.STORES)['Contagem']
    rows = [['Measure', 'Contagem'], ['Visitors', CONTAGEM_VISITORS], ['Receipts', CONTAGEM_RECEIPTS],
            ['Sales (R$ thousand)', sales]]
    return B.report('lesson 5 — Contagem\'s door, 2025', rows, [],
                    ['=ROUND(B3/B2*100,1)', '=ROUND(B4*1000/B3,2)'])


def stock():
    rows = [['Measure', 'Value'], ['Cost of goods sold', COGS], ['Average stock at cost', AVG_STOCK],
            ['Deliveries', DELIVERIES], ['Late', LATE]]
    return B.report('lesson 5 — stock and deliveries, 2025', rows, [],
                    ['=ROUND(B2/B3,1)', '=ROUND(B3/B2*365,1)', '=ROUND((B4-B5)/B4*100,1)',
                     '=ROUND(B2/365,1)'])


def people():
    rows = [['Measure', 'Value'], ['Average headcount', HEADCOUNT], ['Leavers', LEAVERS],
            ['Scheduled hours', SCHEDULED_HOURS], ['Hours absent', ABSENT_HOURS]]
    return B.report('lesson 5 — people, 2025', rows, [],
                    ['=ROUND(B3/B2*100,1)', '=ROUND(B3/B2/12*100,1)', '=ROUND(B5/B4*100,1)'])


def mi(v, lang):
    """Thousands of reais as millions to one decimal: 55,370 -> 55.4 (55,4 in Portuguese)."""
    return B.fmt(v / 1000, lang, 1)


def flows():
    sales = sum(B.SALES_2025)
    staff = OPEX[0][1]
    rest = sum(v for _, v in OPEX[1:])
    profit = sales - COGS - staff - rest
    L = lambda en, pt, v: (en.format(mi(v, 'en')), pt.format(mi(v, 'pt')))
    f = B.Fig('l05-flows', 720, 440, (
        f'Varanda as flows of money and goods. In the centre, the company. Customers pay money in at '
        f'the top, R$ {mi(sales, "en")} million of sales in 2025. Money flows out to suppliers for the goods, '
        f'R$ {mi(COGS, "en")} million, to people for their work, R$ {mi(staff, "en")} million, and to rent, marketing, the '
        f'warehouse and other costs, R$ {mi(rest, "en")} million. What is left is the operating profit, '
        f'R$ {mi(profit, "en")} million. Around the company, the four functions and what each decides: marketing '
        'brings customers in, operations buys, stores and delivers the goods, people hires and '
        'keeps the staff, finance counts all of it and decides where money goes.',
        f'A Varanda como fluxos de dinheiro e de mercadoria. No centro, a empresa. Os clientes pagam, '
        f'em cima: R$ {mi(sales, "pt")} milhões de vendas em 2025. O dinheiro sai para os fornecedores pelas '
        f'mercadorias, R$ {mi(COGS, "pt")} milhões, para as pessoas pelo trabalho, R$ {mi(staff, "pt")} milhões, e para '
        f'aluguel, marketing, depósito e outros custos, R$ {mi(rest, "pt")} milhões. O que sobra é o lucro '
        f'operacional, R$ {mi(profit, "pt")} milhões. Em volta da empresa, as quatro áreas e o que cada uma decide: '
        'marketing traz clientes, operações compra, guarda e entrega as mercadorias, pessoas '
        'contrata e mantém a equipe, finanças conta tudo e decide para onde vai o dinheiro.'))
    # the company in the middle
    cx, cy, cw, ch = 250, 160, 220, 110
    f.rect(cx, cy, cw, ch, fill='--panel', stroke='--phosphor', sw=2)
    f.text(cx + cw / 2, cy + 34, 'Varanda', size=15, anchor='middle', weight=600)
    f.text(cx + cw / 2, cy + 60, ('operating profit', 'lucro operacional'), size=12, anchor='middle', fill='--paper-dim')
    f.text(cx + cw / 2, cy + 82, L('R$ {} million', 'R$ {} milhões', profit), size=13, anchor='middle', fill='--amber', weight=600)
    # customers above, money in
    f.rect(cx, 20, cw, 60, fill='--ink', stroke='--wire')
    f.text(cx + cw / 2, 46, ('customers', 'clientes'), size=13, anchor='middle', weight=600)
    f.text(cx + cw / 2, 66, L('pay R$ {} million', 'pagam R$ {} milhões', sales), size=12, anchor='middle', fill='--paper-dim')
    f.arrow(cx + cw / 2, 82, cx + cw / 2, cy - 2, stroke='--phosphor', sw=2.5)
    # three outflows below
    outs = [(30, ('suppliers', 'fornecedores'), L('goods: R$ {} million', 'mercadorias: R$ {} mi', COGS)),
            (260, ('staff', 'equipe'), L('pay: R$ {} million', 'salários: R$ {} mi', staff)),
            (490, ('everything else', 'todo o resto'), L('R$ {} million', 'R$ {} mi', rest))]
    for x, t, s in outs:
        f.rect(x, 350, 200, 60, fill='--ink', stroke='--wire')
        f.text(x + 100, 376, t, size=13, anchor='middle', weight=600)
        f.text(x + 100, 396, s, size=12, anchor='middle', fill='--paper-dim')
        f.arrow(cx + cw / 2 + (x + 100 - 360) * 0.35, cy + ch + 2, x + 100, 348, stroke='--amber', sw=2)
    # the four functions at the sides
    sides = [(16, 120, ('marketing', 'marketing'), ('brings customers in', 'traz os clientes')),
             (16, 220, ('operations', 'operações'), ('buys, stores, delivers', 'compra, guarda, entrega')),
             (494, 120, ('finance', 'finanças'), ('counts, decides spend', 'conta e decide gastos')),
             (494, 220, ('people', 'pessoas'), ('hires and keeps staff', 'contrata e mantém')),]
    for x, y, t, s in sides:
        f.rect(x, y, 210, 62, fill='--panel', stroke='--wire', dash='4 3')
        f.text(x + 105, y + 26, t, size=13, anchor='middle', weight=600)
        f.text(x + 105, y + 46, s, size=12, anchor='middle', fill='--paper-dim')
    f.text(360, 434, ('money comes in at the top and goes out at the bottom', 'o dinheiro entra por cima e sai por baixo'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Varanda\'s 2025 as money in and money out. Of every R$ 100 customers paid, R$ 2.92 was left '
        'as operating profit; the four functions decide how the rest is spent.',
        'O 2025 da Varanda como dinheiro que entra e que sai. De cada R$ 100 que os clientes pagaram, '
        'sobraram R$ 2,92 de lucro operacional; as quatro áreas decidem como o resto é gasto.'))


def funnel_fig():
    f = B.Fig('l05-funnel', 720, 300, (
        'The online shop\'s funnel for 2025 as three bars of shrinking length: 6.48 million visits, '
        '498,900 carts, 124,000 orders. Between visits and carts, 7.7%; between carts and orders, '
        '24.9%; from visit to order, 1.9%.',
        'O funil da loja online em 2025 como três barras cada vez mais curtas: 6,48 milhões de '
        'visitas, 498.900 carrinhos, 124.000 pedidos. De visita para carrinho, 7,7%; de carrinho '
        'para pedido, 24,9%; de visita para pedido, 1,9%.'))
    steps = [(('visits', 'visitas'), VISITS, ('6.48 million', '6,48 milhões')),
             (('carts', 'carrinhos'), CARTS, (B.fmt(CARTS), B.fmt(CARTS, 'pt'))),
             (('orders', 'pedidos'), ORDERS, (B.fmt(ORDERS), B.fmt(ORDERS, 'pt')))]
    x0, full, top, gap = 150, 420, 34, 84
    for i, (lab, v, txt) in enumerate(steps):
        y = top + i * gap
        w = max(full * v / VISITS, 4)
        f.text(x0 - 14, y + 26, lab, size=13, anchor='end', weight=600)
        f.bar(x0, y, w, 40, fill='--phosphor')
        f.text(x0 + w + 10, y + 26, txt, size=12, fill='--paper', mono=True)
    rates = [(top + 62, ('7.7% of visits put something in a cart', '7,7% das visitas põem algo no carrinho')),
             (top + 62 + gap, ('24.9% of carts become orders', '24,9% dos carrinhos viram pedido'))]
    for y, t in rates:
        f.text(x0 + 6, y, t, size=12, fill='--paper-dim')
    f.text(360, 288, ('1.9% of visits end in an order', '1,9% das visitas terminam num pedido'),
           size=13, anchor='middle', fill='--amber', weight=600)
    B.place(LESSON, f, (
        'The online funnel, 2025. Each step loses most of the one before it; the conversion rate is '
        'the product of the steps.',
        'O funil online, 2025. Cada passo perde a maior parte do anterior; a taxa de conversão é o '
        'produto dos passos.'))


def literal():
    """The formulas sections show with the numbers typed in."""
    return B.report('lesson 5 — the formulas shown with their numbers typed in', [['x']], [],
                    ['=ROUND(15610*1000/124000,2)', '=ROUND(2150*1000/79600,2)',
                     '=ROUND(51480/211500*100,1)', '=ROUND(12480*1000/51480,2)', '=6000/10',
                     '=ROUND((14600-949)/14600*100,1)', '=ROUND(103/410*100,1)',
                     '=ROUND(103/410/12*100,1)', '=ROUND(23500/870000*100,1)'])


def main():
    literal()
    income()
    instalments()
    funnel()
    store()
    stock()
    people()
    flows()
    funnel_fig()


if __name__ == '__main__':
    main()
