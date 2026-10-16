"""Lesson 9: prescriptive analysis. A reorder point for the garden-hose reel at
the warehouse in Contagem, and what a longer lead time does to it; three options
for a December promotion, with sales, profit and the volume each discount needs
to break even; the stock drawn over six weeks."""
import book as B

LESSON = 'le-syjt29mg'

# Reels shipped from the warehouse on each of 14 days in September 2025.
DAILY = [15, 19, 17, 22, 16, 18, 20, 14, 19, 21, 17, 18, 16, 20]
LEAD, SAFETY_DAYS = 7, 4          # supplier's lead time; the longest a delivery ran late
LEAD_NEW = 10
ORDER = 360                       # reels per order: twenty days of demand

# The December promotion on the four-seat garden set.
PRICE, COST = 1000, 600
OPTIONS = [('No discount', 0, 400), ('10% off', 10, 520), ('20% off', 20, 700)]


def reorder():
    rows = [['Day', 'Reels']] + [[k + 1, v] for k, v in enumerate(DAILY)]
    n = len(DAILY) + 1
    rows += [['Average', f'=ROUND(AVERAGE(B2:B{n}),0)'],
             ['Highest', f'=MAX(B2:B{n})'],
             ['Lead time', LEAD],
             ['Safety days', SAFETY_DAYS],
             ['Reorder point', f'=B{n + 1}*(B{n + 3}+B{n + 4})']]
    cells = [f'B{n + 1}', f'B{n + 2}', f'B{n + 5}']
    return B.report('lesson 9 — the reorder point', rows, cells, [
        f'=SUM(B2:B{n})',
        '=18*7', '=18*4', '=18*(7+4)',
        '=18*(10+4)',
        '=198/18',
        '=10+4',
        '=(10+4-198/18)*18',
        '=252-198',
    ])


def promotion():
    rows = [['Option', 'Price', 'Units', 'Sales', 'Profit', 'Units to match']]
    for k, (name, off, units) in enumerate(OPTIONS):
        r = k + 2
        rows.append([name, f'={PRICE}*(1-{off}/100)', units, f'=B{r}*C{r}/1000',
                     f'=(B{r}-{COST})*C{r}/1000', f'=ROUND($E$2*1000/(B{r}-{COST}),0)'])
    cells = [f'{c}{r}' for r in range(2, 5) for c in 'BDEF']
    got = B.report('lesson 9 — three options for December', rows, cells, [
        '=ROUND((D4/D2-1)*100,1)', '=ROUND((E4/E2-1)*100,1)',
        '=ROUND((D3/D2-1)*100,1)', '=ROUND((E3/E2-1)*100,1)',
        '=(900-600)*540/1000', '=(800-600)*800/1000',
        '=1000-600', '=900-600', '=800-600',
        '=ROUND(100*(1000-600)/1000,0)',
        '=E2-E4', '=F3-C3', '=F4-C4',
    ])
    return got


def questions():
    return B.report('lesson 9 — the exercises', [['a']], [], [
        '=25*(6+3)', '=(1200-700)*50', '=ROUND(40000/(1100-700),0)', '=12*(5+2)',
    ])


def stock_figure():
    # A simulation of the stock: 18 reels a day, an order of 360 placed when the
    # stock reaches the reorder point, arriving after the lead time.
    def simulate(lead, days=42, start=396, rop=198):
        level, out, pending, orders, lowest = start, [], [], [], start
        for d in range(days + 1):
            for p in list(pending):
                if p == d:
                    level += ORDER
                    pending.remove(p)
            out.append(level)
            if level <= rop and not pending:
                pending.append(d + lead)
                orders.append(d)
            level = max(level - 18, 0)
        return out, orders
    s7, o7 = simulate(LEAD)
    s10, o10 = simulate(LEAD_NEW)
    def low(series):
        return min(series[d - 1] - 18 for d in range(1, len(series)) if series[d] > series[d - 1])
    print('--- lesson 9 — the stock drawn')
    print('  stock left when a delivery arrives: lead 7 ->', low(s7), ' lead 10 ->', low(s10))
    print('  lead 7 :', s7[:30], 'orders on', o7, 'lowest', min(s7[5:]))
    print('  lead 10:', s10[:30], 'orders on', o10, 'lowest', min(s10[5:]),
          'days at zero', sum(1 for v in s10 if v == 0))
    f = B.Fig('l09-stock', 720, 330, (
        'A line of the reels in stock over six weeks. It falls by 18 a day from 396. Each time it reaches '
        'the reorder point of 198, a dashed line, an order of 360 is placed. With a seven-day lead time the '
        'delivery arrives with 72 reels still on the shelf, the safety stock. A second line, for a ten-day '
        'lead time and the same reorder point, is down to 18 reels, one day of sales, when each delivery '
        'arrives.',
        'Uma linha dos carretéis em estoque ao longo de seis semanas. Ela cai 18 por dia a partir de 396. '
        'Toda vez que chega ao ponto de pedido de 198, uma linha tracejada, sai um pedido de 360. Com sete '
        'dias de prazo, a entrega chega com 72 carretéis ainda na prateleira, o estoque de segurança. Uma '
        'segunda linha, para dez dias de prazo e o mesmo ponto de pedido, está em 18 carretéis, um dia de '
        'vendas, quando cada entrega chega.'))
    x0, x1, y0, y1 = 60, 700, 40, 260
    days, top = 42, 600
    sx, sy = (x1 - x0) / days, (y1 - y0) / top

    def X(d):
        return x0 + d * sx

    def Y(v):
        return y1 - v * sy
    for v in (0, 200, 400, 600):
        f.line(x0, Y(v), x1, Y(v), stroke='--wire', sw=1)
        f.text(x0 - 8, Y(v) + 4, str(v), size=11, anchor='end', fill='--paper-dim', mono=True)
    for d in (0, 7, 14, 21, 28, 35, 42):
        f.text(X(d), y1 + 18, str(d), size=11, anchor='middle', fill='--paper-dim', mono=True)
    f.text((x0 + x1) / 2, y1 + 38, ('days', 'dias'), size=11, anchor='middle', fill='--paper-dim')

    def saw(series, stroke, sw, dash=None):
        pts = []
        for d, v in enumerate(series):
            if d and v > series[d - 1]:
                pts.append((d, series[d - 1] - 18 if series[d - 1] >= 18 else 0))
            pts.append((d, v))
        dd = 'M' + ' L'.join(f'{X(d):.1f} {Y(v):.1f}' for d, v in pts)
        f.path(dd, stroke=stroke, sw=sw, dash=dash)
    f.line(x0, Y(198), x1, Y(198), stroke='--paper-dim', sw=1.5, dash='6 4')
    f.text(x0 + 6, Y(198) - 6, ('reorder point: 198', 'ponto de pedido: 198'), size=11, anchor='start')
    saw(s10, '--amber', 2, dash='5 3')
    saw(s7, '--phosphor', 2.5)
    for d in o7:
        f.arrow(X(d), Y(198) + 34, X(d), Y(198) + 6, stroke='--paper')
    f.text(X(o7[0]) + 6, Y(198) + 44, ('order 360', 'pedido de 360'), size=11)
    # legend
    f.line(x0 + 10, 18, x0 + 34, 18, stroke='--phosphor', sw=2.5)
    f.text(x0 + 40, 22, ('lead time 7 days: lowest 72', 'prazo de 7 dias: mínimo de 72'), size=11)
    f.line(x0 + 330, 18, x0 + 354, 18, stroke='--amber', sw=2, dash='5 3')
    f.text(x0 + 360, 22, ('lead time 10 days, same point: lowest 18', 'prazo de 10 dias, mesmo ponto: mínimo de 18'),
           size=11)
    B.place(LESSON, f, (
        'The reorder rule over six weeks. The point of 198 leaves four days of safety when the supplier '
        'takes seven days. When the supplier takes ten and nobody changes the point, one day is left, and '
        'any late delivery empties the shelf.',
        'A regra de reposição em seis semanas. O ponto de 198 deixa quatro dias de folga quando o '
        'fornecedor leva sete dias. Quando o fornecedor passa a levar dez e ninguém muda o ponto, sobra um '
        'dia, e qualquer entrega atrasada esvazia a prateleira.'))


