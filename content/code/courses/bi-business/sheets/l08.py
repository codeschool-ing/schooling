"""Lesson 8: predictive analysis. A backtest of the second half of 2025 from what
was known at the end of June, by three baseline methods; the error of each month,
the mean absolute percentage error and the bias; the first quarter of 2026
forecast, with a range taken from the backtest."""
import book as B

LESSON = 'le-36p954x7'
H2 = range(6, 12)                     # July to December
JUNE_2025 = B.SALES_2025[5]


def backtest():
    rows = [['Month', 'Actual 2025', 'Same month 2024', 'Naive APE', 'Seasonal APE',
             'Growth forecast', 'Growth APE', '', 'H1 2024', sum(B.SALES_2024[:6])]]
    for k, m in enumerate(H2):
        r = k + 2
        row = [B.MONTHS[m], B.SALES_2025[m], B.SALES_2024[m],
               f'=ROUND(MAX({JUNE_2025}-B{r},B{r}-{JUNE_2025})/B{r}*100,1)',
               f'=ROUND(MAX(C{r}-B{r},B{r}-C{r})/B{r}*100,1)',
               f'=ROUND(C{r}*$J$2/$J$1,0)',
               f'=ROUND(MAX(F{r}-B{r},B{r}-F{r})/B{r}*100,1)']
        if r == 2:
            row += ['', 'H1 2025', sum(B.SALES_2025[:6])]
        rows.append(row)
    rows.append(['MAPE', '', '', '=ROUND(AVERAGE(D2:D7),1)', '=ROUND(AVERAGE(E2:E7),1)', '',
                 '=ROUND(AVERAGE(G2:G7),1)'])
    cells = (['J1', 'J2', 'D8', 'E8', 'G8'] + [f'D{r}' for r in range(2, 8)]
             + [f'E{r}' for r in range(2, 8)] + [f'F{r}' for r in range(2, 8)]
             + [f'G{r}' for r in range(2, 8)])
    return B.report('lesson 8 — the second half of 2025, forecast from June', rows, cells, [
        '=ROUND(J2/J1,4)',
        '=ROUND((J2/J1-1)*100,1)',
        # signed errors, forecast minus actual, in percent
        '=ROUND((C2-B2)/B2*100,1)', '=ROUND((C5-B5)/B5*100,1)', '=ROUND((C7-B7)/B7*100,1)',
        '=ROUND((F2-B2)/B2*100,1)', '=ROUND((F3-B3)/B3*100,1)', '=ROUND((F4-B4)/B4*100,1)',
        '=ROUND((F5-B5)/B5*100,1)', '=ROUND((F6-B6)/B6*100,1)', '=ROUND((F7-B7)/B7*100,1)',
        '=SUM(B2:B7)', '=SUM(F2:F7)', '=ROUND((SUM(F2:F7)/SUM(B2:B7)-1)*100,1)',
        '=SUM(C2:C7)', '=ROUND((SUM(C2:C7)/SUM(B2:B7)-1)*100,1)',
        '=MAX(G2:G7)', '=MAX(E2:E7)', '=MAX(D2:D7)',
        '=ROUND(MEDIAN(G2:G7),1)',
        '=ROUND(AVERAGE(G2:G4,G6:G7),1)',
    ])


def q1():
    g = B.SALES_2025
    rows = [['Month', '2025', 'Forecast 2026', 'Low', 'High', '', '2024 total', sum(B.SALES_2024)],
            ['Jan', g[0], '=ROUND(B2*$H$2/$H$1,0)', '=ROUND(C2*(1-$H$3/100),0)', '=ROUND(C2*(1+$H$3/100),0)',
             '', '2025 total', sum(g)],
            ['Feb', g[1], '=ROUND(B3*$H$2/$H$1,0)', '=ROUND(C3*(1-$H$3/100),0)', '=ROUND(C3*(1+$H$3/100),0)',
             '', 'Typical miss %', 2.3],
            ['Mar', g[2], '=ROUND(B4*$H$2/$H$1,0)', '=ROUND(C4*(1-$H$3/100),0)', '=ROUND(C4*(1+$H$3/100),0)'],
            ['Q1', '=SUM(B2:B4)', '=SUM(C2:C4)', '=SUM(D2:D4)', '=SUM(E2:E4)']]
    cells = ['C2', 'C3', 'C4', 'C5', 'D2', 'E2', 'D3', 'E3', 'D4', 'E4', 'D5', 'E5', 'B5']
    got = B.report('lesson 8 — the first quarter of 2026', rows, cells, [
        '=ROUND(C5*(1-6.7/100),0)', '=ROUND(C5*(1+6.7/100),0)',
        '=ROUND((H2/H1-1)*100,1)',
        '=ROUND(6890*98000/92700,0)', '=ROUND(7284*(1-2.3/100),0)', '=ROUND(7284*(1+2.3/100),0)',
        '=ROUND(22010*(1-2.3/100),0)', '=ROUND(22010*(1+2.3/100),0)',
    ])
    return got


