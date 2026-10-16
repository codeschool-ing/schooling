# lesson 22

@figure('l22-gqm', 22)
def l22_gqm(lang):
    t = {
        'en': dict(cols=['goal', 'question', 'metric'],
                   rows=[('right prices for customers', 'how many pricing defects reach customers?', 'escaped defects, by area'),
                         ('defects found before release', 'how many did we find first?', 'detection percentage'),
                         ('escaped defects do not linger', 'how fast is a pricing defect fixed?', 'days from report to fix')],
                   ask='what decision would change if this number changed?',
                   label='Goal, question, metric, as three columns read left to right. Goal: right prices for '
                         'customers; question: how many pricing defects reach customers; metric: escaped defects by area. '
                         'Goal: defects found before release; question: how many did we find first; metric: detection '
                         'percentage. Goal: escaped defects do not linger; question: how fast is a pricing defect fixed; '
                         'metric: days from report to fix. Under the metrics: what decision would change if this number '
                         'changed?',
                   cap='Run forwards, from goal to number. Most bad metrics come from running it backwards.'),
        'pt': dict(cols=['meta', 'pergunta', 'métrica'],
                   rows=[('preços certos para os clientes', 'quantos defeitos de preço chegam aos clientes?',
                          'defeitos que escaparam, por área'),
                         ('defeitos achados antes da entrega', 'quantos achamos primeiro?', 'percentual de detecção'),
                         ('defeitos que escapam não demoram', 'quão rápido um defeito de preço é corrigido?',
                          'dias do relato à correção')],
                   ask='que decisão mudaria se este número mudasse?',
                   label='Meta, pergunta, métrica, como três colunas lidas da esquerda para a direita. Meta: preços '
                         'certos para os clientes; pergunta: quantos defeitos de preço chegam aos clientes; métrica: '
                         'defeitos que escaparam, por área. Meta: defeitos achados antes da entrega; pergunta: quantos '
                         'achamos primeiro; métrica: percentual de detecção. Meta: defeitos que escapam não demoram; '
                         'pergunta: quão rápido um defeito de preço é corrigido; métrica: dias do relato à correção. Abaixo '
                         'das métricas: que decisão mudaria se este número mudasse?',
                   cap='Feito para a frente, da meta ao número. A maioria das métricas ruins vem de fazê-lo ao contrário.'),
    }[lang]
    f = Fig('l22-gqm', 700, 230, t['label'])
    xs, ws = [10, 230, 480], [200, 230, 210]
    for x, w, c in zip(xs, ws, t['cols']):
        f.text(x + w / 2, 16, c, size=10, weight='600', fill='--phosphor')
    for i, row in enumerate(t['rows']):
        y = 32 + i * 52
        for k, (x, w, s) in enumerate(zip(xs, ws, row)):
            box(f, x, y, w, 40, [s], size=9, fill='--panel' if k < 2 else '--ink',
                stroke='--amber' if k == 2 else '--wire')
            if k < 2:
                arrow(f, x + w + 1, y + 20, xs[k + 1] - 1, y + 20)
    f.text(690, 206, t['ask'], size=9, anchor='end', fill='--amber', weight='600')
    return f, t['cap']


@figure('l22-course', 22)
def l22_course(lang):
    t = {
        'en': dict(groups=[('quality', '1–5'), ('techniques', '6–8'), ('ways of working', '9–17'), ('judgement', '18–22')],
                   items=[['prevent and detect', 'the cost curve', 'evidence, not suspicion', 'the whole team'],
                          ['black box', 'white box', 'grey box'],
                          ['waterfall and V', 'iterative and agile', 'Scrum, Kanban, XP, SAFe', 'TDD, BDD, ATDD'],
                          ['root causes', 'oracles', 'priorities', 'entry and exit', 'metrics']],
                   label='The course in four groups. Quality, lessons 1 to 5: prevent and detect, the cost curve, evidence '
                         'not suspicion, the whole team. Techniques, lessons 6 to 8: black box, white box, grey box. Ways '
                         'of working, lessons 9 to 17: waterfall and V, iterative and agile, Scrum, Kanban, XP and SAFe, '
                         'and TDD, BDD and ATDD. Judgement, lessons 18 to 22: root causes, oracles, priorities, entry and '
                         'exit, metrics.',
                   cap='Twenty-two lessons, four groups. The first and the last are judgement; the middle is what judgement '
                       'works with.'),
        'pt': dict(groups=[('qualidade', '1–5'), ('técnicas', '6–8'), ('jeitos de trabalhar', '9–17'), ('julgamento', '18–22')],
                   items=[['prevenir e detectar', 'a curva de custo', 'evidência, não suspeita', 'o time todo'],
                          ['caixa-preta', 'caixa-branca', 'caixa-cinza'],
                          ['cascata e V', 'iterativo e ágil', 'Scrum, Kanban, XP, SAFe', 'TDD, BDD, ATDD'],
                          ['causas raiz', 'oráculos', 'prioridades', 'entrada e saída', 'métricas']],
                   label='O curso em quatro grupos. Qualidade, aulas 1 a 5: prevenir e detectar, a curva de custo, '
                         'evidência e não suspeita, o time todo. Técnicas, aulas 6 a 8: caixa-preta, caixa-branca, '
                         'caixa-cinza. Jeitos de trabalhar, aulas 9 a 17: cascata e V, iterativo e ágil, Scrum, Kanban, '
                         'XP e SAFe, e TDD, BDD e ATDD. Julgamento, aulas 18 a 22: causas raiz, oráculos, prioridades, '
                         'entrada e saída, métricas.',
                   cap='Vinte e duas aulas, quatro grupos. O primeiro e o último são julgamento; o meio é aquilo com que o '
                       'julgamento trabalha.'),
    }[lang]
    f = Fig('l22-course', 680, 220, t['label'])
    for i, ((name, lessons), items) in enumerate(zip(t['groups'], t['items'])):
        x = 10 + i * 168
        hot = i in (0, 3)
        f.rect(x, 10, 158, 200, stroke='--amber' if hot else '--wire', fill='--ink', rx=6)
        f.text(x + 79, 30, name, size=10, weight='600', fill='--amber' if hot else '--paper')
        f.text(x + 79, 46, lessons, size=9, fill='--paper-dim')
        for k, it in enumerate(items):
            box(f, x + 10, 60 + k * 29, 138, 24, [it], size=8.5)
    return f, t['cap']
