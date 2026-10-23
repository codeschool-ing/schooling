"""Lesson 12: Systems that cannot stop: windows, contracts and SLAs."""
from figures import Fig, T, figure


@figure('l12-chain', 12)
def chain():
    f = Fig('l12-chain', 720, 330, T(
        'Two rows. The top row is the stock check as it is: the Portal B2B at 99.9%, the service '
        'bus at 99.5% and SAP ECC at 99.0%, in series, so the chain is 0.999 times 0.995 times 0.99, '
        'which is 98.41%, about 139.6 hours down a year. The bottom row puts two bus nodes in '
        'parallel between the portal and SAP. On paper the pair is 1 minus 0.005 squared, 99.9975%, '
        'and the chain becomes 98.90%. With last year\'s outage record, 18 of the bus\'s 43.8 hours '
        'came from causes both nodes share, so the pair reaches about 99.79% and not 99.9975%.',
        'Duas linhas. A de cima é a consulta de estoque como ela é: o Portal B2B com 99,9%, o '
        'barramento com 99,5% e o SAP ECC com 99,0%, em série, então a cadeia é 0,999 vezes 0,995 '
        'vezes 0,99, que dá 98,41%, cerca de 139,6 horas fora do ar por ano. A de baixo põe dois nós '
        'do barramento em paralelo entre o portal e o SAP. No papel o par é 1 menos 0,005 ao '
        'quadrado, 99,9975%, e a cadeia passa a 98,90%. Com o histórico de falhas do ano passado, 18 '
        'das 43,8 horas do barramento vieram de causas que os dois nós compartilham, então o par '
        'chega a cerca de 99,79%, e não a 99,9975%.'))
    # top row: in series
    f.text(20, 24, T('in series: every one must be up', 'em série: todos precisam estar no ar'),
           size=11, anchor='start', weight='600')
    xs = [(95, 'Portal B2B', T('99.9%', '99,9%')),
          (290, T('service bus', 'barramento'), T('99.5%', '99,5%')),
          (485, 'SAP ECC', T('99.0%', '99,0%'))]
    for x, name, val in xs:
        f.box(x, 72, 140, 50, [name, val], size=11, stroke='--phosphor')
    f.arrow([(166, 72), (218, 72)], stroke='--paper-dim')
    f.arrow([(361, 72), (413, 72)], stroke='--paper-dim')
    f.arrow([(556, 72), (586, 72)], stroke='--paper-dim')
    f.lines(650, 72, [T('= 98.41%', '= 98,41%'), T('139.6 h a year', '139,6 h por ano')],
            size=11, fill='--amber', weight='600')
    f.text(360, 116, T('0.999 × 0.995 × 0.99 = 0.98406', '0,999 × 0,995 × 0,99 = 0,98406'),
           size=10.5, fill='--paper-dim', mono=True)
    f.line(20, 140, 700, 140, stroke='--wire', width=1, dash='4 4')
    # bottom row: a pair in the middle
    f.text(20, 162, T('a second bus node in parallel', 'um segundo nó do barramento em paralelo'),
           size=11, anchor='start', weight='600')
    f.box(95, 240, 140, 50, ['Portal B2B', T('99.9%', '99,9%')], size=11, stroke='--phosphor')
    f.box(290, 205, 140, 42, [T('bus node A  99.5%', 'nó A  99,5%')], size=11, stroke='--phosphor')
    f.box(290, 275, 140, 42, [T('bus node B  99.5%', 'nó B  99,5%')], size=11, stroke='--phosphor')
    f.box(485, 240, 140, 50, ['SAP ECC', T('99.0%', '99,0%')], size=11, stroke='--phosphor')
    f.arrow([(166, 240), (190, 240), (190, 205), (218, 205)], stroke='--paper-dim')
    f.arrow([(190, 240), (190, 275), (218, 275)], stroke='--paper-dim')
    f.arrow([(361, 205), (390, 205), (390, 240), (413, 240)], stroke='--paper-dim')
    f.path('M361 275 L390 275 L390 240', stroke='--paper-dim', width=1.2)
    f.lines(650, 240, [T('= 98.90%', '= 98,90%'), T('on paper', 'no papel')],
            size=11, fill='--amber', weight='600')
    f.lines(360, 314, [T('pair on paper: 1 − 0.005² = 99.9975%   ·   with the 18 h both nodes share: about 99.79%',
                         'par no papel: 1 − 0,005² = 99,9975%   ·   com as 18 h que os dois nós compartilham: cerca de 99,79%')],
            size=10.5, fill='--paper')
    return f, T('The stock check as a chain. In series the availabilities multiply; a second node '
                'adds a nine on paper, and the outages both nodes share take most of it back.',
                'A consulta de estoque como uma cadeia. Em série as disponibilidades se multiplicam; '
                'um segundo nó acrescenta um nove no papel, e as falhas que os dois nós compartilham '
                'levam de volta a maior parte dele.')