def questions():
    return B.report('lesson 8 — the exercises', [['a']], [], [
        '=ROUND(MAX(900-1000,1000-900)/1000*100,1)',
        '=ROUND(AVERAGE(4,2,6,8),1)',
        '=ROUND(1200*1.05,0)',
        '=ROUND(500*(1-4/100),0)', '=ROUND(500*(1+4/100),0)',
        '=ROUND((15.7-2.3)/15.7*100,0)',
    ])


def chart():
    a24, a25 = B.SALES_2024, B.SALES_2025
    g = sum(a25[:6]) / sum(a24[:6])
    growth = [round(a24[m] * g) for m in H2]
    f = B.Fig('l08-backtest', 720, 360, (
        'A line chart of July to December 2025 in thousands of reais. The actual sales rise from 7,140 '
        'in July to 12,240 in December. The seasonal naive forecast, last year\'s same month, runs just '
        'below the actual line in every month but October. The forecast adjusted for growth sits almost '
        'on the actual line, except in October, where it is 6.7% too high. The naive forecast, June '
        'repeated, is a flat line at 7,330 that misses the November and December peak entirely.',
        'Um gráfico de linhas de julho a dezembro de 2025, em milhares de reais. As vendas reais sobem '
        'de 7.140 em julho a 12.240 em dezembro. A previsão sazonal ingênua, o mesmo mês do ano anterior, '
        'corre logo abaixo da linha real em todos os meses menos outubro. A previsão ajustada pelo '
        'crescimento fica quase em cima da linha real, menos em outubro, onde fica 6,7% acima. A previsão '
        'ingênua, junho repetido, é uma linha reta em 7.330 que perde inteiro o pico de novembro e '
        'dezembro.'))
    x0, x1, y0, y1 = 70, 560, 30, 290
    lo, hi = 6000, 13000
    sy = (y1 - y0) / (hi - lo)

    def Y(v):
        return y1 - (v - lo) * sy
    for v in (6000, 8000, 10000, 12000):
        f.line(x0, Y(v), x1, Y(v), stroke='--wire', sw=1)
        f.text(x0 - 8, Y(v) + 4, (B.fmt(v), B.fmt(v, 'pt')), size=11, anchor='end', fill='--paper-dim', mono=True)
    xs = [x0 + 30 + k * (x1 - x0 - 60) / 5 for k in range(6)]
    for k, m in enumerate(H2):
        f.text(xs[k], y1 + 20, (B.MONTHS[m], B.MONTHS_PT[m]), size=11, anchor='middle', fill='--paper-dim')

    def series(vals, stroke, sw, dash=None):
        d = 'M' + ' L'.join(f'{x:.1f} {Y(v):.1f}' for x, v in zip(xs, vals))
        f.path(d, stroke=stroke, sw=sw, dash=dash)
    series([JUNE_2025] * 6, '--paper-dim', 1.5, dash='2 4')
    series([a24[m] for m in H2], '--phosphor', 2, dash='6 4')
    series(growth, '--amber', 2)
    series([a25[m] for m in H2], '--paper', 2.5)
    # legend, right of the plot
    lx = 580
    items = [('--paper', None, ('actual 2025', 'real 2025'), 2.5),
             ('--amber', None, ('last year × growth', 'ano anterior × cresc.'), 2),
             ('--phosphor', '6 4', ('last year\'s month', 'mês do ano anterior'), 2),
             ('--paper-dim', '2 4', ('June, repeated', 'junho repetido'), 1.5)]
    for k, (stroke, dash, label, sw) in enumerate(items):
        y = 60 + k * 30
        f.line(lx, y, lx + 22, y, stroke=stroke, sw=sw, dash=dash)
        f.text(lx + 28, y + 4, label, size=11)
    f.text(lx, 60 + 4 * 30 + 10, ('average miss', 'erro médio'), size=11, fill='--paper-dim')
    for k, (label, v) in enumerate([(('× growth', '× cresc.'), ('2.3%', '2,3%')),
                                    (('last year', 'ano anterior'), ('5.3%', '5,3%')),
                                    (('June', 'junho'), ('15.7%', '15,7%'))]):
        y = 60 + 4 * 30 + 30 + k * 20
        f.text(lx, y, label, size=11)
        f.text(712, y, v, size=11, anchor='end', mono=True)
    # October, where growth overshoots
    ox = xs[3]
    f.text(ox - 6, Y(growth[3]) - 24, ('Oct: +6.7%', 'out: +6,7%'), size=11, anchor='middle', weight=600)
    f.text(x0, 340, ('thousands of reais; forecasts made with data up to June 2025',
                     'milhares de reais; previsões feitas com dados até junho de 2025'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'The backtest. Each forecast is drawn against what happened. Last year\'s month adjusted for the '
        'first half\'s growth misses by 2.3% on average, and its one large miss is October, where the '
        'campaign moved.',
        'O teste com o passado. Cada previsão desenhada contra o que aconteceu. O mês do ano anterior '
        'ajustado pelo crescimento do primeiro semestre erra 2,3% em média, e o seu único erro grande é '
        'outubro, onde a campanha mudou de lugar.'))


