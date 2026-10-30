"""Lesson 19: Private Link, private endpoints and service endpoints."""
from figures import Fig, T, figure


@figure('l19-three-roads', 19)
def three_roads():
    f = Fig('l19-three-roads', 720, 340, T(
        'Three roads from the application in snet-app to the storage account stshopprod. On the left, '
        'the virtual network vnet-shop-prod holds snet-app and snet-pe. On the right, on Microsoft\'s '
        'side of the line, the storage account has a public endpoint. The public road leaves the '
        'network for the public endpoint, which is open to the internet. The service endpoint road '
        'reaches the same public endpoint over the backbone, carrying the subnet\'s identity. The '
        'private endpoint road goes to a network interface at 10.20.4.4 inside snet-pe, which Private '
        'Link connects to the account, and the public endpoint can be switched off.',
        'Três caminhos da aplicação em snet-app até a storage account stshopprod. À esquerda, a rede '
        'virtual vnet-shop-prod guarda snet-app e snet-pe. À direita, do lado da Microsoft, a storage '
        'account tem um endpoint público. O caminho público sai da rede para o endpoint público, que '
        'está aberto à internet. O caminho do service endpoint chega ao mesmo endpoint público pelo '
        'backbone, levando a identidade da sub-rede. O caminho do private endpoint vai até uma interface '
        'de rede em 10.20.4.4 dentro de snet-pe, que o Private Link liga à conta, e o endpoint público '
        'pode ser desligado.'))
    # the network and its subnets are outlines, so the roads can be seen leaving them
    f.path('M20 30 H350 V320 H20 Z', stroke='--wire')
    f.text(36, 48, T('virtual network', 'rede virtual'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(334, 48, 'vnet-shop-prod', size=10, anchor='end', mono=True)
    f.path('M40 66 H190 V216 H40 Z', stroke='--wire')
    f.text(115, 84, 'snet-app', size=10, mono=True)
    f.rect(65, 104, 100, 30, stroke='--paper-dim', fill='--scan')
    f.text(115, 119, T('application', 'aplicação'), size=9.5)
    f.path('M40 236 H330 V306 H40 Z', stroke='--wire')
    f.text(56, 252, 'snet-pe', size=10, anchor='start', mono=True)
    f.rect(200, 248, 116, 44, stroke='--phosphor', fill='--scan')
    f.text(258, 262, T('private endpoint', 'private endpoint'), size=9)
    f.text(258, 280, '10.20.4.4', size=10, mono=True)
    # Microsoft side
    f.line(400, 20, 400, 330, stroke='--paper-dim', dash='5 4')
    f.text(560, 30, T('Microsoft\'s side', 'o lado da Microsoft'), size=9.5, fill='--paper-dim')
    f.rect(450, 120, 230, 120, stroke='--amber', fill='--panel')
    f.text(565, 138, 'stshopprod', size=10.5, mono=True)
    f.rect(470, 154, 190, 34, stroke='--paper-dim', fill='--scan')
    f.text(565, 171, T('public endpoint', 'endpoint público'), size=9.5)
    f.rect(470, 198, 190, 32, stroke='--phosphor', fill='--scan')
    f.text(565, 214, 'Private Link', size=9.5)
    # roads
    f.arrow([(166, 112), (300, 70), (560, 70), (560, 119)], stroke='--amber', width=1.4)
    f.text(430, 56, T('1  the public road', '1  o caminho público'), size=9.5, anchor='start', fill='--amber')
    f.arrow([(166, 126), (360, 150), (469, 168)], stroke='--paper', width=1.4, dash='6 3')
    f.text(212, 166, T('2  service endpoint', '2  service endpoint'), size=9.5, anchor='start')
    f.arrow([(115, 135), (115, 225), (190, 225), (199, 262)], stroke='--phosphor', width=1.4)
    f.text(56, 180, T('3  private', '3  private'), size=9.5, anchor='start', fill='--phosphor')
    f.text(56, 196, T('endpoint', 'endpoint'), size=9.5, anchor='start', fill='--phosphor')
    f.arrow([(317, 270), (420, 270), (420, 214), (469, 214)], stroke='--phosphor', width=1.4)
    f.text(565, 300, T('internet', 'internet'), size=9.5, fill='--paper-dim')
    f.arrow([(565, 288), (565, 241)], stroke='--paper-dim', width=1.2, dash='3 3')
    return f, T('Roads 1 and 2 end at the same public endpoint. Only road 3 lets it be closed.',
                'Os caminhos 1 e 2 terminam no mesmo endpoint público. Só o 3 permite fechá-lo.')


@figure('l19-dns-split', 19)
def dns_split():
    f = Fig('l19-dns-split', 720, 300, T(
        'The same name resolved from two places. The chain starts at stshopprod.blob.core.windows.net, '
        'a CNAME to stshopprod.privatelink.blob.core.windows.net. Asked from the internet, the public '
        'DNS answers the intermediate name with a further CNAME that ends at the public address of the '
        'storage service. Asked from inside vnet-shop-prod, Azure\'s resolver at 168.63.129.16 finds the '
        'linked private zone privatelink.blob.core.windows.net and answers the intermediate name with '
        'the A record 10.20.4.4.',
        'O mesmo nome resolvido de dois lugares. A cadeia começa em stshopprod.blob.core.windows.net, '
        'um CNAME para stshopprod.privatelink.blob.core.windows.net. Perguntado da internet, o DNS '
        'público responde o nome intermediário com mais um CNAME que termina no endereço público do '
        'serviço de storage. Perguntado de dentro da vnet-shop-prod, o resolvedor do Azure em '
        '168.63.129.16 encontra a zona privada ligada privatelink.blob.core.windows.net e responde o nome '
        'intermediário com o registro A 10.20.4.4.'))
    f.rect(210, 20, 300, 34, stroke='--wire', fill='--panel')
    f.text(360, 37, 'stshopprod.blob.core.windows.net', size=10.5, mono=True)
    f.arrow([(360, 55), (360, 86)], stroke='--paper-dim')
    f.text(372, 72, 'CNAME', size=9, anchor='start', mono=True, fill='--paper-dim')
    f.rect(160, 88, 400, 34, stroke='--phosphor', fill='--panel')
    f.text(360, 105, 'stshopprod.privatelink.blob.core.windows.net', size=10.5, mono=True)
    # left: internet
    f.arrow([(250, 123), (160, 180)], stroke='--amber')
    f.rect(20, 182, 280, 96, stroke='--amber', fill='--ink')
    f.text(160, 200, T('asked from the internet', 'perguntado da internet'), size=10, weight='600')
    f.text(160, 222, T('the public DNS answers the middle link', 'o DNS público responde o elo do meio'), size=9.5, fill='--paper-dim')
    f.text(160, 244, T('CNAME onwards to the public endpoint', 'CNAME adiante até o endpoint público'), size=9.5, fill='--paper-dim')
    f.text(160, 264, T('a public address', 'um endereço público'), size=10, fill='--amber')
    # right: inside the vnet
    f.arrow([(470, 123), (560, 180)], stroke='--phosphor')
    f.rect(420, 182, 280, 96, stroke='--phosphor', fill='--ink')
    f.text(560, 200, T('asked from vnet-shop-prod', 'perguntado da vnet-shop-prod'), size=10, weight='600')
    f.text(560, 222, T('168.63.129.16 has a linked private zone', '168.63.129.16 tem uma zona privada ligada'), size=9.5, fill='--paper-dim')
    f.text(560, 244, 'A  10.20.4.4', size=10.5, mono=True)
    f.text(560, 264, T('the private endpoint', 'o private endpoint'), size=10, fill='--phosphor')
    return f, T('The private zone takes over the middle link, not the account\'s name.',
                'A zona privada assume o elo do meio, não o nome da conta.')
