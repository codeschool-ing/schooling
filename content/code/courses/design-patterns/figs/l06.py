"""Lesson 6: the GoF patterns in practice."""
from figures import Fig, T, figure


@figure('l06-catalogue', 6)
def catalogue():
    f = Fig('l06-catalogue', 720, 300, T(
        'The twenty-three patterns of the 1994 book in three columns. Creational, five: Abstract '
        'Factory, Builder, Factory Method, Prototype, Singleton. Structural, seven: Adapter, Bridge, '
        'Composite, Decorator, Facade, Flyweight, Proxy. Behavioural, eleven: Chain of '
        'Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, '
        'Strategy, Template Method, Visitor. Thirteen are drawn with a solid border because this '
        'lesson works through them: Builder, Factory Method, Singleton, Adapter, Decorator, Facade, '
        'Proxy, Command, Iterator, Observer, State, Strategy and Template Method. The other ten have '
        'a dashed border.',
        'Os vinte e três padrões do livro de 1994 em três colunas. Criacionais, cinco: Abstract '
        'Factory, Builder, Factory Method, Prototype, Singleton. Estruturais, sete: Adapter, Bridge, '
        'Composite, Decorator, Facade, Flyweight, Proxy. Comportamentais, onze: Chain of '
        'Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, '
        'Strategy, Template Method, Visitor. Treze têm borda contínua porque esta lição trata '
        'deles: Builder, Factory Method, Singleton, Adapter, Decorator, Facade, Proxy, Command, '
        'Iterator, Observer, State, Strategy e Template Method. Os outros dez têm borda tracejada.'))
    here = {'Builder', 'Factory Method', 'Singleton', 'Adapter', 'Decorator', 'Facade', 'Proxy',
            'Command', 'Iterator', 'Observer', 'State', 'Strategy', 'Template Method'}
    cols = [
        (105, T('creational · 5', 'criacionais · 5'),
         [['Abstract Factory', 'Builder', 'Factory Method', 'Prototype', 'Singleton']]),
        (295, T('structural · 7', 'estruturais · 7'),
         [['Adapter', 'Bridge', 'Composite', 'Decorator', 'Facade', 'Flyweight', 'Proxy']]),
        (560, T('behavioural · 11', 'comportamentais · 11'),
         [['Chain of Responsibility', 'Command', 'Interpreter', 'Iterator', 'Mediator', 'Memento'],
          ['Observer', 'State', 'Strategy', 'Template Method', 'Visitor']]),
    ]
    for cx, head, groups in cols:
        f.text(cx, 20, head, size=11, weight='600')
        offs = [0] if len(groups) == 1 else [-80, 80]
        for off, names in zip(offs, groups):
            for i, n in enumerate(names):
                y = 52 + i * 31
                mine = n in here
                f.box(cx + off, y, 150, 24, [n], size=9.5,
                      stroke='--phosphor' if mine else '--paper-dim',
                      dash=None if mine else '3 3', fillt='--paper' if mine else '--paper-dim')
    f.line(200, 10, 200, 236, stroke='--wire', width=1, dash='4 4')
    f.line(390, 10, 390, 236, stroke='--wire', width=1, dash='4 4')
    f.rect(170, 258, 34, 18, stroke='--phosphor', fill='--panel', rx=4)
    f.text(212, 267, T('in this lesson (13)', 'nesta lição (13)'), size=10, anchor='start')
    f.rect(410, 258, 34, 18, stroke='--paper-dim', fill='--panel', rx=4, dash='3 3')
    f.text(452, 267, T('named only (10)', 'só citados (10)'), size=10, anchor='start', fill='--paper-dim')
    return f, T('The catalogue by family. The solid boxes are the thirteen this lesson builds; the dashed ones get a line in the table.',
                'O catálogo por família. As caixas contínuas são os treze que esta lição constrói; as tracejadas ganham uma linha na tabela.')


