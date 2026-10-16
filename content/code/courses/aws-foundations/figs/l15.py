"""Lesson 15: the Cost and Usage Report, and who spent what."""
from figures import Fig, T, figure


@figure('l15-pipeline', 15)
def pipeline():
    f = Fig('l15-pipeline', 720, 300, T(
        'Two paths to the same question. Above, the AWS way, not run in this course: usage in every '
        'account becomes the bill; a data export in the management account writes CUR 2.0 files, '
        'in Parquet, to the bucket shop-logs under billing; Amazon Athena runs SQL over those '
        'files; Amazon QuickSight draws dashboards from the answers. Below, this lab: make_cur.py '
        'writes cur.csv, made-up lines in the same columns; ask.py loads it into sqlite3 and runs '
        'the same SQL; the answer is a table in the terminal.',
        'Dois caminhos para a mesma pergunta. Em cima, o jeito da AWS, não rodado neste curso: o '
        'uso em toda conta vira a fatura; uma exportação de dados na conta de gerenciamento grava '
        'arquivos CUR 2.0, em Parquet, no bucket shop-logs sob billing; o Amazon Athena roda SQL '
        'sobre esses arquivos; o Amazon QuickSight desenha painéis a partir das respostas. Embaixo, '
        'este laboratório: make_cur.py grava cur.csv, linhas inventadas nas mesmas colunas; ask.py '
        'o carrega no sqlite3 e roda o mesmo SQL; a resposta é uma tabela no terminal.'))
    f.text(20, 26, T('the AWS way: not run in this course', 'o jeito da AWS: não rodado neste curso'),
           size=10.5, anchor='start', weight='600', fill='--paper-dim')
    top = [(T('usage in every', 'uso em toda'), T('account', 'conta')),
           (T('a data export', 'exportação de dados'), 'CUR 2.0'),
           ('shop-logs/billing', 'Parquet'),
           ('Amazon Athena', T('SQL over S3', 'SQL sobre o S3')),
           ('Amazon QuickSight', T('dashboards', 'painéis'))]
    xs = [20, 162, 304, 446, 588]
    for i, (x, (a, b)) in enumerate(zip(xs, top)):
        f.rect(x, 42, 120, 60, stroke='--paper-dim', fill='--panel', dash='5 4')
        mono = i == 2
        f.text(x + 60, 63, a, size=10, mono=mono)
        f.text(x + 60, 82, b, size=10, fill='--paper-dim', mono=False)
        if i:
            f.arrow([(x - 20, 72), (x - 3, 72)], stroke='--paper-dim', width=1.3)
    f.text(20, 166, T('this lab: on your own machine', 'este laboratório: na sua máquina'), size=10.5,
           anchor='start', weight='600', fill='--phosphor')
    bottom = [('make_cur.py', T('made-up lines', 'linhas inventadas')),
              ('cur.csv', T('the same columns', 'as mesmas colunas')),
              ('ask.py', 'sqlite3'),
              (T('a table', 'uma tabela'), T('in the terminal', 'no terminal'))]
    xs = [20, 197, 374, 551]
    for i, (x, (a, b)) in enumerate(zip(xs, bottom)):
        f.rect(x, 182, 150, 60, stroke='--phosphor', fill='--panel')
        f.text(x + 75, 203, a, size=10, mono=i < 3)
        f.text(x + 75, 222, b, size=10, fill='--paper-dim', mono=(i == 2))
        if i:
            f.arrow([(x - 25, 212), (x - 3, 212)], stroke='--phosphor', width=1.3)
    f.text(360, 128, T('the same SQL asks both', 'o mesmo SQL pergunta aos dois'), size=10,
           fill='--amber', italic=True)
    f.line(506, 104, 449, 180, stroke='--amber', width=1.2, dash='3 3')
    f.text(360, 276, T('the lab replaces the data, not the method', 'o laboratório troca os dados, não o método'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Above, what a real organisation runs. Below, the same questions against a file you made.',
                'Em cima, o que uma organização real roda. Embaixo, as mesmas perguntas contra um '
                'arquivo que você fez.')


@figure('l15-amortise', 15)
def amortise():
    f = Fig('l15-amortise', 720, 300, T(
        'Each team\'s month in the made-up report, in dollars, before tax and credits, counted '
        'two ways. Web: 376.55 unblended, 456.23 amortised. Data: 165.90 both ways. No team: 210.82 '
        'unblended, 131.14 amortised. The difference, 79.68 dollars, is the Savings Plan\'s fee, '
        'which unblended leaves untagged and amortised moves onto the web team that used it.',
        'O mês de cada time no relatório inventado, em dólares, antes de impostos e créditos, '
        'contado de dois jeitos. Web: 376,55 sem combinar, 456,23 amortizado. Data: 165,90 dos dois '
        'jeitos. Sem time: 210,82 sem combinar, 131,14 amortizado. A diferença, 79,68 dólares, é a '
        'taxa do Savings Plan, que o não combinado deixa sem tag e o amortizado põe no time web que '
        'a usou.'))

    def y(d):
        return 250 - d * 200 / 500

    f.line(80, y(0), 690, y(0), stroke='--paper-dim', width=1.2)
    for d in (0, 100, 200, 300, 400):
        f.text(72, y(d), str(d), size=10, anchor='end', fill='--paper-dim')
    f.text(80, 22, T('dollars, before tax and credits', 'dólares, antes de impostos e créditos'),
           size=10, anchor='start', fill='--paper-dim')
    groups = [('web', 376.55, 456.23), ('data', 165.90, 165.90),
              (T('(no team)', '(sem time)'), 210.82, 131.14)]
    for i, (name, unb, amo) in enumerate(groups):
        gx = 130 + i * 190
        for j, (val, colour) in enumerate(((unb, '--paper-dim'), (amo, '--phosphor'))):
            bx = gx + j * 62
            f.rect(bx, y(val), 52, y(0) - y(val), stroke=colour, fill='--scan', rx=2)
            label = f'{val:.2f}' if T('en', 'pt') == 'en' else f'{val:.2f}'.replace('.', ',')
            f.text(bx + 26, y(val) - 9, label, size=10, fill=colour)
        f.text(gx + 57, y(0) + 16, name, size=10.5, mono=(name in ('web', 'data')))
    f.rect(520, 30, 12, 12, stroke='--paper-dim', fill='--scan', rx=2)
    f.text(538, 36, T('unblended', 'não combinado'), size=10, anchor='start', fill='--paper-dim')
    f.rect(520, 50, 12, 12, stroke='--phosphor', fill='--scan', rx=2)
    f.text(538, 56, T('amortised', 'amortizado'), size=10, anchor='start', fill='--phosphor')
    f.text(360, 290, T('made-up data, from cur.csv; the 79.68 that moves is the Savings Plan fee',
                       'dados inventados, do cur.csv; os 79,68 que mudam de lugar são a taxa do Savings Plan'),
           size=9.5, fill='--paper-dim', italic=True)
    return f, T('Amortised moves the plan\'s fee from nobody onto the team whose hours it covered.',
                'O amortizado tira a taxa do plano de ninguém e a põe no time cujas horas ela cobriu.')
