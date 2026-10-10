"""Lesson 17: finance, through the four questions every industry lesson uses
(the decisions, the indicators, the data, the trap).

Ipê Crédito is invented: a consumer-credit company in São Paulo with personal
loans and a credit card. Its head of BI is Fernanda Okada. What other lessons may
lean on: a loan is in default when an instalment is 90 or more days overdue (the
figure this lesson reports; lesson 21 sets it beside the 30 days collections
uses); the personal-loan product launched in January 2024; 2025 average book
R$ 820 million. Figures in millions of reais unless a name says otherwise."""
import book as B

LESSON = 'le-05agjtww'

# ---------------------------------------------------------------- the year
# (line, 2024, 2025)
YEAR = [
    ('Average loan book', 640, 820),
    ('Interest income', 236, 291),
    ('Fee income', 30, 36),
    ('Funding cost', 77, 98),
    ('Credit losses', 45, 74),
    ('Operating costs', 64, 72),
]
YEAR_PT = ['Carteira média', 'Receita de juros', 'Receita de tarifas', 'Custo de captação',
           'Perdas de crédito', 'Custos operacionais']

# ---------------------------------------------------------------- vintages
# The personal loan, by quarter of origination: amount lent (R$ million) and the
# share of it 90+ days overdue at 6, 9 and 12 months on book, counted from the end
# of the quarter; 12 stands for 12 or more. Empty where the vintage is not that old
# on 31 December 2025.
VINTAGES = [
    ('2024 Q1', 20, 2.0, 3.4, 4.5),
    ('2024 Q2', 24, 2.1, 3.5, 4.6),
    ('2024 Q3', 28, 2.2, 3.6, 4.8),
    ('2024 Q4', 32, 2.3, 3.8, 5.0),
    ('2025 Q1', 45, 2.9, 4.7, None),
    ('2025 Q2', 60, 3.4, None, None),
    ('2025 Q3', 80, None, None, None),
    ('2025 Q4', 105, None, None, None),
]
APPETITE = 4.0     # the 90+ rate the board said it would accept

# ---------------------------------------------------------------- fraud
CARD_TX = 400000           # card transactions in December 2025
FRAUD = 400                # of which fraudulent, found out later
LOSS = 1100                # reais lost on a fraud nobody stopped
FP_COST = 15               # reais to handle a good transaction that was blocked
RULES = [('Rule A', 300, 7992), ('Rule B', 240, 3996)]      # (rule, fraud caught, good blocked)

# ---------------------------------------------------------------- CLV
# (channel, acquisition cost, annual margin per customer, retention %), reais
CHANNELS = [
    ('Partner stores', 180, 260, 70),
    ('Search ads', 420, 380, 80),
    ('Comparison sites', 650, 340, 60),
    ('Referral', 120, 300, 75),
]
CHANNELS_PT = {'Partner stores': 'Lojas parceiras', 'Search ads': 'Anúncios de busca',
               'Comparison sites': 'Sites comparadores', 'Referral': 'Indicação'}


def year():
    rows = [['Line', '2024', '2025']] + [[n, a, b] for n, a, b in YEAR]
    # 2 book, 3 interest, 4 fees, 5 funding, 6 losses, 7 opex
    rows += [['Net interest income', '=B3-B5', '=C3-C5'],              # 8
             ['Total income', '=B8+B4', '=C8+C4'],                     # 9
             ['Profit before tax', '=B9-B6-B7', '=C9-C6-C7'],          # 10
             ['Net interest margin %', '=ROUND(B8/B2*100,1)', '=ROUND(C8/C2*100,1)'],
             ['Cost of risk %', '=ROUND(B6/B2*100,1)', '=ROUND(C6/C2*100,1)'],
             ['Efficiency ratio %', '=ROUND(B7/B9*100,1)', '=ROUND(C7/C9*100,1)']]
    cells = []
    for r in range(8, 14):
        cells += [f'B{r}', f'C{r}']
    return B.report('lesson 17 — Ipê\'s year', rows, cells, [
        '=ROUND((C2/B2-1)*100,1)', '=ROUND((C9/B9-1)*100,1)', '=ROUND((C10/B10-1)*100,1)',
        '=ROUND((C6/B6-1)*100,1)', '=C6-ROUND(C2*B6/B2,0)',
    ])


