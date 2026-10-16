"""Lesson 14: on demand, reservations and Savings Plans on the bill."""
from figures import Fig, T, figure


@figure('l14-breakeven', 14)
def breakeven():
    f = Fig('l14-breakeven', 720, 360, T(
        'Dollars a month against hours run in a month, for one m7i.large in sa-east-1, from the '
        'price lists of 25 September 2026. On demand is a line rising from 0 dollars at 0 hours to '
        '117.27 at 730 hours. The one-year standard reservation with no upfront is flat at 72.68, '
        'and the line on demand crosses it at 452 hours. The one-year Compute Savings Plan with no '
        'upfront is flat at 79.68, crossed at 496 hours. Left of the crossing, on demand is '
        'cheaper; right of it, the commitment is.',
        'Dólares por mês contra horas rodadas no mês, para um m7i.large em sa-east-1, pelas listas '
        'de preços de 25 de setembro de 2026. Sob demanda é uma linha que sobe de 0 dólar em 0 '
        'hora até 117,27 em 730 horas. A reserva padrão de um ano sem adiantamento é plana em '
        '72,68, e a linha sob demanda a cruza em 452 horas. O Compute Savings Plan de um ano sem '
        'adiantamento é plano em 79,68, cruzado em 496 horas. À esquerda do cruzamento, sob demanda '
        'é mais barato; à direita, o compromisso é.'))

    def x(h):
        return 90 + h * 580 / 730

    def y(d):
        return 290 - d * 240 / 130

    f.line(x(0), y(0), x(730), y(0), stroke='--paper-dim', width=1.2)
    f.line(x(0), y(0), x(0), y(130), stroke='--paper-dim', width=1.2)
    for h in (0, 200, 400, 600, 730):
        f.text(x(h), y(0) + 14, str(h), size=10, fill='--paper-dim')
    f.text(x(365), y(0) + 34, T('hours the machine runs in a month', 'horas que a máquina roda no mês'),
           size=10, fill='--paper-dim')
    for d in (0, 50, 100):
        f.text(x(0) - 8, y(d), str(d), size=10, anchor='end', fill='--paper-dim')
    f.text(x(0), 22, T('dollars a month', 'dólares por mês'), size=10, anchor='start',
           fill='--paper-dim')
    # the two commitments
    f.line(x(0), y(72.68), x(730), y(72.68), stroke='--amber', width=2)
    f.text(x(10), y(72.68) + 14, T('reservation, standard: 72.68', 'reserva padrão: 72,68'),
           size=10, anchor='start', fill='--amber')
    f.line(x(0), y(79.68), x(730), y(79.68), stroke='--paper-dim', width=2, dash='6 4')
    f.text(x(10), y(79.68) - 12, T('Compute Savings Plan: 79.68', 'Compute Savings Plan: 79,68'),
           size=10, anchor='start', fill='--paper-dim')
    # on demand
    f.line(x(0), y(0), x(730), y(117.27), stroke='--phosphor', width=2)
    f.text(x(730) - 4, y(117.27) - 12, T('on demand: 117.27', 'sob demanda: 117,27'), size=10,
           anchor='end', fill='--phosphor')
    for h, lab in ((452, '452 h'), (496, '496 h')):
        d = h * 0.16065
        f.line(x(h), y(d) + 6, x(h), y(0), stroke='--paper-dim', width=1, dash='2 3')
        f.circle(x(h), y(d), 4.5, fill='--amber' if h == 452 else '--paper-dim')
    f.text(x(452) - 4, y(0) - 12, '452 h', size=10, anchor='end', fill='--amber', weight='600')
    f.text(x(496) + 4, y(0) - 12, '496 h', size=10, anchor='start', fill='--paper-dim',
           weight='600')
    f.text(x(250), y(12), T('on demand is cheaper', 'sob demanda é mais barato'), size=10.5,
           fill='--phosphor', italic=True)
    f.text(x(620), y(40), T('the commitment is cheaper', 'o compromisso é mais barato'), size=10.5,
           fill='--amber', italic=True)
    return f, T('A commitment is a flat line; on demand climbs with the hours. Where they cross is the '
                'break-even.',
                'Um compromisso é uma linha plana; sob demanda sobe com as horas. Onde elas se cruzam é '
                'o ponto de equilíbrio.')


@figure('l14-lines', 14)
def lines():
    f = Fig('l14-lines', 720, 290, T(
        'One hour of an m7i.large in sa-east-1 on the bill, paid for in three ways, at the rates of '
        'the price lists of 25 September 2026. On demand: one line, Usage, 0.16065. Under a '
        'standard Reserved Instance: two lines, DiscountedUsage at 0.00000 and this hour\'s share of '
        'the RIFee, 0.09956; paid 0.09956. Under a Compute Savings Plan: three lines, '
        'SavingsPlanCoveredUsage at 0.16065, SavingsPlanNegation at minus 0.16065, and '
        'SavingsPlanRecurringFee at 0.10915; paid 0.10915.',
        'Uma hora de um m7i.large em sa-east-1 na fatura, paga de três jeitos, pelas tarifas das '
        'listas de preços de 25 de setembro de 2026. Sob demanda: uma linha, Usage, 0,16065. Sob '
        'uma Reserved Instance padrão: duas linhas, DiscountedUsage a 0,00000 e a parte desta hora '
        'do RIFee, 0,09956; pago 0,09956. Sob um Compute Savings Plan: três linhas, '
        'SavingsPlanCoveredUsage a 0,16065, SavingsPlanNegation a menos 0,16065, e '
        'SavingsPlanRecurringFee a 0,10915; pago 0,10915.'))
    cols = [
        (20, T('on demand', 'sob demanda'), '--phosphor',
         [('Usage', '0.16065')], '0.16065'),
        (255, T('standard reservation', 'reserva padrão'), '--amber',
         [('DiscountedUsage', '0.00000'), ('RIFee', '0.09956')], '0.09956'),
        (490, 'Compute Savings Plan', '--paper-dim',
         [('SavingsPlanCoveredUsage', '0.16065'), ('SavingsPlanNegation', '-0.16065'),
          ('SavingsPlanRecurringFee', '0.10915')], '0.10915'),
    ]
    for cx, title, colour, rows, total in cols:
        f.text(cx + 105, 30, title, size=11, weight='600', fill=colour)
        f.rect(cx, 46, 210, 196, stroke=colour, fill='--scan')
        for i, (kind, amount) in enumerate(rows):
            ry = 62 + i * 52
            f.rect(cx + 10, ry, 190, 40, stroke='--wire', fill='--panel')
            f.text(cx + 20, ry + 13, kind, size=10, anchor='start', mono=True)
            if kind == 'RIFee':
                f.text(cx + 20, ry + 29, T("this hour's share", 'a parte desta hora'), size=9.5,
                       anchor='start', fill='--paper-dim', italic=True)
            f.text(cx + 190, ry + 29, amount, size=10, anchor='end', mono=True,
                   fill='--amber' if amount.startswith('-') else '--paper')
        f.line(cx + 10, 222, cx + 200, 222, stroke=colour, width=1)
        f.text(cx + 20, 232, T('paid for the hour', 'pago pela hora'), size=10, anchor='start',
               fill=colour)
        f.text(cx + 190, 232, total, size=10.5, anchor='end', mono=True, weight='600', fill=colour)
    f.text(360, 272, T('documented line types, priced from the list; not a captured bill',
                       'tipos de linha documentados, com preços da lista; não é uma fatura capturada'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('The same hour is one line, two or three. What was paid is the bottom of each column.',
                'A mesma hora é uma linha, duas ou três. O que foi pago está no pé de cada coluna.')
