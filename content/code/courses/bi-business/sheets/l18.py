"""Lesson 18: retail through lesson 17's four questions. Like-for-like growth with a
store that opened mid-2024, the garden category's stock page (days of cover, sell-through
and the sales a stock-out hides), a campaign measured against a holdout, and one
supplier's fill rate against its on-time-in-full."""
import book as B

LESSON = 'le-z172pqfz'

# 2024 sales by store, thousands of reais. Ipatinga opened in July 2024, so its 2024 is six
# months. The eight others traded both whole years. 2025 is book.STORES.
OPENED_2024 = 'Ipatinga'
SALES_2024_BY_STORE = {
    'Savassi': 11520, 'Pampulha': 10610, 'Contagem': 12650, 'Betim': 8700,
    'Nova Lima': 8980, 'Sete Lagoas': 6690, 'Divinópolis': 6540, 'Juiz de Fora': 8910,
    'Ipatinga': 3350,
}
ONLINE_2024 = 14750
assert sum(SALES_2024_BY_STORE.values()) + ONLINE_2024 == sum(B.SALES_2024)

# The garden category, the four weeks to Sunday 26 October 2025: units on hand that
# morning, units sold in the 28 days, days of the 28 with stock on the shelf, price in reais.
GARDEN = [
    (('Hose reel, 30 m', 'Enrolador com mangueira, 30 m'), 0, 84, 18, 289),
    (('Garden hose, 15 m', 'Mangueira de jardim, 15 m'), 410, 196, 28, 79),
    (('Pruning shears', 'Tesoura de poda'), 95, 133, 28, 64),
    (('Clay pot, 30 cm', 'Vaso de barro, 30 cm'), 1240, 62, 28, 45),
    (('Oscillating sprinkler', 'Aspersor oscilante'), 36, 150, 28, 119),
    (('Potting soil, 20 kg', 'Terra adubada, 20 kg'), 300, 360, 25, 39),
]
DAYS = 28

# The spring e-mail campaign: 40,000 online customers, 10% held out at random.
CAMPAIGN = dict(customers=36000, orders=1512, hold_customers=4000, hold_orders=136,
                ticket=350, discount=0.15, sending=3600)

# One supplier, eight purchase orders for the hose reel, August to October 2025:
# units ordered, units received, days late (0 = on or before the promised date).
POS = [(120, 120, 0), (120, 114, 0), (150, 150, 2), (150, 150, 0),
       (120, 120, 9), (120, 108, 0), (150, 150, 0), (150, 150, 4)]


def like_for_like():
    order = [s for s, _, _ in B.STORES if s != OPENED_2024] + [OPENED_2024]
    s25 = {s: v for s, _, v in B.STORES}
    rows = [['Store', '2024', '2025', 'Growth %']]
    for k, s in enumerate(order, start=2):
        rows.append([s, SALES_2024_BY_STORE[s], s25[s], f'=ROUND((C{k}/B{k}-1)*100,1)'])
    rows.append(['All stores', '=SUM(B2:B10)', '=SUM(C2:C10)', '=ROUND((C11/B11-1)*100,1)'])
    rows.append(['Like-for-like', '=SUM(B2:B9)', '=SUM(C2:C9)', '=ROUND((C12/B12-1)*100,1)'])
    cells = [f'D{k}' for k in range(2, 11)] + ['B11', 'C11', 'D11', 'B12', 'C12', 'D12']
    got = B.report('lesson 18 — like-for-like', rows, cells, [
        '=ROUND((C10-B10)/B11*100,1)',          # points of growth from the new store
        '=ROUND((C12-B12)/B11*100,1)',          # points from the eight
        f'=ROUND(({B.ONLINE_2025}/{ONLINE_2024}-1)*100,1)',
        f'=ROUND(({sum(B.SALES_2025)}/{sum(B.SALES_2024)}-1)*100,1)',
    ])
    return got


