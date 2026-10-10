"""Lesson 16: strategic BI. Varanda's five years, 2021 to 2025, as the board sees
them: sales nominal and in real terms (against an illustrative price index the
lesson gives and labels as such), the growth rate compounded over four years,
sales per square metre of store, the online share and sales per employee, each
against the plan the board approved. 2024 and 2025 are book.py's; Ipatinga, the
ninth store, opened in July 2024 (lesson 18), so 2021 to 2023 had eight."""
import book as B

LESSON = 'le-0km935vy'

YEARS = [2021, 2022, 2023, 2024, 2025]
SALES = [72.4, 80.1, 86.3, round(sum(B.SALES_2024) / 1000, 1), round(sum(B.SALES_2025) / 1000, 1)]
# An illustrative consumer price index, 2021 = 100. Not an official series.
INDEX = [100.0, 106.0, 110.8, 115.6, 120.4]
ONLINE = [9.1, 11.2, 12.9, 14.75, B.ONLINE_2025 / 1000]
# Average sales floor in the year, square metres: eight stores until mid-2024.
FLOOR_8 = sum(f for n, f, _ in B.STORES if n != 'Ipatinga')
FLOOR_IPA = dict((n, f) for n, f, _ in B.STORES)['Ipatinga']
FLOOR = [FLOOR_8, FLOOR_8, FLOOR_8, FLOOR_8 + FLOOR_IPA / 2, FLOOR_8 + FLOOR_IPA]
STAFF = [330, 350, 365, 395, 410]
IPATINGA_2025 = dict((n, s) for n, _, s in B.STORES)['Ipatinga'] / 1000
# What the board approved in 2022 for 2025.
PLAN = dict(sales=100.0, real_growth=4.0, per_m2=4300, online=18.0, per_staff=250)

assert SALES[3] == 92.7 and SALES[4] == 98.0


def growth():
    """The sheet the student types: year, sales, index; real sales and the CAGRs."""
    rows = [['Year', 'Sales', 'Index', 'Real', 'Growth %', 'Real growth %']]
    for k, (y, s, i) in enumerate(zip(YEARS, SALES, INDEX), start=2):
        rows.append([y, s, i, f'=ROUND(B{k}/C{k}*100,1)',
                     '' if k == 2 else f'=ROUND((B{k}/B{k - 1}-1)*100,1)',
                     '' if k == 2 else f'=ROUND((D{k}/D{k - 1}-1)*100,1)'])
    cells = [f'D{k}' for k in range(2, 7)] + [f'E{k}' for k in range(3, 7)] + [f'F{k}' for k in range(3, 7)]
    return B.report('lesson 16 — five years, nominal and real', rows, cells, [
        '=ROUND(((B6/B2)^(1/4)-1)*100,1)',
        '=ROUND(((D6/D2)^(1/4)-1)*100,1)',
        '=ROUND((B6/B2-1)*100,1)',
        '=ROUND((D6/D2-1)*100,1)',
        '=ROUND(((B6/B2)^(1/5)-1)*100,1)',          # the classic slip: five years, four steps
        '=ROUND(AVERAGE(E3:E6),1)',
        '=ROUND(72.4*1.079^4,1)',                    # checking the CAGR back
        f'=ROUND((((B6-{IPATINGA_2025})/B2)^(1/4)-1)*100,1)',
        '=ROUND((C6/C2-1)*100,1)',
        '=B6-B2', '=D6-D2', '=ROUND((D6-D2)/(B6-B2)*100,1)',
        '=ROUND((B6/B2-1)*100/4,1)', '=ROUND((C3/C2-1)*100,1)', '=ROUND((C6/C5-1)*100,1)',
    ])


