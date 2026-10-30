"""Lesson 12: Entra ID and on-premises Active Directory."""
from figures import Fig, T, figure


@figure('l12-sync', 12)
def sync():
    f = Fig('l12-sync', 720, 300, T(
        'The two synchronisation programs side by side. On the left, Connect Sync: in the office '
        'network, a server holds the whole engine and its database, reads Active Directory and writes '
        'to Entra ID. On the right, Cloud Sync: in the office network, two light provisioning agents '
        'answer requests from a provisioning service that runs in Entra ID, which holds the '
        'configuration and the engine. Both copy from Active Directory towards Entra ID.',
        'Os dois programas de sincronização lado a lado. À esquerda, o Connect Sync: na rede do '
        'escritório, um servidor guarda o motor inteiro e o banco de dados dele, lê o Active Directory e '
        'escreve no Entra ID. À direita, o Cloud Sync: na rede do escritório, dois agentes leves de '
        'provisionamento respondem a pedidos de um serviço de provisionamento que roda no Entra ID, que '
        'guarda a configuração e o motor. Os dois copiam do Active Directory para o Entra ID.'))
    for x, title in [(20, 'Connect Sync'), (370, 'Cloud Sync')]:
        f.text(x + 165, 22, title, size=11.5, weight='600')
        f.rect(x, 40, 330, 76, stroke='--phosphor', fill='--ink')
        f.text(x + 14, 56, 'Microsoft Entra ID', size=9.5, anchor='start', fill='--phosphor')
        f.rect(x, 170, 330, 116, stroke='--paper-dim', fill='--ink', dash='5 4')
        f.text(x + 14, 186, T('office network', 'rede do escritório'), size=9.5, anchor='start', fill='--paper-dim')
        f.rect(x + 20, 240, 120, 34, stroke='--wire', fill='--panel')
        f.text(x + 80, 257, 'Active Directory', size=10)
    # Connect Sync: engine on the ground
    f.rect(190, 200, 140, 74, stroke='--amber', fill='--panel')
    f.lines(260, 237, [T('engine', 'motor'), T('and database', 'e banco de dados')], size=10)
    f.arrow([(141, 257), (189, 257)], stroke='--paper-dim')
    f.arrow([(260, 199), (260, 117)], stroke='--amber', width=1.4)
    f.text(180, 88, T('a copy of the directory', 'uma cópia do diretório'), size=10)
    # Cloud Sync: engine in the cloud
    f.rect(540, 64, 150, 40, stroke='--amber', fill='--panel')
    f.lines(615, 84, [T('engine and', 'motor e'), T('configuration', 'configuração')], size=9.5)
    for i, ax in enumerate([540, 620]):
        f.rect(ax, 214, 70, 30, stroke='--wire', fill='--panel')
        f.text(ax + 35, 229, T('agent', 'agente'), size=9.5)
        f.arrow([(ax + 35, 213), (ax + 35, 117)], stroke='--amber', width=1.4)
    f.arrow([(491, 257), (560, 257), (560, 245)], stroke='--paper-dim')
    f.text(455, 88, T('a copy of the directory', 'uma cópia do diretório'), size=10)
    return f, T('The same copy, made by a whole engine on the ground or by agents answering one in the cloud.',
                'A mesma cópia, feita por um motor inteiro no chão ou por agentes respondendo a um na nuvem.')


@figure('l12-methods', 12)
def methods():
    f = Fig('l12-methods', 720, 250, T(
        'Who checks the password in each of the three sign-in methods. With password hash '
        'synchronisation, Entra ID checks it against a hash it was sent. With pass-through '
        'authentication, Entra ID passes it to an agent in the office, which asks Active Directory. With '
        'federation, Entra ID sends the person to the company\'s own federation server, which checks it '
        'and sends them back with a signed statement.',
        'Quem confere a senha em cada um dos três métodos de login. Com a sincronização de hash de senha, '
        'o Entra ID a confere contra um hash que recebeu. Com a autenticação de passagem, o Entra ID a '
        'passa a um agente no escritório, que pergunta ao Active Directory. Com a federação, o Entra ID '
        'manda a pessoa ao servidor de federação da própria empresa, que confere e a manda de volta com '
        'uma declaração assinada.'))
    rows = [(T('password hash sync', 'sincronização de hash'), T('Entra ID, against a synchronised hash', 'o Entra ID, contra um hash sincronizado'), False),
            (T('pass-through', 'autenticação de passagem'), T('an agent in the office, asking Active Directory', 'um agente no escritório, perguntando ao Active Directory'), True),
            (T('federation', 'federação'), T('the company\'s federation server', 'o servidor de federação da empresa'), True)]
    f.text(130, 26, T('method', 'método'), size=10, weight='600', fill='--paper-dim')
    f.text(450, 26, T('who checks the password', 'quem confere a senha'), size=10, weight='600', fill='--paper-dim')
    f.text(660, 26, T('needs the office', 'precisa do escritório'), size=10, weight='600', fill='--paper-dim')
    for i, (m, who, ground) in enumerate(rows):
        y = 70 + i * 58
        f.rect(30, y - 20, 200, 40, stroke='--wire', fill='--panel')
        f.text(130, y, m, size=10.5)
        f.arrow([(231, y), (269, y)], stroke='--paper-dim')
        f.rect(270, y - 20, 360, 40, stroke='--amber' if ground else '--phosphor', fill='--panel')
        f.text(450, y, who, size=10)
        f.text(660, y, T('yes', 'sim') if ground else T('no', 'não'), size=10.5, weight='600')
    return f, T('The further the check sits from the cloud, the more the office must be up for anybody to sign in.',
                'Quanto mais longe da nuvem fica a conferência, mais o escritório precisa estar no ar para alguém entrar.')