@figure('l06-decorator', 6)
def decorator():
    f = Fig('l06-decorator', 720, 250, T(
        'Three nested boxes: Capped with a cap of 1000 on the outside, GraceDays with 2 days inside '
        'it, and DailyFine at 50 cents in the middle. A call fine(40) enters the outer box and is '
        'passed on unchanged as 40; GraceDays passes 40 minus 2, which is 38; DailyFine computes 38 '
        'times 50, which is 1900. On the way back GraceDays returns 1900 unchanged and Capped '
        'returns the smaller of 1900 and 1000, which is 1000.',
        'Três caixas aninhadas: Capped com teto de 1000 por fora, GraceDays com 2 dias dentro dela e '
        'DailyFine a 50 centavos no meio. Uma chamada fine(40) entra na caixa de fora e é repassada '
        'sem mudança como 40; GraceDays repassa 40 menos 2, que dá 38; DailyFine calcula 38 vezes '
        '50, que dá 1900. Na volta, GraceDays devolve 1900 sem mudança e Capped devolve o menor '
        'entre 1900 e 1000, que é 1000.'))
    f.rect(40, 46, 640, 190, stroke='--phosphor', fill='--panel', width=1.4, rx=6)
    f.text(54, 62, 'Capped(cap=1000)', size=10, anchor='start', mono=True, weight='600')
    f.rect(140, 82, 440, 136, stroke='--phosphor', fill='--ink', width=1.4, rx=6)
    f.text(154, 98, 'GraceDays(days=2)', size=10, anchor='start', mono=True, weight='600')
    f.rect(240, 120, 240, 78, stroke='--phosphor', fill='--panel', width=1.4, rx=6)
    f.text(320, 142, 'DailyFine(50)', size=10, mono=True, weight='600')
    f.text(320, 168, '38 × 50 = 1900', size=10.5, mono=True)
    down, up = 380, 460
    f.text(down - 8, 24, 'fine(40)', size=10, anchor='end', mono=True)
    f.arrow([(down, 14), (down, 44)], stroke='--paper-dim')
    f.text(down - 8, 66, '40', size=10, anchor='end', mono=True)
    f.arrow([(down, 50), (down, 80)], stroke='--paper-dim')
    f.text(down - 8, 103, '40 − 2 = 38', size=10, anchor='end', mono=True)
    f.arrow([(down, 86), (down, 118)], stroke='--paper-dim')
    f.arrow([(up, 118), (up, 86)], stroke='--amber')
    f.text(up + 8, 103, '1900', size=10, anchor='start', mono=True)
    f.arrow([(up, 80), (up, 50)], stroke='--amber')
    f.text(up + 8, 66, '1900', size=10, anchor='start', mono=True)
    f.arrow([(up, 44), (up, 14)], stroke='--amber')
    f.text(up + 8, 24, 'min(1900, 1000) = 1000', size=10, anchor='start', mono=True, fill='--amber')
    return f, T('student.fine(40), followed through the stack. Each layer changes what goes in or what comes out, and knows nothing about the others.',
                'student.fine(40), acompanhada pela pilha. Cada camada muda o que entra ou o que sai, e não sabe nada das outras.')


@figure('l06-state', 6)
def state():
    f = Fig('l06-state', 720, 230, T(
        'A state diagram of one copy of a book with three states: Available, OnLoan and OnHold. '
        'From Available, lend goes to OnLoan and reserve goes to OnHold. From OnLoan, give_back goes '
        'to Available when nobody is waiting and to OnHold when somebody is; reserve stays in OnLoan '
        'and remembers who is waiting. From OnHold, lend by the member it is held for goes to '
        'OnLoan. Every other request in a state is refused.',
        'Um diagrama de estados de um exemplar de livro com três estados: Available, OnLoan e '
        'OnHold. De Available, lend vai para OnLoan e reserve vai para OnHold. De OnLoan, give_back '
        'vai para Available quando ninguém espera e para OnHold quando alguém espera; reserve fica '
        'em OnLoan e guarda quem espera. De OnHold, lend pelo membro para quem está guardado vai '
        'para OnLoan. Todo outro pedido num estado é recusado.'))
    for x, name, sub in [(100, 'Available', None), (360, 'OnLoan', T('remembers who waits', 'guarda quem espera')),
                         (620, 'OnHold', T('for one member', 'para um membro'))]:
        f.rect(x - 75, 92, 150, 46, stroke='--phosphor', fill='--panel', width=1.4, rx=10)
        if sub:
            f.text(x, 107, name, size=10.5, mono=True, weight='600')
            f.text(x, 124, sub, size=9, fill='--paper-dim', italic=True)
        else:
            f.text(x, 115, name, size=10.5, mono=True, weight='600')
    f.arrow([(175, 104), (283, 104)], stroke='--paper-dim')
    f.text(229, 95, 'lend', size=9.5, mono=True)
    f.arrow([(283, 128), (177, 128)], stroke='--paper-dim')
    f.text(229, 143, 'give_back', size=9.5, mono=True)
    f.text(229, 157, T('nobody waiting', 'ninguém espera'), size=9, fill='--paper-dim', italic=True)
    f.arrow([(435, 115), (543, 115)], stroke='--paper-dim')
    f.text(489, 92, 'give_back', size=9.5, mono=True)
    f.text(489, 106, T('somebody waiting', 'alguém espera'), size=9, fill='--paper-dim', italic=True)
    f.arrow([(100, 92), (100, 46), (620, 46), (620, 90)], stroke='--paper-dim')
    f.text(360, 38, 'reserve', size=9.5, mono=True)
    f.arrow([(620, 138), (620, 190), (360, 190), (360, 140)], stroke='--paper-dim')
    f.text(490, 202, 'lend', size=9.5, mono=True)
    f.text(490, 216, T('by the member it is held for', 'pelo membro para quem está guardado'), size=9,
           fill='--paper-dim', italic=True)
    f.text(100, 178, T('anything else:', 'qualquer outro pedido:'), size=9.5, fill='--amber', italic=True)
    f.text(100, 192, T('Refused, with the reason', 'Refused, com o motivo'), size=9.5, fill='--amber', italic=True)
    return f, T('One copy, three situations. Each arrow is a method that moves the copy on; each missing arrow is a refusal with a reason.',
                'Um exemplar, três situações. Cada seta é um método que leva o exemplar adiante; cada seta que falta é uma recusa com motivo.')
