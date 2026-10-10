"""Lesson 7: diagnostic analysis. October 2025 against October 2024, broken down
by store and channel and into orders and average ticket; where the change sits;
the suspects tested; October and November taken together."""
import book as B

LESSON = 'le-x7h26kcp'

# October, by store and for the online shop, in thousands of reais. The stores
# are each a little above October 2024; the online shop is not.
OCT = [
    ('Savassi', 950, 993),
    ('Pampulha', 848, 882),
    ('Contagem', 1036, 1042),
    ('Betim', 716, 738),
    ('Nova Lima', 750, 789),
    ('Sete Lagoas', 545, 561),
    ('Divinópolis', 520, 539),
    ('Ipatinga', 562, 588),
    ('Juiz de Fora', 723, 748),
    ('Online', 1370, 1080),
]
NOV_ONLINE = (1660, 2060)            # November's online shop, 2024 and 2025
# Orders: receipts in the stores, paid orders online.
ORDERS = {'stores': (17500, 17920), 'online': (3914, 3086)}
# The online shop's October 2024, split at the campaign: 1-20 October without,
# 21-31 October with. October 2025 had no campaign day.
SPLIT_2024 = ((20, 1760), (11, 2154))

assert sum(a for _, a, _ in OCT) == B.SALES_2024[9]
assert sum(b for _, _, b in OCT) == B.SALES_2025[9]


def october():
    rows = [['Line', 'Oct 2024', 'Oct 2025', 'Change', 'Points']]
    for k, (n, a, b) in enumerate(OCT):
        r = k + 2
        rows.append([n, a, b, f'=C{r}-B{r}', f'=ROUND(D{r}/B$12*100,1)'])
    rows.append(['Total', '=SUM(B2:B11)', '=SUM(C2:C11)', '=C12-B12', '=ROUND((C12/B12-1)*100,1)'])
    cells = ['B12', 'C12', 'D12', 'E12'] + [f'D{r}' for r in range(2, 12)] + [f'E{r}' for r in range(2, 12)]
    return B.report('lesson 7 — October by store and channel', rows, cells, [
        '=SUM(E2:E10)',
        '=SUM(E2:E11)',
        '=SUM(D2:D10)',
        '=ROUND((SUM(C2:C10)/SUM(B2:B10)-1)*100,1)',
        '=ROUND((C11/B11-1)*100,1)',
        '=ROUND(SUM(D2:D10)/B12*100,2)',
        '=ROUND(D11/B12*100,2)',
        '=SUM(B2:B10)',
        '=SUM(C2:C10)',
    ])


def orders():
    so, oo = ORDERS['stores'], ORDERS['online']
    rows = [['', 'Oct 2024', 'Oct 2025'],
            ['Store sales', 6650, 6880], ['Store receipts', so[0], so[1]],
            ['Online sales', 1370, 1080], ['Online orders', oo[0], oo[1]]]
    return B.report('lesson 7 — orders times average ticket', rows, [], [
        '=ROUND(B2*1000/B3,0)', '=ROUND(C2*1000/C3,0)',
        '=ROUND(B4*1000/B5,0)', '=ROUND(C4*1000/C5,0)',
        '=ROUND((C3/B3-1)*100,1)', '=ROUND((C5/B5-1)*100,1)',
        '=ROUND(((C2*1000/C3)/(B2*1000/B3)-1)*100,1)',
        '=ROUND(((C4*1000/C5)/(B4*1000/B5)-1)*100,1)',
        '=ROUND((C2/B2-1)*100,1)', '=ROUND((C4/B4-1)*100,1)',
    ])