def stock():
    rows = [['Product', 'On hand', 'Sold', 'Days in stock', 'Price',
             'Per day', 'Days of cover', 'Sell-through %', 'Lost units', 'Lost R$']]
    for k, (name, onhand, sold, din, price) in enumerate(GARDEN, start=2):
        rows.append([name[0], onhand, sold, din, price,
                     f'=ROUND(C{k}/D{k},2)',
                     f'=ROUND(B{k}/(C{k}/D{k}),1)',
                     f'=ROUND(C{k}/(C{k}+B{k})*100,1)',
                     f'=ROUND(C{k}/D{k}*({DAYS}-D{k}),0)',
                     f'=I{k}*E{k}'])
    n = len(GARDEN) + 1
    rows.append(['Total', '', '', '', '', '', '', '', f'=SUM(I2:I{n})', f'=SUM(J2:J{n})'])
    cells = []
    for k in range(2, n + 1):
        cells += [f'F{k}', f'G{k}', f'H{k}', f'I{k}', f'J{k}']
    cells += [f'I{n + 1}', f'J{n + 1}']
    return B.report('lesson 18 — the garden stock page', rows, cells,
                    ['=B5*E5', '=ROUND(G5/365*12,1)'])


def campaign():
    c = CAMPAIGN
    rows = [['Group', 'Customers', 'Orders'],
            ['Campaign', c['customers'], c['orders']],
            ['Holdout', c['hold_customers'], c['hold_orders']],
            ['Average ticket', c['ticket']],
            ['Discount', c['discount']],
            ['Sending cost', c['sending']]]
    return B.report('lesson 18 — the campaign against its holdout', rows, [], [
        '=ROUND(C2/B2*100,2)',
        '=ROUND(C3/B3*100,2)',
        '=ROUND(B2*(C2/B2-C3/B3),0)',
        '=C2-ROUND(B2*(C2/B2-C3/B3),0)',
        '=C2*B4*B5+B6',
        '=ROUND((C2*B4*B5+B6)/C2,1)',
        '=ROUND((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3)),0)',
        '=ROUND((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3))/B4*100,1)',
        '=ROUND(B2*C3/B3,0)',
        '=C2*B4',
        '=ROUND(SQRT(C3/B3*(1-C3/B3)/B3)*100,2)',   # one standard error of the holdout's rate
    ])


def supplier():
    rows = [['Order', 'Ordered', 'Received', 'Days late', 'In full', 'On time', 'OTIF']]
    for k, (o, r, late) in enumerate(POS, start=2):
        rows.append([f'PO {k - 1}', o, r, late, f'=IF(C{k}>=B{k},1,0)', f'=IF(D{k}<=0,1,0)',
                     f'=E{k}*F{k}'])
    n = len(POS) + 1
    rows.append(['Total', f'=SUM(B2:B{n})', f'=SUM(C2:C{n})', '', f'=SUM(E2:E{n})',
                 f'=SUM(F2:F{n})', f'=SUM(G2:G{n})'])
    t = n + 1
    return B.report('lesson 18 — one supplier: fill rate against OTIF', rows,
                    [f'B{t}', f'C{t}', f'E{t}', f'F{t}', f'G{t}'] + [f'G{k}' for k in range(2, n + 1)],
                    [f'=ROUND(C{t}/B{t}*100,1)', f'=ROUND(E{t}/{len(POS)}*100,1)',
                     f'=ROUND(F{t}/{len(POS)}*100,1)', f'=ROUND(G{t}/{len(POS)}*100,1)',
                     f'=ROUND(SUM(D2:D{n})/{len(POS)},2)'])


# ------------------------------------------------------------------ figures

