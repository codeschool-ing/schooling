"""Lesson 15: tactical BI. Renata's marketing review for November 2025: the
online shop's channels against their targets, the department's budget against
what was spent, and the review drawn as the screen she opens on 5 December.

November's online sales (R$ 2,060 thousand, against R$ 1,660 thousand in
November 2024) and the campaign that moved from October into November are
lesson 7's; this file only adds what the marketing review needs."""
import book as B

LESSON = 'le-rh1kdw2s'

# November 2025, the online shop by traffic channel:
# (channel, spend in thousands of reais, visits, orders, target cost per order in reais)
CHANNELS = [
    ('Paid search', 96, 118000, 1860, 55),
    ('Social ads', 84, 142000, 1090, 65),
    ('Email', 9, 46000, 930, 12),
    ('Organic and direct', 0, 168000, 1270, None),
]
CHANNELS_PT = {'Paid search': 'Busca paga', 'Social ads': 'Anúncios em redes',
               'Email': 'E-mail', 'Organic and direct': 'Orgânico e direto'}
ORDERS_TARGET = 4800
ONLINE_NOV = (1660, 2060)          # lesson 7: November's online shop, 2024 and 2025
ONLINE_OCT = (1370, 1080)          # lesson 7: October's

# The marketing department's November budget and what happened, thousands of reais.
# (line, kind, budget, actual)
BUDGET = [
    ('Online sales', 'revenue', 1900, 2060),
    ('Paid search', 'cost', 90, 96),
    ('Social ads', 'cost', 70, 84),
    ('Email platform', 'cost', 10, 9),
    ('Content production', 'cost', 30, 22),
    ('Free-delivery offers', 'cost', 40, 52),
]
BUDGET_PT = {'Online sales': 'Vendas online', 'Paid search': 'Busca paga', 'Social ads': 'Anúncios em redes',
             'Email platform': 'Plataforma de e-mail', 'Content production': 'Produção de conteúdo',
             'Free-delivery offers': 'Ofertas de frete grátis'}

assert sum(c[1] for c in CHANNELS) == sum(b[3] for b in BUDGET[1:4])
assert BUDGET[0][3] == ONLINE_NOV[1]


def channels():
    rows = [['Channel', 'Spend', 'Visits', 'Orders', 'Target', 'Cost per order', 'Conversion %']]
    for k, (n, sp, v, o, t) in enumerate(CHANNELS, start=2):
        rows.append([n, sp, v, o, '' if t is None else t,
                     f'=IF(B{k}=0,"",ROUND(B{k}*1000/D{k},1))', f'=ROUND(D{k}/C{k}*100,2)'])
    n = len(rows)
    rows.append(['Total', f'=SUM(B2:B{n})', f'=SUM(C2:C{n})', f'=SUM(D2:D{n})', '', '',
                 f'=ROUND(D{n + 1}/C{n + 1}*100,2)'])
    return B.report('lesson 15 — November by channel', rows,
                    ['F2', 'F3', 'F4', 'F5', 'G2', 'G3', 'G4', 'G5', f'B{n + 1}', f'C{n + 1}',
                     f'D{n + 1}', f'G{n + 1}'],
                    [f'=ROUND(B{n + 1}*1000/SUM(D2:D4),1)',
                     f'=ROUND(B{n + 1}*1000/D{n + 1},1)',
                     f'=ROUND({ONLINE_NOV[1]}*1000/D{n + 1},0)',
                     f'=ROUND((D{n + 1}/{ORDERS_TARGET}-1)*100,1)',
                     f'=ROUND((F3/E3-1)*100,1)',
                     f'=ROUND((F2/E2-1)*100,1)'])


def versus():
    """November against budget and against last year, and the two months together (lesson 7)."""
    (n24, n25), (o24, o25) = ONLINE_NOV, ONLINE_OCT
    rows = [['', '2024', '2025', 'Budget'], ['Oct', o24, o25, ''], ['Nov', n24, n25, BUDGET[0][2]]]
    return B.report('lesson 15 — November online, against budget and last year', rows, [], [
        '=ROUND((C3/D3-1)*100,1)', '=ROUND((C3/B3-1)*100,1)', '=B2+B3', '=C2+C3',
        '=ROUND(((C2+C3)/(B2+B3)-1)*100,1)', '=ROUND((189/170-1)*100,1)',
        f'=ROUND(40000/{ORDERS_TARGET},2)', '=ROUND(52000/5150,2)'])