def suspects():
    (d1, o1), (d2, o2) = SPLIT_2024
    rows = [['', 'days', 'orders'],
            ['Oct 2024, 1-20, no campaign', d1, o1],
            ['Oct 2024, 21-31, campaign', d2, o2],
            ['Oct 2025, 1-31, no campaign', 31, ORDERS['online'][1]]]
    got = B.report('lesson 7 — online orders a day, with and without the campaign', rows, [], [
        '=ROUND(C2/B2,1)', '=ROUND(C3/B3,1)', '=ROUND(C4/B4,1)',
        '=ROUND((C4/B4)/(C2/B2)*100-100,1)', '=C2+C3',
    ])
    n24, n25 = NOV_ONLINE
    rows = [['', '2024', '2025'],
            ['Oct, all', B.SALES_2024[9], B.SALES_2025[9]],
            ['Nov, all', B.SALES_2024[10], B.SALES_2025[10]],
            ['Oct, online', 1370, 1080],
            ['Nov, online', n24, n25]]
    got2 = B.report('lesson 7 — October and November together', rows, [], [
        '=B2+B3', '=C2+C3', '=ROUND(((C2+C3)/(B2+B3)-1)*100,1)',
        '=B4+B5', '=C4+C5', '=ROUND(((C4+C5)/(B4+B5)-1)*100,1)',
        '=ROUND((C5/B5-1)*100,1)', '=ROUND((C3/B3-1)*100,1)',
        '=ROUND(((C2-C4+C3-C5)/(B2-B4+B3-B5)-1)*100,1)',
    ])
    return got, got2


def questions():
    return B.report('lesson 7 — the exercises', [['a']], [], [
        '=ROUND(-290/8020*100,1)', '=ROUND(2400*350/1000,0)',
        '=ROUND(2400*450/1000,0)',
        '=ROUND((1250/1300-1)*100,1)',
        '=ROUND((180-150)/1200*100,1)',
        '=ROUND((789/750-1)*100,1)',
        '=ROUND((1042/1036-1)*100,1)',
        '=75*0.5',
        '=3914-3086', '=ROUND(1370*1000/3914,2)', '=ROUND(1080*1000/3086,2)',
    ])


def tree():
    f = B.Fig('l07-tree', 720, 330, (
        'A tree. At the top, October 2025: R$ 7,960 thousand, down 0.7% on October 2024. It splits '
        'into the stores, R$ 6,880 thousand, up 3.5%, and the online shop, R$ 1,080 thousand, down '
        '21.2%. The stores split into 17,920 receipts, up 2.4%, times an average ticket of R$ 384, up '
        '1.0%. The online shop splits into 3,086 orders, down 21.2%, times an average ticket of R$ 350, '
        'unchanged.',
        'Uma árvore. No topo, outubro de 2025: R$ 7.960 mil, 0,7% abaixo de outubro de 2024. Ela se '
        'divide nas lojas, R$ 6.880 mil, alta de 3,5%, e na loja online, R$ 1.080 mil, queda de 21,2%. '
        'As lojas se dividem em 17.920 cupons, alta de 2,4%, vezes um tíquete médio de R$ 384, alta de '
        '1,0%. A loja online se divide em 3.086 pedidos, queda de 21,2%, vezes um tíquete médio de '
        'R$ 350, sem mudança.'))

    def node(cx, y, w, title, value, change, hot=False):
        x = cx - w / 2
        f.rect(x, y, w, 64, fill='--panel', stroke='--amber' if hot else '--phosphor')
        f.text(cx, y + 20, title, size=12, anchor='middle', fill='--paper-dim')
        f.text(cx, y + 39, value, size=13, anchor='middle', weight=600)
        f.text(cx, y + 56, change, size=12, anchor='middle', fill='--paper' if hot else '--paper-dim')

    node(360, 14, 220, ('October 2025, all', 'outubro de 2025, tudo'), ('R$ 7,960 thousand', 'R$ 7.960 mil'),
         ('−0.7% on Oct 2024', '−0,7% sobre out/2024'))
    node(190, 124, 200, ('the nine stores', 'as nove lojas'), ('R$ 6,880 thousand', 'R$ 6.880 mil'),
         ('+3.5%', '+3,5%'))
    node(540, 124, 200, ('the online shop', 'a loja online'), ('R$ 1,080 thousand', 'R$ 1.080 mil'),
         ('−21.2%', '−21,2%'), hot=True)
    node(100, 240, 160, ('receipts', 'cupons'), ('17,920', '17.920'), ('+2.4%', '+2,4%'))
    node(280, 240, 160, ('average ticket', 'tíquete médio'), ('R$ 384', 'R$ 384'), ('+1.0%', '+1,0%'))
    node(450, 240, 160, ('orders', 'pedidos'), ('3,086', '3.086'), ('−21.2%', '−21,2%'), hot=True)
    node(630, 240, 160, ('average ticket', 'tíquete médio'), ('R$ 350', 'R$ 350'), ('0.0%', '0,0%'))
    # top to the two channels
    f.line(360, 78, 360, 100)
    f.line(190, 100, 540, 100)
    f.line(190, 100, 190, 122)
    f.line(540, 100, 540, 122)
    # channels to their two factors
    for cx, a, b in ((190, 100, 280), (540, 450, 630)):
        f.line(cx, 188, cx, 214)
        f.line(a, 214, b, 214)
        f.line(a, 214, a, 238)
        f.line(b, 214, b, 238)
        f.text((a + b) / 2, 278, '×', size=16, anchor='middle', fill='--paper-dim', mono=True)
    B.place(LESSON, f, (
        'October 2025 broken down twice: by channel, then each channel into orders and average ticket. '
        'The fall sits in one branch, and in one factor of it: online orders.',
        'Outubro de 2025 decomposto duas vezes: por canal, e depois cada canal em pedidos e tíquete '
        'médio. A queda está num galho só, e num fator dele: os pedidos online.'))


