"""Lesson 8: where a subnet's routes come from, and how a private one goes public."""
from figures import Fig, T, figure


@figure('l08-routes', 8)
def routes():
    f = Fig('l08-routes', 720, 400, T(
        'The clinic\'s VPC, 10.20.0.0/16, with an internet gateway on its edge. The web subnet, '
        '10.20.1.0/24, is associated with its own route table, which sends 0.0.0.0/0 to the internet '
        'gateway: it is public. The records subnet, 10.20.2.0/24, has no table of its own, so it '
        'follows the VPC\'s main table, which holds only the local route: it is private by '
        'inheritance. A single route added to the main table, 0.0.0.0/0 to the internet gateway, '
        'reaches every subnet that follows it, the records subnet included.',
        'A VPC da clínica, 10.20.0.0/16, com um internet gateway na borda. A sub-rede web, '
        '10.20.1.0/24, está associada à sua própria tabela de rotas, que manda 0.0.0.0/0 para o '
        'internet gateway: é pública. A sub-rede de prontuários, 10.20.2.0/24, não tem tabela própria, '
        'então segue a tabela principal da VPC, que só tem a rota local: é privada por herança. Uma '
        'única rota acrescentada à tabela principal, 0.0.0.0/0 para o internet gateway, alcança toda '
        'sub-rede que a segue, a de prontuários inclusive.'))
    # the internet and the gateway
    f.text(360, 20, T('the internet', 'a internet'), size=11, weight='600', fill='--paper-dim')
    f.rect(300, 34, 120, 32, stroke='--paper-dim', fill='--scan')
    f.text(360, 50, T('internet gateway', 'internet gateway'), size=10)
    # the VPC
    f.rect(20, 82, 680, 304, stroke='--phosphor', fill='--panel', dash='6 4')
    f.text(36, 100, 'VPC 10.20.0.0/16', size=10.5, anchor='start', mono=True, fill='--phosphor')
    # web subnet and its table
    f.rect(48, 290, 260, 72, stroke='--amber', fill='--scan', width=1.4)
    f.text(178, 314, T('web subnet', 'sub-rede web'), size=11, weight='600')
    f.text(178, 338, '10.20.1.0/24', size=10, mono=True, fill='--paper-dim')
    f.rect(48, 124, 260, 96, stroke='--paper-dim', fill='--scan')
    f.text(64, 144, T('its own table', 'a tabela própria dela'), size=10.5, anchor='start', weight='600')
    f.text(64, 170, '10.20.0.0/16  local', size=10, anchor='start', mono=True)
    f.text(64, 194, '0.0.0.0/0     igw', size=10, anchor='start', mono=True, fill='--amber')
    f.arrow([(178, 288), (178, 222)], stroke='--paper-dim')
    f.text(186, 256, T('associated', 'associada'), size=9.5, anchor='start', fill='--paper-dim', italic=True)
    f.arrow([(308, 172), (330, 172), (330, 68)], stroke='--amber')
    # records subnet and the main table
    f.rect(412, 290, 260, 72, stroke='--wire', fill='--scan', width=1.4)
    f.text(542, 314, T('records subnet', 'sub-rede de prontuários'), size=11, weight='600')
    f.text(542, 338, '10.20.2.0/24', size=10, mono=True, fill='--paper-dim')
    f.rect(412, 124, 260, 96, stroke='--paper-dim', fill='--scan')
    f.text(428, 144, T('the VPC\'s main table', 'a tabela principal da VPC'), size=10.5, anchor='start', weight='600')
    f.text(428, 170, '10.20.0.0/16  local', size=10, anchor='start', mono=True)
    f.text(428, 194, '+ 0.0.0.0/0   igw', size=10, anchor='start', mono=True, fill='--amber')
    f.text(600, 194, T('caio\'s route', 'a rota do caio'), size=9.5, anchor='start', fill='--amber', italic=True)
    f.arrow([(542, 288), (542, 222)], stroke='--paper-dim', dash='4 3')
    f.lines(550, 248, [T('no table of its own:', 'sem tabela própria:'),
                       T('follows the main one', 'segue a principal')], size=9.5, anchor='start',
            fill='--paper-dim', italic=True)
    f.arrow([(672, 172), (688, 172), (688, 50), (422, 50)], stroke='--amber', dash='4 3')
    return f, T('A subnet\'s privacy is a property of the table it follows. The records subnet was '
                'private only because the main table was, and one route added there for something '
                'else changed it.',
                'A privacidade de uma sub-rede é uma propriedade da tabela que ela segue. A sub-rede de '
                'prontuários era privada só porque a tabela principal era, e uma rota posta ali para '
                'outra coisa a mudou.')