def options_figure():
    f = B.Fig('l09-options', 720, 300, (
        'Three pairs of bars for the December promotion on the garden set. No discount: sales of 400 '
        'thousand reais and profit of 160 thousand. Ten per cent off: sales of 468 thousand and profit '
        'of 156 thousand. Twenty per cent off: sales of 560 thousand and profit of 140 thousand. Sales '
        'rise from left to right and profit falls.',
        'Três pares de barras para a promoção de dezembro do jogo de jardim. Sem desconto: vendas de 400 '
        'mil reais e lucro de 160 mil. Dez por cento: vendas de 468 mil e lucro de 156 mil. Vinte por '
        'cento: vendas de 560 mil e lucro de 140 mil. As vendas sobem da esquerda para a direita e o '
        'lucro cai.'))
    data = [(('no discount', 'sem desconto'), 400, 160), (('10% off', '10% de desconto'), 468, 156),
            (('20% off', '20% de desconto'), 560, 140)]
    x0, x1, y0, y1 = 70, 700, 40, 240
    top = 600
    sy = (y1 - y0) / top
    for v in (0, 200, 400, 600):
        f.line(x0, y1 - v * sy, x1, y1 - v * sy, stroke='--wire', sw=1)
        f.text(x0 - 8, y1 - v * sy + 4, str(v), size=11, anchor='end', fill='--paper-dim', mono=True)
    gw = (x1 - x0) / 3
    bw = 56
    for k, (label, sales, profit) in enumerate(data):
        gx = x0 + k * gw + gw / 2
        f.bar(gx - bw - 4, y1 - sales * sy, bw, sales * sy, fill='--phosphor')
        f.bar(gx + 4, y1 - profit * sy, bw, profit * sy, fill='--amber')
        f.text(gx - bw / 2 - 4, y1 - sales * sy - 6, str(sales), size=11, anchor='middle', mono=True)
        f.text(gx + bw / 2 + 4, y1 - profit * sy - 6, str(profit), size=11, anchor='middle', mono=True)
        f.text(gx, y1 + 20, label, size=12, anchor='middle')
    f.bar(x0, 12, 14, 14, fill='--phosphor')
    f.text(x0 + 20, 24, ('sales', 'vendas'), size=12)
    f.bar(x0 + 100, 12, 14, 14, fill='--amber')
    f.text(x0 + 120, 24, ('profit', 'lucro'), size=12)
    f.text(x1, 24, ('thousands of reais', 'milhares de reais'), size=11, anchor='end', fill='--paper-dim')
    f.text(x1, 290, ('the option that sells most earns least', 'a opção que mais vende é a que menos lucra'),
           size=12, anchor='end', fill='--paper-dim')
    B.place(LESSON, f, (
        'Three options for December, on Varanda\'s own estimates of how many sets each would sell. The '
        'best option for sales and the best for profit are at opposite ends.',
        'Três opções para dezembro, com as estimativas da própria Varanda de quantos jogos cada uma '
        'venderia. A melhor opção para as vendas e a melhor para o lucro ficam em pontas opostas.'))


def main():
    reorder()
    promotion()
    questions()
    stock_figure()
    options_figure()


if __name__ == '__main__':
    main()
