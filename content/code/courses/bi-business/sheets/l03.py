"""Lesson 3: the four roles on the path from the records to a decision, Renata's
repeat-customer question with its numbers, and what crosses each handoff."""
import book as B

LESSON = 'le-4xcwse98'

# Renata's question, on the online shop's 2025 first-time customers.
FIRST_TIME = 13200          # customers whose first ever order was placed in January to June 2025
RETURNED = 3820            # of those, bought again within 180 days of the first order
ONLY_CANCELLED = 420       # of those, whose only order was later cancelled


LATE_FIRST, LATE_RETURNED = 840, 184     # first order delivered late, and of those came back


def by_delivery():
    rows = [['First order', 'Customers', 'Came back', 'Rate'],
            ['Late', LATE_FIRST, LATE_RETURNED, '=ROUND(C2/B2*100,1)'],
            ['On time', FIRST_TIME - LATE_FIRST, RETURNED - LATE_RETURNED, '=ROUND(C3/B3*100,1)'],
            ['All', '=B2+B3', '=C2+C3', '=ROUND(C4/B4*100,1)']]
    return B.report('lesson 3 — repeat rate by whether the first order arrived late', rows,
                    ['B3', 'C3', 'D2', 'D3', 'D4'])


def repeat():
    rows = [['Measure', 'Customers'],
            ['First-time customers, Jan-Jun 2025', FIRST_TIME],
            ['Bought again within 180 days', RETURNED],
            ['Only order cancelled', ONLY_CANCELLED],
            ['Repeat rate, as first defined', '=ROUND(B3/B2*100,1)'],
            ['First-time customers, cancelled excluded', '=B2-B4'],
            ['Repeat rate, cancelled excluded', '=ROUND(B3/B6*100,1)']]
    return B.report('lesson 3 — the repeat rate, and the same rate after the pipeline changed',
                    rows, ['B5', 'B6', 'B7'])


def roles():
    f = B.Fig('l03-roles', 720, 420, (
        'A path from left to right. On the left, the company\'s records: the stores\' tills, the '
        'online shop, the warehouse. An arrow to the data engineer, who delivers data that arrives '
        'correct and on time, into one database. From the database three arrows go to three roles '
        'stacked on the right: the BI analyst, who delivers the recurring answers and the '
        'definitions behind them; the data analyst, who delivers an answer to a new question; the '
        'data scientist, who delivers a model that predicts or decides. All three arrows end at '
        'the decisions.',
        'Um caminho da esquerda para a direita. À esquerda, os registros da empresa: os caixas das '
        'lojas, a loja online, o depósito. Uma seta para o engenheiro de dados, que entrega dados '
        'que chegam certos e no prazo, num banco de dados. Do banco saem três setas para três '
        'papéis empilhados à direita: o analista de BI, que entrega as respostas recorrentes e as '
        'definições por trás delas; o analista de dados, que entrega a resposta a uma pergunta '
        'nova; o cientista de dados, que entrega um modelo que prevê ou decide. As três terminam '
        'nas decisões.'))
    # the records
    f.rect(16, 120, 120, 170, fill='--ink', stroke='--wire')
    f.text(76, 145, ('the records', 'os registros'), size=13, anchor='middle', weight=600)
    for i, (en, pt) in enumerate([('store tills', 'caixas das lojas'), ('online shop', 'loja online'),
                                  ('warehouse', 'depósito'), ('payroll', 'folha')]):
        f.text(76, 180 + i * 26, (en, pt), size=12, anchor='middle', fill='--paper-dim')
    f.arrow(138, 205, 166, 205)
    # the engineer
    f.rect(168, 150, 160, 110, fill='--panel', stroke='--phosphor')
    f.text(248, 178, ('data engineer', 'engenheiro de dados'), size=13, anchor='middle', weight=600)
    f.text(248, 202, ('data that arrives', 'dados que chegam'), size=11, anchor='middle', fill='--paper-dim')
    f.text(248, 218, ('correct and on time', 'certos e no prazo'), size=11, anchor='middle', fill='--paper-dim')
    f.text(248, 244, 'Tiago', size=12, anchor='middle', fill='--amber')
    # the three on the right
    roles = [
        (40, ('BI analyst', 'analista de BI'), ('the same answer, every week,', 'a mesma resposta, toda semana,'),
         ('and its written definition', 'e a definição escrita dela'), 'Lívia'),
        (160, ('data analyst', 'analista de dados'), ('an answer to a new question,', 'a resposta a uma pergunta nova,'),
         ('once, then perhaps again', 'uma vez, e talvez de novo'), ('Lívia, again', 'Lívia, de novo')),
        (280, ('data scientist', 'cientista de dados'), ('a model that predicts', 'um modelo que prevê'),
         ('or decides on its own', 'ou decide sozinho'), ('nobody, yet', 'ninguém, ainda')),
    ]
    rx, rw, rh = 370, 220, 100
    for y, title, l1, l2, who in roles:
        f.rect(rx, y, rw, rh, fill='--panel', stroke='--phosphor')
        f.text(rx + rw / 2, y + 27, title, size=13, anchor='middle', weight=600)
        f.text(rx + rw / 2, y + 51, l1, size=11, anchor='middle', fill='--paper-dim')
        f.text(rx + rw / 2, y + 67, l2, size=11, anchor='middle', fill='--paper-dim')
        f.text(rx + rw / 2, y + 89, who, size=12, anchor='middle', fill='--amber')
        f.arrow(330, 205, rx - 2, y + rh / 2)
        f.arrow(rx + rw + 2, y + rh / 2, 640, 205)
    f.rect(642, 160, 70, 90, fill='--ink', stroke='--wire')
    f.text(677, 200, ('the', 'as'), size=12, anchor='middle')
    f.text(677, 218, ('decisions', 'decisões'), size=12, anchor='middle')
    f.text(360, 408, ('the name in each box: who does that work at Varanda in 2026', 'o nome em cada caixa: quem faz esse trabalho na Varanda em 2026'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Four roles between the records and the decisions, each named by what it delivers. At '
        'Varanda one part-time engineer and one analyst cover three of them.',
        'Quatro papéis entre os registros e as decisões, cada um nomeado pelo que entrega. Na '
        'Varanda, um engenheiro de meio período e uma analista cobrem três deles.'))