def vintages():
    rows = [['Vintage', 'Lent', 'M6', 'M9', 'M12', 'Now']]
    for k, (v, amt, a, b, c) in enumerate(VINTAGES, start=2):
        rows.append([v, amt, '' if a is None else a, '' if b is None else b, '' if c is None else c,
                     f'=IF(E{k}<>"",E{k},IF(D{k}<>"",D{k},IF(C{k}<>"",C{k},0)))'])
    n = len(rows)
    cells = [f'F{k}' for k in range(2, n + 1)]
    return B.report('lesson 17 — vintages of the personal loan', rows, cells, [
        f'=ROUND(SUMPRODUCT(B2:B{n},F2:F{n})/SUM(B2:B{n}),2)',
        '=ROUND(AVERAGE(C2:C5),1)', '=ROUND(AVERAGE(C6:C7),1)',
        '=ROUND(SUMPRODUCT(B2:B5,E2:E5)/SUM(B2:B5),2)',
        f'=SUM(B2:B{n})', '=SUM(B8:B9)', f'=ROUND(SUM(B8:B9)/SUM(B2:B{n})*100,1)',
        f'=ROUND(SUMPRODUCT(B2:B{n},F2:F{n})/100,1)',
        # the same book seen on 31 December 2024: Q1 at 9 months, Q2 at 6, Q3 and Q4 younger
        '=ROUND((B2*D2+B3*C3)/SUM(B2:B5),2)',
        '=ROUND((C7/C3-1)*100,1)',
    ])


def fraud():
    rows = [['Rule', 'Caught', 'Good blocked', 'Precision %', 'Missed', 'Cost']]
    for k, (r, c, g) in enumerate(RULES, start=2):
        rows.append([r, c, g, f'=ROUND(B{k}/(B{k}+C{k})*100,1)', f'={FRAUD}-B{k}',
                     f'=E{k}*{LOSS}+C{k}*{FP_COST}'])
    cells = ['D2', 'D3', 'E2', 'E3', 'F2', 'F3']
    return B.report('lesson 17 — two fraud rules, one month', rows, cells, [
        f'=ROUND({FRAUD}/{CARD_TX}*100,2)', f'={CARD_TX}-{FRAUD}',
        f'=ROUND(B2/{FRAUD}*100,0)', f'=ROUND(C2/({CARD_TX}-{FRAUD})*100,1)',
        f'=ROUND(C2/B2,1)', f'={FRAUD}*{LOSS}',
        f'=ROUND(B3/{FRAUD}*100,0)', f'=ROUND(C3/({CARD_TX}-{FRAUD})*100,1)',
        f'=E2*{LOSS}', f'=C2*{FP_COST}', f'=E3*{LOSS}', f'=C3*{FP_COST}',
    ])


def clv():
    rows = [['Channel', 'CAC', 'Margin', 'Retention %', 'Years', 'CLV', 'CLV/CAC']]
    for k, (c, cac, m, r) in enumerate(CHANNELS, start=2):
        rows.append([c, cac, m, r, f'=ROUND(1/(1-D{k}/100),2)', f'=ROUND(C{k}*E{k},0)',
                     f'=ROUND(F{k}/B{k},1)'])
    cells = []
    for k in range(2, 6):
        cells += [f'E{k}', f'F{k}', f'G{k}']
    return B.report('lesson 17 — customer lifetime value by channel', rows, cells, [
        '=ROUND(1/(1-0.9),1)', '=ROUND(1/(1-0.5),1)', '=ROUND(340*1/(1-0.75),0)',
        '=ROUND(260*1/(1-0.75),0)',
    ])