def fan():
    a24, a25 = B.SALES_2024, B.SALES_2025
    g = sum(a25) / sum(a24)
    fc = [round(a25[k] * g) for k in range(3)]
    f = B.Fig('l08-range', 720, 300, (
        'Three months of 2026, January to March. For each, a diamond marks the forecast, 7,284, 6,882 and '
        '7,844 thousand reais, with a short bar for the typical miss of 2.3% either side and a longer, '
        'fainter bar for the worst miss of the backtest, 6.7% either side.',
        'Três meses de 2026, de janeiro a março. Em cada um, um losango marca a previsão, 7.284, 6.882 e '
        '7.844 mil reais, com uma barra curta para o erro típico de 2,3% para cada lado e uma barra mais '
        'longa e mais clara para o pior erro do teste, 6,7% para cada lado.'))
    x0, x1, y0, y1 = 120, 700, 30, 230
    lo, hi = 6200, 8600
    sx = (x1 - x0) / (hi - lo)

    def X(v):
        return x0 + (v - lo) * sx
    for v in (6500, 7000, 7500, 8000, 8500):
        f.line(X(v), y0, X(v), y1, stroke='--wire', sw=1)
        f.text(X(v), y1 + 18, (B.fmt(v), B.fmt(v, 'pt')), size=11, anchor='middle', fill='--paper-dim', mono=True)
    for k in range(3):
        y = y0 + 35 + k * 65
        c = fc[k]
        f.text(x0 - 14, y + 4, (['January', 'February', 'March'][k], ['janeiro', 'fevereiro', 'março'][k]),
               size=12, anchor='end')
        f.bar(X(c * 0.933), y - 3, X(c * 1.067) - X(c * 0.933), 6, fill='--phosphor-dim')
        f.bar(X(c * 0.977), y - 6, X(c * 1.023) - X(c * 0.977), 12, fill='--phosphor')
        f.path(f'M{X(c) - 5:.1f} {y:.1f} L{X(c):.1f} {y - 9:.1f} L{X(c) + 5:.1f} {y:.1f} '
               f'L{X(c):.1f} {y + 9:.1f} Z', stroke='--paper', sw=1.5, fill='--paper')
        f.text(X(c), y - 14, (B.fmt(c), B.fmt(c, 'pt')), size=11, anchor='middle', mono=True)
    f.bar(x0, 272, 22, 10, fill='--phosphor')
    f.text(x0 + 30, 281, ('typical miss, ±2.3%', 'erro típico, ±2,3%'), size=11)
    f.bar(x0 + 220, 274, 22, 6, fill='--phosphor-dim')
    f.text(x0 + 250, 281, ('worst miss, ±6.7%', 'pior erro, ±6,7%'), size=11)
    f.text(700, 281, ('thousands of reais', 'milhares de reais'), size=11, anchor='end', fill='--paper-dim')
    B.place(LESSON, f, (
        'The first quarter of 2026 shown as a forecast should be: each month a number, with the range the '
        'backtest earned and, fainter, how far the backtest\'s worst month missed.',
        'O primeiro trimestre de 2026 mostrado como uma previsão deve ser: cada mês um número, com a faixa '
        'que o teste justificou e, mais clara, o tamanho do erro do pior mês do teste.'))


def main():
    backtest()
    q1()
    questions()
    chart()
    fan()


if __name__ == '__main__':
    main()
