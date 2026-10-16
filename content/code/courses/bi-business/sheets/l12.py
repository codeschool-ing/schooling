"""Lesson 12: twelve orders and the average that two of them make, a total that only
grows, one complaint rate that falls and rises at once, two stores where the better
one in every kind of delivery is worse overall, and rates on bases too small to bear
them. Figures: the twelve orders on one axis, and the two stores by kind."""
import book as B

LESSON = 'le-xtd27pvw'

# Online orders in the week of 9 to 15 March 2026, in reais. The last two are an
# architect's office furnishing a hotel.
ORDERS = [189, 245, 312, 278, 420, 156, 365, 298, 540, 233, 18400, 9850]

# Registered customers (all time) and active customers (bought in the last 12 months),
# at the end of each quarter of 2025.
QUARTERS = [('Q1', 188300, 61200), ('Q2', 195900, 60400), ('Q3', 203700, 58900),
            ('Q4', 212400, 57800)]

# The online shop in November, 2024 and 2025.
NOV = [('Nov 2024', 5000, 4000, 150), ('Nov 2025', 8000, 4400, 210)]

# Home deliveries in February 2026, by store and kind: (store, kind, deliveries, on time).
STORES = [('Contagem', 'furniture', 400, 300), ('Contagem', 'parcels', 100, 95),
          ('Savassi', 'furniture', 100, 70), ('Savassi', 'parcels', 400, 360)]


def average():
    rows = [['Order', 'Value']] + [[k + 1, v] for k, v in enumerate(ORDERS)]
    return B.report('lesson 12 — twelve orders and their average', rows, [],
                    ['=SUM(B2:B13)', '=ROUND(AVERAGE(B2:B13),0)', '=MEDIAN(B2:B13)',
                     '=ROUND(AVERAGE(B2:B11),0)', '=MEDIAN(B2:B11)',
                     '=ROUND((B12+B13)/SUM(B2:B13)*100,1)', '=COUNT(B2:B13)',
                     '=ROUND(AVERAGE(B2:B12),0)'])


def vanity():
    rows = [['Quarter', 'Registered', 'Active']] + [list(q) for q in QUARTERS]
    return B.report('lesson 12 — a total that only grows', rows, [],
                    ['=ROUND(C2/B2*100,1)', '=ROUND(C3/B3*100,1)', '=ROUND(C4/B4*100,1)',
                     '=ROUND(C5/B5*100,1)', '=B5-B2', '=C5-C2',
                     '=ROUND((B5/B2-1)*100,1)', '=ROUND((C5/C2-1)*100,1)'])


def denominators():
    rows = [['Month', 'Orders', 'Customers', 'Complaints']] + [list(r) for r in NOV]
    got = B.report('lesson 12 — one complaint rate, two denominators', rows, [],
                   ['=ROUND((B3/B2-1)*100,1)', '=ROUND((C3/C2-1)*100,1)',
                    '=ROUND((D3/D2-1)*100,1)',
                    '=ROUND(D2/B2*100,1)', '=ROUND(D3/B3*100,1)',
                    '=ROUND(D2/C2*100,1)', '=ROUND(D3/C3*100,1)',
                    '=ROUND(B2/C2,2)', '=ROUND(B3/C3,2)'])
    # conversion that rose because traffic fell
    conv = [['', 'Visits', 'Orders'], ['Before', 300000, 3750], ['After', 210000, 3375]]
    B.report('lesson 12 — conversion up, because visits fell', conv, [],
             ['=ROUND(C2/B2*100,2)', '=ROUND(C3/B3*100,2)', '=ROUND((B3/B2-1)*100,1)',
              '=ROUND((C3/C2-1)*100,1)'])
    return got


def simpson():
    rows = [['Store', 'Kind', 'Deliveries', 'On time']] + [list(r) for r in STORES]
    for k in range(2, 6):
        rows[k - 1].append(f'=ROUND(D{k}/C{k}*100,1)')
    rows[0].append('Rate')
    got = B.report('lesson 12 — two stores, two kinds of delivery', rows,
                   ['E2', 'E3', 'E4', 'E5'],
                   ['=ROUND((D2+D3)/(C2+C3)*100,1)', '=ROUND((D4+D5)/(C4+C5)*100,1)',
                    '=ROUND(C2/(C2+C3)*100,0)', '=ROUND(C4/(C4+C5)*100,0)',
                    '=ROUND((E2+E3)/2,1)', '=ROUND((E4+E5)/2,1)'])
    return got


def small():
    rows = [['', 'Before', 'After'], ['Complaints', 1, 3], ['Sold', 12, 12],
            ['On promise %', 76.9, 86.2]]
    return B.report('lesson 12 — small bases, and points against percent', rows, [],
                    ['=ROUND((C2/B2-1)*100,0)', '=ROUND(B2/B3*100,1)', '=ROUND(C2/C3*100,1)',
                     '=ROUND(2/12*100,1)', '=ROUND(1/12*100,1)',
                     '=C4-B4', '=ROUND((C4/B4-1)*100,1)',
                     '=ROUND((1.5/1.25-1)*100,0)', '=1.5-1.25'])