def questions():
    return B.report('lesson 17 — the exercises', [['a']], [], [
        '=ROUND(180/(180+2820)*100,1)', '=ROUND(30/1000*100,1)', '=ROUND(500/(1-0.8),0)',
        '=ROUND((300-120)/2000*100,1)', '=ROUND(2820/180,1)'])


# ----------------------------------------------------------------- figures

def four_figure():
    f = B.Fig('l17-four', 720, 360, (
        'Four boxes in a row, numbered 1 to 4, each with a question and Ipê Crédito\'s answer underneath. '
        '1, the decisions: what does this industry decide over and over? At Ipê: whom to lend to, how '
        'much and at what rate; which card payment to block. 2, the indicators: which serve those '
        'decisions? Net interest margin, cost of risk, default by vintage, fraud precision, lifetime '
        'value. 3, the data: where does it come from, and what is odd about it? The outcome of a loan '
        'arrives months after the decision, and declined applicants are never seen again. 4, the trap: '
        'which one is typical? A growing book looks safe, because young loans have not had time to '
        'default. An arrow runs from each box to the next.',
        'Quatro caixas em linha, numeradas de 1 a 4, cada uma com uma pergunta e a resposta da Ipê Crédito '
        'embaixo. 1, as decisões: o que este setor decide sem parar? Na Ipê: para quem emprestar, quanto e '
        'a que taxa; que compra no cartão bloquear. 2, os indicadores: quais servem a essas decisões? '
        'Margem financeira, custo do risco, inadimplência por safra, precisão da fraude, valor do '
        'cliente. 3, os dados: de onde vêm, e o que têm de estranho? O resultado de um empréstimo chega '
        'meses depois da decisão, e quem foi recusado nunca mais aparece. 4, a armadilha: qual é a típica? '
        'Uma carteira que cresce parece segura, porque os empréstimos novos ainda não tiveram tempo de '
        'atrasar. Uma seta vai de cada caixa para a seguinte.'))
    boxes = [
        (('the decisions', 'as decisões'),
         ('what does this industry', 'o que este setor'), ('decide over and over?', 'decide sem parar?'),
         [('whom to lend to, how', 'a quem emprestar, quanto'), ('much, at what rate;', 'e a que taxa; que'),
          ('which card payment', 'compra no cartão'), ('to block', 'bloquear')]),
        (('the indicators', 'os indicadores'),
         ('which ones serve', 'quais servem'), ('those decisions?', 'a essas decisões?'),
         [('net interest margin,', 'margem financeira,'), ('cost of risk, default', 'custo do risco,'),
          ('by vintage, fraud', 'atraso por safra,'), ('precision, CLV', 'precisão da fraude, CLV')]),
        (('the data', 'os dados'),
         ('where from, and what', 'de onde vêm, e o que'), ('is odd about it?', 'têm de estranho?'),
         [('a loan\'s outcome', 'o resultado do'), ('arrives months later;', 'empréstimo chega meses'),
          ('the declined are', 'depois; os recusados'), ('never seen again', 'nunca mais aparecem')]),
        (('the trap', 'a armadilha'),
         ('which one is typical', 'qual é a típica'), ('of this industry?', 'deste setor?'),
         [('a growing book looks', 'uma carteira que cresce'), ('safe: young loans have', 'parece segura: o'),
          ('not had time to', 'empréstimo novo ainda'), ('default', 'não teve tempo de atrasar')]),
    ]
    W, H, gap = 156, 300, 20
    for k, (title, q1, q2, ans) in enumerate(boxes):
        x = 20 + k * (W + gap)
        f.rect(x, 30, W, H, fill='--panel', stroke='--amber' if k == 3 else '--phosphor')
        f.text(x + 12, 56, str(k + 1), size=20, weight=600, fill='--paper-dim', mono=True)
        f.text(x + 34, 55, title, size=14, weight=600)
        f.text(x + 12, 84, q1, size=12)
        f.text(x + 12, 102, q2, size=12)
        f.line(x + 12, 120, x + W - 12, 120, stroke='--wire', sw=1)
        f.text(x + 12, 142, ('at Ipê:', 'na Ipê:'), size=11, fill='--paper-dim')
        for j, a in enumerate(ans):
            f.text(x + 12, 166 + j * 20, a, size=12)
        if k < 3:
            f.arrow(x + W + 2, 180, x + W + gap - 2, 180)
    f.text(360, 352, ('Lessons 18 to 21 ask the same four questions of retail, health, industry and the regulator.',
                      'As aulas 18 a 21 fazem as mesmas quatro perguntas ao varejo, à saúde, à indústria e ao regulador.'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'The four questions, answered for a consumer lender. The fourth is the one an analyst from outside '
        'the industry walks into, and the first three are how to see it coming.',
        'As quatro perguntas, respondidas para uma financeira. A quarta é aquela em que um analista de fora '
        'do setor cai, e as três primeiras são o jeito de vê-la chegando.'))