@figure('l12-budget', 12)
def budget():
    W, H = 720, 320
    f = Fig('l12-budget', W, H, T(
        'A line chart of September replayed against the new objective: failed order submissions '
        'counted cumulatively over 30 days, against an error budget of 120. About one submission a '
        'day fails for ordinary reasons. On day 2, during the close, the stock check times out and '
        'the line jumps by 48. On day 18 a portal release costs 32 more, and the line reaches 98, '
        'past the freeze threshold at 96, which is 80% of the budget. The month ends at 110, under '
        'the budget of 120.',
        'Um gráfico de linha de setembro reprocessado contra o novo objetivo: envios de pedido com '
        'falha somados ao longo de 30 dias, contra um orçamento de erro de 120. Cerca de um envio por '
        'dia falha por motivos comuns. No dia 2, durante o fechamento, a consulta de estoque estoura '
        'o tempo e a linha sobe 48. No dia 18 uma versão do portal custa mais 32, e a linha chega a '
        '98, além do limite de congelamento em 96, que é 80% do orçamento. O mês termina em 110, '
        'abaixo do orçamento de 120.'))
    x0, x1, y0, y1 = 70, 690, 270, 40
    def X(d):
        return x0 + (d - 0) * (x1 - x0) / 30

    def Y(v):
        return y0 - v * (y0 - y1) / 130
    f.line(x0, y0, x1, y0, stroke='--wire', width=1)
    f.line(x0, y0, x0, y1, stroke='--wire', width=1)
    for v in (0, 40, 80, 120):
        f.text(x0 - 8, Y(v), str(v), size=10, anchor='end', fill='--paper-dim')
    for d in (1, 5, 10, 15, 20, 25, 30):
        f.text(X(d), y0 + 14, str(d), size=10, fill='--paper-dim')
    f.text((x0 + x1) / 2, y0 + 32, T('day of September', 'dia de setembro'), size=10.5,
           fill='--paper-dim')
    f.text(18, (y0 + y1) / 2 + 40, T('failed', 'falhas'), size=10.5, fill='--paper-dim',
           anchor='start')
    # budget and threshold
    f.line(x0, Y(120), x1, Y(120), stroke='--amber', width=1.4)
    f.text(x0 + 6, Y(120) - 9, T('error budget: 120 failed submissions in 30 days',
                                  'orçamento de erro: 120 envios com falha em 30 dias'),
           size=10.5, anchor='start', fill='--amber')
    f.line(x0, Y(96), x1, Y(96), stroke='--paper-dim', width=1, dash='4 4')
    f.text(x0 + 6, Y(96) + 10, T('80% spent: releases stop', '80% gasto: as versões param'),
           size=10.5, anchor='start', fill='--paper-dim')
    pts = [(X(0), Y(0))]
    total = 0
    for d in range(1, 31):
        prev = total
        total += 1
        if d == 2:
            pts.append((X(d - 0.02), Y(prev + 1)))
            total += 48
        if d == 18:
            pts.append((X(d - 0.02), Y(prev + 1)))
            total += 32
        pts.append((X(d), Y(total)))
    f.path('M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts), stroke='--phosphor', width=2)
    f.circle(X(18), Y(98), 3.5)
    f.circle(X(30), Y(110), 3.5)
    f.text(X(2) + 8, Y(50) + 16, T('day 2: close, stock check times out, +48',
                                    'dia 2: fechamento, a consulta estoura o tempo, +48'),
           size=10.5, anchor='start')
    f.text(X(18) - 8, Y(98) - 30, T('day 18: a portal release, +32 → 98',
                                     'dia 18: uma versão do portal, +32 → 98'),
           size=10.5, anchor='end')
    f.text(X(30) - 4, Y(110) + 16, T('110 at the end', '110 no fim'), size=10.5, anchor='end')
    return f, T('September, replayed against the new objective. Two incidents spent most of the '
                'budget, and from the evening of the 18th the policy would have stopped releases.',
                'Setembro, reprocessado contra o novo objetivo. Dois incidentes gastaram a maior parte '
                'do orçamento, e a partir da noite do dia 18 a política teria parado as versões.')


@figure('l12-month', 12)
def month():
    W, H = 720, 300
    f = Fig('l12-month', W, H, T(
        'November 2026 as a strip of 30 days, starting on Sunday the 1st. Weekends are shaded, and the '
        'national holidays on the 2nd, the 15th and the 20th are marked. Row one: SAP\'s Sunday window '
        'from 01:00 to 05:00, on the 1st, 8th, 15th, 22nd and 29th. Row two: the close of October, '
        'on the five working days from the 3rd to the 9th. Row three: the farm payment on the 10th. '
        'Row four: the change freeze, which began on 29 October and runs to the 10th, and starts '
        'again on the 27th. Between them, eleven working days from the 11th to the 26th are open '
        'for changes.',
        'Novembro de 2026 como uma faixa de 30 dias, começando no domingo, dia 1º. Os fins de semana '
        'estão sombreados, e os feriados nacionais dos dias 2, 15 e 20 estão marcados. Linha um: a '
        'janela de domingo do SAP, das 01:00 às 05:00, nos dias 1, 8, 15, 22 e 29. Linha dois: o '
        'fechamento de outubro, nos cinco dias úteis de 3 a 9. Linha três: o pagamento dos '
        'produtores no dia 10. Linha quatro: o congelamento de mudanças, que começou em 29 de '
        'outubro e vai até o dia 10, e recomeça no dia 27. Entre os dois, onze dias úteis, de 11 a '
        '26, ficam abertos para mudanças.'))
    x0, cw = 150, 18.5
    def X(d):
        return x0 + (d - 1) * cw
    top, rowh = 60, 36
    weekend = {d for d in range(1, 31) if (d - 1) % 7 in (0, 6)}
    holiday = {2, 15, 20}
    for d in range(1, 31):
        shade = '--scan' if d in weekend or d in holiday else '--panel'
        f.rect(X(d), top - 16, cw - 2, 20, stroke=None, fill=shade, rx=1)
        f.text(X(d) + (cw - 2) / 2, top - 6, str(d), size=10,
               fill='--amber' if d in holiday else '--paper', weight='600' if d in holiday else None)
    f.text(x0 + 15 * cw, 22, T('November 2026: shaded days are weekends and national holidays (2, 15, 20)',
                               'novembro de 2026: dias sombreados são fins de semana e feriados nacionais (2, 15, 20)'),
           size=11)
    labels = [T('SAP window, Sun 01–05', 'janela do SAP, dom 01–05'),
              T('close of October', 'fechamento de outubro'),
              T('farms paid', 'pagamento aos produtores'),
              T('change freeze', 'congelamento')]
    for i, lab in enumerate(labels):
        f.text(x0 - 8, top + 14 + i * rowh, lab, size=10.5, anchor='end')
    # row 1: Sundays
    for d in (1, 8, 15, 22, 29):
        f.rect(X(d) + 2, top + 5, cw - 6, 18, stroke=None, fill='--amber', rx=2)
    # row 2: close, working days 3..9
    for a, b in ((3, 6), (9, 9)):
        f.rect(X(a) + 1, top + rowh + 5, (b - a + 1) * cw - 4, 18, stroke=None, fill='--phosphor', rx=2)
    # row 3: payment
    f.rect(X(10) + 1, top + 2 * rowh + 5, cw - 4, 18, stroke=None, fill='--phosphor', rx=2)
    # row 4: freeze
    yf = top + 3 * rowh + 5
    f.rect(X(1) + 1, yf, 10 * cw - 4, 18, stroke='--amber', fill='--panel', rx=2, dash='3 2')
    f.rect(X(27) + 1, yf, 4 * cw - 4, 18, stroke='--amber', fill='--panel', rx=2, dash='3 2')
    f.text(X(1) + 6, yf + 9, T('← from 29 October', '← desde 29 de outubro'), size=10, anchor='start')
    f.text(X(27) + 6, yf + 9, T('to Dec', 'até dez'), size=10, anchor='start')
    # open days
    ya = top + 4 * rowh + 20
    f.path(f'M{X(11) + 1:.1f} {ya - 6:.1f} L{X(11) + 1:.1f} {ya:.1f} L{X(26) + cw - 3:.1f} {ya:.1f} '
           f'L{X(26) + cw - 3:.1f} {ya - 6:.1f}', stroke='--phosphor', width=1.4)
    f.text((X(11) + X(26) + cw) / 2, ya + 16,
           T('open for changes: 11 working days, from the 11th to the 26th',
             'aberto para mudanças: 11 dias úteis, de 11 a 26'), size=11, weight='600')
    return f, T('November 2026 on one strip. The holiday on the 2nd pushes the close to the 9th, the '
                'payment follows on the 10th, and the freeze runs from October without a gap.',
                'Novembro de 2026 numa faixa. O feriado do dia 2 empurra o fechamento até o dia 9, o '
                'pagamento vem logo no dia 10, e o congelamento vem de outubro sem intervalo.')


@figure('l12-recovery', 12)
def recovery():
    W, H = 720, 250
    f = Fig('l12-recovery', W, H, T(
        'A timeline of a failure of SAP. On the left, the last log backup; 15 minutes later, the '
        'failure. The span between them is the RPO, the work that may be lost. From the failure, the '
        'RTO of 8 hours runs to the right, divided into the steps of recovery: 20 minutes to detect, '
        '40 to decide, 4 hours to restore the database, 1 hour to apply the logs, 1.5 hours to check '
        'and reconnect. The steps take 7.5 hours, half an hour inside the objective.',
        'Uma linha do tempo de uma falha do SAP. À esquerda, o último backup de log; 15 minutos '
        'depois, a falha. O trecho entre os dois é o RPO, o trabalho que pode ser perdido. A partir '
        'da falha, o RTO de 8 horas corre para a direita, dividido nas etapas da recuperação: 20 '
        'minutos para detectar, 40 para decidir, 4 horas para restaurar o banco, 1 hora para aplicar '
        'os logs, 1,5 hora para conferir e reconectar. As etapas levam 7,5 horas, meia hora dentro '
        'do objetivo.'))
    y = 120
    xf = 170          # the failure
    hx = 62           # pixels per hour on the right
    xb = 70           # last backup, drawn wider than scale: the RPO is minutes
    f.line(30, y, xf, y, stroke='--wire', width=1.4)
    f.line(xb, y - 26, xb, y + 26, stroke='--paper-dim', width=1.4)
    f.lines(xb, y + 44, [T('last log', 'último backup'), T('backup', 'de log')], size=10.5)
    f.line(xf, y - 40, xf, y + 26, stroke='--amber', width=2)
    f.text(xf - 5, y + 34, T('failure', 'falha'), size=11, fill='--amber', weight='600', anchor='end')
    f.arrow([(xf - 4, y - 30), (xb + 4, y - 30)], stroke='--paper-dim', start=True)
    f.lines((xb + xf) / 2, y - 52, [T('RPO 15 min: work', 'RPO 15 min: trabalho'),
                                     T('that may be lost', 'que pode ser perdido')], size=10.5)
    steps = [(1 / 3, T('detect', 'detectar')), (2 / 3, T('decide', 'decidir')),
             (4, T('restore 2,400 GB', 'restaurar 2.400 GB')),
             (1, T('logs', 'logs')), (1.5, T('check, reconnect', 'conferir, religar'))]
    x = xf
    for i, (h, lab) in enumerate(steps):
        w = h * hx
        f.rect(x + 1, y - 14, w - 2, 28, stroke='--phosphor', fill='--panel', rx=2)
        if w > 60:
            f.text(x + w / 2, y, lab, size=10.5)
        else:
            f.line(x + w / 2, y + 14, x + w / 2, y + 42 + 16 * (i % 2), stroke='--wire', width=1)
            f.text(x + w / 2, y + 50 + 16 * (i % 2), lab, size=10.5)
        x += w
    xe = xf + 8 * hx
    f.line(x, y, 700, y, stroke='--wire', width=1.4)
    f.line(x, y - 20, x, y + 20, stroke='--phosphor', width=2)
    f.text(x, y + 84, T('back after 7.5 h', 'de volta em 7,5 h'), size=10.5, weight='600',
           anchor='end')
    f.line(xe, y - 40, xe, y + 26, stroke='--amber', width=1.4, dash='4 3')
    f.arrow([(xf + 4, y - 30), (xe - 4, y - 30)], stroke='--paper-dim', start=True)
    f.text((xf + xe) / 2, y - 44, T('RTO 8 h: until the service is usable again',
                                    'RTO 8 h: até o serviço voltar a ser usável'), size=10.5)
    f.text(xe, y + 38, T('objective', 'objetivo'), size=10.5, fill='--amber')
    return f, T('The RPO looks back from the failure, the RTO forward. The restore itself is half '
                'of the eight hours. (The RPO is drawn wider than its scale.)',
                'O RPO olha para trás a partir da falha, o RTO para a frente. A restauração em si é '
                'metade das oito horas. (O RPO está desenhado mais largo do que a escala.)')
