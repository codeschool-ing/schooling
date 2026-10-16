"""Lesson 12: entities, aggregates, value objects and repositories."""
from figures import Fig, T, figure


@figure('l12-boundaries', 12)
def boundaries():
    f = Fig('l12-boundaries', 720, 300, T(
        'Two aggregates, each inside a dashed boundary. On the left, the Member aggregate: the root '
        'Member, with fields id, name and owed, holds a list of Loan objects, each with copy_id and '
        'due, drawn with a filled diamond at the Member end. On the right, the Copy aggregate: a '
        'single root Copy with id, kind and on_loan_to. A dashed arrow labelled "by id" runs from '
        'Loan\'s copy_id to Copy, and another from Copy\'s on_loan_to back to Member. Outside code, '
        'at the bottom, has solid arrows only to the two roots, never to a Loan.',
        'Dois agregados, cada um dentro de uma fronteira tracejada. À esquerda, o agregado Member: '
        'a raiz Member, com os campos id, name e owed, guarda uma lista de objetos Loan, cada um com '
        'copy_id e due, desenhada com um losango cheio do lado de Member. À direita, o agregado '
        'Copy: uma única raiz Copy com id, kind e on_loan_to. Uma seta tracejada marcada "pelo id" '
        'vai do copy_id de Loan até Copy, e outra do on_loan_to de Copy de volta a Member. O código '
        'de fora, embaixo, tem setas cheias só para as duas raízes, nunca para um Loan.'))
    # boundaries drawn as outlines: the 'by id' arrows cross them on purpose
    f.path('M20 14 L350 14 L350 214 L20 214 Z', stroke='--amber', width=1.2, dash='5 4')
    f.text(185, 30, T('Member aggregate', 'agregado Member'), size=10.5, weight='600', fill='--amber')
    f.path('M470 14 L700 14 L700 214 L470 214 Z', stroke='--amber', width=1.2, dash='5 4')
    f.text(585, 30, T('Copy aggregate', 'agregado Copy'), size=10.5, weight='600', fill='--amber')
    f.klass(40, 50, 130, 'Member', ['id', 'name', 'owed: Money'], ['borrow()', 'give_back()'],
            stereo=T('«root»', '«raiz»'))
    f.klass(220, 70, 110, 'Loan', ['copy_id', 'due'])
    f.has([(170, 100), (220, 100)])
    f.text(275, 118 + 26, T('0..5, inside', '0..5, dentro'), size=9.5, fill='--paper-dim', italic=True)
    f.klass(520, 60, 140, 'Copy', ['id', 'kind', 'on_loan_to'], ['check_out()'], stereo=T('«root»', '«raiz»'))
    f.arrow([(330, 92), (517, 92)], stroke='--phosphor', dash='4 3')
    f.text(420, 82, T('by id', 'pelo id'), size=10, fill='--paper')
    f.arrow([(520, 158), (173, 158)], stroke='--phosphor', dash='4 3')
    f.text(420, 148, T('by id', 'pelo id'), size=10, fill='--paper')
    f.box(360, 270, 200, 30, [T('outside code: desk, use cases', 'código de fora: balcão, casos de uso')], size=9.5)
    f.arrow([(300, 255), (300, 240), (105, 240), (105, 217)], stroke='--paper-dim')
    f.arrow([(420, 255), (420, 240), (590, 240), (590, 217)], stroke='--paper-dim')
    f.text(175, 252, T('only through the roots', 'só pelas raízes'), size=9.5, fill='--paper-dim', italic=True)
    return f, T('Each aggregate keeps its own rule behind its root. Between aggregates there are ids, never references to the objects.',
                'Cada agregado guarda a própria regra atrás da raiz. Entre agregados há ids, nunca referências aos objetos.')


@figure('l12-repository', 12)
def repository():
    f = Fig('l12-repository', 720, 270, T(
        'A class diagram of repositories.py. In the middle, the protocol MemberRepository with two '
        'methods, get and save. The function lend_copy, on the left, uses it, drawn as a plain '
        'arrow. Below, two classes implement it, drawn with hollow arrowheads: InMemoryMembers, '
        'which keeps deep copies in a dictionary, and SqliteMembers, which maps one Member onto '
        'the tables members and loans. Both get and save a whole Member; there is no repository '
        'for loans.',
        'Um diagrama de classes de repositories.py. No meio, o protocolo MemberRepository com dois '
        'métodos, get e save. A função lend_copy, à esquerda, o usa, desenhada como uma seta '
        'simples. Embaixo, duas classes o implementam, desenhadas com pontas de seta vazadas: '
        'InMemoryMembers, que guarda cópias profundas num dicionário, e SqliteMembers, que mapeia um '
        'Member nas tabelas members e loans. As duas buscam e salvam um Member inteiro; não existe '
        'repositório para empréstimos.'))
    f.box(110, 60, 150, 34, ['lend_copy()'], size=10, mono=True, stroke='--phosphor')
    f.klass(290, 24, 190, 'MemberRepository', [], ['get(member_id) -> Member', 'save(member)'],
            stereo='«protocol»')
    f.arrow([(185, 60), (287, 60)], stroke='--paper-dim')
    f.text(236, 50, T('uses', 'usa'), size=9.5, fill='--paper-dim')
    specs = [(150, 'InMemoryMembers', ['_rows: dict'], T('deep copies in a dict', 'cópias profundas num dict')),
             (430, 'SqliteMembers', ['db: Connection'], T('tables members and loans', 'tabelas members e loans'))]
    for x, name, flds, note in specs:
        h = f.klass(x, 160, 170, name, flds, ['get()', 'save()'])
        f.isa([(x + 85, 160), (x + 85, 135), (385, 135), (385, 101)], dash='4 3')
        f.text(x + 85, 160 + h + 14, note, size=9.5, fill='--paper-dim', italic=True)
    f.text(620, 60, T('no LoanRepository:', 'nenhum LoanRepository:'), size=10, fill='--amber', anchor='middle')
    f.text(620, 76, T('a loan is never loaded', 'um empréstimo nunca é'), size=9.5, fill='--paper-dim')
    f.text(620, 90, T('without its member', 'carregado sem o sócio'), size=9.5, fill='--paper-dim')
    return f, T('One protocol, two storages, one use case that cannot tell them apart.',
                'Um protocolo, dois armazenamentos, um caso de uso que não sabe diferenciá-los.')
