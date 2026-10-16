"""Lesson 14: refactoring."""
from figures import Fig, T, figure


@figure('l14-moves', 14)
def moves():
    f = Fig('l14-moves', 720, 270, T(
        'Two ways of reaching the same restructured code, drawn along a time axis. Above, a '
        'refactoring: ten small moves such as rename, extract and move, each followed by a dot for '
        'a passing test run, so the program works at every point and any dot is a place to stop and '
        'commit. Below, a rewrite: one long bar labelled "nothing runs" covering almost the whole '
        'time, ending in a cluster of failures at the first run.',
        'Duas maneiras de chegar ao mesmo código reestruturado, desenhadas ao longo de um eixo de '
        'tempo. Em cima, uma refatoração: dez movimentos pequenos como renomear, extrair e mover, '
        'cada um seguido de um ponto que é uma execução de testes que passou, então o programa '
        'funciona em todo momento e qualquer ponto é um lugar para parar e fazer commit. Embaixo, '
        'uma reescrita: uma barra longa com o rótulo "nada roda" cobrindo quase todo o tempo, '
        'terminando num amontoado de falhas na primeira execução.'))
    x0, x1 = 60, 690
    f.text(x0, 28, T('refactoring: small moves, a passing run after each', 'refatoração: movimentos pequenos, uma execução que passa depois de cada'),
           size=11, weight='600', anchor='start')
    names = [T('rename', 'renomear'), T('extract', 'extrair'), '', T('extract', 'extrair'), '',
             T('move', 'mover'), '', T('new class', 'classe nova'), '', '']
    step = (x1 - x0) / 10
    y = 70
    f.line(x0, y, x1, y, stroke='--wire', width=1.2)
    for i, n in enumerate(names):
        cx = x0 + step * (i + 1)
        f.circle(cx, y, 6, fill='--phosphor')
        if n:
            f.text(cx - step / 2, y - 14, n, size=9.5, fill='--paper-dim')
    f.text(x0 + step * 5, y + 26, T('any dot is a working program: stop, commit, go home',
                                    'qualquer ponto é um programa que funciona: pare, faça commit, vá para casa'),
           size=10, fill='--paper', italic=True)
    f.arrow([(x0 + step * 5, y + 16), (x0 + step * 5, y + 9)], stroke='--paper-dim', width=1)

    f.text(x0, 140, T('rewrite: one big step', 'reescrita: um passo grande'), size=11, weight='600', anchor='start')
    y2 = 180
    f.rect(x0, y2 - 13, (x1 - x0) * 0.82, 26, stroke='--wire', fill='--panel', dash='5 4', rx=3)
    f.text(x0 + (x1 - x0) * 0.41, y2, T('nothing runs', 'nada roda'), size=10, fill='--paper-dim', italic=True)
    for dx, dy in [(0, 0), (14, -9), (14, 9), (28, 0), (42, -9), (42, 9)]:
        f.circle(x0 + (x1 - x0) * 0.82 + 16 + dx, y2 + dy, 5, fill='--amber')
    f.text(x1 - 4, y2 + 30, T('first run: many failures at once', 'primeira execução: muitas falhas de uma vez'),
           size=10, fill='--paper', italic=True, anchor='end')
    f.arrow([(x0, 245), (x1, 245)], stroke='--paper-dim', width=1.2)
    f.text(x1, 258, T('time', 'tempo'), size=10, fill='--paper-dim', anchor='end')
    return f, T('Both end with the same code. Only one of them works on every day in between.',
                'Os dois terminam com o mesmo código. Só um deles funciona em todos os dias do caminho.')


@figure('l14-kinds', 14)
def kinds():
    f = Fig('l14-kinds', 720, 320, T(
        'Before and after replacing the conditional with polymorphism. On the left, before: two '
        'functions, due_date and label, each holding the same chain of tests on the kind string: '
        'book, film, anything else. On the right, after: Loan holds a Kind, drawn with a diamond at '
        'the Loan end. Kind is a protocol with a label and a due method. Book, Film and OtherItem '
        'each implement it. A dictionary, KINDS, turns the incoming string into a Kind once, when '
        'the loan is built.',
        'Antes e depois de trocar o condicional por polimorfismo. À esquerda, antes: duas funções, '
        'due_date e label, cada uma com a mesma cadeia de testes sobre a string do tipo: book, film, '
        'qualquer outra coisa. À direita, depois: Loan tem um Kind, desenhado com um losango do lado '
        'de Loan. Kind é um protocolo com um label e um método due. Book, Film e OtherItem o '
        'implementam. Um dicionário, KINDS, transforma a string que chega num Kind uma vez, quando o '
        'empréstimo é montado.'))
    f.text(140, 20, T('before: one switch, written twice', 'antes: um switch, escrito duas vezes'), size=11, weight='600')
    f.klass(30, 44, 220, 'due_date(kind, lent_on)', ['if kind == "book": +14', 'elif kind == "film": +7', 'else: +0'],
            size=9.5, stroke='--amber')
    f.klass(30, 156, 220, 'label(kind)', ['if kind == "book": "book"', 'elif kind == "film": ...', 'else: "item"'],
            size=9.5, stroke='--amber')
    f.text(140, 278, T('a new kind: find both chains', 'um tipo novo: achar as duas cadeias'), size=10,
           fill='--amber', italic=True)
    f.line(290, 14, 290, 300, stroke='--wire', width=1, dash='4 4')
    f.text(505, 20, T('after: each kind answers for itself', 'depois: cada tipo responde por si'), size=11, weight='600')
    hl = f.klass(315, 44, 150, 'Loan', ['member', 'title', 'kind: Kind'], ['days_late()'], size=9.5)
    hk = f.klass(560, 52, 130, 'Kind', ['label'], ['due(lent_on)'], size=9.5, stereo='«protocol»')
    f.has([(465, 84), (560, 84)])
    for i, n in enumerate(['Book', 'Film', 'OtherItem']):
        x = 410 + i * 100
        f.klass(x, 200, 90, n, size=9)
        f.isa([(x + 45, 200), (x + 45, 178), (625, 178), (625, 52 + hk)], width=1, dash='4 3')
    f.box(390, 258, 150, 26, ['KINDS: str → Kind'], size=9.5, mono=True, stroke='--wire')
    f.arrow([(390, 245), (390, 44 + hl + 2)], stroke='--paper-dim', width=1)
    f.text(398, 232, T('used once, in from_row', 'usado uma vez, em from_row'), size=9.5, fill='--paper-dim',
           anchor='start', italic=True)
    f.text(560, 290, T('a new kind: one class, one entry', 'um tipo novo: uma classe, uma entrada'), size=10,
           fill='--amber', italic=True)
    return f, T('The knowledge of what each kind does moves out of the switches and into the kinds.',
                'O conhecimento do que cada tipo faz sai dos switches e vai para os tipos.')
