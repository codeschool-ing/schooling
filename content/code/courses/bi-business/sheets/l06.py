"""Lesson 6: descriptive analysis. The two years by month, the totals, year over
year against month over month, the shares of the fourth quarter and of December,
growth that compounds, and the four analyses on one timeline."""
import book as B

LESSON = 'le-v8nnws05'


def months():
    rows = [['Month', '2024', '2025', 'YoY %', 'MoM %']]
    for k, (m, a, b) in enumerate(zip(B.MONTHS, B.SALES_2024, B.SALES_2025)):
        r = k + 2
        row = [m, a, b, f'=ROUND((C{r}/B{r}-1)*100,1)']
        row.append('' if r == 2 else f'=ROUND((C{r}/C{r - 1}-1)*100,1)')
        rows.append(row)
    rows.append(['Total', '=SUM(B2:B13)', '=SUM(C2:C13)', '=ROUND((C14/B14-1)*100,1)'])
    cells = ['B14', 'C14', 'D14'] + [f'D{r}' for r in range(2, 14)] + [f'E{r}' for r in range(3, 14)]
    return B.report('lesson 6 — the two years by month', rows, cells, [
        '=ROUND(AVERAGE(D2:D13),1)',
        '=ROUND(SUM(C11:C13)/C14*100,1)',
        '=ROUND(SUM(B11:B13)/B14*100,1)',
        '=ROUND(C13/C14*100,1)',
        '=ROUND(B13/B14*100,1)',
        '=C11-B11',
        '=C14-B14',
        '=MIN(D2:D13)',
        '=MAX(D2:D13)',
        '=MIN(E3:E13)',
        '=MAX(E3:E13)',
        '=ROUND((B12/B11-1)*100,1)',
        '=ROUND((B11/B10-1)*100,1)',
        '=ROUND((C13/C14)/(B13/B14)*100-100,1)',
        '=ROUND(C13/C14*100-B13/B14*100,1)',
    ])


def growth():
    rows = [['a', 'b']]
    return B.report('lesson 6 — growth that compounds, and a fall that a rise does not undo', rows, [], [
        '=ROUND((1.057^3-1)*100,1)',
        '=3*5.7',
        '=100*0.9*1.1',
    ])


def questions():
    """The numbers the lesson's numeric questions ask for."""
    return B.report('lesson 6 — the exercises', [['a']], [], [
        '=ROUND((1050/980-1)*100,1)',
        '=ROUND((1.1^2-1)*100,1)',
        '=ROUND((7350/6890-1)*100,1)',
        '=ROUND(11290/92700*100,1)',
    ])


def timeline():
    f = B.Fig('l06-four', 720, 336, (
        'A timeline from 2025 on the left to 2026 on the right, with today, January 2026, in the '
        'middle. Above the past: descriptive analysis, what happened, and diagnostic analysis, why '
        'it happened. Above the future: predictive analysis, what is likely to happen. Below today, '
        'with an arrow into the future: prescriptive analysis, what to do about it.',
        'Uma linha do tempo de 2025, à esquerda, a 2026, à direita, com hoje, janeiro de 2026, no '
        'meio. Sobre o passado: a análise descritiva, o que aconteceu, e a diagnóstica, por que '
        'aconteceu. Sobre o futuro: a preditiva, o que deve acontecer. Abaixo de hoje, com uma seta '
        'para o futuro: a prescritiva, o que fazer a respeito.'))
    W, H = 176, 104
    tops = [
        (16, 34, ('descriptive', 'descritiva'), ('what happened?', 'o que aconteceu?'),
         ('2025: R$ 98.0 million', '2025: R$ 98,0 milhões'), ('5.7% above 2024', '5,7% acima de 2024')),
        (206, 34, ('diagnostic', 'diagnóstica'), ('why did it happen?', 'por que aconteceu?'),
         ('why did October fall', 'por que outubro caiu'), ('when no other month did?', 'e nenhum outro mês?')),
        (528, 34, ('predictive', 'preditiva'), ('what is likely to happen?', 'o que deve acontecer?'),
         ('sales in the first', 'vendas do primeiro'), ('quarter of 2026', 'trimestre de 2026')),
    ]
    for x, y, title, q, d1, d2 in tops:
        f.rect(x, y, W, H, fill='--panel', stroke='--phosphor')
        f.text(x + W / 2, y + 26, title, size=14, anchor='middle', weight=600)
        f.text(x + W / 2, y + 48, q, size=12, anchor='middle')
        f.text(x + W / 2, y + 72, d1, size=11, anchor='middle', fill='--paper-dim')
        f.text(x + W / 2, y + 88, d2, size=11, anchor='middle', fill='--paper-dim')
    # the axis
    ax = 186
    f.line(16, ax, 704, ax, stroke='--paper-dim', sw=1.5)
    f.arrow(690, ax, 706, ax, stroke='--paper-dim')
    f.line(430, ax - 10, 430, ax + 10, stroke='--paper', sw=2)
    f.text(200, ax + 22, ('the past: 2025', 'o passado: 2025'), size=12, anchor='middle', fill='--paper-dim')
    f.text(616, ax + 22, ('the future: 2026', 'o futuro: 2026'), size=12, anchor='middle', fill='--paper-dim')
    f.text(430, ax - 16, ('today', 'hoje'), size=12, anchor='middle', weight=600)
    # the two past boxes hang over the past, the predictive one over the future
    for x in (104, 294):
        f.line(x, 138, x, ax - 2, stroke='--wire', sw=1.5, dash='4 3')
    f.line(616, 138, 616, ax - 2, stroke='--wire', sw=1.5, dash='4 3')
    # prescriptive, below today, acting on the future
    px, py = 342, 222
    f.rect(px, py, W, H, fill='--panel', stroke='--amber')
    f.text(px + W / 2, py + 26, ('prescriptive', 'prescritiva'), size=14, anchor='middle', weight=600)
    f.text(px + W / 2, py + 48, ('what should we do?', 'o que devemos fazer?'), size=12, anchor='middle')
    f.text(px + W / 2, py + 72, ('when to reorder', 'quando repor'), size=11, anchor='middle', fill='--paper-dim')
    f.text(px + W / 2, py + 88, ('garden-hose reels', 'o carretel de mangueira'), size=11, anchor='middle',
           fill='--paper-dim')
    f.line(430, ax + 2, 430, py - 2, stroke='--wire', sw=1.5, dash='4 3')
    f.arrow(px + W + 2, py + H / 2, 640, py + H / 2, stroke='--amber')
    f.text(646, py + H / 2 + 4, ('acts on it', 'age sobre ele'), size=12, anchor='start')
    f.text(16, 300, ('lessons 6 to 9, in this order:', 'aulas 6 a 9, nesta ordem:'), size=12,
           fill='--paper-dim')
    f.text(16, 318, ('each needs the one before', 'cada uma precisa da anterior'), size=12,
           fill='--paper-dim')
    B.place(LESSON, f, (
        'The four kinds of analysis on one timeline, each with one of Varanda\'s questions. Two look '
        'back, one looks forward, and the last one chooses what to do now.',
        'Os quatro tipos de análise numa linha do tempo, cada um com uma pergunta da Varanda. Dois '
        'olham para trás, um olha para a frente, e o último escolhe o que fazer agora.'))


