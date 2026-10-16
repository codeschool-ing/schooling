"""Lesson 11: what forty numbers cost a meeting, ten candidate indicators scored for
Caio's page, and a guard that catches a target being met the wrong way. Figures:
objective to questions to indicators, and the pairs."""
import book as B

LESSON = 'le-d1mkpfj7'

# Candidates for the operations page, scored 1 to 5 on four criteria.
# (name, pt name, relevant, actionable, data available, cheap to produce)
CANDIDATES = [
    ('Delivered on promise', 'Entregue no prazo', 5, 5, 4, 4),
    ('Damaged deliveries', 'Entregas com avaria', 4, 5, 4, 4),
    ('Stock-outs, top 200', 'Rupturas, top 200', 5, 4, 3, 3),
    ('Days of stock', 'Dias de estoque', 4, 3, 5, 5),
    ('Picking errors', 'Erros de separação', 4, 5, 3, 3),
    ('Delivery cost per order', 'Custo de entrega por pedido', 4, 4, 4, 3),
    ('Pallets received a day', 'Paletes recebidos por dia', 2, 2, 5, 5),
    ('Products in the catalogue', 'Produtos no catálogo', 2, 1, 5, 5),
    ('Forklift utilisation', 'Uso das empilhadeiras', 2, 3, 2, 2),
    ('Store energy per m²', 'Energia por m² nas lojas', 2, 3, 2, 3),
]
WEIGHTS = [3, 3, 2, 2]


def meeting():
    rows = [['Indicators', 'Seconds each', 'People', 'Weeks'], [40, 45, 8, 48], [6, 45, 8, 48]]
    return B.report('lesson 11 — what reading every number costs the Monday meeting', rows, [],
                    ['=A2*B2/60', '=A2*B2/60*C2/60', '=ROUND(A2*B2/60*C2/60*D2,0)',
                     '=A3*B3/60', '=ROUND(A3*B3/60*C3/60*D3,0)'])


def scoring():
    rows = [['Indicator', 'Relevant', 'Actionable', 'Data', 'Cheap', 'Score'],
            ['Weight'] + WEIGHTS]
    for k, (name, _, *s) in enumerate(CANDIDATES, start=3):
        rows.append([name] + s + [f'=SUMPRODUCT(B$2:E$2,B{k}:E{k})'])
    n = len(rows)
    got = B.report('lesson 11 — ten candidates for the operations page', rows,
                   [f'F{k}' for k in range(3, n + 1)],
                   ['=SUMPRODUCT(B2:E2,B3:E3)', '=3*5+3*5+2*4+2*4',
                    '=B2*5+C2*5+D2*5+E2*5',
                    '=B2*3+C2*4+D2*5+E2*4'])   # a drill: same-day shipping scored 3, 4, 5, 4
    # the same table with the data weight at 1: does the cut move?
    alt = [r[:] for r in rows]
    alt[1] = ['Weight', 3, 3, 1, 2]
    got2 = B.report('lesson 11 — the same ten, data weighted 1 instead of 2', alt,
                    [f'F{k}' for k in range(3, n + 1)])
    return got, got2


def guard():
    rows = [['Month', 'Delivered', 'Damaged', 'On promise %'],
            ['Feb', 1840, 22, 76.9], ['May', 1910, 59, 86.2]]
    return B.report('lesson 11 — the guard beside the KPI', rows, [],
                    ['=ROUND(C2/B2*100,1)', '=ROUND(C3/B3*100,1)'])