def pack():
    """The board pack's five lines, year by year."""
    rows = [['Year', 'Sales', 'Online', 'Floor', 'Staff', 'Per m2', 'Online %', 'Per staff']]
    for k, (y, s, o, f, st) in enumerate(zip(YEARS, SALES, ONLINE, FLOOR, STAFF), start=2):
        rows.append([y, s, o, f, st, f'=ROUND((B{k}-C{k})*1000000/D{k},0)', f'=ROUND(C{k}/B{k}*100,1)',
                     f'=ROUND(B{k}*1000/E{k},0)'])
    cells = []
    for c in 'FGH':
        cells += [f'{c}{k}' for k in range(2, 7)]
    return B.report('lesson 16 — the board pack', rows, cells, [
        '=ROUND((F6/F4-1)*100,1)',
        '=ROUND((F6/F4)/(120.4/110.8)*100-100,1)',
        '=D6', '=D4',
        f'=ROUND((B6/{PLAN["sales"]}-1)*100,1)', f'={PLAN["online"]}-G6', f'=ROUND((H6/{PLAN["per_staff"]}-1)*100,1)',
        f'=ROUND((F6/{PLAN["per_m2"]}-1)*100,1)', f'=1.5-{PLAN["real_growth"]}',
    ])


def questions():
    return B.report('lesson 16 — the exercises', [['a']], [], [
        '=ROUND(((150/100)^(1/4)-1)*100,1)', '=ROUND(110/1.10,1)', '=ROUND(((121/100)^(1/2)-1)*100,1)',
        '=ROUND((1.08/1.05-1)*100,1)', '=ROUND((1.30/1.15-1)*100,1)', '=ROUND((1.06/1.04-1)*100,1)',
        '=ROUND(82.39*1000000/20500,0)'])


# ----------------------------------------------------------------- figures

def per_year():
    # Rounded to one decimal, as the student's column D is, so the growth figures match the sheet.
    real = [round(s / i * 100, 1) for s, i in zip(SALES, INDEX)]
    rg = [None] + [(real[k] / real[k - 1] - 1) * 100 for k in range(1, 5)]
    per_m2 = [(s - o) * 1e6 / f for s, o, f in zip(SALES, ONLINE, FLOOR)]
    share = [o / s * 100 for o, s in zip(ONLINE, SALES)]
    per_staff = [s * 1000 / st for s, st in zip(SALES, STAFF)]
    return real, rg, per_m2, share, per_staff


