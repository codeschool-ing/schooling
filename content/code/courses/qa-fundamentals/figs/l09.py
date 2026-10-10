# lesson 9

@figure('l09-waterfall', 9)
def l09_waterfall(lang):
    t = {
        'en': dict(ph=['requirements', 'design', 'implementation', 'testing', 'operation'],
                   doc=['specification', 'design document', 'code', 'test report', ''],
                   back='going back costs more the further down you are',
                   label='Five phases drawn as steps going down and to the right: requirements, design, implementation, '
                         'testing, operation. Each phase hands a document to the next: specification, design document, '
                         'code, test report. A dashed arrow runs back up from testing to requirements, labelled going back '
                         'costs more the further down you are.',
                   cap='The waterfall as it is usually drawn. Testing is the fourth step, the first moment the system '
                       'meets anything but its own documents.'),
        'pt': dict(ph=['requisitos', 'projeto', 'implementação', 'teste', 'operação'],
                   doc=['especificação', 'documento de projeto', 'código', 'relatório de teste', ''],
                   back='voltar custa mais quanto mais abaixo você está',
                   label='Cinco fases desenhadas como degraus descendo para a direita: requisitos, projeto, implementação, '
                         'teste, operação. Cada fase entrega um documento à seguinte: especificação, documento de projeto, '
                         'código, relatório de teste. Uma seta tracejada volta do teste aos requisitos, com o rótulo voltar '
                         'custa mais quanto mais abaixo você está.',
                   cap='A cascata como costuma ser desenhada. O teste é o quarto degrau, o primeiro momento em que o '
                       'sistema encontra algo além dos próprios documentos.'),
    }[lang]
    f = Fig('l09-waterfall', 660, 270, t['label'])
    for i, p in enumerate(t['ph']):
        x, y = 20 + i * 122, 20 + i * 44
        hl = i == 3
        box(f, x, y, 118, 34, [p], stroke='--amber' if hl else '--wire', size=10.5, weights=['600'])
        if i < 4:
            f.path(f'M{x + 118:.1f} {y + 17:.1f} L{x + 132:.1f} {y + 17:.1f} L{x + 132:.1f} {y + 43:.1f}',
                   stroke='--paper-dim', width=1.3, arrow=True)
            f.text(x + 138, y + 30, t['doc'][i], size=9, anchor='start', fill='--paper-dim')
    f.path('M400 187 C 330 245, 110 240, 79 56', stroke='--amber', width=1.3, dash='4 3', arrow=True)
    f.text(250, 252, t['back'], size=9.5, fill='--amber')
    return f, t['cap']


@figure('l09-v', 9)
def l09_v(lang):
    t = {
        'en': dict(left=['requirements', 'system design', 'architecture', 'module design'],
                   right=['acceptance testing', 'system testing', 'integration testing', 'unit testing'],
                   code='code', tests='tested against',
                   down='described, on the way down', up='tested, on the way up',
                   label='A V shape. The left arm goes down through requirements, system design, architecture and module '
                         'design to code at the bottom. The right arm goes up through unit testing, integration testing, '
                         'system testing and acceptance testing. Horizontal dashed lines join each level on the left to '
                         'the test on the right that checks it: requirements to acceptance testing, system design to '
                         'system testing, architecture to integration testing, module design to unit testing.',
                   cap='Each horizontal line is a pair: a description, and the test level whose expected results come '
                       'from it. The tests on the right can be designed as soon as the description on the left exists.'),
        'pt': dict(left=['requisitos', 'projeto do sistema', 'arquitetura', 'projeto do módulo'],
                   right=['teste de aceitação', 'teste de sistema', 'teste de integração', 'teste de unidade'],
                   code='código', tests='testado contra',
                   down='descrito, na descida', up='testado, na subida',
                   label='Uma forma de V. O braço esquerdo desce por requisitos, projeto do sistema, arquitetura e projeto do '
                         'módulo até o código, embaixo. O braço direito sobe por teste de unidade, teste de integração, teste '
                         'de sistema e teste de aceitação. Linhas horizontais tracejadas ligam cada nível da esquerda ao teste '
                         'da direita que o confere: requisitos a teste de aceitação, projeto do sistema a teste de sistema, '
                         'arquitetura a teste de integração, projeto do módulo a teste de unidade.',
                   cap='Cada linha horizontal é um par: uma descrição, e o nível de teste cujos resultados esperados vêm '
                       'dela. Os testes da direita podem ser projetados assim que a descrição da esquerda existe.'),
    }[lang]
    f = Fig('l09-v', 660, 300, t['label'])
    w, h = 150, 32
    for i in range(4):
        lx, rx, y = 20 + i * 40, 490 - i * 40, 24 + i * 56
        box(f, lx, y, w, h, [t['left'][i]], size=10.5, weights=['600'])
        box(f, rx, y, w, h, [t['right'][i]], size=10.5, stroke='--phosphor', weights=['600'])
        f.line(lx + w + 4, y + h / 2, rx - 4, y + h / 2, stroke='--wire', width=1, dash='3 4')
        if i == 0:
            f.text(330, y + h / 2 - 8, t['tests'], size=9, fill='--paper-dim')
        if i < 3:
            arrow(f, lx + 40, y + h + 1, lx + 60, y + 55)
            arrow(f, rx + 90, y + 55, rx + 110, y + h + 1, stroke='--phosphor')
    box(f, 255, 248, 150, 32, [t['code']], stroke='--amber', size=10.5, weights=['600'])
    arrow(f, 180 + 40, 24 + 3 * 56 + h + 1, 255, 262)
    arrow(f, 405, 262, 370 + 70, 24 + 3 * 56 + h + 1, stroke='--phosphor')
    f.text(20, 290, t['down'], size=9.5, anchor='start', fill='--paper-dim')
    f.text(640, 290, t['up'], size=9.5, anchor='end', fill='--phosphor')
    return f, t['cap']
