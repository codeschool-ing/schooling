"""Lesson 2: composition over inheritance."""
from figures import Fig, T, figure


@figure('l02-self-call', 2)
def self_call():
    f = Fig('l02-self-call', 700, 320, T(
        'A sequence diagram of counting.py adding three titles. The program calls add_all on the '
        'CountingShelf, which adds 3 to its counter and calls the parent Shelf\'s add_all. The '
        'parent loops and calls self.add once per title; because self is the CountingShelf, each of '
        'those three calls lands back in the child\'s add, which adds 1 to the counter each time '
        'before calling the parent\'s add. The three titles are counted twice: 1 for the first '
        'title, plus 3, plus 3, makes 7, while the shelf holds 4.',
        'Um diagrama de sequência de counting.py acrescentando três títulos. O programa chama '
        'add_all no CountingShelf, que soma 3 ao contador e chama o add_all do pai, Shelf. O pai faz '
        'um laço e chama self.add uma vez por título; como self é o CountingShelf, cada uma dessas '
        'três chamadas volta para o add do filho, que soma 1 ao contador a cada vez antes de chamar '
        'o add do pai. Os três títulos são contados duas vezes: 1 do primeiro título, mais 3, mais '
        '3, dá 7, enquanto a prateleira guarda 4.'))
    cols = [(100, T('the program', 'o programa'), False), (350, 'CountingShelf', True), (600, 'Shelf', True)]
    for x, name, mono in cols:
        f.box(x, 30, 150, 28, [name], mono=mono, stroke='--phosphor', size=10.5)
        f.line(x, 44, x, 272, stroke='--wire', width=1, dash='4 4')
    # 1: program -> child
    f.arrow([(100, 80), (346, 80)], stroke='--paper-dim')
    f.text(225, 69, 'add_all(3 titles)', mono=True, size=9.5)
    f.text(225, 96, 'added += 3', mono=True, size=9.5, fill='--amber')
    # 2: child -> parent
    f.arrow([(350, 135), (596, 135)], stroke='--paper-dim')
    f.text(475, 124, 'super().add_all(titles)', mono=True, size=9.5)
    # 3: parent -> child, the hidden self-call
    f.arrow([(600, 190), (354, 190)], stroke='--amber', width=1.6)
    f.text(475, 179, 'self.add(title)  × 3', mono=True, size=9.5, fill='--amber')
    f.text(475, 206, T('self is the CountingShelf', 'self é o CountingShelf'), size=10,
           fill='--paper-dim', italic=True)
    f.text(225, 190, 'added += 1  × 3', mono=True, size=9.5, fill='--amber')
    # 4: child -> parent again
    f.arrow([(350, 245), (596, 245)], stroke='--paper-dim')
    f.text(475, 234, 'super().add(title)  × 3', mono=True, size=9.5)
    f.text(330, 300, T('counted: 1 + 3 + 3 = 7', 'contados: 1 + 3 + 3 = 7'), size=11, weight='600', anchor='end')
    f.text(370, 300, T('on the shelf: 4', 'na prateleira: 4'), size=11, weight='600', anchor='start')
    return f, T('The parent\'s add_all calls add on self, and self is the child. Every title added in a batch is counted twice.',
                'O add_all do pai chama add em self, e self é o filho. Cada título acrescentado em lote é contado duas vezes.')


@figure('l02-refactor', 2)
def refactor():
    f = Fig('l02-refactor', 780, 330, T(
        'Two class diagrams of loans.py. On the left, before: Loan with days = 14 and fine; FilmLoan '
        'sets days to 7 and StudentLoan overrides fine, both pointing up to Loan; StudentFilmLoan '
        'points up to FilmLoan and overrides fine with a copy of StudentLoan\'s method. Four classes, '
        'one method written twice. On the right, after: one Loan class with title, due and policy, '
        'holding a FinePolicy protocol drawn with a filled diamond; PerDay and GraceDays implement '
        'FinePolicy, and GraceDays itself holds another FinePolicy, the rule it hands the remaining '
        'days to.',
        'Dois diagramas de classes de loans.py. À esquerda, antes: Loan com days = 14 e fine; '
        'FilmLoan põe days em 7 e StudentLoan sobrescreve fine, as duas apontando para Loan; '
        'StudentFilmLoan aponta para FilmLoan e sobrescreve fine com uma cópia do método de '
        'StudentLoan. Quatro classes, um método escrito duas vezes. À direita, depois: uma só classe '
        'Loan com title, due e policy, que tem um protocolo FinePolicy, desenhado com um losango '
        'cheio; PerDay e GraceDays implementam FinePolicy, e o próprio GraceDays tem outro '
        'FinePolicy, a regra a que repassa os dias restantes.'))
    f.text(190, 18, T('before: a class per combination', 'antes: uma classe por combinação'), size=11, weight='600')
    hl = f.klass(125, 40, 130, 'Loan', ['days = 14'], ['fine()'])
    f.klass(20, 160, 110, 'FilmLoan', ['days = 7'])
    f.klass(220, 160, 120, 'StudentLoan', [], ['fine()'])
    f.klass(20, 245, 140, 'StudentFilmLoan', [], ['fine()'])
    f.isa([(75, 160), (75, 135), (190, 135), (190, 40 + hl)])
    f.isa([(280, 160), (280, 135), (190, 135), (190, 40 + hl)])
    f.isa([(75, 245), (75, 205)])
    f.lines(172, 268, [T('fine() copied', 'fine() copiado'), T('from StudentLoan', 'de StudentLoan')],
            size=10, fill='--amber', italic=True, anchor='start')
    f.line(390, 20, 390, 315, stroke='--wire', width=1, dash='4 4')
    f.text(585, 18, T('after: a loan holds its rule', 'depois: um empréstimo tem sua regra'), size=11, weight='600')
    f.klass(410, 50, 130, 'Loan', ['title', 'due', 'policy'], ['fine()'])
    f.klass(600, 60, 140, 'FinePolicy', [], ['fine(days_late)'], stereo='«protocol»')
    f.has([(540, 85), (600, 85)])
    f.klass(560, 220, 90, 'PerDay', ['cents'])
    f.klass(670, 220, 90, 'GraceDays', ['free', 'then'])
    f.isa([(605, 220), (605, 185), (670, 185), (670, 119.5)], width=1, dash='4 3')
    f.isa([(715, 220), (715, 185), (670, 185), (670, 119.5)], width=1, dash='4 3')
    f.has([(760, 262), (772, 262), (772, 90), (740, 90)])
    f.lines(475, 205, ['open_loan()', T('picks the parts', 'escolhe as partes')], size=10, fill='--amber', italic=True)
    f.text(585, 305, T('a new option is a new part, not a new class', 'uma opção nova é uma parte nova, não uma classe nova'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('The same loans before and after the refactoring. The axes that multiplied classes on the left are fields holding parts on the right.',
                'Os mesmos empréstimos antes e depois da refatoração. Os eixos que multiplicavam classes à esquerda viram campos com partes à direita.')
