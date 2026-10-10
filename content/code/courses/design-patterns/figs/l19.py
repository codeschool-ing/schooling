"""Lesson 19: choosing the pattern for the problem."""
from figures import Fig, T, figure


@figure('l19-two-arrangements', 19)
def two_arrangements():
    f = Fig('l19-two-arrangements', 720, 280, T(
        'Two arrangements of the same fine notice. On the left, plain.py: one module with a '
        'constant, DAILY_FINE, and one function, notice. On the right, layered.py as a class '
        'diagram: NoticeService holds a FineCalculator and a NoticeFormatter; FineCalculator holds '
        'a PolicyFactory and calls fine on a FinePolicy protocol; PolicyFactory creates a '
        'DailyFine, the only class that implements FinePolicy. The left is 10 lines; the right is '
        '46 lines with six classes.',
        'Duas arrumações do mesmo aviso de multa. À esquerda, plain.py: um módulo com uma '
        'constante, DAILY_FINE, e uma função, notice. À direita, layered.py como diagrama de '
        'classes: NoticeService tem um FineCalculator e um NoticeFormatter; FineCalculator tem uma '
        'PolicyFactory e chama fine num protocolo FinePolicy; PolicyFactory cria um DailyFine, a '
        'única classe que implementa FinePolicy. A esquerda tem 10 linhas; a direita tem 46 linhas '
        'e seis classes.'))
    f.text(105, 16, 'plain.py', size=11, weight='600', mono=True)
    f.klass(25, 70, 160, 'plain.py', ['DAILY_FINE = 50'], ['notice()'], stereo='«module»')
    f.text(105, 250, T('10 lines, 1 function', '10 linhas, 1 função'), size=10.5, fill='--amber', weight='600')
    f.line(212, 10, 212, 266, stroke='--wire', width=1, dash='4 4')
    f.text(470, 16, 'layered.py', size=11, weight='600', mono=True)
    hs = f.klass(235, 40, 140, 'NoticeService', [], ['notice()'])
    f.klass(235, 170, 140, 'NoticeFormatter', [], ['format()'])
    hc = f.klass(415, 40, 135, 'FineCalculator', [], ['compute()'])
    f.klass(415, 170, 135, 'PolicyFactory', [], ['for_category()'])
    hp = f.klass(600, 40, 110, 'FinePolicy', [], ['fine()'], stereo='«protocol»')
    f.klass(600, 170, 110, 'DailyFine', [], ['fine()'])
    f.has([(375, 62), (415, 62)])
    f.has([(305, 40 + hs), (305, 170)])
    f.has([(482, 40 + hc), (482, 170)])
    f.arrow([(550, 62), (598, 62)], stroke='--paper-dim', width=1.2)
    f.text(574, 52, T('calls', 'chama'), size=9, fill='--paper-dim', italic=True)
    f.arrow([(550, 192), (598, 192)], stroke='--paper-dim', width=1.2, dash='4 3')
    f.text(574, 182, T('creates', 'cria'), size=9, fill='--paper-dim', italic=True)
    f.isa([(655, 170), (655, 40 + hp)], dash='4 3')
    f.text(470, 250, T('46 lines, 6 classes, 1 function', '46 linhas, 6 classes, 1 função'),
           size=10.5, fill='--amber', weight='600')
    return f, T('The same sentence, from one function or from six classes. Every box on the right is a place a reader may have to visit.',
                'A mesma frase, de uma função ou de seis classes. Cada caixa à direita é um lugar que quem lê pode ter de visitar.')


