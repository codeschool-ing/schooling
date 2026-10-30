"""Lesson 14: reading the bill."""
from figures import Fig, T, figure


@figure('l14-breakeven', 14)
def breakeven():
    f = Fig('l14-breakeven', 720, 320, T(
        'The month\'s cost of one machine against the share of the month it runs, with the lesson\'s '
        'invented prices. Pay as you go rises in a straight line from 0 to 730 at 100%. A one-year '
        'reservation at 0.60 an hour is flat at 438, and crosses the pay-as-you-go line at 60%. A '
        'three-year one at 0.40 is flat at 292, and crosses at 40%. Left of a crossing the '
        'reservation loses money, right of it the reservation saves.',
        'O custo mensal de uma máquina contra a parte do mês em que ela roda, com os preços inventados '
        'da lição. O pagamento conforme o uso sobe em linha reta de 0 a 730 em 100%. Uma reserva de um '
        'ano a 0,60 por hora é plana em 438, e cruza a linha do pagamento conforme o uso em 60%. Uma de '
        'três anos a 0,40 é plana em 292, e cruza em 40%. À esquerda de um cruzamento a reserva perde '
        'dinheiro, à direita ela economiza.'))
    x0, x1, y0, y1 = 90, 640, 260, 40
    def X(p): return x0 + p / 100 * (x1 - x0)
    def Y(v): return y0 - v / 800 * (y0 - y1)
    f.line(x0, y0, x1, y0, stroke='--paper-dim')
    f.line(x0, y0, x0, y1, stroke='--paper-dim')
    for v in (0, 292, 438, 730):
        f.text(x0 - 10, Y(v), str(v), size=9.5, anchor='end', mono=True, fill='--paper-dim')
    for p in (0, 40, 60, 100):
        f.text(X(p), y0 + 16, f'{p}%', size=9.5, mono=True, fill='--paper-dim')
    f.text((x0 + x1) / 2, y0 + 38, T('share of the month the machine runs', 'parte do mês em que a máquina roda'),
           size=10, fill='--paper-dim')
    f.path(f'M{X(0):.1f} {Y(0):.1f} L{X(100):.1f} {Y(730):.1f}', stroke='--phosphor', width=2)
    f.text(X(84), Y(730) - 4, T('pay as you go', 'conforme o uso'), size=10, anchor='end', fill='--phosphor')
    f.line(X(0), Y(438), X(100), Y(438), stroke='--amber', width=1.6)
    f.text(X(100), Y(438) - 10, T('one-year reservation', 'reserva de um ano'), size=10, anchor='end', fill='--amber')
    f.line(X(0), Y(292), X(100), Y(292), stroke='--paper', width=1.4, dash='6 4')
    f.text(X(100), Y(292) + 14, T('three-year reservation', 'reserva de três anos'), size=10, anchor='end', fill='--paper')
    f.circle(X(60), Y(438), 4.5, fill='--amber')
    f.circle(X(40), Y(292), 4.5, fill='--paper')
    return f, T('Invented prices: the reservation pays only to the right of where its line crosses.',
                'Preços inventados: a reserva só compensa à direita de onde a sua linha cruza.')


@figure('l14-savings-plan-hours', 14)
def plan_hours():
    f = Fig('l14-savings-plan-hours', 720, 280, T(
        'Six hours under a savings plan committed to an invented 10 an hour, drawn as bars. In hours '
        'one and two the eligible usage, at its discounted price, is 10 and uses the commitment '
        'exactly. In hour three it is 14: 10 comes out of the commitment and the extra 4 of usage is '
        'billed at pay-as-you-go prices. In hours four and five it is 6, and the remaining 4 of the '
        'commitment is lost. In hour six nothing runs and the whole 10 is lost.',
        'Seis horas sob um savings plan com compromisso de 10 por hora, valor inventado, desenhadas '
        'como barras. Nas horas um e dois o uso elegível, ao preço com desconto, é 10 e consome o '
        'compromisso exatamente. Na hora três é 14: 10 saem do compromisso e os 4 de uso a mais são '
        'cobrados ao preço do pagamento conforme o uso. Nas horas quatro e cinco é 6, e os 4 restantes '
        'do compromisso se perdem. Na hora seis nada roda e os 10 inteiros se perdem.'))
    use = [10, 10, 14, 6, 6, 0]
    base, unit = 210, 10
    f.line(60, base - 10 * unit, 560, base - 10 * unit, stroke='--amber', dash='6 4')
    f.text(565, base - 10 * unit, T('commitment: 10 an hour', 'compromisso: 10 por hora'), size=10,
           anchor='start', fill='--amber')
    for i, u in enumerate(use):
        x = 80 + i * 80
        covered = min(u, 10)
        if covered:
            f.rect(x, base - covered * unit, 50, covered * unit, stroke='--phosphor', fill='--panel', rx=2)
        if u > 10:
            f.rect(x, base - u * unit, 50, (u - 10) * unit, stroke='--paper', fill='--scan', rx=2)
        if u < 10:
            f.rect(x, base - 10 * unit, 50, (10 - u) * unit, stroke='--paper-dim', fill='--ink', rx=2, dash='3 3')
        f.text(x + 25, base + 16, T(f'hour {i + 1}', f'hora {i + 1}'), size=9.5, fill='--paper-dim')
    f.line(60, base, 560, base, stroke='--paper-dim')
    f.rect(80, 240, 14, 12, stroke='--phosphor', fill='--panel', rx=2)
    f.text(100, 246, T('covered by the plan', 'coberto pelo plano'), size=9.5, anchor='start')
    f.rect(260, 240, 14, 12, stroke='--paper', fill='--scan', rx=2)
    f.text(280, 246, T('billed at pay as you go', 'cobrado conforme o uso'), size=9.5, anchor='start')
    f.rect(460, 240, 14, 12, stroke='--paper-dim', fill='--ink', rx=2, dash='3 3')
    f.text(480, 246, T('unused, and lost', 'não usado, e perdido'), size=9.5, anchor='start')
    return f, T('Each hour stands alone: an unused part does not carry over to the next.',
                'Cada hora vale sozinha: uma parte não usada não passa para a próxima.')