def strip(got):
    f = B.Fig('l12-orders', 720, 200, (
        'Twelve orders as dots on one line from 0 to 20,000 reais. Ten sit crowded together at '
        'the far left, all below 600 reais. Two sit far to the right, at 9,850 and 18,400. The '
        'median, 305 reais, is marked inside the crowd; the mean, 2,607 reais, is marked in the '
        'empty space between the crowd and the two large orders, where no order is.',
        'Doze pedidos como pontos numa linha de 0 a 20.000 reais. Dez ficam amontoados na ponta '
        'esquerda, todos abaixo de 600 reais. Dois ficam longe, à direita, em 9.850 e 18.400. A '
        'mediana, 305 reais, está marcada dentro do amontoado; a média, 2.607 reais, está marcada '
        'no espaço vazio entre o amontoado e os dois pedidos grandes, onde não há pedido nenhum.'))
    x0, x1, top = 40, 680, 96

    def X(v):
        return x0 + (x1 - x0) * v / 20000
    f.line(x0, top, x1, top, stroke='--paper-dim', sw=1)
    for t in range(0, 20001, 5000):
        f.line(X(t), top, X(t), top + 6, stroke='--paper-dim', sw=1)
        f.text(X(t), top + 22, (B.fmt(t), B.fmt(t, 'pt')), size=11, anchor='middle',
               fill='--paper-dim')
    f.text(x1, top + 42, ('reais per order', 'reais por pedido'), size=11, anchor='end',
           fill='--paper-dim')
    for k, v in enumerate(ORDERS):
        y = top - 10 - (k % 5) * 7 if v < 1000 else top - 10
        f.path(f'M{X(v) - 4:.1f} {y:.1f} a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0', stroke='none', sw=0,
               fill='--phosphor')
    mean = float(got['=ROUND(AVERAGE(B2:B13),0)'])
    med = float(got['=MEDIAN(B2:B13)'])
    f.line(X(mean), 30, X(mean), top, stroke='--amber', sw=2)
    f.text(X(mean) + 8, 34, (f'mean R$ {B.fmt(mean)}', f'média R$ {B.fmt(mean, "pt")}'), size=12,
           weight=600)
    f.text(X(mean) + 8, 50, ('no order is near it', 'nenhum pedido perto dela'), size=11,
           fill='--paper-dim')
    f.line(X(med), 152, X(med), top + 30, stroke='--paper', sw=1.5)
    f.text(X(med) - 4, 172, (f'median R$ {B.fmt(med)}', f'mediana R$ {B.fmt(med, "pt")}'), size=12,
           weight=600)
    f.text(X(med) - 4, 188, ('half the orders below, half above', 'metade dos pedidos abaixo, metade acima'), size=11, fill='--paper-dim')
    f.text(X(14125), top - 22, ('the hotel\'s two orders', 'os dois pedidos do hotel'), size=11,
           anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'The week\'s twelve orders. Ten of them, every ordinary customer, fit in the first sliver '
        'of the axis. The mean sits where nobody bought anything.',
        'Os doze pedidos da semana. Dez deles, todos os clientes comuns, cabem no primeiro pedaço '
        'do eixo. A média fica onde ninguém comprou nada.'))


def bars(got):
    f = B.Fig('l12-simpson', 720, 330, (
        'Bars of on-time delivery rate for two stores. Furniture: Contagem 75%, Savassi 70%. '
        'Parcels: Contagem 95%, Savassi 90%. All deliveries: Contagem 79%, Savassi 86%. Contagem '
        'is ahead in each kind and behind overall. Under the bars, the mix: 80% of Contagem\'s '
        'deliveries are furniture, against 20% of Savassi\'s.',
        'Barras da taxa de entrega no prazo de duas lojas. Móveis: Contagem 75%, Savassi 70%. '
        'Pacotes: Contagem 95%, Savassi 90%. Todas as entregas: Contagem 79%, Savassi 86%. Contagem '
        'está à frente em cada tipo e atrás no total. Abaixo das barras, o mix: 80% das entregas de '
        'Contagem são móveis, contra 20% das de Savassi.'))
    base, scale = 250, 2.0      # 100% = 200 px
    groups = [(('furniture', 'móveis'), got['E2'], got['E4']),
              (('parcels', 'pacotes'), got['E3'], got['E5']),
              (('all deliveries', 'todas as entregas'), got['=ROUND((D2+D3)/(C2+C3)*100,1)'],
               got['=ROUND((D4+D5)/(C4+C5)*100,1)'])]
    for g, (name, a, b) in enumerate(groups):
        gx = 60 + g * 220
        for j, (v, fill) in enumerate(((a, '--phosphor'), (b, '--amber'))):
            v = float(v)
            x = gx + j * 74
            h = v * scale
            f.bar(x, base - h, 60, h, fill=fill)
            f.text(x + 30, base - h - 8, (f'{B.fmt(v)}%', f'{B.fmt(v, "pt")}%'), size=12,
                   anchor='middle', weight=600)
        f.text(gx + 67, base + 22, name, size=12, anchor='middle')
    f.line(40, base, 700, base, stroke='--paper-dim', sw=1)
    f.line(467, 30, 467, base + 30, stroke='--paper-dim', sw=1, dash='4 3')
    # legend
    f.bar(60, 290, 14, 14, fill='--phosphor')
    f.text(80, 302, ('Contagem: 80% of its deliveries are furniture',
                     'Contagem: 80% das entregas são móveis'), size=12)
    f.bar(400, 290, 14, 14, fill='--amber')
    f.text(420, 302, ('Savassi: 20% furniture', 'Savassi: 20% móveis'), size=12)
    B.place(LESSON, f, (
        'Contagem is ahead in each kind of delivery and behind in the total. The total is an '
        'average of the two kinds, weighted by a mix the two stores do not share.',
        'Contagem está à frente em cada tipo de entrega e atrás no total. O total é uma média dos '
        'dois tipos, pesada por um mix que as duas lojas não compartilham.'))


def main():
    got = average()
    vanity()
    denominators()
    s = simpson()
    small()
    strip(got)
    bars(s)


if __name__ == '__main__':
    main()