def handoffs():
    f = B.Fig('l03-handoffs', 720, 260, (
        'Four boxes in a row joined by arrows: Tiago the data engineer, Lívia the analyst, Renata '
        'the marketing director, the campaign. Under each arrow, what has to cross it: between '
        'Tiago and Lívia, a change notice for the data; between Lívia and Renata, the written '
        'definition of a returning customer; between Renata and the campaign, the decision and '
        'who owns it.',
        'Quatro caixas em fila ligadas por setas: Tiago, o engenheiro de dados; Lívia, a analista; '
        'Renata, a diretora de marketing; a campanha. Embaixo de cada seta, o que precisa '
        'atravessá-la: entre Tiago e Lívia, um aviso de mudança nos dados; entre Lívia e Renata, a '
        'definição escrita de cliente que volta; entre Renata e a campanha, a decisão e quem '
        'responde por ela.'))
    boxes = [(10, 'Tiago', ('data engineer', 'engenheiro de dados')),
             (200, 'Lívia', ('BI analyst', 'analista de BI')),
             (390, 'Renata', ('marketing director', 'diretora de marketing')),
             (580, ('the campaign', 'a campanha'), ('in May', 'em maio'))]
    W, H = 130, 64
    for x, t, s in boxes:
        f.rect(x, 40, W, H, fill='--panel', stroke='--phosphor')
        f.text(x + W / 2, 66, t, size=14, anchor='middle', weight=600)
        f.text(x + W / 2, 88, s, size=11, anchor='middle', fill='--paper-dim')
    notes = [
        (10 + W, ('a change notice:', 'um aviso de mudança:'), ('"cancelled orders', '"pedidos cancelados'),
         ('leave on 1 March"', 'saem em 1º de março"')),
        (200 + W, ('the definition:', 'a definição:'), ('"bought again within', '"comprou de novo em'),
         ('180 days"', 'até 180 dias"')),
        (390 + W, ('the decision', 'a decisão'), ('and its owner,', 'e quem responde'),
         ('in writing', 'por ela, por escrito')),
    ]
    for x, a, b, c in notes:
        f.arrow(x + 2, 72, x + 58, 72)
        cx = x + 30
        f.rect(cx - 88, 130, 176, 78, fill='--ink', stroke='--amber', dash='4 3')
        f.line(cx, 76, cx, 128, stroke='--amber', sw=1)
        f.text(cx, 154, a, size=12, anchor='middle', weight=600)
        f.text(cx, 174, b, size=11, anchor='middle', fill='--paper-dim')
        f.text(cx, 192, c, size=11, anchor='middle', fill='--paper-dim')
    f.text(360, 244, ('a number breaks where nothing written crosses the arrow',
                      'um número quebra onde nada escrito atravessa a seta'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Renata\'s question as a chain of handoffs. Each arrow needs something written to cross it; '
        'the one that was missing in March moved the repeat rate by a point.',
        'A pergunta de Renata como uma cadeia de passagens. Cada seta precisa de algo escrito que a '
        'atravesse; o que faltou em março mexeu um ponto na taxa de recompra.'))


def main():
    repeat()
    by_delivery()
    roles()
    handoffs()


if __name__ == '__main__':
    main()