def bars():
    pts = []
    for n, a, b in OCT:
        pts.append((n, (b - a) / B.SALES_2024[9] * 100))
    f = B.Fig('l07-points', 720, 352, (
        'Horizontal bars, one per line of the October table, showing how many percentage points each '
        'added to or took from the total change of −0.7%. Each of the nine stores adds between 0.1 and '
        '0.5 points. The online shop takes away 3.6 points.',
        'Barras horizontais, uma por linha da tabela de outubro, mostrando quantos pontos percentuais '
        'cada uma somou ou tirou da variação total de −0,7%. Cada uma das nove lojas soma entre 0,1 e '
        '0,5 ponto. A loja online tira 3,6 pontos.'))
    zero, scale = 470, 52                 # x of zero; px per point
    top, row = 28, 26
    f.line(zero, top - 8, zero, top + row * len(pts) + 2, stroke='--paper-dim', sw=1)
    for k, (n, p) in enumerate(pts):
        y = top + k * row
        label = ('Online', 'Online') if n == 'Online' else n
        f.text(150, y + 14, label, size=12, anchor='end')
        w = abs(p) * scale
        if p >= 0:
            f.bar(zero, y + 3, w, 16, fill='--phosphor')
            f.text(zero + w + 6, y + 15, (f'+{p:.1f}', f'+{p:.1f}'.replace('.', ',')), size=11,
                   fill='--paper-dim', mono=True)
        else:
            f.bar(zero - w, y + 3, w, 16, fill='--amber')
            f.text(zero - w - 6, y + 15, (f'−{-p:.1f}', f'−{-p:.1f}'.replace('.', ',')), size=11,
                   anchor='end', fill='--paper-dim', mono=True)
    yb = top + row * len(pts) + 26
    f.text(zero, yb, ('percentage points of October\'s −0.7%', 'pontos percentuais dos −0,7% de outubro'),
           size=12, anchor='middle', fill='--paper-dim')
    f.text(zero - 16, yb + 22, ('stores together: +2.9', 'lojas juntas: +2,9'), size=12, anchor='end',
           weight=600)
    f.text(zero + 16, yb + 22, ('online: −3.6', 'online: −3,6'), size=12, anchor='start', weight=600)
    B.place(LESSON, f, (
        'Where October\'s change sits. Every store added a little; the online shop took away more than '
        'all nine added together.',
        'Onde está a variação de outubro. Cada loja somou um pouco; a loja online tirou mais do que as '
        'nove somaram juntas.'))


def main():
    october()
    orders()
    suspects()
    questions()
    tree()
    bars()


if __name__ == '__main__':
    main()