def variance():
    """The table the student types: variance and variance percent, and the verdict."""
    rows = [['Line', 'Kind', 'Budget', 'Actual', 'Variance', 'Variance %', 'Verdict']]
    for k, (line, kind, b, a) in enumerate(BUDGET, start=2):
        rows.append([line, kind, b, a, f'=D{k}-C{k}', f'=ROUND(E{k}/C{k}*100,1)',
                     f'=IF(B{k}="revenue",IF(E{k}>=0,"F","U"),IF(E{k}<=0,"F","U"))'])
    n = len(rows)
    rows.append(['Total cost', '', f'=SUM(C3:C{n})', f'=SUM(D3:D{n})', f'=D{n + 1}-C{n + 1}',
                 f'=ROUND(E{n + 1}/C{n + 1}*100,1)', ''])
    cells = []
    for r in range(2, n + 2):
        cells += [f'E{r}', f'F{r}', f'G{r}']
    cells += [f'C{n + 1}', f'D{n + 1}']
    return B.report('lesson 15 — budget against actual, November', rows, cells, [
        f'=ROUND(C{n + 1}/C2*100,1)', f'=ROUND(D{n + 1}/D2*100,1)',
        '=E3+E4',
    ])


def questions():
    """What the exercises ask that the sections do not compute."""
    return B.report('lesson 15 — the exercises', [['a']], [], [
        '=ROUND(84000/1090,1)', '=ROUND((52-40)/40*100,1)', '=ROUND(-8/30*100,1)',
        '=ROUND(30000/400,1)', '=ROUND((1150-1200)/1200*100,1)', '=ROUND(96000/1860,1)'])


# ----------------------------------------------------------------- figures

