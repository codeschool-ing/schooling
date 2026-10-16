"""Lesson 4: the skill map drawn against the courses of the bi track, and
Lívia's four weeks of February 2026 in hours by kind of work."""
import book as B

LESSON = 'le-ehp6ejt7'

# Lívia's own log, four working weeks of February 2026, in hours.
WEEKS = 4
HOURS = [
    (('Answering requests', 'Atender pedidos'), 36),
    (('Meetings with the business', 'Reuniões com as áreas'), 37),
    (('Checking and fixing data', 'Conferir e corrigir dados'), 31),
    (('Running recurring reports', 'Rodar relatórios recorrentes'), 24),
    (('Writing definitions and notes', 'Escrever definições e notas'), 21),
    (('Building dashboards and charts', 'Construir painéis e gráficos'), 16),
    (('Learning', 'Estudar'), 11),
]


def week():
    rows = [['Kind of work', 'Hours']]
    for (en, _), h in HOURS:
        rows.append([en, h])
    n = len(rows)                                  # last row of data (8)
    t = n + 1
    rows.append(['Total', f'=SUM(B2:B{n})'])
    rows[0].append('Share')
    for k in range(2, n + 1):
        rows[k - 1].append(f'=ROUND(B{k}/B${t}*100,1)')
    cells = [f'B{t}'] + [f'C{k}' for k in range(2, n + 1)]
    got = B.report('lesson 4 — four weeks of February in hours, and each kind\'s share', rows, cells,
                   [f'=SUM(C2:C{n})',
                    f'=B{t}/{WEEKS}',
                    '=B2+B3', '=B4+B6',
                    f'=ROUND((B2+B3)/B{t}*100,1)',     # requests and meetings: the business
                    f'=ROUND((B4+B6)/B{t}*100,1)'])    # checking data and writing definitions
    return got


def skills():
    f = B.Fig('l04-skills', 720, 424, (
        'Four groups of skills, each a box listing the skills and, under them, the courses of the '
        'bi track that teach them. Tools: a spreadsheet, SQL, a BI tool, a little modelling and '
        'code; courses excel-analytics, sql-databases, analytics-bi, warehouse-modeling, python. '
        'Analysis: descriptive statistics, cleaning data, time series and tests; courses '
        'statistics, data-cleaning, bi-techniques. Business: how the company makes money, its '
        'functions, its rules about data; courses bi-business, data-governance. Communication: '
        'writing, a chart, a meeting; courses visualization, data-storytelling.',
        'Quatro grupos de habilidades, cada um uma caixa com as habilidades e, embaixo, os cursos '
        'da trilha bi que as ensinam. Ferramentas: planilha, SQL, uma ferramenta de BI, um pouco '
        'de modelagem e de código; cursos excel-analytics, sql-databases, analytics-bi, '
        'warehouse-modeling, python. Análise: estatística descritiva, limpeza de dados, séries '
        'temporais e testes; cursos statistics, data-cleaning, bi-techniques. Negócio: como a '
        'empresa ganha dinheiro, suas áreas, suas regras sobre dados; cursos bi-business, '
        'data-governance. Comunicação: escrever, um gráfico, uma reunião; cursos visualization, '
        'data-storytelling.'))
    groups = [
        (16, 16, ('tools', 'ferramentas'),
         [('a spreadsheet', 'planilha'), ('SQL', 'SQL'), ('a BI tool', 'uma ferramenta de BI'),
          ('a little modelling and code', 'um pouco de modelagem e código')],
         ['excel-analytics', 'sql-databases', 'analytics-bi', 'warehouse-modeling', 'python']),
        (368, 16, ('analysis', 'análise'),
         [('descriptive statistics', 'estatística descritiva'), ('cleaning data', 'limpeza de dados'),
          ('time series and tests', 'séries temporais e testes')],
         ['statistics', 'data-cleaning', 'bi-techniques']),
        (16, 206, ('business', 'negócio'),
         [('how the company makes money', 'como a empresa ganha dinheiro'),
          ('what each function decides', 'o que cada área decide'),
          ('the rules about data', 'as regras sobre dados')],
         ['bi-business', 'data-governance']),
        (368, 206, ('communication', 'comunicação'),
         [('writing a paragraph', 'escrever um parágrafo'), ('choosing a chart', 'escolher um gráfico'),
          ('running a meeting', 'conduzir uma reunião')],
         ['visualization', 'data-storytelling']),
    ]
    W, H = 336, 178
    for x, y, title, items, courses in groups:
        f.rect(x, y, W, H, fill='--panel', stroke='--phosphor')
        f.text(x + 16, y + 28, title, size=14, weight=600)
        for i, it in enumerate(items):
            f.text(x + 16, y + 54 + i * 20, it, size=12, fill='--paper')
        f.line(x + 16, y + 136, x + W - 16, y + 136, stroke='--wire', sw=1)
        # course slugs are identifiers: mono, identical in both languages
        line1 = ', '.join(courses[:3])
        line2 = ', '.join(courses[3:])
        f.text(x + 16, y + 154, line1, size=11, fill='--paper-dim', mono=True)
        if line2:
            f.text(x + 16, y + 170, line2, size=11, fill='--paper-dim', mono=True)
    f.text(360, 414, ('above the line, the skill; below it, the bi-track courses that teach it',
                      'acima da linha, a habilidade; abaixo, os cursos da trilha bi que a ensinam'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'The BI analyst\'s skills in four groups, against the courses of the bi track. Business and '
        'communication carry as much of the job as the tools do.',
        'As habilidades do analista de BI em quatro grupos, diante dos cursos da trilha bi. Negócio e '
        'comunicação carregam tanto do trabalho quanto as ferramentas.'))