def risk_figure():
    amt = sum(v[1] for v in VINTAGES)
    young = sum(v[1] for v in VINTAGES[6:])
    now = []
    for v in VINTAGES:
        last = [x for x in v[2:] if x is not None]
        now.append(last[-1] if last else 0)
    head = sum(a * r for a, r in zip([v[1] for v in VINTAGES], now)) / amt
    f = B.Fig('l17-risk', 720, 440, (
        f'A mock of Ipê\'s monthly risk view for December 2025, personal loans. Three tiles: share of the '
        f'amount lent now 90 or more days overdue, {head:.2f}%, against a risk appetite of {APPETITE:.1f}%; '
        f'cost of risk for the whole book, 9.0% in 2025 against 7.0% in 2024; and the share of the amount '
        f'lent that is less than six months old, {young / amt * 100:.1f}%, which cannot show defaults yet. '
        f'Below, vintage curves: the share 90 or more days overdue at 6, 9 and 12 months on book, one line '
        f'per quarter of lending. The four 2024 lines sit close together, from 2.0 to 2.3% at six months '
        f'and 4.5 to 5.0% at twelve. The 2025 lines sit above them: 2.9 and 3.4% at six months.',
        f'Um esboço da visão mensal de risco da Ipê em dezembro de 2025, empréstimo pessoal. Três blocos: '
        f'parcela do valor emprestado hoje com 90 dias ou mais de atraso, {B.fmt(head, "pt", 2)}%, contra um '
        f'apetite de risco de {B.fmt(APPETITE, "pt", 1)}%; custo do risco da carteira toda, 9,0% em 2025 '
        f'contra 7,0% em 2024; e a parcela do valor emprestado com menos de seis meses, '
        f'{B.fmt(young / amt * 100, "pt", 1)}%, que ainda não consegue mostrar atrasos. Abaixo, curvas de '
        f'safra: a parcela com 90 dias ou mais de atraso aos 6, 9 e 12 meses de carteira, uma linha por '
        f'trimestre de concessão. As quatro linhas de 2024 ficam juntas, de 2,0 a 2,3% aos seis meses e '
        f'4,5 a 5,0% aos doze. As linhas de 2025 ficam acima delas: 2,9 e 3,4% aos seis meses.'))
    f.rect(8, 8, 704, 424, fill='--panel', stroke='--wire')
    f.text(24, 36, ('Ipê Crédito · risk view · personal loans · December 2025',
                    'Ipê Crédito · visão de risco · empréstimo pessoal · dez. 2025'), size=14, weight=600)
    tiles = [
        (('90+ days overdue, whole book', '90+ dias de atraso, carteira toda'),
         (f'{head:.2f}%', f'{B.fmt(head, "pt", 2)}%'),
         (f'risk appetite {APPETITE:.1f}%', f'apetite de risco {B.fmt(APPETITE, "pt", 1)}%'), False),
        (('cost of risk, whole company', 'custo do risco, empresa toda'), ('9.0%', '9,0%'),
         ('2024: 7.0%', '2024: 7,0%'), False),
        (('lent in the last six months', 'emprestado nos últimos 6 meses'),
         (f'{young / amt * 100:.1f}%', f'{B.fmt(young / amt * 100, "pt", 1)}%'),
         ('too young to show defaults', 'novo demais para mostrar atraso'), True),
    ]
    for k, (label, num, sub, hot) in enumerate(tiles):
        x = 24 + k * 228
        f.rect(x, 52, 216, 86, fill='--scan', stroke='--amber' if hot else '--wire', sw=2 if hot else 1)
        f.text(x + 14, 72, label, size=11, fill='--paper-dim')
        f.text(x + 14, 102, num, size=24, weight=600)
        f.text(x + 14, 124, sub, size=11)
    # vintage curves
    f.text(24, 164, ('Vintages: share 90+ days overdue, by months on book',
                     'Safras: parcela com 90+ dias de atraso, por meses de carteira'), size=12, weight=600)
    x0, x1, y0, y1 = 80, 430, 400, 186
    lo, hi = 0, 6
    ages = [6, 9, 12]
    sx = lambda i: x0 + i * (x1 - x0) / 2
    sy = lambda v: y0 - (v - lo) / (hi - lo) * (y0 - y1)
    for v in range(0, 7, 2):
        f.line(x0 - 6, sy(v), x0, sy(v), stroke='--paper-dim', sw=1)
        f.text(x0 - 10, sy(v) + 4, f'{v}%', size=11, anchor='end', mono=True, fill='--paper-dim')
    f.line(x0, y1 - 4, x0, y0, stroke='--paper-dim', sw=1)
    f.line(x0, y0, x1 + 8, y0, stroke='--paper-dim', sw=1)
    for i, a in enumerate(ages):
        f.text(sx(i), y0 + 16, (f'{a} months', f'{a} meses'), size=11, anchor='middle', fill='--paper-dim')
    f.line(x0, sy(APPETITE), x1, sy(APPETITE), stroke='--paper', sw=1, dash='5 4')
    f.text(x1 + 12, sy(APPETITE) + 4, ('appetite', 'apetite'), size=11)
    for name, _, *rates in VINTAGES:
        pts = [(i, r) for i, r in enumerate(rates) if r is not None]
        if not pts:
            continue
        hot = name.startswith('2025')
        col = '--amber' if hot else '--phosphor'
        if len(pts) > 1:
            f.path('M' + ' L'.join(f'{sx(i):.1f} {sy(r):.1f}' for i, r in pts), stroke=col, sw=2)
        for i, r in pts:
            f.bar(sx(i) - 3, sy(r) - 3, 6, 6, fill=col)
    f.text(sx(0) - 14, sy(3.4) - 2, ('2025 Q2', '2025 T2'), size=11, anchor='end')
    f.text(sx(1) - 14, sy(4.7) - 2, ('2025 Q1', '2025 T1'), size=11, anchor='end')
    f.text(x1 + 12, sy(5.0) - 4, ('2024, four quarters', '2024, quatro trimestres'), size=11)
    # the note on the right
    nx = 540
    notes = [
        (('2025 Q3 and Q4: R$ 185 million', '2025 T3 e T4: R$ 185 milhões'), True),
        (('lent, no point on the', 'emprestados, sem ponto no'), False),
        (('chart yet', 'gráfico ainda'), False),
        (('At six months, every 2025', 'Aos seis meses, cada safra'), True),
        (('vintage is above every', 'de 2025 está acima de'), False),
        (('2024 one.', 'todas as de 2024.'), False),
    ]
    for j, (t, strong) in enumerate(notes):
        if t[0] or t[1]:
            f.text(nx, 250 + j * 20, t, size=11, weight=600 if strong else None,
                   fill='--paper' if strong else '--paper-dim')
    B.place(LESSON, f, (
        'Ipê\'s risk view. The headline rate sits well under the appetite, and the tile beside it says why '
        'that means little: almost half the money was lent too recently to have defaulted. The vintage '
        'curves, compared at the same age, show the newer loans going bad faster.',
        'A visão de risco da Ipê. A taxa da manchete fica bem abaixo do apetite, e o bloco ao lado diz por '
        'que isso quer dizer pouco: quase metade do dinheiro foi emprestada recentemente demais para ter '
        'atrasado. As curvas de safra, comparadas na mesma idade, mostram os empréstimos novos estragando '
        'mais rápido.'))