def review_figure():
    tot_sp = sum(c[1] for c in CHANNELS)
    tot_o = sum(c[3] for c in CHANNELS)
    n24, n25 = ONLINE_NOV
    o24, o25 = ONLINE_OCT
    bud = BUDGET[0][2]

    def pct(x, lang, dp=1):
        s = f'{x:+.{dp}f}%'
        return s.replace('.', ',') if lang == 'pt' else s

    vb = (n25 / bud - 1) * 100
    vy = (n25 / n24 - 1) * 100
    v2 = ((o25 + n25) / (o24 + n24) - 1) * 100
    vo = (tot_o / ORDERS_TARGET - 1) * 100
    f = B.Fig('l15-review', 720, 430, (
        f'A mock of the marketing review screen for November 2025, closed on 5 December. Three tiles: '
        f'online sales R$ 2,060 thousand, {vb:+.1f}% on budget and {vy:+.1f}% on November 2024, with a note '
        f'that the campaign moved from October and October and November together grew {v2:+.1f}%; orders '
        f'{tot_o:,}, {vo:+.1f}% on a target of {ORDERS_TARGET:,}; media spend R$ {tot_sp} thousand against '
        f'a budget of R$ 170 thousand. Below, a table by channel with spend, visits, orders and cost per '
        f'order against its target, drawn as a bar with a target mark. Social ads is the one channel '
        f'over its target.',
        f'Um esboço da tela da reunião de marketing de novembro de 2025, fechada em 5 de dezembro. Três '
        f'blocos: vendas online R$ 2.060 mil, {pct(vb, "pt")} sobre o orçamento e {pct(vy, "pt")} sobre '
        f'novembro de 2024, com a nota de que a campanha veio de outubro e outubro e novembro juntos '
        f'cresceram {pct(v2, "pt")}; pedidos {B.fmt(tot_o, "pt")}, {pct(vo, "pt")} sobre a meta de '
        f'{B.fmt(ORDERS_TARGET, "pt")}; gasto em mídia R$ {tot_sp} mil contra orçamento de R$ 170 mil. '
        f'Abaixo, uma tabela por canal com gasto, visitas, pedidos e custo por pedido contra a meta, '
        f'desenhado como barra com uma marca na meta. Anúncios em redes é o único canal acima da meta.'))
    f.rect(8, 8, 704, 414, fill='--panel', stroke='--wire')
    f.text(24, 36, ('Marketing review · November 2025', 'Reunião de marketing · novembro de 2025'),
           size=14, weight=600)
    f.text(696, 36, ('month closed 5 Dec · online shop', 'mês fechado em 5/dez · loja online'), size=12,
           anchor='end', fill='--paper-dim')
    tiles = [
        (('online sales', 'vendas online'), ('R$ 2,060 thousand', 'R$ 2.060 mil'),
         [((f'{pct(vb, "en")} on budget', f'{pct(vb, "pt")} sobre o orçamento')),
          ((f'{pct(vy, "en")} on Nov 2024 *', f'{pct(vy, "pt")} sobre nov/2024 *'))]),
        (('orders', 'pedidos'), (f'{tot_o:,}', B.fmt(tot_o, 'pt')),
         [((f'{pct(vo, "en")} on target', f'{pct(vo, "pt")} sobre a meta')),
          ((f'target {ORDERS_TARGET:,}', f'meta {B.fmt(ORDERS_TARGET, "pt")}'))]),
        (('media spend', 'gasto em mídia'), (f'R$ {tot_sp} thousand', f'R$ {tot_sp} mil'),
         [(('budget R$ 170 thousand', 'orçamento R$ 170 mil')),
          ((f'{pct((tot_sp / 170 - 1) * 100, "en")} on budget', f'{pct((tot_sp / 170 - 1) * 100, "pt")} sobre o orçamento'))]),
    ]
    for k, (label, num, lines) in enumerate(tiles):
        x = 24 + k * 228
        f.rect(x, 52, 216, 96, fill='--scan', stroke='--amber' if k == 2 else '--wire',
               sw=2 if k == 2 else 1)
        f.text(x + 14, 72, label, size=11, fill='--paper-dim')
        f.text(x + 14, 98, num, size=20, weight=600)
        f.text(x + 14, 118, lines[0], size=11)
        f.text(x + 14, 136, lines[1], size=11, fill='--paper-dim')
    f.text(24, 168, (f'* the yearly campaign moved from late October into November; October and November '
                     f'together: {pct(v2, "en")}',
                     f'* a campanha anual saiu do fim de outubro para novembro; outubro e novembro juntos: '
                     f'{pct(v2, "pt")}'), size=11, fill='--paper-dim')
    f.text(24, 198, ('By channel', 'Por canal'), size=12, weight=600)
    heads = [(24, ('channel', 'canal'), 'start'), (240, ('spend', 'gasto'), 'end'),
             (316, ('visits', 'visitas'), 'end'), (382, ('orders', 'pedidos'), 'end'),
             (408, ('cost per order against target', 'custo por pedido contra a meta'), 'start')]
    for x, h, a in heads:
        f.text(x, 220, h, size=11, anchor=a, fill='--paper-dim')
    bx, bw = 408, 170             # the bar area
    top = 100.0                   # reais at the right-hand end
    for k, (n, sp, v, o, t) in enumerate(CHANNELS):
        y = 230 + k * 40
        hot = t is not None and sp * 1000 / o > t
        f.rect(20, y, 680, 34, fill='--scan', stroke='--amber' if hot else '--wire', sw=2 if hot else 1)
        ty = y + 22
        f.text(30, ty, (n, CHANNELS_PT[n]), size=12)
        f.text(240, ty, ('—' if sp == 0 else f'R$ {sp}k', '—' if sp == 0 else f'R$ {sp} mil'), size=12,
               anchor='end', mono=True)
        f.text(316, ty, (f'{v:,}', B.fmt(v, 'pt')), size=12, anchor='end', mono=True)
        f.text(382, ty, (f'{o:,}', B.fmt(o, 'pt')), size=12, anchor='end', mono=True)
        if t is None:
            f.text(bx, ty, ('no media spend', 'sem gasto em mídia'), size=11, fill='--paper-dim')
            continue
        cpo = sp * 1000 / o
        f.bar(bx, y + 11, bw * cpo / top, 12, fill='--amber' if hot else '--phosphor')
        tx = bx + bw * t / top
        f.line(tx, y + 6, tx, y + 28, stroke='--paper', sw=2)
        lab = f'R$ {cpo:.1f}'
        f.text(bx + bw + 10, ty, (f'{lab} / {t}', f'{lab.replace(".", ",")} / {t}'), size=12, mono=True,
               weight=600 if hot else None)
    f.text(24, 404, ('Bar: cost per order in reais; white mark: the target. Organic and direct visits '
                     'cost no media.',
                     'Barra: custo por pedido em reais; marca branca: a meta. Visitas orgânicas e diretas '
                     'não custam mídia.'), size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'Renata\'s November screen. Every number sits beside the one it is judged against: the budget, '
        'last year, the target. The footnote stops a campaign that moved from passing for growth.',
        'A tela de novembro da Renata. Cada número fica ao lado daquele contra o qual é julgado: o '
        'orçamento, o ano passado, a meta. A nota de rodapé impede que uma campanha que mudou de mês '
        'passe por crescimento.'))