def gqm():
    f = B.Fig('l11-gqm', 720, 330, (
        'A tree read from left to right. One objective, keep the date we give the customer, '
        'leads to three questions: are we late, and where; do we damage what we deliver; is the '
        'product there to send. Each question leads to the indicator that answers it: delivered '
        'on promise by route, damaged deliveries, and stock-outs among the top 200 products.',
        'Uma árvore lida da esquerda para a direita. Um objetivo, cumprir a data que damos ao '
        'cliente, leva a três perguntas: estamos atrasando, e onde; avariamos o que entregamos; o '
        'produto está lá para enviar. Cada pergunta leva ao indicador que a responde: entregue no '
        'prazo por rota, entregas com avaria e rupturas entre os 200 produtos principais.'))
    f.text(110, 30, ('objective', 'objetivo'), size=11, anchor='middle', fill='--paper-dim')
    f.text(360, 30, ('questions', 'perguntas'), size=11, anchor='middle', fill='--paper-dim')
    f.text(605, 30, ('indicators', 'indicadores'), size=11, anchor='middle', fill='--paper-dim')
    f.rect(20, 125, 180, 80, fill='--panel', stroke='--amber')
    f.text(110, 158, ('keep the date we', 'cumprir a data que'), size=13, anchor='middle', weight=600)
    f.text(110, 178, ('give the customer', 'damos ao cliente'), size=13, anchor='middle', weight=600)
    qs = [(('are we late, and where?', 'estamos atrasando, e onde?'),
           ('delivered on promise', 'entregue no prazo'), ('by route, weekly', 'por rota, semanal')),
          (('do we damage what we deliver?', 'avariamos o que entregamos?'),
           ('damaged deliveries', 'entregas com avaria'), ('percent, weekly', 'porcentagem, semanal')),
          (('is the product there to send?', 'o produto está lá para enviar?'),
           ('stock-outs, top 200', 'rupturas, top 200'), ('days out, weekly', 'dias em falta, semanal'))]
    for k, (q, ind, note) in enumerate(qs):
        y = 50 + 95 * k
        f.rect(255, y, 210, 60, fill='--panel', stroke='--phosphor')
        f.text(360, y + 35, q, size=12, anchor='middle')
        f.rect(510, y, 190, 60, fill='--panel', stroke='--phosphor')
        f.text(605, y + 27, ind, size=12, anchor='middle', weight=600)
        f.text(605, y + 46, note, size=11, anchor='middle', fill='--paper-dim')
        f.arrow(202, 165, 253, y + 30)
        f.arrow(467, y + 30, 508, y + 30)
    f.text(360, 322, ('an indicator with no question above it has no reason to be on the page',
                      'um indicador sem pergunta acima dele não tem motivo para estar na página'),
           size=11, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Objective, questions, indicators, for Caio\'s delivery objective. Read from the left it '
        'chooses the indicators; read from the right it is the written reason each one is there.',
        'Objetivo, perguntas, indicadores, para o objetivo de entregas do Caio. Lida da esquerda, '
        'ela escolhe os indicadores; lida da direita, é o motivo escrito de cada um estar ali.'))


def pairs():
    rows = [
        (('delivered on promise', 'entregue no prazo'), ('rush the van, drop the sofa', 'correr com a van, derrubar o sofá'),
         ('damaged deliveries', 'entregas com avaria')),
        (('call handling time', 'tempo de atendimento'), ('end the call before it is solved', 'encerrar antes de resolver'),
         ('repeat calls in 7 days', 'nova ligação em 7 dias')),
        (('online conversion', 'conversão online'), ('sell what does not fit the room', 'vender o que não cabe na sala'),
         ('returns rate', 'taxa de devolução')),
        (('stock-outs', 'rupturas'), ('fill the warehouse', 'lotar o depósito'),
         ('days of stock', 'dias de estoque')),
    ]
    f = B.Fig('l11-pairs', 720, 40 + 72 * len(rows), (
        'Four pairs. On the left a KPI, on the right the guard that watches it, and between them '
        'the way the KPI is met without improving anything: delivered on promise and damaged '
        'deliveries; call handling time and repeat calls within seven days; online conversion and '
        'the returns rate; stock-outs and days of stock.',
        'Quatro pares. À esquerda um KPI, à direita a guarda que o vigia, e entre eles o jeito de '
        'cumprir o KPI sem melhorar nada: entregue no prazo e entregas com avaria; tempo de '
        'atendimento e nova ligação em sete dias; conversão online e taxa de devolução; rupturas e '
        'dias de estoque.'))
    f.text(115, 30, 'KPI', size=11, anchor='middle', fill='--paper-dim')
    f.text(360, 30, ('the shortcut it invites', 'o atalho que ele convida'), size=11, anchor='middle',
           fill='--paper-dim')
    f.text(605, 30, ('the guard', 'a guarda'), size=11, anchor='middle', fill='--paper-dim')
    for k, (kpi, cheat, guard) in enumerate(rows):
        y = 44 + 72 * k
        f.rect(20, y, 190, 52, fill='--panel', stroke='--phosphor')
        f.text(115, y + 31, kpi, size=13, anchor='middle', weight=600)
        f.rect(510, y, 190, 52, fill='--panel', stroke='--amber')
        f.text(605, y + 31, guard, size=13, anchor='middle', weight=600)
        f.line(212, y + 26, 508, y + 26, stroke='--paper-dim', dash='4 3')
        f.text(360, y + 19, cheat, size=11, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Each KPI with the guard read beside it. The middle column is why the guard exists: the '
        'cheapest way to move the number on the left shows up in the number on the right.',
        'Cada KPI com a guarda lida ao lado. A coluna do meio é o motivo de a guarda existir: o '
        'jeito mais barato de mexer o número da esquerda aparece no número da direita.'))


def main():
    meeting()
    scoring()
    guard()
    gqm()
    pairs()


if __name__ == '__main__':
    main()