def fraud_figure():
    legit = CARD_TX - FRAUD
    caught, blocked = RULES[0][1], RULES[0][2]
    f = B.Fig('l17-fraud', 720, 330, (
        f'A tree of December\'s 400,000 card payments. 400 are fraud and 399,600 are good. Of the 400 fraud, '
        f'rule A flags 300 and misses 100. Of the 399,600 good, it flags 7,992 and lets 391,608 through. '
        f'Among the 8,292 flagged, 300 are fraud: a precision of 3.6%.',
        f'Uma árvore dos 400.000 pagamentos com cartão de dezembro. 400 são fraude e 399.600 são legítimos. '
        f'Dos 400 fraudulentos, a regra A sinaliza 300 e deixa passar 100. Dos 399.600 legítimos, sinaliza '
        f'7.992 e deixa passar 391.608. Entre os 8.292 sinalizados, 300 são fraude: precisão de 3,6%.'))

    def node(cx, y, w, top, num, hot=False):
        f.rect(cx - w / 2, y, w, 52, fill='--panel', stroke='--amber' if hot else '--phosphor')
        f.text(cx, y + 21, top, size=11, anchor='middle', fill='--paper-dim')
        f.text(cx, y + 41, num, size=14, anchor='middle', weight=600, mono=True)

    def n(x):
        return (f'{x:,}', B.fmt(x, 'pt'))
    node(360, 14, 220, ('card payments in December', 'pagamentos com cartão em dezembro'), n(CARD_TX))
    node(190, 110, 180, ('fraud', 'fraude'), n(FRAUD))
    node(530, 110, 180, ('good', 'legítimos'), n(legit))
    node(95, 206, 150, ('fraud flagged', 'fraude sinalizada'), n(caught), hot=True)
    node(270, 206, 150, ('fraud missed', 'fraude que passou'), n(FRAUD - caught))
    node(450, 206, 150, ('good flagged', 'legítimos sinalizados'), n(blocked), hot=True)
    node(625, 206, 150, ('good let through', 'legítimos liberados'), n(legit - blocked))
    f.line(360, 66, 360, 88)
    f.line(190, 88, 530, 88)
    f.line(190, 88, 190, 108)
    f.line(530, 88, 530, 108)
    for cx, a, b in ((190, 95, 270), (530, 450, 625)):
        f.line(cx, 162, cx, 184)
        f.line(a, 184, b, 184)
        f.line(a, 184, a, 204)
        f.line(b, 184, b, 204)
    f.text(360, 292, (f'flagged by rule A: {caught + blocked:,}, of which {caught} are fraud',
                      f'sinalizados pela regra A: {B.fmt(caught + blocked, "pt")}, dos quais {caught} são fraude'),
           size=12, anchor='middle', weight=600)
    f.text(360, 314, ('precision 3.6%: about 27 good customers blocked for each fraud caught',
                      'precisão de 3,6%: cerca de 27 clientes bons bloqueados para cada fraude pega'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Rule A catches three frauds in four, and still most of what it flags is good customers, because '
        'good payments outnumber fraud a thousand to one.',
        'A regra A pega três fraudes em cada quatro, e ainda assim a maior parte do que ela sinaliza são '
        'clientes bons, porque os pagamentos legítimos superam a fraude mil para um.'))


def main():
    year()
    vintages()
    fraud()
    clv()
    questions()
    four_figure()
    risk_figure()
    fraud_figure()


if __name__ == '__main__':
    main()
