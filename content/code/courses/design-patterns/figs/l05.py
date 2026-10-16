"""Lesson 5: dependency injection and inversion of control."""
from figures import Fig, T, figure


@figure('l05-root', 5)
def root():
    f = Fig('l05-root', 720, 330, T(
        'A class diagram of the overdue-notices program. OverdueNotices, at the top, holds three '
        'collaborators, drawn as lines with a filled diamond at its end: a LoanStore, a Notifier and '
        'a Clock, each a protocol. Below them, five concrete classes implement the protocols: '
        'ListedLoans implements LoanStore; EmailNotifier and SmsNotifier implement Notifier; '
        'SystemClock and FixedClock implement Clock. A dashed boundary encloses the five concrete '
        'classes and is labelled main.py, the composition root: the only file that names them.',
        'Um diagrama de classes do programa de avisos de atraso. OverdueNotices, no alto, guarda três '
        'colaboradores, desenhados como linhas com um losango cheio do lado dele: um LoanStore, um '
        'Notifier e um Clock, cada um deles um protocolo. Abaixo, cinco classes concretas '
        'implementam os protocolos: ListedLoans implementa LoanStore; EmailNotifier e SmsNotifier '
        'implementam Notifier; SystemClock e FixedClock implementam Clock. Uma fronteira tracejada '
        'envolve as cinco classes concretas e tem o rótulo main.py, a raiz de composição: o único '
        'arquivo que as nomeia.'))
    h = f.klass(270, 14, 180, 'OverdueNotices', ['loans', 'notifier', 'clock'], ['send_all()'])
    bottom = 14 + h
    f.text(462, 40, T('asks for three protocols,', 'pede três protocolos'), size=10,
           fill='--paper-dim', italic=True, anchor='start')
    f.text(462, 55, T('builds none of them', 'e não constrói nenhum'), size=10,
           fill='--paper-dim', italic=True, anchor='start')
    protos = [(40, 'LoanStore', 'open_loans()'), (270, 'Notifier', 'send()'), (500, 'Clock', 'today()')]
    py = 150
    ph = 0
    for x, name, meth in protos:
        ph = f.klass(x, py, 180, name, [], [meth], stereo='«protocol»')
    f.has([(300, bottom), (300, 130), (130, 130), (130, py)])
    f.has([(360, bottom), (360, py)])
    f.has([(420, bottom), (420, 130), (590, 130), (590, py)])
    pb = py + ph
    f.rect(20, 228, 680, 92, stroke='--amber', fill='--ink', dash='5 4', rx=6)
    concrete = [(70, 120, 'ListedLoans', 130), (245, 110, 'EmailNotifier', 360),
                (365, 110, 'SmsNotifier', 360), (490, 95, 'SystemClock', 590),
                (595, 95, 'FixedClock', 590)]
    for x, w, name, target in concrete:
        f.klass(x, 250, w, name, size=9)
        cx = x + w / 2
        f.isa([(cx, 250), (cx, 238), (target, 238), (target, pb)], width=1, dash='4 3')
    f.text(360, 300, T('main.py, the composition root: the only file that names these classes',
                       'main.py, a raiz de composição: o único arquivo que nomeia estas classes'),
           size=10.5, fill='--amber', italic=True)
    return f, T('The job depends on three protocols. Which classes stand behind them is decided in one file.',
                'O trabalho depende de três protocolos. Que classes ficam por trás deles é decidido num arquivo só.')


@figure('l05-locator', 5)
def locator():
    f = Fig('l05-locator', 720, 270, T(
        'Two versions of the same job side by side. On the left, injected: OverdueNotices has a '
        'constructor that takes loans, notifier and clock, and three boxes, LoanStore, Notifier and '
        'Clock, each send an arrow up into it, labelled handed in, visible in the signature. On the '
        'right, located: LocatedNotices has a constructor that takes nothing; an arrow goes from it '
        'down to a Services registry, and from the registry to three keys, loans, notifier and '
        'clock. The clock key is drawn dashed in amber and labelled never provided, found only when '
        'send_all runs.',
        'Duas versões do mesmo trabalho lado a lado. À esquerda, injetado: OverdueNotices tem um '
        'construtor que recebe loans, notifier e clock, e três caixas, LoanStore, Notifier e Clock, '
        'mandam cada uma uma seta para dentro dele, com o rótulo entregues, visíveis na assinatura. '
        'À direita, localizado: LocatedNotices tem um construtor que não recebe nada; uma seta vai '
        'dele até um registro Services, e do registro até três chaves, loans, notifier e clock. A '
        'chave clock aparece tracejada em âmbar com o rótulo nunca fornecido, descoberto só quando '
        'send_all roda.'))
    f.text(175, 16, T('injected', 'injetado'), size=11, weight='600')
    h = f.klass(55, 34, 240, 'OverdueNotices', [], ['__init__(loans, notifier, clock)', 'send_all()'],
                size=9.5)
    jb = 34 + h
    for i, name in enumerate(['LoanStore', 'Notifier', 'Clock']):
        x = 30 + i * 100
        f.box(x + 45, 175, 90, 24, [name], size=9.5, mono=True, stroke='--phosphor')
        f.arrow([(x + 45, 163), (x + 45, jb + 2)], stroke='--paper-dim', width=1.2)
    f.text(175, 215, T('handed in, visible in the signature', 'entregues, visíveis na assinatura'),
           size=10, fill='--paper-dim', italic=True)
    f.line(360, 12, 360, 258, stroke='--wire', width=1, dash='4 4')
    f.text(545, 16, T('located', 'localizado'), size=11, weight='600')
    h2 = f.klass(425, 34, 240, 'LocatedNotices', [], ['__init__()', 'send_all()'], size=9.5)
    lb = 34 + h2
    sh = f.klass(485, 112, 120, 'Services', [], ['get(key)'], size=9.5)
    f.arrow([(545, lb), (545, 110)], stroke='--paper-dim', width=1.2)
    f.text(555, lb + 12, T('from inside send_all', 'de dentro de send_all'), size=9.5,
           fill='--paper-dim', italic=True, anchor='start')
    sb = 112 + sh
    keys = [(400, 'loans', False), (500, 'notifier', False), (600, 'clock', True)]
    for x, k, missing in keys:
        f.box(x + 40, 195, 80, 22, [k], size=9.5, mono=True,
              stroke='--amber' if missing else '--phosphor', dash='4 3' if missing else None,
              fillt='--amber' if missing else '--paper')
        f.arrow([(545, sb), (545, sb + 10), (x + 40, sb + 10), (x + 40, 182)],
                stroke='--paper-dim', width=1)
    f.text(640, 222, T('never provided:', 'nunca fornecido:'), size=9.5, fill='--amber', italic=True)
    f.text(640, 236, T('found when send_all runs', 'descoberto quando send_all roda'), size=9.5,
           fill='--amber', italic=True)
    return f, T('The same three dependencies, declared on the left and fetched on the right. Only the left one can be checked before the job runs.',
                'As mesmas três dependências, declaradas à esquerda e buscadas à direita. Só a da esquerda pode ser verificada antes de o trabalho rodar.')
