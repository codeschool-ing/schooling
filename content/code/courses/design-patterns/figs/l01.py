"""Lesson 1: object orientation."""
from figures import Fig, T, figure


@figure('l01-items', 1)
def items():
    f = Fig('l01-items', 700, 290, T(
        'A class diagram of items.py. Item, at the top, has the fields title, shelf and loan_days '
        'and the method describe. Three classes point up to it with hollow arrowheads, meaning each '
        'is an Item: Book adds nothing; Film sets loan_days to 7, adds minutes and overrides '
        'describe; ReferenceBook sets loan_days to 0 and overrides describe. A call to describe on '
        'a Film looks in Film first, then Item, then object.',
        'Um diagrama de classes de items.py. Item, no alto, tem os campos title, shelf e loan_days '
        'e o método describe. Três classes apontam para ele com pontas de seta vazadas, o que quer '
        'dizer que cada uma é um Item: Book não acrescenta nada; Film põe loan_days em 7, acrescenta '
        'minutes e sobrescreve describe; ReferenceBook põe loan_days em 0 e sobrescreve describe. '
        'Uma chamada a describe num Film procura primeiro em Film, depois em Item, depois em object.'))
    h = f.klass(260, 14, 180, 'Item', ['title: str', 'shelf: str', 'loan_days = 14'], ['describe()'])
    tops = []
    specs = [
        (40, 'Book', [], [], T('changes nothing', 'não muda nada')),
        (260, 'Film', ['loan_days = 7', 'minutes: int'], ['describe()'], T('adds and extends', 'acrescenta e estende')),
        (480, 'ReferenceBook', ['loan_days = 0'], ['describe()'], T('replaces describe', 'substitui describe')),
    ]
    for x, name, flds, meths, note in specs:
        y = 170
        hh = f.klass(x, y, 180, name, flds, meths)
        f.isa([(x + 90, y), (x + 90, 145), (350, 145), (350, 14 + h)])
        f.text(x + 90, y + hh + 16, note, size=10, fill='--paper-dim', italic=True)
    f.text(560, 60, T('hollow head: "is a"', 'ponta vazada: "é um"'), size=10, fill='--paper-dim', anchor='start')
    return f, T('Three children of one parent. Each inherits the fields and the method, and two of them change what describe does.',
                'Três filhos de um pai. Cada um herda os campos e o método, e dois deles mudam o que describe faz.')


@figure('l01-isa-hasa', 1)
def isa_hasa():
    f = Fig('l01-isa-hasa', 720, 300, T(
        'Two ways to give a member a notification channel. On the left, inheritance: Member at the '
        'top, with six subclasses below it, one for each combination of status and channel, such '
        'as StudentEmailMember and AdultSmsMember. On the right, composition: one Member class '
        'holding a Channel, drawn with a filled diamond at the Member end, and Email, Sms and '
        'PrintedSlip each implementing Channel. Adding a fourth channel costs three classes on the '
        'left and one on the right.',
        'Duas maneiras de dar a um membro um canal de aviso. À esquerda, herança: Member no alto, '
        'com seis subclasses abaixo, uma para cada combinação de categoria e canal, como '
        'StudentEmailMember e AdultSmsMember. À direita, composição: uma única classe Member que '
        'tem um Channel, desenhada com um losango cheio do lado de Member, e Email, Sms e '
        'PrintedSlip implementando Channel. Um quarto canal custa três classes à esquerda e uma à '
        'direita.'))
    f.text(170, 18, T('inheritance: one class per combination', 'herança: uma classe por combinação'),
           size=11, weight='600')
    f.klass(110, 34, 120, 'Member')
    names = ['StudentEmail', 'AdultEmail', 'StudentSms', 'AdultSms', 'StudentSlip', 'AdultSlip']
    f.isa([(170, 236), (170, 62)], width=1)
    for i, n in enumerate(names):
        col, row = i % 2, i // 2
        x, y = (30 if col == 0 else 200), 96 + row * 52
        h = f.klass(x, y, 110, n, size=8.5)
        edge = x + 110 if col == 0 else x
        f.line(edge, y + h / 2, 170, y + h / 2, stroke='--paper-dim', width=1)
    f.text(170, 272, T('a fourth channel: +2 classes', 'um quarto canal: +2 classes'), size=10,
           fill='--amber', italic=True)
    f.line(355, 20, 355, 285, stroke='--wire', width=1, dash='4 4')
    f.text(540, 18, T('composition: a member has a channel', 'composição: um membro tem um canal'),
           size=11, weight='600')
    f.klass(390, 50, 130, 'Member', ['name', 'channel'], ['notify()'])
    f.klass(580, 60, 120, 'Channel', [], ['deliver()'], stereo='«protocol»')
    f.has([(520, 85), (580, 85)])
    for i, n in enumerate(['Email', 'Sms', 'PrintedSlip']):
        x = 400 + i * 108
        f.klass(x, 190, 100, n, size=9)
        f.isa([(x + 50, 190), (x + 50, 165), (640, 165), (640, 116)], width=1, dash='4 3')
    f.text(540, 272, T('a fourth channel: +1 class', 'um quarto canal: +1 classe'), size=10,
           fill='--amber', italic=True)
    return f, T('The same choices, built two ways. Inheritance multiplies the axes that vary; composition adds them.',
                'As mesmas escolhas, construídas de duas maneiras. A herança multiplica os eixos que variam; a composição soma.')
