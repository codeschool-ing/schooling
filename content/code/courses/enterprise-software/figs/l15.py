"""Lesson 15: Buy versus build: how to justify the decision."""
from figures import Fig, T, figure

# Serra Alta's sheet, month by month (all invented; the lesson's tables are these numbers).
# Month 1 is January 2027 and month 36 is December 2029. Each line is (first, last, per month).
FTE, COLETA = 25_000, 15_000


def _a():
    sub = [(m, m, {1: 1900, 2: 2000, 3: 2100}[(m - 1) // 12 + 1] * (26 if m > 24 else 25))
           for m in range(1, 37)]
    return sub + [(1, 9, 40_000), (4, 9, 25_000), (2, 9, 30_000), (3, 8, 25_000), (1, 36, 2_500),
                  (10, 36, 4_000), (1, 9, FTE), (10, 36, FTE / 2), (7, 9, 80_000 / 3),
                  (1, 12, COLETA)] + [(m, m, 10_000) for m in range(12, 37, 3)]


def _b():
    return [(1, 36, 15_000), (1, 16, 62_500), (12, 16, 30_000), (8, 13, 25_000), (4, 16, 120_000),
            (13, 36, 4_000), (17, 36, 8_000), (1, 36, FTE), (14, 16, 80_000 / 3), (30, 30, 150_000),
            (1, 19, COLETA)]


def _c():
    return [(1, 12, 7 * FTE), (10, 14, 30_000), (5, 12, 37_500), (1, 12, 3_000), (13, 36, 9_000),
            (13, 36, 10_000), (24, 24, 40_000), (36, 36, 40_000), (13, 36, 35_000),
            (13, 15, 80_000 / 3), (30, 30, 60_000), (1, 18, COLETA)]


def _cumulative(spans):
    month = [0.0] * 37
    for a, z, amt in spans:
        for m in range(a, z + 1):
            month[m] += amt
    out, run = [0.0], 0.0
    for m in range(1, 37):
        run += month[m]
        out.append(run)
    return out


def _n(v):
    """A sum of reais, grouped the way each language writes it."""
    s = f'{round(v):,}'
    return T(s, s.replace(',', '.'))


def _m(v):
    """Millions with two decimals."""
    s = f'{v / 1e6:.2f}'
    return T(s + ' M', s.replace('.', ',') + ' mi')


@figure('l15-core-context', 15)
def core_context():
    f = Fig('l15-core-context', 720, 360, T(
        "A two-by-two grid of Serra Alta's work. The horizontal axis runs from context on the left, "
        "work every company does, to core on the right, work that sets Serra Alta apart. The "
        "vertical axis runs from supporting at the bottom to mission-critical at the top. Top left, "
        "context and mission-critical: payroll, accounting in SAP, issuing NF-e and the farm-payment "
        "calculation. Top right, core and mission-critical: the milk-quality payment policy and the "
        "field technicians who help farms meet it. Bottom left, context and supporting: email and "
        "Teams, expense claims. Bottom right, core and supporting: trying new things on the Portal "
        "B2B. A dashed box in the top right, farm payment as Joana first placed it, has an arrow "
        "splitting it in two: the policy stays core, and the calculation moves to context.",
        "Uma grade dois por dois do trabalho da Serra Alta. O eixo horizontal vai de contexto, à "
        "esquerda, o trabalho que toda empresa faz, a núcleo, à direita, o trabalho que diferencia a "
        "Serra Alta. O eixo vertical vai de apoio, embaixo, a crítico para a missão, em cima. Em cima "
        "à esquerda, contexto e crítico: folha de pagamento, contabilidade no SAP, emissão de NF-e e "
        "o cálculo do pagamento aos produtores. Em cima à direita, núcleo e crítico: a política de "
        "pagamento por qualidade do leite e os técnicos de campo que ajudam as fazendas a cumpri-la. "
        "Embaixo à esquerda, contexto e apoio: e-mail e Teams, reembolso de despesas. Embaixo à "
        "direita, núcleo e apoio: experimentos no Portal B2B. Uma caixa tracejada em cima à direita, "
        "o pagamento aos produtores onde Joana o pôs primeiro, tem uma seta que o divide em dois: a "
        "política fica no núcleo, e o cálculo passa para o contexto."))
    x0, x1, xm = 90, 700, 395
    y0, y1, ym = 20, 310, 165
    f.rect(x0, y0, x1 - x0, y1 - y0, stroke='--wire', fill='--panel', rx=2)
    f.line(xm, y0, xm, y1, stroke='--wire', width=1)
    f.line(x0, ym, x1, ym, stroke='--wire', width=1)
    f.text((x0 + xm) / 2, 334, T('context: every company does it', 'contexto: toda empresa faz'),
           size=11, weight='600')
    f.text((xm + x1) / 2, 334, T('core: it sets Serra Alta apart', 'núcleo: diferencia a Serra Alta'),
           size=11, weight='600')
    f.lines(46, 92, [T('mission-', 'crítico'), T('critical', 'para a missão')], size=10.5,
            weight='600')
    f.lines(44, 238, [T('supporting', 'apoio')], size=10.5, weight='600')
    # top left
    for i, s in enumerate([T('payroll', 'folha de pagamento'),
                           T('accounting in SAP', 'contabilidade no SAP'),
                           T('issuing NF-e', 'emissão de NF-e')]):
        f.box(178, 44 + i * 32, 150, 24, [s], size=10)
    f.box(320, 132, 132, 34, [T('farm-payment', 'cálculo do'), T('calculation', 'pagamento')],
          size=10, stroke='--phosphor')
    # top right
    f.box(498, 128, 156, 40, [T('milk-quality', 'política de pagamento'),
                              T('payment policy', 'por qualidade')], size=10, stroke='--phosphor')
    f.box(624, 64, 128, 40, [T('field technicians', 'técnicos de campo'),
                             T('on the farms', 'nas fazendas')], size=10)
    f.box(470, 58, 132, 32, [T('farm payment,', 'pagamento, onde'), T('first draft', 'Joana o pôs')],
          size=9.5, stroke='--amber', dash='4 3', fillt='--paper')
    f.arrow([(498, 75), (498, 106)], stroke='--phosphor', width=1.3)
    f.arrow([(430, 82), (346, 113)], stroke='--phosphor', width=1.3)
    # bottom
    f.box(178, 214, 150, 24, [T('email and Teams', 'e-mail e Teams')], size=10)
    f.box(178, 250, 150, 24, [T('expense claims', 'reembolso de despesas')], size=10)
    f.box(548, 232, 176, 40, [T('trying new things', 'experimentos'),
                              T('on the Portal B2B', 'no Portal B2B')], size=10)
    return f, T('Two questions, not one. Whether work sets the company apart decides buy or build; '
                'whether it is mission-critical decides how carefully either is done.',
                'Duas perguntas, não uma. Se o trabalho diferencia a empresa decide entre comprar e '
                'construir; se ele é crítico decide o cuidado com que qualquer dos dois é feito.')


@figure('l15-a-by-year', 15)
def a_by_year():
    f = Fig('l15-a-by-year', 720, 300, T(
        "Option A, the SaaS product, as four bars. Year 1 is the tallest, R$ 2,044,500: R$ 1,160,000 "
        "of it paid once (implementation, migration, integration, customisation, training and "
        "Coleta's last twelve months) and R$ 884,500 that recurs. Year 2 is R$ 868,000 and year 3 is "
        "R$ 923,200, all recurring. A fourth, dashed bar is the exit, R$ 397,800, paid only if "
        "Serra Alta leaves.",
        "A opção A, o produto SaaS, em quatro barras. O ano 1 é a mais alta, R$ 2.044.500: "
        "R$ 1.160.000 pagos uma vez (implantação, migração, integração, customização, treinamento e "
        "os últimos doze meses da Coleta) e R$ 884.500 que se repetem. O ano 2 é R$ 868.000 e o ano 3, "
        "R$ 923.200, tudo recorrente. Uma quarta barra, tracejada, é a saída, R$ 397.800, paga só se "
        "a Serra Alta sair."))
    base, k = 250, 200 / 2_100_000
    bars = [(T('year 1', 'ano 1'), 884_500, 1_160_000, 2_044_500),
            (T('year 2', 'ano 2'), 868_000, 0, 868_000),
            (T('year 3', 'ano 3'), 923_200, 0, 923_200)]
    for i, (name, rec, once, tot) in enumerate(bars):
        x = 120 + i * 140
        h1 = rec * k
        f.rect(x, base - h1, 90, h1, stroke=None, fill='--phosphor', rx=0)
        if once:
            h2 = once * k
            f.rect(x, base - h1 - h2, 90, h2, stroke=None, fill='--amber', rx=0)
            f.text(x + 45, base - h1 - h2 / 2, _n(once), size=10, fill='--ink', weight='600')
        f.text(x + 45, base - h1 / 2, _n(rec), size=10, fill='--ink', weight='600')
        f.text(x + 45, base - tot * k - 12, _n(tot), size=10.5, weight='600', mono=True)
        f.text(x + 45, base + 18, name, size=11, weight='600')
    x = 120 + 3 * 140
    h = 397_800 * k
    f.rect(x, base - h, 90, h, stroke='--paper-dim', fill='--panel', rx=0, dash='4 3')
    f.text(x + 45, base - h - 12, _n(397_800), size=10.5, weight='600', mono=True)
    f.text(x + 45, base + 18, T('exit', 'saída'), size=11, weight='600')
    f.line(100, base, 680, base, stroke='--wire', width=1)
    f.rect(120, 278, 12, 12, stroke=None, fill='--amber', rx=0)
    f.text(138, 284, T('paid once', 'pago uma vez'), size=10.5, anchor='start')
    f.rect(270, 278, 12, 12, stroke=None, fill='--phosphor', rx=0)
    f.text(288, 284, T('paid every year', 'pago todo ano'), size=10.5, anchor='start')
    f.rect(430, 278, 12, 12, stroke='--paper-dim', fill='--panel', rx=0, dash='3 2')
    f.text(448, 284, T('paid only on leaving', 'pago só ao sair'), size=10.5, anchor='start')
    return f, T('Option A, in reais, by the year the money is paid. Year 1 carries everything that '
                'is paid once; years 2 and 3 show what owning it costs.',
                'A opção A, em reais, pelo ano em que o dinheiro é pago. O ano 1 carrega tudo o que se '
                'paga uma vez; os anos 2 e 3 mostram quanto custa ter o sistema.')


@figure('l15-quote-and-sheet', 15)
def quote_and_sheet():
    f = Fig('l15-quote-and-sheet', 720, 250, T(
        "Two horizontal bars on one scale. Option A: the vendor's proposal showed R$ 2,070,000, and "
        "the full three-year sheet, exit included, is R$ 4,233,500, so R$ 2,163,500 was not in the "
        "proposal. Option C: the build estimate was R$ 2,100,000, and the full sheet is "
        "R$ 4,679,000, so R$ 2,579,000 was not in the estimate.",
        "Duas barras horizontais na mesma escala. Opção A: a proposta do fornecedor mostrava "
        "R$ 2.070.000, e a planilha completa de três anos, com a saída, dá R$ 4.233.500; portanto "
        "R$ 2.163.500 não estavam na proposta. Opção C: a estimativa de construção era "
        "R$ 2.100.000, e a planilha completa dá R$ 4.679.000; portanto R$ 2.579.000 não estavam na "
        "estimativa."))
    x0, k = 120, 480 / 4_700_000
    rows = [(T('A: buy', 'A: comprar'), T('the proposal', 'a proposta'), 2_070_000, 4_233_500, 62),
            (T('C: build', 'C: construir'), T('the estimate', 'a estimativa'), 2_100_000, 4_679_000, 160)]
    for name, what, quoted, full, y in rows:
        f.text(x0 - 12, y + 17, name, size=11, weight='600', anchor='end')
        wq, wf = quoted * k, full * k
        f.rect(x0, y, wq, 34, stroke=None, fill='--phosphor', rx=0)
        f.rect(x0 + wq, y, wf - wq, 34, stroke='--amber', fill='--panel', rx=0, dash='4 3')
        f.text(x0 + wq / 2, y + 17, what, size=10.5, fill='--ink', weight='600')
        f.text(x0 + wq + (wf - wq) / 2, y + 11, T('not in it', 'fora dela'), size=10, fill='--amber',
               weight='600')
        f.text(x0 + wq + (wf - wq) / 2, y + 25, _n(full - quoted), size=10, mono=True)
        f.text(x0 + wq / 2, y - 9, _n(quoted), size=10, mono=True, fill='--paper-dim')
        f.text(x0 + wf + 6, y + 17, _n(full), size=10.5, mono=True, weight='600', anchor='start')
    f.line(x0, 222, x0 + 4_500_000 * k, 222, stroke='--wire', width=1)
    for v in range(0, 5_000_000, 1_000_000):
        f.line(x0 + v * k, 218, x0 + v * k, 226, stroke='--wire', width=1)
        f.text(x0 + v * k, 238, _m(v) if v else '0', size=9.5, fill='--paper-dim')
    return f, T('What each side put on the first page, and the three-year sheet with every line. '
                'Both first numbers were honest; neither was a cost of ownership.',
                'O que cada lado pôs na primeira página, e a planilha de três anos com todas as '
                'linhas. Os dois primeiros números eram honestos; nenhum era custo de propriedade.')


@figure('l15-cumulative', 15)
def cumulative():
    f = Fig('l15-cumulative', 720, 360, T(
        "Cumulative spending of the three options over 36 months, from January 2027, in millions of "
        "reais. All three start together. C, the build, climbs fastest in year 1 and reaches "
        "R$ 2.71 million at month 12; B, the SAP extension, overtakes it and reaches R$ 3.97 million "
        "by month 18; A, the SaaS product, flattens after month 9. At month 36 A has spent "
        "R$ 3.84 million, C R$ 4.37 million and B R$ 5.07 million. A dot on each line marks the "
        "first farm payment from the new system: A at month 10, C at month 16, B at month 17. A "
        "dashed vertical line at month 18 marks Sebastião's retirement. Exit costs are not drawn.",
        "Gasto acumulado das três opções em 36 meses, a partir de janeiro de 2027, em milhões de "
        "reais. As três começam juntas. C, a construção, sobe mais rápido no ano 1 e chega a "
        "R$ 2,71 milhões no mês 12; B, a extensão do SAP, a ultrapassa e chega a R$ 3,97 milhões no "
        "mês 18; A, o produto SaaS, achata depois do mês 9. No mês 36 A gastou R$ 3,84 milhões, C "
        "R$ 4,37 milhões e B R$ 5,07 milhões. Um ponto em cada linha marca o primeiro pagamento aos "
        "produtores pelo sistema novo: A no mês 10, C no mês 16, B no mês 17. Uma linha vertical "
        "tracejada no mês 18 marca a aposentadoria de Sebastião. Os custos de saída não estão "
        "desenhados."))
    X0, X1, Y0, Y1 = 80, 590, 30, 300
    top = 5_500_000

    def px(m):
        return X0 + (X1 - X0) * m / 36

    def py(v):
        return Y1 - (Y1 - Y0) * v / top

    for v in range(0, 6_000_000, 1_000_000):
        f.line(X0, py(v), X1, py(v), stroke='--wire', width=0.8, dash=None if v == 0 else '2 4')
        f.text(X0 - 8, py(v), _m(v) if v else '0', size=9.5, fill='--paper-dim', anchor='end', mono=True)
    for m in range(0, 37, 6):
        f.text(px(m), Y1 + 15, str(m), size=9.5, fill='--paper-dim', mono=True)
    f.text((X0 + X1) / 2, Y1 + 34, T('months from January 2027', 'meses a partir de janeiro de 2027'),
           size=10.5, fill='--paper-dim')
    f.line(px(18), Y0, px(18), Y1, stroke='--paper-dim', width=1, dash='4 3')
    f.text(px(18) + 6, Y0 + 6, T('Sebastião retires', 'Sebastião se aposenta'), size=10, anchor='start',
           fill='--paper-dim')
    series = [(_a(), '--phosphor', None, T('A: buy', 'A: comprar'), 10),
              (_b(), '--amber', None, T('B: extend SAP', 'B: estender o SAP'), 17),
              (_c(), '--paper', '6 3', T('C: build', 'C: construir'), 16)]
    ends = {}
    for spans, colour, dash, name, first in series:
        c = _cumulative(spans)
        f.path('M' + ' L'.join(f'{px(m):.1f} {py(c[m]):.1f}' for m in range(37)), stroke=colour,
               width=2, dash=dash)
        f.circle(px(first), py(c[first]), 4, fill=colour)
        ends[name] = c[36]
    for (spans, colour, dash, name, first), dy in zip(series, (6, 0, 0)):
        v = ends[name]
        f.text(X1 + 10, py(v) + dy - 7, name, size=10.5, anchor='start', weight='600')
        f.text(X1 + 10, py(v) + dy + 7, _m(v), size=10, anchor='start', mono=True)
    f.circle(X0 + 10, 348, 4, fill='--paper-dim')
    f.text(X0 + 20, 348, T('first farm payment from the new system', 'primeiro pagamento aos produtores pelo sistema novo'),
           size=10, anchor='start', fill='--paper-dim')
    return f, T('Cumulative spending, in millions of reais, before any exit cost. The build spends '
                'first and the extension spends most; the purchase is the only one paying farms '
                'before 2028.',
                'Gasto acumulado, em milhões de reais, antes de qualquer custo de saída. A construção '
                'gasta primeiro e a extensão gasta mais; a compra é a única que paga produtores antes '
                'de 2028.')
