"""Lesson 13: budgets, tags and Cost Explorer."""
from figures import Fig, T, figure


@figure('l13-alerts', 13)
def alerts():
    f = Fig('l13-alerts', 720, 340, T(
        'An illustration of one month against a budget, not a capture. The horizontal axis is the '
        'day of the month, from 1 to 30; the vertical axis is spending as a percentage of the '
        'budget, with lines at 80% and 100%. The actual spending rises slowly until day 8, when a '
        'new machine starts, and then faster. On day 10 the forecast, drawn dashed from that day, '
        'already ends the month above 100%, so the forecasted alert fires on day 10. The actual '
        'spending crosses 80% on day 21, and the actual alert fires then.',
        'Uma ilustração de um mês contra um orçamento, não uma captura. O eixo horizontal é o dia '
        'do mês, de 1 a 30; o eixo vertical é o gasto como porcentagem do orçamento, com linhas em '
        '80% e 100%. O gasto real sobe devagar até o dia 8, quando uma máquina nova começa, e '
        'depois mais rápido. No dia 10 a previsão, desenhada tracejada a partir desse dia, já '
        'termina o mês acima de 100%, então o alerta de previsão dispara no dia 10. O gasto real '
        'passa de 80% no dia 21, e o alerta real dispara aí.'))

    def x(d):
        return 90 + (d - 1) * 580 / 29

    def y(p):
        return 280 - p * 230 / 150

    # axes
    f.line(x(1), y(0), x(30), y(0), stroke='--paper-dim', width=1.2)
    f.line(x(1), y(0), x(1), y(150), stroke='--paper-dim', width=1.2)
    for d in (1, 10, 20, 30):
        f.text(x(d), y(0) + 14, str(d), size=10, fill='--paper-dim')
    f.text(x(15.5), y(0) + 34, T('day of the month', 'dia do mês'), size=10, fill='--paper-dim')
    f.text(x(1) - 8, y(0), '0%', size=10, anchor='end', fill='--paper-dim')
    f.text(x(1), 20, T('spending, as a share of the budget', 'gasto, como fração do orçamento'),
           size=10, anchor='start', fill='--paper-dim')
    # thresholds
    f.line(x(1), y(80), x(30), y(80), stroke='--amber', width=1, dash='5 4')
    f.text(x(1) - 8, y(80), '80%', size=10, anchor='end', fill='--amber')
    f.line(x(1), y(100), x(30), y(100), stroke='--paper-dim', width=1, dash='5 4')
    f.text(x(1) - 8, y(100), '100%', size=10, anchor='end', fill='--paper-dim')

    def actual(d):
        return 1.5 * d if d <= 8 else 12 + (d - 8) * 68 / 13

    pts = [(x(d), y(actual(d))) for d in range(1, 31)]
    f.path('M' + ' L'.join(f'{a:.1f} {b:.1f}' for a, b in pts), stroke='--phosphor', width=2)
    f.text(x(30) - 4, y(actual(30)) + 18, T('actual', 'real'), size=10, anchor='end',
           fill='--phosphor')
    # the forecast made on day 10
    f.line(x(10), y(actual(10)), x(30), y(145), stroke='--amber', width=1.6, dash='6 4')
    f.text(x(30) - 4, y(145) - 12, T('forecast, made on day 10', 'previsão, feita no dia 10'),
           size=10, anchor='end', fill='--amber')
    # the two alerts
    f.circle(x(10), y(actual(10)), 5, fill='--amber')
    f.text(x(10) + 10, y(actual(10)) + 22, T('day 10: forecasted alert', 'dia 10: alerta de previsão'),
           size=10, anchor='start', fill='--amber', weight='600')
    f.circle(x(21), y(80), 5, fill='--phosphor')
    f.text(x(21) + 10, y(80) + 20, T('day 21: actual alert', 'dia 21: alerta real'), size=10,
           anchor='start', fill='--phosphor', weight='600')
    f.text(x(8), y(actual(8)) - 26, T('a new machine', 'uma máquina nova'), size=9.5,
           fill='--paper-dim', italic=True)
    f.line(x(8), y(actual(8)) - 18, x(8), y(actual(8)) - 6, stroke='--paper-dim', width=1)
    f.text(360, 334, T('an illustration, not a capture', 'uma ilustração, não uma captura'), size=9.5,
           fill='--paper-dim', italic=True)
    return f, T('The forecast warns when the rate changes; the actual alert, when the money is gone.',
                'A previsão avisa quando o ritmo muda; o alerta real, quando o dinheiro já foi.')