def chart():
    f = B.Fig('l06-months', 720, 330, (
        'A bar chart of Varanda\'s sales by month in thousands of reais, 2024 and 2025 side by side. '
        'Both years climb towards December, the highest month in each, at 11,290 and 12,240. Every '
        'month of 2025 is above the same month of 2024 except October: 7,960 against 8,020.',
        'Um gráfico de barras das vendas da Varanda por mês, em milhares de reais, 2024 e 2025 lado '
        'a lado. Os dois anos sobem até dezembro, o maior mês de cada um, com 11.290 e 12.240. Todo '
        'mês de 2025 fica acima do mesmo mês de 2024, menos outubro: 7.960 contra 8.020.'))
    x0, x1, y0, y1 = 64, 704, 40, 270          # plot area
    top = 13000
    sy = (y1 - y0) / top
    for v in (0, 4000, 8000, 12000):
        y = y1 - v * sy
        f.line(x0, y, x1, y, stroke='--wire', sw=1)
        f.text(x0 - 8, y + 4, (B.fmt(v), B.fmt(v, 'pt')), size=11, anchor='end', fill='--paper-dim', mono=True)
    gw = (x1 - x0) / 12
    bw = 18
    for k in range(12):
        gx = x0 + k * gw + gw / 2
        a, b = B.SALES_2024[k], B.SALES_2025[k]
        f.bar(gx - bw - 1, y1 - a * sy, bw, a * sy, fill='--phosphor-dim')
        f.bar(gx + 1, y1 - b * sy, bw, b * sy, fill='--amber' if k == 9 else '--phosphor')
        f.text(gx, y1 + 18, (B.MONTHS[k], B.MONTHS_PT[k]), size=11, anchor='middle', fill='--paper-dim')
    # the one month below its year-ago self
    gx = x0 + 9 * gw + gw / 2
    f.text(gx + 10, y1 - B.SALES_2025[9] * sy - 34, ('Oct: −0.7%', 'out: −0,7%'), size=12,
           anchor='middle', weight=600)
    f.line(gx + 10, y1 - B.SALES_2025[9] * sy - 28, gx + 10, y1 - B.SALES_2025[9] * sy - 4,
           stroke='--paper-dim', sw=1)
    # legend
    f.bar(x0, 12, 14, 14, fill='--phosphor-dim')
    f.text(x0 + 20, 24, '2024', size=12)
    f.bar(x0 + 70, 12, 14, 14, fill='--phosphor')
    f.text(x0 + 90, 24, '2025', size=12)
    f.text(x0 + 150, 24, ('thousands of reais', 'milhares de reais'), size=12, fill='--paper-dim')
    f.text(x1, 318, ('December is the highest month in both years', 'dezembro é o maior mês nos dois anos'),
           size=12, anchor='end', fill='--paper-dim')
    B.place(LESSON, f, (
        'Varanda\'s two years by month. The shape repeats, December on top in both, so a month is '
        'compared with the same month a year before. October 2025 is the one that fell.',
        'Os dois anos da Varanda por mês. O desenho se repete, com dezembro no topo nos dois, então '
        'um mês se compara com o mesmo mês do ano anterior. Outubro de 2025 é o que caiu.'))


def main():
    months()
    growth()
    questions()
    timeline()
    chart()


if __name__ == '__main__':
    main()
