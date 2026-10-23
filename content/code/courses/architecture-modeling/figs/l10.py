"""Lesson 10: Zachman."""
from figures import Fig, T, figure, picture

COLS = [T('What', 'O quê'), T('How', 'Como'), T('Where', 'Onde'), T('Who', 'Quem'), T('When', 'Quando'), T('Why', 'Por quê')]
ROWS = [T('Executive', 'Executivo'), T('Business mgmt', 'Gestão do negócio'), T('Architect', 'Arquiteto'),
        T('Engineer', 'Engenheiro'), T('Technician', 'Técnico'), T('Enterprise', 'Empresa')]
X0, Y0, CW, RH = 150, 40, 92, 38


def grid(f, words=True, fills=None):
    t = f.text if words else (lambda *a, **k: None)
    for j, c in enumerate(COLS):
        f.rect(X0 + j * CW + 2, Y0 - 30, CW - 4, 26, stroke='--amber', fill='--panel', rx=3, width=1.2)
        t(X0 + j * CW + CW / 2, Y0 - 17, c, size=10, weight='600')
    for i, r in enumerate(ROWS):
        y = Y0 + i * RH
        f.rect(14, y + 2, X0 - 20, RH - 4, stroke='--phosphor', fill='--panel', rx=3, width=1.2)
        t(14 + (X0 - 20) / 2, y + RH / 2, r, size=9.5, weight='600')
        for j in range(6):
            mark = (fills or {}).get((i, j))
            stroke = '--wire'
            if mark == 'have':
                stroke = '--phosphor'
            elif mark == 'gap':
                stroke = '--amber'
            f.rect(X0 + j * CW + 2, y + 2, CW - 4, RH - 4, stroke=stroke, fill='--ink', rx=2,
                   width=1.6 if mark else 1, dash='4 3' if mark == 'gap' else None)


@figure('l10-zachman', 10)
def zachman():
    f = Fig('l10-zachman', 720, 280, T(
        'The Zachman grid: six columns, the questions what, how, where, who, when and why, and six rows, '
        'the perspectives of the executive, business management, the architect, the engineer, the '
        'technician and the enterprise itself. Each of the 36 cells is one kind of description. Three '
        'cells carry examples: what for the executive is a list of things; what for the architect is a '
        'logical data model; how for the engineer is a physical process design.',
        'A grade de Zachman: seis colunas, as perguntas o quê, como, onde, quem, quando e por quê, e seis '
        'linhas, as perspectivas do executivo, da gestão do negócio, do arquiteto, do engenheiro, do '
        'técnico e da própria empresa. Cada uma das 36 células é um tipo de descrição. Três células têm '
        'exemplos: o quê para o executivo é uma lista de coisas; o quê para o arquiteto é um modelo '
        'lógico de dados; como para o engenheiro é o desenho físico de um processo.'))
    grid(f)
    ex = [(0, 0, T('list of things', 'lista de coisas')), (2, 0, T('logical data', 'dados lógicos')),
          (3, 1, T('physical design', 'desenho físico'))]
    for i, j, s in ex:
        f.text(X0 + j * CW + CW / 2, Y0 + i * RH + RH / 2, s, size=8.5, fill='--paper-dim', italic=True)
    return f, T('A cell is one question for one audience. Moving down a row changes the language of the description, not only its detail.',
                'Uma célula é uma pergunta para um público. Descer uma linha muda a linguagem da descrição, não só o detalhe.')


@picture('zachman-grid')
def zachman_picture():
    f = Fig('zachman-grid', 720, 280, '')
    grid(f, words=False)
    return f


HAVE = {(0, 5), (1, 5), (2, 5), (1, 3), (1, 1), (2, 1), (2, 0), (2, 4), (3, 1), (3, 0), (3, 2), (3, 4), (2, 3),
        (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5)}
GAPS = {(0, 4), (1, 4), (1, 2), (3, 3)}


@figure('l10-course-in-grid', 10)
def course_grid():
    fills = {k: 'have' for k in HAVE}
    fills.update({k: 'gap' for k in GAPS})
    f = Fig('l10-course-in-grid', 720, 310, T(
        'The Zachman grid with this course\'s artefacts marked. Cells drawn in the accent colour hold '
        'something from lessons 1 to 9, such as the board vision, the utility tree, the class diagram, the '
        'container diagram, the sequence diagram and the deployment diagram. Four cells are marked as '
        'gaps with a dashed amber outline: when for the executive and for business management, where for '
        'business management, and who for the engineer.',
        'A grade de Zachman com os artefatos deste curso marcados. As células na cor de destaque guardam '
        'algo das aulas 1 a 9, como a visão da diretoria, a árvore de utilidade, o diagrama de classes, o '
        'diagrama de containers, o diagrama de sequência e o diagrama de implantação. Quatro células '
        'aparecem como lacunas, com contorno âmbar tracejado: quando para o executivo e para a gestão do '
        'negócio, onde para a gestão do negócio, e quem para o engenheiro.'))
    grid(f, fills=fills)
    notes = {(0, 5): T('vision', 'visão'), (1, 5): T('scenarios', 'cenários'), (2, 0): T('class', 'classes'),
             (2, 4): T('state machine', 'estados'), (3, 1): T('sequence', 'sequência'), (3, 2): T('deployment', 'implantação'),
             (1, 1): 'BPMN', (1, 3): T('RACI', 'RACI'), (2, 5): 'ADRs', (3, 0): T('containers', 'containers'),
             (0, 4): T('calendar?', 'calendário?'), (1, 2): T('route map?', 'mapa de linhas?'), (3, 3): T('on call?', 'plantão?'),
             (1, 4): T('calendar?', 'calendário?')}
    for (i, j), s in notes.items():
        gap = (i, j) in GAPS
        f.text(X0 + j * CW + CW / 2, Y0 + i * RH + RH / 2, s, size=8.5, fill='--amber' if gap else '--paper',
               italic=gap)
    f.text(14, 290, T('accent: drawn in this course · dashed amber: nobody drew it', 'destaque: desenhado neste curso · âmbar tracejado: ninguém desenhou'),
           size=9, anchor='start', fill='--paper-dim')
    return f, T('The empty cells are not failures; they are scope choices nobody had noticed making.',
                'As células vazias não são falhas; são escolhas de escopo que ninguém tinha percebido estar fazendo.')