def variance_figure():
    rows = []
    for line, kind, b, a in BUDGET:
        v = a - b
        good = v >= 0 if kind == 'revenue' else v <= 0
        rows.append((line, kind, v, v / b * 100, good))
    f = B.Fig('l15-variance', 720, 300, (
        'Horizontal bars of November\'s variance against budget, in thousands of reais, for six lines. '
        'Online sales +160, favourable. Paid search +6, social ads +14 and free-delivery offers +12, all '
        'costs above budget and so unfavourable. Email platform −1 and content production −8, costs '
        'below budget and so favourable. Bars going right are above budget; the colour says whether '
        'that is good.',
        'Barras horizontais da variação de novembro contra o orçamento, em milhares de reais, para seis '
        'linhas. Vendas online +160, favorável. Busca paga +6, anúncios em redes +14 e ofertas de frete '
        'grátis +12, todos custos acima do orçamento e portanto desfavoráveis. Plataforma de e-mail −1 e '
        'produção de conteúdo −8, custos abaixo do orçamento e portanto favoráveis. Barras para a direita '
        'estão acima do orçamento; a cor diz se isso é bom.'))
    zero = 360
    scale = 1.6                    # px per thousand reais, sales shown on the same scale
    top, row = 40, 34
    f.text(zero, 22, ('variance, R$ thousand: below budget ← → above budget',
                      'variação, R$ mil: abaixo do orçamento ← → acima do orçamento'),
           size=12, anchor='middle', fill='--paper-dim')
    f.line(zero, top - 4, zero, top + row * len(rows), stroke='--paper-dim', sw=1)
    for k, (line, kind, v, p, good) in enumerate(rows):
        y = top + k * row
        f.text(150, y + 20, (line, BUDGET_PT[line]),
               size=12, anchor='end')
        f.text(156, y + 20, (f'({kind})', '(receita)' if kind == 'revenue' else '(custo)'), size=11,
               fill='--paper-dim')
        w = max(abs(v) * scale, 2)
        fill = '--phosphor' if good else '--amber'
        sign = '+' if v > 0 else '−'
        lab_en = f'{sign}{abs(v)}  ' + ('F' if good else 'U')
        lab_pt = f'{sign}{abs(v)}  ' + ('F' if good else 'D')
        if v >= 0:
            f.bar(zero, y + 8, w, 18, fill=fill)
            f.text(zero + w + 6, y + 21, (lab_en, lab_pt), size=11, mono=True)
        else:
            f.bar(zero - w, y + 8, w, 18, fill=fill)
            f.text(zero - w - 6, y + 21, (lab_en, lab_pt), size=11, mono=True, anchor='end')
    yl = top + row * len(rows) + 30
    f.bar(170, yl - 11, 14, 14, fill='--phosphor')
    f.text(190, yl, ('F: favourable', 'F: favorável'), size=12)
    f.bar(330, yl - 11, 14, 14, fill='--amber')
    f.text(350, yl, ('U: unfavourable', 'D: desfavorável'), size=12)
    B.place(LESSON, f, (
        'The same sign means opposite things on the two kinds of line. Sales above budget are good '
        'news; a cost above budget is not, and a cost below it is only good news if it is a saving.',
        'O mesmo sinal quer dizer coisas opostas nos dois tipos de linha. Vendas acima do orçamento são '
        'boa notícia; um custo acima do orçamento não é, e um custo abaixo só é boa notícia se for '
        'economia.'))


def main():
    channels()
    versus()
    variance()
    questions()
    review_figure()
    variance_figure()


if __name__ == '__main__':
    main()
