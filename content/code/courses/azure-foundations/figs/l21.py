"""Lesson 21: Azure DNS: public zones, private zones and records."""
from figures import Fig, T, figure


@figure('l21-delegation', 21)
def delegation():
    f = Fig('l21-delegation', 720, 300, T(
        'How a question for shop.example reaches Azure DNS. A resolver asks the root, which refers it '
        'to the servers of .example. Those hold the delegation the registrar wrote: four NS records '
        'naming ns1-01.azure-dns.com, ns2-01.azure-dns.net, ns3-01.azure-dns.org and '
        'ns4-01.azure-dns.info. The resolver asks one of them, and the zone shop.example in Azure DNS '
        'answers with its records. The name server numbers are an example.',
        'Como uma pergunta sobre shop.example chega ao Azure DNS. Um resolvedor pergunta à raiz, que o '
        'encaminha aos servidores de .example. Esses guardam a delegação que o registrador escreveu: '
        'quatro registros NS citando ns1-01.azure-dns.com, ns2-01.azure-dns.net, ns3-01.azure-dns.org e '
        'ns4-01.azure-dns.info. O resolvedor pergunta a um deles, e a zona shop.example no Azure DNS '
        'responde com os seus registros. Os números dos servidores de nomes são um exemplo.'))
    f.rect(20, 110, 130, 60, stroke='--paper-dim', fill='--panel')
    f.text(85, 132, T('resolver', 'resolvedor'), size=10.5)
    f.text(85, 152, T('asks on your behalf', 'pergunta por você'), size=9, fill='--paper-dim')
    f.rect(230, 20, 160, 50, stroke='--wire', fill='--scan')
    f.text(310, 45, T('the root', 'a raiz'), size=10.5)
    f.rect(230, 115, 160, 50, stroke='--wire', fill='--scan')
    f.text(310, 132, '.example', size=10.5, mono=True)
    f.text(310, 150, T('holds the delegation', 'guarda a delegação'), size=9, fill='--paper-dim')
    f.rect(470, 20, 230, 260, stroke='--phosphor', fill='--ink')
    f.text(585, 40, 'Azure DNS', size=10.5, weight='600', fill='--phosphor')
    for i, ns in enumerate(['ns1-01.azure-dns.com', 'ns2-01.azure-dns.net', 'ns3-01.azure-dns.org',
                            'ns4-01.azure-dns.info']):
        f.text(585, 64 + i * 18, ns, size=9.5, mono=True)
    f.rect(495, 150, 180, 112, stroke='--amber', fill='--panel')
    f.text(585, 168, T('zone', 'zona'), size=9, fill='--paper-dim')
    f.text(585, 186, 'shop.example', size=10.5, mono=True)
    f.text(585, 210, '@  A  (alias)', size=9.5, mono=True, fill='--paper-dim')
    f.text(585, 228, 'www  CNAME', size=9.5, mono=True, fill='--paper-dim')
    f.text(585, 246, '@  MX  10', size=9.5, mono=True, fill='--paper-dim')
    f.arrow([(151, 120), (229, 52)], stroke='--paper-dim')
    f.text(176, 76, '1', size=10, weight='600')
    f.arrow([(151, 140), (229, 140)], stroke='--paper-dim')
    f.text(190, 130, '2', size=10, weight='600')
    f.arrow([(151, 160), (300, 215), (494, 205)], stroke='--phosphor', width=1.4)
    f.text(300, 232, T('3  ask a server the delegation named', '3  pergunta a um servidor da delegação'),
           size=9.5, fill='--phosphor')
    f.arrow([(391, 140), (469, 100)], stroke='--amber', dash='5 4')
    f.text(400, 98, 'NS', size=9.5, mono=True, fill='--amber')
    return f, T('Written at the registrar, the four NS records send every resolver to Azure.',
                'Escritos no registrador, os quatro registros NS mandam todo resolvedor ao Azure.')


@figure('l21-resolver', 21)
def resolver():
    f = Fig('l21-resolver', 720, 280, T(
        'The office asking Azure\'s private names. A laptop in the office asks the office DNS server. '
        'A conditional forwarder sends questions for shop.internal and for the privatelink zones over '
        'the VPN to the Private Resolver\'s inbound endpoint in the hub, which answers from Azure\'s '
        'resolver and the linked private zones. In the other direction, the outbound endpoint and a '
        'forwarding ruleset send questions for corp.shop.example to the office DNS server.',
        'O escritório perguntando os nomes privados do Azure. Um notebook no escritório pergunta ao '
        'servidor DNS do escritório. Um encaminhador condicional manda as perguntas sobre shop.internal e '
        'sobre as zonas privatelink pela VPN até o inbound endpoint do Private Resolver no hub, que '
        'responde com o resolvedor do Azure e as zonas privadas ligadas. No sentido contrário, o outbound '
        'endpoint e um conjunto de regras de encaminhamento mandam as perguntas sobre corp.shop.example '
        'para o servidor DNS do escritório.'))
    f.path('M20 30 H250 V250 H20 Z', stroke='--paper-dim', dash='5 4')
    f.text(36, 48, T('the office', 'o escritório'), size=10, anchor='start')
    f.text(234, 48, '192.168.0.0/16', size=9.5, anchor='end', mono=True, fill='--paper-dim')
    f.rect(45, 70, 120, 40, stroke='--wire', fill='--panel')
    f.text(105, 90, T('laptop', 'notebook'), size=10)
    f.rect(45, 160, 180, 60, stroke='--wire', fill='--panel')
    f.text(135, 178, T('office DNS server', 'servidor DNS do escritório'), size=9.5)
    f.text(135, 200, '192.168.1.10', size=9.5, mono=True, fill='--paper-dim')
    f.arrow([(105, 111), (105, 159)], stroke='--paper-dim')
    f.path('M440 30 H700 V250 H440 Z', stroke='--phosphor')
    f.text(456, 48, 'vnet-shop-hub', size=10, anchor='start', mono=True)
    f.rect(465, 70, 210, 50, stroke='--phosphor', fill='--scan')
    f.text(570, 88, T('inbound endpoint', 'inbound endpoint'), size=9.5)
    f.text(570, 106, 'Private Resolver', size=9.5, fill='--paper-dim')
    f.rect(465, 140, 210, 40, stroke='--wire', fill='--panel')
    f.text(570, 160, T('private zones, linked', 'zonas privadas, ligadas'), size=9.5)
    f.rect(465, 195, 210, 45, stroke='--amber', fill='--scan')
    f.text(570, 211, T('outbound endpoint', 'outbound endpoint'), size=9.5)
    f.text(570, 228, T('and its ruleset', 'e as suas regras'), size=9, fill='--paper-dim')
    f.arrow([(226, 175), (340, 120), (464, 95)], stroke='--phosphor', width=1.4)
    f.text(320, 92, 'shop.internal', size=9.5, mono=True, fill='--phosphor')
    f.text(320, 108, T('privatelink zones', 'zonas privatelink'), size=9, fill='--phosphor')
    f.arrow([(570, 121), (570, 139)], stroke='--paper-dim', start=True)
    f.arrow([(464, 218), (340, 230), (226, 205)], stroke='--amber', width=1.4)
    f.text(340, 246, 'corp.shop.example', size=9.5, mono=True, fill='--amber')
    return f, T('Each side forwards the other the names only it knows, over the VPN.',
                'Cada lado encaminha ao outro os nomes que só ele conhece, pela VPN.')
