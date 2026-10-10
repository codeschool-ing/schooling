"""Lesson 4: SOLID, interface segregation and dependency inversion."""
from figures import Fig, T, figure


@figure('l04-inversion', 4)
def inversion():
    f = Fig('l04-inversion', 720, 300, T(
        'Two diagrams of the fine notices. On the left, before: OverdueNotices imports SmtpMailer, '
        'so the arrow runs down from the rules to the mail code, and the policy depends on the '
        'detail. On the right, after: the module notices.py holds both OverdueNotices and the '
        'Notifier protocol it uses, drawn with a diamond. Below it, in adapters.py, EmailNotifier '
        'and SmsNotifier each point up to Notifier with a hollow arrowhead. The arrows now run from '
        'the details up to the policy.',
        'Dois diagramas dos avisos de multa. À esquerda, antes: OverdueNotices importa SmtpMailer, '
        'então a seta desce das regras para o código de e-mail, e a regra depende do detalhe. À '
        'direita, depois: o módulo notices.py guarda OverdueNotices e o protocolo Notifier que ele '
        'usa, desenhado com um losango. Abaixo, em adapters.py, EmailNotifier e SmsNotifier apontam '
        'para cima, para Notifier, com ponta de seta vazada. As setas agora vão dos detalhes para a '
        'regra.'))
    f.text(175, 18, T('before: the rules import the detail', 'antes: as regras importam o detalhe'), size=11, weight='600')
    f.klass(90, 60, 170, 'OverdueNotices', [], ['send()'])
    f.klass(90, 200, 170, 'SmtpMailer', [], ['send_mail()'])
    f.arrow([(175, 105), (175, 196)], stroke='--amber', width=1.5)
    f.text(185, 150, 'import', mono=True, size=9.5, fill='--amber', anchor='start')
    f.text(175, 275, T('the policy depends on the detail', 'a regra depende do detalhe'), size=10,
           fill='--paper-dim', italic=True)
    f.line(355, 20, 355, 290, stroke='--wire', width=1, dash='4 4')
    f.text(540, 18, T("after: the detail imports the rules' port", 'depois: o detalhe importa a porta das regras'),
           size=11, weight='600')
    f.rect(380, 36, 320, 116, stroke='--paper-dim', fill='--ink', dash='5 4')
    f.text(390, 50, 'notices.py', mono=True, size=9.5, fill='--paper-dim', anchor='start')
    f.klass(392, 70, 140, 'OverdueNotices', [], ['send()'])
    f.klass(560, 62, 130, 'Notifier', [], ['notify()'], stereo='«protocol»')
    f.has([(532, 92), (560, 92)])
    f.line(380, 196, 700, 196, stroke='--paper-dim', width=1, dash='5 4')
    f.text(390, 210, 'adapters.py', mono=True, size=9.5, fill='--paper-dim', anchor='start')
    f.klass(392, 226, 140, 'EmailNotifier')
    f.klass(560, 226, 130, 'SmsNotifier')
    f.isa([(462, 226), (462, 176), (625, 176), (625, 121.5)], stroke='--amber', width=1.4)
    f.isa([(625, 226), (625, 121.5)], stroke='--amber', width=1.4)
    f.text(540, 288, T('the detail depends on the policy', 'o detalhe depende da regra'), size=10,
           fill='--paper-dim', italic=True)
    return f, T('The same rules before and after inversion. The protocol moved into the rules\' module, and the import arrows turned round.',
                'As mesmas regras antes e depois da inversão. O protocolo foi para o módulo das regras, e as setas de import viraram.')


@figure('l04-ports', 4)
def ports():
    f = Fig('l04-ports', 720, 290, T(
        'The rules in the middle, as notices.py with OverdueNotices, and a Notifier port on its '
        'right edge. On the left, the driving side: main.py and cli.py each call into the rules. On '
        'the right, the driven side: the rules call out through the Notifier port to EmailNotifier, '
        'to SmsNotifier, and in a test to Recording. Nothing in the middle imports anything at the '
        'edges.',
        'As regras no meio, como notices.py com OverdueNotices, e uma porta Notifier na borda '
        'direita. À esquerda, o lado que conduz: main.py e cli.py chamam as regras. À direita, o lado '
        'conduzido: as regras chamam para fora pela porta Notifier, até EmailNotifier, SmsNotifier e, '
        'num teste, Recording. Nada no meio importa coisa alguma das bordas.'))
    f.text(110, 30, T('driving side', 'lado que conduz'), size=11, weight='600')
    f.text(620, 30, T('driven side', 'lado conduzido'), size=11, weight='600')
    f.rect(260, 80, 200, 120, stroke='--phosphor', width=1.6)
    f.text(360, 104, 'notices.py', mono=True, size=10, fill='--paper-dim')
    f.text(360, 134, 'OverdueNotices', mono=True, size=11, weight='600')
    f.text(360, 160, T('the rules', 'as regras'), size=10, fill='--paper-dim', italic=True)
    f.rect(430, 122, 80, 36, stroke='--amber', width=1.4, fill='--panel', rx=2)
    f.text(470, 140, 'Notifier', mono=True, size=9.5, fill='--amber')
    for y, name in [(100, 'main.py'), (180, 'cli.py')]:
        f.box(110, y, 120, 30, [name], mono=True, stroke='--paper-dim')
        f.arrow([(170, y), (256, y)], stroke='--paper-dim')
    for y, name, dash in [(80, 'EmailNotifier', None), (140, 'SmsNotifier', None), (200, 'Recording', '4 3')]:
        f.box(625, y, 130, 30, [name], mono=True, stroke='--paper-dim', dash=dash)
        f.arrow([(510, 140), (535, 140), (535, y), (556, y)], stroke='--paper-dim')
    f.text(625, 226, T('in a test', 'num teste'), size=9.5, fill='--paper-dim', italic=True)
    f.text(360, 268, T('nothing in the middle imports anything at the edges',
                       'nada no meio importa coisa alguma das bordas'), size=10, fill='--paper-dim', italic=True)
    return f, T('Ports and adapters: the driving adapters call the rules, and the rules reach every driven adapter through a port they own.',
                'Portas e adaptadores: os adaptadores que conduzem chamam as regras, e as regras chegam a cada adaptador conduzido por uma porta que é delas.')
