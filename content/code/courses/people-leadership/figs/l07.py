"""Lesson 7: themes across a quarter of one-to-ones."""
from figures import Fig, T, figure


@figure('l07-themes', 7)
def themes():
    f = Fig('l07-themes', 720, 300, T(
        'A grid with seven people in rows and three months in columns. Each cell shows which themes '
        'came up in that person’s one-to-ones that month. Dependencies on Payments appear for five '
        'of the seven people across the quarter. On-call appears for four people in the first month '
        'and one in the third. Growth appears for four people over the quarter, and never for Marcos.',
        'Uma grade com sete pessoas nas linhas e três meses nas colunas. Cada célula mostra quais '
        'temas apareceram nas 1:1 daquela pessoa naquele mês. Dependências de Pagamentos aparecem '
        'para cinco das sete pessoas ao longo do trimestre. Plantão aparece para quatro pessoas no '
        'primeiro mês e para uma no terceiro. Crescimento aparece para quatro pessoas no trimestre, e '
        'nunca para o Marcos.'))
    people = ['Diego', 'Yara', 'Paula', 'Marcos', 'Camila', 'Thiago', 'Fábio']
    marks = {  # person -> [month1, month2, month3], each a set of P (payments), O (on-call), G (growth)
        'Diego': ['P', 'PG', 'G'], 'Yara': ['O', 'PG', 'G'], 'Paula': ['OP', 'P', 'G'],
        'Marcos': ['O', '', ''], 'Camila': ['P', 'P', ''], 'Thiago': ['O', 'O', 'OG'],
        'Fábio': ['', 'P', ''],
    }
    cols = {'P': ('--amber', T('dependencies on Payments', 'dependências de Pagamentos')),
            'O': ('--phosphor', T('on-call', 'plantão')),
            'G': ('--paper', T('growth', 'crescimento'))}
    x0, y0, cw, rh = 120, 50, 110, 30
    for j, m in enumerate([T('month 1', 'mês 1'), T('month 2', 'mês 2'), T('month 3', 'mês 3')]):
        f.text(x0 + j * cw + cw / 2, 30, m, size=11, weight='600')
    for i, p in enumerate(people):
        y = y0 + i * rh
        f.text(x0 - 12, y + rh / 2, p, size=11, anchor='end')
        for j in range(3):
            x = x0 + j * cw
            f.rect(x + 3, y + 3, cw - 6, rh - 6, stroke='--wire', fill='--panel', width=1, rx=3)
            for k, t in enumerate(marks[p][j]):
                f.circle(x + 28 + k * 26, y + rh / 2, 7, fill=cols[t][0])
    lx = x0 + 3 * cw + 40
    for k, t in enumerate('POG'):
        y = 80 + k * 34
        f.circle(lx + 7, y, 7, fill=cols[t][0])
        f.text(lx + 24, y, cols[t][1], size=11.5, anchor='start')
    return f, T('No single meeting showed that Payments was the team’s largest drag. The tally did.',
                'Nenhuma reunião sozinha mostrou que Pagamentos era o maior freio do time. A contagem mostrou.')
