"""Lesson 13: budgets, alerts and cost analysis."""
from figures import Fig, T, figure


@figure('l13-two-alerts', 13)
def two_alerts():
    f = Fig('l13-two-alerts', 720, 330, T(
        'An invented month for a budget of 50: a forgotten machine adds 2 a day from the first. The '
        'actual cost rises in a straight line and crosses 40, the 80% threshold, on day 20, where the '
        'actual alert fires. The forecast for the month, drawn as a dashed line, sits at about 60 '
        'from the start, above the budget of 50, so the forecast alert fires on day 3, seventeen days '
        'earlier.',
        'Um mês inventado para um orçamento de 50: uma máquina esquecida soma 2 por dia desde o dia '
        'primeiro. O custo real sobe em linha reta e cruza 40, o limite de 80%, no dia 20, quando o '
        'alerta real dispara. A previsão do mês, desenhada tracejada, fica em cerca de 60 desde o '
        'início, acima do orçamento de 50, então o alerta de previsão dispara no dia 3, dezessete dias '
        'antes.'))
    x0, x1, y0, y1 = 80, 660, 270, 40
    def X(d): return x0 + (d - 1) / 29 * (x1 - x0)
    def Y(v): return y0 - v / 70 * (y0 - y1)
    f.line(x0, y0, x1, y0, stroke='--paper-dim')
    f.line(x0, y0, x0, y1, stroke='--paper-dim')
    for v in (0, 20, 40, 50, 60):
        f.text(x0 - 10, Y(v), str(v), size=9.5, anchor='end', mono=True, fill='--paper-dim')
    for d in (1, 10, 20, 30):
        f.text(X(d), y0 + 16, str(d), size=9.5, mono=True, fill='--paper-dim')
    f.text((x0 + x1) / 2, y0 + 36, T('day of the month', 'dia do mês'), size=10, fill='--paper-dim')
    f.line(x0, Y(50), x1, Y(50), stroke='--amber', dash='6 4')
    f.text(x1, Y(50) - 10, T('budget: 50', 'orçamento: 50'), size=10, anchor='end', fill='--amber')
    f.line(x0, Y(40), x1, Y(40), stroke='--wire', dash='2 4')
    f.text(x1, Y(40) + 12, T('80% of the budget', '80% do orçamento'), size=9.5, anchor='end', fill='--paper-dim')
    f.path(f'M{X(1):.1f} {Y(2):.1f} L{X(30):.1f} {Y(60):.1f}', stroke='--phosphor', width=2)
    f.path(f'M{X(3):.1f} {Y(60):.1f} L{X(30):.1f} {Y(60):.1f}', stroke='--paper', width=1.4, dash='5 4')
    f.text(X(12), Y(60) - 12, T('forecast for the month', 'previsão do mês'), size=10, fill='--paper')
    f.circle(X(3), Y(60), 5, fill='--paper')
    f.text(X(3) + 10, Y(60) + 18, T('forecast alert, day 3', 'alerta de previsão, dia 3'), size=10, anchor='start', fill='--paper')
    f.circle(X(20), Y(40), 5, fill='--phosphor')
    f.text(X(20) + 10, Y(40) + 22, T('actual alert, day 20', 'alerta real, dia 20'), size=10, anchor='start', fill='--phosphor')
    f.text(X(13), Y(10), T('actual cost', 'custo real'), size=10, anchor='start', fill='--phosphor')
    return f, T('An invented month: the forecast alert arrives seventeen days before the actual one.',
                'Um mês inventado: o alerta de previsão chega dezessete dias antes do real.')


@figure('l13-delay', 13)
def delay():
    f = Fig('l13-delay', 720, 170, T(
        'The chain between a cost and the e-mail about it, from Microsoft\'s documentation: the cost '
        'is incurred; its data reaches Cost Management 8 to 24 hours later; budgets are evaluated once '
        'every 24 hours; the e-mail goes out within an hour of the evaluation.',
        'A cadeia entre um custo e o e-mail sobre ele, segundo a documentação da Microsoft: o custo '
        'acontece; os dados chegam ao Cost Management de 8 a 24 horas depois; os orçamentos são '
        'avaliados uma vez a cada 24 horas; o e-mail sai até uma hora depois da avaliação.'))
    steps = [T('a cost is incurred', 'um custo acontece'),
             T('data reaches Cost Management', 'os dados chegam ao Cost Management'),
             T('the budget is evaluated', 'o orçamento é avaliado'),
             T('the e-mail is sent', 'o e-mail é enviado')]
    gaps = [T('8 to 24 hours', '8 a 24 horas'), T('up to 24 hours', 'até 24 horas'),
            T('within an hour', 'até uma hora')]
    w, gap = 140, 40
    for i, s in enumerate(steps):
        x = 20 + i * (w + gap)
        f.rect(x, 50, w, 56, stroke='--wire' if i < 3 else '--amber', fill='--panel')
        words = s.split(' ')
        half = (len(words) + 1) // 2
        f.lines(x + w / 2, 78, [' '.join(words[:half]), ' '.join(words[half:])], size=10)
        if i < 3:
            f.arrow([(x + w + 3, 78), (x + w + gap - 3, 78)], stroke='--paper-dim')
            f.text(x + w + gap / 2, 132 if i % 2 == 0 else 30, gaps[i], size=9.5, fill='--paper-dim')
    return f, T('More than a day can pass between the cost and the alert about it.',
                'Mais de um dia pode passar entre o custo e o alerta sobre ele.')