def hours_fig(got):
    f = B.Fig('l04-hours', 720, 330, (
        'Horizontal bars, one per kind of work, for Lívia\'s 176 hours in four weeks of February: '
        'meetings with the business 37 hours, answering requests 36, checking and fixing data 31, '
        'running recurring reports 24, writing definitions and notes 21, building dashboards and '
        'charts 16, learning 11.',
        'Barras horizontais, uma por tipo de trabalho, para as 176 horas de Lívia em quatro semanas '
        'de fevereiro: reuniões com as áreas 37 horas, atender pedidos 36, conferir e corrigir dados '
        '31, rodar relatórios recorrentes 24, escrever definições e notas 21, construir painéis e '
        'gráficos 16, estudar 11.'))
    data = sorted(HOURS, key=lambda r: -r[1])
    x0, scale, top, step = 260, 9.0, 30, 38
    for i, (label, h) in enumerate(data):
        y = top + i * step
        chart = label[0].startswith('Building')
        f.text(x0 - 12, y + 18, label, size=12, anchor='end', fill='--paper',
               weight=600 if chart else None)
        f.bar(x0, y + 4, h * scale, 22, fill='--amber' if chart else '--phosphor')
        f.text(x0 + h * scale + 8, y + 20, f'{h} h', size=12, mono=True, fill='--paper-dim')
    f.line(x0, top - 4, x0, top + len(data) * step, stroke='--wire', sw=1)
    f.text(360, 316, ('hours in four weeks; the highlighted bar is the part people picture as the job',
                      'horas em quatro semanas; a barra destacada é a parte que se imagina ser o trabalho'),
           size=12, anchor='middle', fill='--paper-dim')
    B.place(LESSON, f, (
        'Lívia\'s February in hours. Building dashboards and charts is 9.1% of her time; talking to '
        'the business and answering it is 41.5%.',
        'O fevereiro de Lívia em horas. Construir painéis e gráficos é 9,1% do tempo dela; conversar '
        'com as áreas e responder a elas é 41,5%.'))


def december():
    rows = [['Month', 'Sales']] + [[m, v] for m, v in zip(B.MONTHS, B.SALES_2025)]
    rows.append(['Total', '=SUM(B2:B13)'])
    return B.report('lesson 4 — December\'s share of 2025 (the skill-map example)', rows, ['B14'],
                    ['=ROUND(B13/B14*100,1)'])


def betim_week():
    rows = [['Store', 'Sales 2025'], ['Betim', dict((n, v) for n, _, v in B.STORES)['Betim']]]
    return B.report('lesson 4 — an ordinary week at Betim, in thousands (the empty file)', rows, [],
                    ['=ROUND(B2/52,0)'])


def main():
    betim_week()
    december()
    got = week()
    skills()
    hours_fig(got)


if __name__ == '__main__':
    main()