def stock_page(st):
    """The garden buyer's stock page, drawn from the stock sheet's own numbers."""
    f = B.Fig('l18-stock-page', 720, 420, (
        'A mock of a stock page for the garden category, four weeks to Sunday 26 October 2025, '
        'updated Monday at 06:10. Four tiles across the top: 1 product out of stock; 1 with under '
        '14 days of cover; 1 with over 180 days of cover; estimated lost sales R$ 15.3 thousand. '
        'Below, a table of six products ordered by urgency: the hose reel is out of stock, with 10 '
        'days out and 47 units lost; the sprinkler has 6.7 days of cover; the clay pot has 560 days '
        'of cover; potting soil, pruning shears and the garden hose are fine.',
        'Maquete de uma página de estoque da categoria jardim, quatro semanas até domingo, 26 de '
        'outubro de 2025, atualizada segunda às 06:10. Quatro quadros no alto: 1 produto sem '
        'estoque; 1 com menos de 14 dias de cobertura; 1 com mais de 180 dias de cobertura; venda '
        'perdida estimada de R$ 15,3 mil. Abaixo, uma tabela de seis produtos em ordem de urgência: '
        'o enrolador com mangueira está sem estoque, com 10 dias em falta e 47 unidades perdidas; o '
        'aspersor tem 6,7 dias de cobertura; o vaso de barro tem 560 dias; a terra adubada, a '
        'tesoura de poda e a mangueira estão bem.'))
    f.rect(10, 10, 700, 400, fill='--ink', stroke='--wire', sw=1)
    f.text(28, 40, ('Garden · stock', 'Jardim · estoque'), size=15, weight=600)
    f.text(692, 34, ('four weeks to Sun 26 Oct 2025', 'quatro semanas até dom., 26/10/2025'),
           size=11, anchor='end', fill='--paper-dim')
    f.text(692, 50, ('updated Mon 27 Oct, 06:10', 'atualizado seg., 27/10, 06:10'),
           size=11, anchor='end', fill='--paper-dim')
    lost = st['J8']
    lost_k = round(int(lost) / 1000, 1)
    tiles = [
        ('1', ('out of stock', 'sem estoque'), '--amber'),
        ('1', ('cover under 14 days', 'cobertura abaixo de 14 dias'), '--amber'),
        ('1', ('cover over 180 days', 'cobertura acima de 180 dias'), '--phosphor'),
        ((f'R$ {B.fmt(lost_k, "en", 1)}k', f'R$ {B.fmt(lost_k, "pt", 1)} mil'),
         ('lost sales, estimated', 'venda perdida, estimada'), '--phosphor'),
    ]
    x = 28
    for big, small, stroke in tiles:
        f.rect(x, 66, 156, 76, fill='--panel', stroke=stroke)
        f.text(x + 12, 100, big, size=22, weight=600)
        f.text(x + 12, 126, small, size=11, fill='--paper-dim')
        x += 168
    # the table, exceptions first
    cols = [(28, 'start', ('product', 'produto')), (330, 'end', ('on hand', 'em estoque')),
            (440, 'end', ('days of cover', 'dias de cobertura')),
            (548, 'end', ('days out', 'dias em falta')), (566, 'start', ('status', 'situação'))]
    y = 176
    for cx, anchor, label in cols:
        f.text(cx, y, label, size=11, anchor=anchor, fill='--paper-dim')
    f.line(28, y + 8, 692, y + 8, stroke='--wire', sw=1)
    order = [0, 4, 3, 5, 2, 1]
    status = {0: (('out of stock', 'sem estoque'), '--amber'),
              4: (('reorder now', 'repor já'), '--amber'),
              3: (('overstock', 'excesso'), '--phosphor')}
    y += 32
    for i in order:
        name, onhand, sold, din, price = GARDEN[i]
        k = i + 2
        cover = st[f'G{k}']
        f.text(28, y, name, size=12)
        f.text(330, y, (B.fmt(onhand, 'en'), B.fmt(onhand, 'pt')), size=12, anchor='end', mono=True)
        cv = float(cover)
        f.text(440, y, (B.fmt(cv, 'en', 1), B.fmt(cv, 'pt', 1)), size=12, anchor='end', mono=True)
        f.text(548, y, str(DAYS - din), size=12, anchor='end', mono=True)
        lab, colour = status.get(i, (('ok', 'ok'), None))
        if colour:
            f.bar(566, y - 10, 10, 10, fill=colour)
            f.text(584, y, lab, size=12)
        else:
            f.text(584, y, lab, size=12, fill='--paper-dim')
        y += 30
    f.text(28, 396, ('days of cover = units on hand ÷ units sold per day in stock',
                     'dias de cobertura = unidades em estoque ÷ vendas por dia com estoque'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'A stock page built for the person who buys the category. It opens on the exceptions, '
        'puts a money figure on the shelf that was empty, and leaves the products that are fine at '
        'the bottom.',
        'Uma página de estoque feita para quem compra a categoria. Ela abre nas exceções, põe um '
        'valor em reais na prateleira que ficou vazia e deixa no fim os produtos que estão bem.'))