@figure('l13-flow', 13)
def flow():
    f = Fig('l13-flow', 720, 330, T(
        'From an hour of use to a line in a report, through two gates. On the left, two '
        'resources: an m7i.large tagged team=web and a t3.medium with no tag. Each hour of use '
        'becomes a line on the bill carrying the tags the resource had at that hour: the first '
        'line carries team=web, the second none. Gate one, between them: the tag must be on the '
        'resource when the cost happens. Gate two, before the report: the key team must be '
        'activated in Billing, in the management account. On the right, the report grouped by '
        'team: team$web holds the first line, and team$, the untagged remainder, holds the second.',
        'De uma hora de uso a uma linha num relatório, por duas portas. À esquerda, dois '
        'recursos: um m7i.large com a tag team=web e um t3.medium sem tag. Cada hora de uso vira '
        'uma linha na fatura que leva as tags que o recurso tinha naquela hora: a primeira linha '
        'leva team=web, a segunda nenhuma. Porta um, entre os dois: a tag tem de estar no recurso '
        'quando o custo acontece. Porta dois, antes do relatório: a chave team tem de estar ativada '
        'no Billing, na conta de gerenciamento. À direita, o relatório agrupado por team: team$web '
        'guarda a primeira linha, e team$, o resto sem tag, guarda a segunda.'))
    cols = [(20, T('an hour of use', 'uma hora de uso')),
            (265, T('a line on the bill', 'uma linha na fatura')),
            (510, T('a report, grouped by team', 'um relatório, agrupado por team'))]
    for cx, title in cols:
        f.text(cx + 95, 30, title, size=11, weight='600', fill='--paper-dim')
        f.rect(cx, 48, 190, 170, stroke='--wire', fill='--scan')
    rows = [(95, 'm7i.large', 'team=web', '--phosphor'), (170, 't3.medium', T('no tag', 'sem tag'), '--amber')]
    for ry, name, tag, colour in rows:
        f.rect(35, ry - 24, 160, 48, stroke=colour, fill='--panel')
        f.text(115, ry - 9, name, size=10.5, mono=True)
        f.text(115, ry + 10, tag, size=10, mono=tag == 'team=web', fill=colour)
        f.rect(280, ry - 24, 160, 48, stroke=colour, fill='--panel')
        f.text(360, ry - 9, T('1 hour, m7i.large', '1 hora, m7i.large') if ry == 95
               else T('1 hour, t3.medium', '1 hora, t3.medium'), size=10)
        f.text(360, ry + 10, 'tags: team=web' if ry == 95 else 'tags: -', size=10, mono=True,
               fill=colour)
        f.arrow([(197, ry), (277, ry)], stroke='--paper-dim', width=1.3)
        f.rect(525, ry - 24, 160, 48, stroke=colour, fill='--panel')
        f.text(605, ry - 9, 'team$web' if ry == 95 else 'team$', size=10.5, mono=True)
        f.text(605, ry + 10, T('the web team', 'o time web') if ry == 95
               else T('the untagged remainder', 'o resto sem tag'), size=10, fill=colour)
        f.arrow([(442, ry), (522, ry)], stroke='--paper-dim', width=1.3)
    # the gates
    for gx, n, rows_ in ((237, '1', (T('the tag is on', 'a tag está no'),
                                     T('the resource at', 'recurso na'),
                                     T('the hour of use', 'hora do uso'))),
                         (482, '2', (T('the key is', 'a chave está'),
                                     T('activated in', 'ativada no'),
                                     T('Billing', 'Billing')))):
        f.line(gx, 48, gx, 218, stroke='--amber', width=2.5, dash='3 3')
        f.circle(gx, 252, 13, fill='--amber')
        f.text(gx, 252, n, size=11, weight='600', fill='--ink')
        f.lines(gx, 293, rows_, size=10, fill='--amber')
    return f, T('A cost reaches a report under a tag only if the tag was there at the hour, and the '
                'key was activated.',
                'Um custo chega a um relatório sob uma tag só se a tag estava lá na hora, e a chave '
                'foi ativada.')
