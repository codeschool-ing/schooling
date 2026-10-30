"""Lesson 12: budgets."""
from figures import Fig, T, figure


@figure('l12-month', 12)
def month():
    f = Fig('l12-month', 720, 290, T(
        'A month of spending against a budget of 300 dollars, with the day of the month across and the '
        'money up. A solid line climbs as money is spent: 84.17 dollars early in the month, 273.40 '
        'later, 318.92 near the end. A dashed line is Google\'s forecast for the end of the month, '
        'which crosses 300 dollars on day 5, long before the solid line does. Horizontal marks at 150, '
        '270 and 300 dollars are the actual thresholds at 50, 90 and 100 percent. The forecasted '
        'threshold fires on day 5; the 90 percent actual threshold on day 26; the 100 percent on day 29.',
        'Um mês de gasto contra um orçamento de 300 dólares, com o dia do mês na horizontal e o dinheiro na '
        'vertical. Uma linha cheia sobe conforme o dinheiro é gasto: 84,17 dólares no começo do mês, '
        '273,40 mais tarde, 318,92 perto do fim. Uma linha tracejada é a previsão do Google para o fim do '
        'mês, que passa dos 300 dólares no dia 5, muito antes da linha cheia. Marcas horizontais em 150, '
        '270 e 300 dólares são os limites reais de 50, 90 e 100 por cento. O limite previsto dispara no '
        'dia 5; o de 90 por cento real no dia 26; o de 100 por cento no dia 29.'))
    x0, x1, y0, y1 = 70, 680, 250, 30
    def X(day):
        return x0 + (x1 - x0) * (day - 1) / 29
    def Y(usd):
        return y0 - (y0 - y1) * usd / 360
    f.line(x0, y0, x1, y0, stroke='--paper-dim')
    f.line(x0, y0, x0, y1, stroke='--paper-dim')
    for d in (1, 10, 20, 30):
        f.text(X(d), y0 + 14, str(d), size=9, mono=True, fill='--paper-dim')
    f.text(X(15), y0 + 30, T('day of the month', 'dia do mês'), size=9.5, fill='--paper-dim')
    for usd, pct in ((150, '50%'), (270, '90%'), (300, '100%')):
        f.line(x0, Y(usd), x1, Y(usd), stroke='--wire', dash='3 4')
        f.text(x0 - 6, Y(usd), str(usd), size=9, mono=True, anchor='end', fill='--paper-dim')
        f.text(x1 + 4, Y(usd), pct, size=9, mono=True, anchor='start', fill='--paper-dim')
    pts = [(1, 0), (8, 84.17), (16, 160), (26, 273.4), (29, 318.92)]
    f.path('M' + ' L'.join(f'{X(d):.1f} {Y(u):.1f}' for d, u in pts), stroke='--phosphor', width=2.2)
    f.path(f'M{X(1):.1f} {Y(0):.1f} L{X(5):.1f} {Y(60):.1f} L{X(30):.1f} {Y(340):.1f}', stroke='--amber',
           width=1.6, dash='6 4')
    f.circle(X(5), Y(300) + 2, 4, fill='--amber')
    f.text(X(5) + 8, Y(318), T('forecast passes 300 on day 5', 'previsão passa de 300 no dia 5'),
           size=9.5, anchor='start', fill='--amber')
    f.circle(X(26), Y(273.4), 4, fill='--phosphor')
    f.text(X(26) - 8, Y(273.4) + 16, '273.40', size=9, mono=True, anchor='end', fill='--phosphor')
    f.circle(X(29), Y(318.92), 4, fill='--phosphor')
    f.text(X(29) - 8, Y(318.92) - 10, '318.92', size=9, mono=True, anchor='end', fill='--phosphor')
    f.circle(X(8), Y(84.17), 4, fill='--phosphor')
    f.text(X(8) + 8, Y(84.17) + 4, '84.17', size=9, mono=True, anchor='start', fill='--phosphor')
    f.text(X(19), Y(60), T('actual spend', 'gasto real'), size=9.5, fill='--phosphor')
    return f, T('The forecasted threshold warns weeks before the actual one does.',
                'O limite previsto avisa semanas antes do real.')