def board_figure():
    real, rg, per_m2, share, per_staff = per_year()

    def n(x, dp, lang):
        s = f'{x:,.{dp}f}'
        return B.fmt(x, 'pt', dp) if lang == 'pt' else s

    lines = [
        (('Sales, R$ million', 'Vendas, R$ milhões'), SALES, 1, PLAN['sales'], False,
         ('below plan', 'abaixo do plano')),
        (('Real growth, % a year', 'Crescimento real, % ao ano'), rg, 1, PLAN['real_growth'], False,
         ('below plan', 'abaixo do plano')),
        (('Store sales per m², R$', 'Vendas por m² de loja, R$'), per_m2, 0, PLAN['per_m2'], False,
         ('below plan; flat for three years', 'abaixo do plano; parada há três anos')),
        (('Online share of sales, %', 'Participação online, %'), share, 1, PLAN['online'], False,
         ('below plan; flat since 2024', 'abaixo do plano; parada desde 2024')),
        (('Sales per employee, R$ thousand', 'Vendas por funcionário, R$ mil'), per_staff, 0, PLAN['per_staff'],
         False, ('below plan', 'abaixo do plano')),
    ]
    f = B.Fig('l16-pack', 720, 420, (
        'A mock of the board pack page for 2025. Five rows, each with five yearly values from 2021 to '
        '2025, a small line of the trend, the 2025 plan and the gap to it. Sales: 72.4, 80.1, 86.3, 92.7, '
        '98.0 million against a plan of 100. Real growth: 4.4, 3.0, 3.0 and 1.5% a year from 2022, against '
        'a plan of 4. Store sales per square metre: 3,459, 3,765, 4,011, 4,018, 4,019 reais against 4,300. '
        'Online share: 12.6, 14.0, 14.9, 15.9, 15.9% against 18. Sales per employee: 219, 229, 236, 235, '
        '239 thousand reais against 250. Every row is below plan. A note says the price index is '
        'illustrative.',
        'Um esboço da página do pacote do conselho de 2025. Cinco linhas, cada uma com cinco valores anuais '
        'de 2021 a 2025, uma linha pequena da tendência, o plano de 2025 e a diferença para ele. Vendas: 72,4, 80,1, '
        '86,3, 92,7, 98,0 milhões contra um plano de 100. Crescimento real: 4,4, 3,0, 3,0 e 1,5% ao ano a '
        'partir de 2022, contra um plano de 4. Vendas por metro quadrado de loja: 3.459, 3.765, 4.011, 4.018, '
        '4.019 reais contra 4.300. Participação online: 12,6, 14,0, 14,9, 15,9, 15,9% contra 18. Vendas por '
        'funcionário: 219, 229, 236, 235, 239 mil reais contra 250. Todas as linhas estão abaixo do plano. '
        'Uma nota diz que o índice de preços é ilustrativo.'))
    f.rect(8, 8, 704, 404, fill='--panel', stroke='--wire')
    f.text(24, 36, ('Board pack · Varanda Casa & Jardim · year 2025', 'Pacote do conselho · Varanda Casa & Jardim · ano 2025'),
           size=14, weight=600)
    f.text(696, 36, ('closed and audited figures', 'números fechados e auditados'), size=12, anchor='end',
           fill='--paper-dim')
    xs = [262, 316, 370, 424, 478]                # right edges of the five year columns
    f.text(24, 66, ('indicator', 'indicador'), size=11, fill='--paper-dim')
    for x, y in zip(xs, YEARS):
        f.text(x, 66, str(y), size=11, anchor='end', mono=True, fill='--paper-dim')
    f.text(500, 66, ('trend', 'tendência'), size=11, fill='--paper-dim')
    f.text(614, 66, ('plan', 'plano'), size=11, anchor='end', fill='--paper-dim')
    f.text(690, 66, ('gap', 'diferença'), size=11, anchor='end', fill='--paper-dim')
    for k, (label, vals, dp, plan, ok, verdict) in enumerate(lines):
        y = 78 + k * 58
        f.rect(20, y, 680, 50, fill='--scan', stroke='--wire', sw=1)
        f.text(30, y + 21, label, size=12, weight=600)
        f.text(30, y + 39, verdict, size=11, fill='--paper-dim')
        for x, v in zip(xs, vals):
            if v is None:
                f.text(x, y + 30, '—', size=12, anchor='end', mono=True, fill='--paper-dim')
            else:
                f.text(x, y + 30, (n(v, dp, 'en'), n(v, dp, 'pt')), size=12, anchor='end', mono=True)
        # the sparkline, scaled to the row's own range, with the plan as a dashed line
        pts = [(i, v) for i, v in enumerate(vals) if v is not None]
        lo = min([v for _, v in pts] + [plan])
        hi = max([v for _, v in pts] + [plan])
        span = hi - lo or 1
        sx = lambda i: 500 + i * 18
        sy = lambda v: y + 42 - (v - lo) / span * 32
        f.path('M' + ' L'.join(f'{sx(i):.1f} {sy(v):.1f}' for i, v in pts), stroke='--phosphor', sw=2)
        f.line(500, sy(plan), 572, sy(plan), stroke='--paper-dim', sw=1, dash='3 3')
        f.text(614, y + 30, (n(plan, dp, 'en'), n(plan, dp, 'pt')), size=12, anchor='end', mono=True)
        last = vals[-1]
        if k in (1, 3):           # rates: the gap in points
            g = round(last, 1) - plan
            gl = (f'{g:+.1f} pts'.replace('-', '−'), f'{g:+.1f} p.p.'.replace('-', '−').replace('.', ',', 1))
        else:                     # amounts: the gap in per cent
            g = (round(last, dp) / plan - 1) * 100
            gl = (f'{g:+.1f}%'.replace('-', '−'), f'{g:+.1f}%'.replace('-', '−').replace('.', ','))
        f.text(690, y + 30, gl, size=12, anchor='end', mono=True, weight=600)
    f.text(24, 386, ('Real terms use an illustrative price index (2021 = 100), not an official series. '
                     'Dashed line: the 2025 plan.',
                     'Os termos reais usam um índice de preços ilustrativo (2021 = 100), não uma série '
                     'oficial. Linha tracejada: o plano de 2025.'), size=11, fill='--paper-dim')
    f.text(24, 403, ('Ipatinga, the ninth store, opened in July 2024.',
                     'Ipatinga, a nona loja, abriu em julho de 2024.'), size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'The page the board reads first. Five numbers, five years, and the plan beside each. No row is '
        'alarming on its own; together they say that Varanda grows in reais and barely in real terms.',
        'A página que o conselho lê primeiro. Cinco números, cinco anos, e o plano ao lado de cada um. '
        'Nenhuma linha assusta sozinha; juntas, dizem que a Varanda cresce em reais e quase nada em termos '
        'reais.'))