def holdout_bars(cg):
    inc = int(cg['=ROUND(B2*(C2/B2-C3/B3),0)'])
    tot = CAMPAIGN['orders']
    anyway = tot - inc
    f = B.Fig('l18-holdout', 720, 260, (
        f'One horizontal bar for the {tot} orders placed by the campaign group. The larger part, '
        f'{anyway} orders, is what the holdout says the group would have placed anyway; the smaller '
        f'part, {inc} orders, is what the campaign added.',
        f'Uma barra horizontal com os {B.fmt(tot, "pt")} pedidos do grupo da campanha. A parte maior, '
        f'{B.fmt(anyway, "pt")} pedidos, é o que o grupo de controle diz que o grupo faria de qualquer '
        f'jeito; a parte menor, {inc} pedidos, é o que a campanha acrescentou.'))
    x0, x1 = 40, 680
    scale = (x1 - x0) / tot
    wa = anyway * scale
    f.text(x0, 40, (f'{B.fmt(tot, "en")} orders from the campaign group, two weeks',
                    f'{B.fmt(tot, "pt")} pedidos do grupo da campanha, duas semanas'), size=13, weight=600)
    f.bar(x0, 60, wa, 56, fill='--scan')
    f.bar(x0 + wa, 60, tot * scale - wa, 56, fill='--amber')
    f.rect(x0, 60, x1 - x0, 56, fill='none', stroke='--paper-dim', sw=1)
    f.text(x0, 140, (f'{B.fmt(anyway, "en")} would have happened anyway',
                     f'{B.fmt(anyway, "pt")} aconteceriam de qualquer jeito'), size=12)
    hr = float(cg['=ROUND(C3/B3*100,2)'])
    cr = float(cg['=ROUND(C2/B2*100,2)'])
    cust = CAMPAIGN['customers']
    f.text(x0, 158, (f'the holdout bought at {hr:.2f}%: {B.fmt(cust, "en")} × {hr:.2f}%',
                     f'o controle comprou a {B.fmt(hr, "pt", 2)}%: {B.fmt(cust, "pt")} × '
                     f'{B.fmt(hr, "pt", 2)}%'), size=11, fill='--paper-dim')
    f.text(x1, 140, (f'{inc} caused by the campaign', f'{inc} causados pela campanha'), size=12,
           anchor='end')
    d = cr - hr
    f.text(x1, 158, (f'{cr:.2f}% − {hr:.2f}% = {d:.2f} points',
                     f'{B.fmt(cr, "pt", 2)}% − {B.fmt(hr, "pt", 2)}% = {B.fmt(d, "pt", 2)} ponto'), size=11,
           anchor='end', fill='--paper-dim')
    f.text(360, 214, (f'the 15% discount went to all {B.fmt(tot, "en")}; the campaign changed what {inc} did',
                      f'o desconto de 15% foi para os {B.fmt(tot, "pt")}; a campanha mudou o que {inc} fizeram'),
           size=12, anchor='middle', fill='--paper')
    pi = cg['=ROUND((C2*B4*B5+B6)/(B2*(C2/B2-C3/B3)),0)']
    pc = round(float(cg['=ROUND((C2*B4*B5+B6)/C2,1)']))
    f.text(360, 236, (f'cost per incremental order: R$ {pi}, against R$ {pc} per campaign order',
                      f'custo por pedido incremental: R$ {pi}, contra R$ {pc} por pedido da campanha'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'The campaign group\'s orders split by what the holdout shows. Most of them would have come '
        'anyway, and they were given the discount too.',
        'Os pedidos do grupo da campanha divididos pelo que o grupo de controle mostra. A maioria '
        'viria de qualquer jeito, e também levou o desconto.'))


def exercises():
    """Numbers the lesson's questions use that the sections do not print."""
    rows = [['Group', 'Customers', 'Orders'], ['Campaign', 50000, 1500], ['Holdout', 5000, 130]]
    return B.report('lesson 18 — exercise: another campaign against its holdout', rows, [],
                    ['=ROUND(B2*(C2/B2-C3/B3),0)', '=ROUND(C2/B2*100,2)', '=ROUND(C3/B3*100,2)'])


def main():
    exercises()
    like_for_like()
    st = stock()
    cg = campaign()
    supplier()
    stock_page(st)
    holdout_bars(cg)


if __name__ == '__main__':
    main()