@figure('l19-shapes', 19)
def shapes():
    f = Fig('l19-shapes', 720, 300, T(
        'Three patterns told apart by what a class holds. Left, decorator: CountingCatalogue is a '
        'Catalogue and also holds a Catalogue, so it holds the interface it offers. Middle, '
        'adapter: PartnerCatalogue is a Catalogue and holds a dictionary in the partner\'s format, '
        'so it holds another interface and offers yours. Right, strategy: FineDesk holds a '
        'FinePolicy, which DailyFine and CappedFine implement, so it holds one of a family and '
        'offers an interface of its own.',
        'Três padrões distinguidos pelo que uma classe guarda. À esquerda, decorator: '
        'CountingCatalogue é um Catalogue e também guarda um Catalogue, então guarda a interface que '
        'oferece. No meio, adapter: PartnerCatalogue é um Catalogue e guarda um dicionário no formato '
        'do parceiro, então guarda outra interface e oferece a sua. À direita, strategy: FineDesk '
        'guarda uma FinePolicy, que DailyFine e CappedFine implementam, então guarda um de uma '
        'família e oferece uma interface própria.'))
    for i, title in enumerate([T('decorator', 'decorator'), T('adapter', 'adapter'), T('strategy', 'strategy')]):
        f.text(i * 240 + 120, 14, title, size=11, weight='600')
    for x in (240, 480):
        f.line(x, 8, x, 292, stroke='--wire', width=1, dash='4 4')
    # decorator
    hp = f.klass(60, 34, 120, 'Catalogue', [], ['title()'], stereo='«protocol»')
    f.klass(45, 140, 150, 'CountingCatalogue', ['_inner'], ['title()'])
    f.isa([(90, 140), (90, 34 + hp)])
    f.has([(150, 140), (150, 34 + hp)])
    f.text(84, 118, T('is a', 'é um'), size=9, fill='--paper-dim', italic=True, anchor='end')
    f.text(158, 118, T('has a', 'tem um'), size=9, fill='--paper-dim', italic=True, anchor='start')
    f.text(120, 270, T('holds the interface it offers', 'guarda a interface que oferece'),
           size=10, fill='--amber', weight='600')
    # adapter
    x0 = 240
    hp = f.klass(x0 + 60, 34, 120, 'Catalogue', [], ['title()'], stereo='«protocol»')
    hh = f.klass(x0 + 45, 140, 150, 'PartnerCatalogue', ['_records'], ['title()'])
    f.isa([(x0 + 120, 140), (x0 + 120, 34 + hp)])
    f.box(x0 + 120, 238, 170, 24, [T('a dict in the partner\'s format', 'um dict no formato do parceiro')],
          size=9.5)
    f.has([(x0 + 120, 140 + hh), (x0 + 120, 226)])
    f.text(x0 + 120, 270, T('holds another interface, offers yours', 'guarda outra interface, oferece a sua'),
           size=10, fill='--amber', weight='600')
    # strategy
    x0 = 480
    f.klass(x0 + 5, 34, 90, 'FineDesk', ['policy'], ['charge()'])
    hp = f.klass(x0 + 135, 34, 100, 'FinePolicy', [], ['fine()'], stereo='«protocol»')
    f.has([(x0 + 95, 60), (x0 + 135, 60)])
    f.klass(x0 + 82, 160, 75, 'DailyFine', [], ['fine()'], size=9)
    f.klass(x0 + 163, 160, 75, 'CappedFine', [], ['fine()'], size=9)
    f.isa([(x0 + 120, 160), (x0 + 120, 130), (x0 + 185, 130), (x0 + 185, 34 + hp)])
    f.line(x0 + 200, 160, x0 + 200, 130, stroke='--paper-dim', width=1.3)
    f.line(x0 + 200, 130, x0 + 185, 130, stroke='--paper-dim', width=1.3)
    f.text(x0 + 120, 270, T('holds one of a family, offers its own', 'guarda um de uma família, oferece a sua'),
           size=10, fill='--amber', weight='600')
    return f, T('Decorator, adapter and strategy are all composition. What the class holds, and whether it is the interface the class offers, tells them apart.',
                'Decorator, adapter e strategy são todos composição. O que a classe guarda, e se é a interface que ela oferece, é o que os distingue.')