def real_figure():
    real, *_ = per_year()
    f = B.Fig('l16-real', 720, 320, (
        'Two lines over 2021 to 2025. Sales in reais of each year rise from 72.4 to 98.0 million. The same '
        'sales in 2021 reais rise from 72.4 to 81.4 million. The gap between the lines, the part of '
        'the growth that was prices, widens every year.',
        'Duas linhas de 2021 a 2025. As vendas em reais de cada ano sobem de 72,4 para 98,0 milhões. As '
        'mesmas vendas em reais de 2021 sobem de 72,4 para 81,4 milhões. A distância entre as linhas, a '
        'parte do crescimento que foi preço, aumenta a cada ano.'))
    x0, x1, y0, y1 = 90, 560, 260, 40
    lo, hi = 70, 100
    sx = lambda i: x0 + i * (x1 - x0) / 4
    sy = lambda v: y0 - (v - lo) / (hi - lo) * (y0 - y1)
    for v in (70, 80, 90, 100):
        f.line(x0 - 6, sy(v), x0, sy(v), stroke='--paper-dim', sw=1)
        f.text(x0 - 10, sy(v) + 4, str(v), size=11, anchor='end', mono=True, fill='--paper-dim')
    f.line(x0, y1 - 8, x0, y0, stroke='--paper-dim', sw=1)
    f.line(x0, y0, x1 + 10, y0, stroke='--paper-dim', sw=1)
    for i, y in enumerate(YEARS):
        f.text(sx(i), y0 + 18, str(y), size=11, anchor='middle', mono=True, fill='--paper-dim')
    f.text(24, 24, ('R$ million', 'R$ milhões'), size=12, fill='--paper-dim')
    f.path('M' + ' L'.join(f'{sx(i):.1f} {sy(v):.1f}' for i, v in enumerate(SALES)), stroke='--amber', sw=2.5)
    f.path('M' + ' L'.join(f'{sx(i):.1f} {sy(v):.1f}' for i, v in enumerate(real)), stroke='--phosphor', sw=2.5)
    f.text(x1 + 14, sy(SALES[-1]) + 4, (f'{SALES[-1]:.1f} in reais of each year', f'{B.fmt(SALES[-1], "pt", 1)} em reais de cada ano'),
           size=12)
    f.text(x1 + 14, sy(real[-1]) + 4, (f'{real[-1]:.1f} in 2021 reais', f'{B.fmt(real[-1], "pt", 1)} em reais de 2021'),
           size=12)
    f.text(x0 + 4, y0 + 46, ('Prices: an illustrative index, 2021 = 100, reaching 120.4 in 2025.',
                             'Preços: um índice ilustrativo, 2021 = 100, chegando a 120,4 em 2025.'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'Nominal and real sales. Of the R$ 25.6 million Varanda added between 2021 and 2025, the larger part '
        'was prices; the real line grew by R$ 9.0 million in 2021 reais.',
        'Vendas nominais e reais. Dos R$ 25,6 milhões que a Varanda somou entre 2021 e 2025, a maior parte '
        'foi preço; a linha real cresceu R$ 9,0 milhões em reais de 2021.'))


def main():
    growth()
    pack()
    questions()
    board_figure()
    real_figure()


if __name__ == '__main__':
    main()
