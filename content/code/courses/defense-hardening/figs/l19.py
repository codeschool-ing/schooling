"""Lesson 19: file and URL analysis."""
from figures import Fig, T, figure


def box(f, x, y, w, h, a, b=None, c='--wire'):
    f.rect(x, y, w, h, stroke=c, fill='--panel', width=1.5, rx=3)
    f.text(x + w / 2, y + h / 2 - (8 if b else 0), a, size=10.5, weight='600')
    if b:
        f.text(x + w / 2, y + h / 2 + 10, b, size=9.5, fill='--paper-dim')


@figure('l19-triage', 19)
def triage():
    f = Fig('l19-triage', 720, 280, T(
        'The order of triage. One: look locally, with file, a hash, strings and a YARA rule, which sends '
        'nothing anywhere. Two: search the hash on an online service, which reveals nothing about the '
        'content. If a report exists, read it and stop. If not, three: ask whether the file is the '
        'firm\'s or carries a client\'s data. If yes, analyse it privately, in your own sandbox or a paid '
        'private service. If no, it may be uploaded. Four, in every case: write down the hash, where you '
        'looked, what it said and when.',
        'A ordem da triagem. Um: olhar localmente, com file, um hash, strings e uma regra YARA, o que não '
        'manda nada a lugar nenhum. Dois: buscar o hash num serviço online, o que não revela nada do '
        'conteúdo. Se existe relatório, ler e parar. Se não, três: perguntar se o arquivo é do escritório '
        'ou traz dados de cliente. Se sim, analisar em privado, no seu próprio sandbox ou num serviço '
        'privado pago. Se não, pode ser enviado. Quatro, em todo caso: anotar o hash, onde olhou, o que '
        'disse e quando.'))
    box(f, 20, 30, 150, 50, T('1 look locally', '1 olhar localmente'), T('file, hash, strings, YARA', 'file, hash, strings, YARA'),
        c='--phosphor')
    box(f, 210, 30, 150, 50, T('2 search the hash', '2 buscar o hash'), T('reveals nothing', 'não revela nada'), c='--phosphor')
    f.line(170, 55, 210, 55, stroke='--paper-dim', width=1.3, arrow=True)
    box(f, 400, 30, 140, 50, T('report found', 'relatório achado'), T('read it, stop', 'ler, parar'))
    f.line(360, 55, 400, 55, stroke='--paper-dim', width=1.3, arrow=True)
    box(f, 210, 130, 150, 56, T('3 the firm’s file?', '3 é do escritório?'), T('or a client’s data?', 'ou dado de cliente?'),
        c='--amber')
    f.line(285, 80, 285, 130, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(292, 106, T('nothing found', 'nada achado'), size=9.5, anchor='start', fill='--paper-dim')
    box(f, 20, 140, 150, 50, T('private analysis', 'análise privada'), T('lesson 12, or paid', 'aula 12, ou paga'))
    f.line(210, 160, 170, 162, stroke='--amber', width=1.3, arrow=True)
    f.text(190, 148, T('yes', 'sim'), size=9.5, fill='--amber')
    box(f, 400, 140, 140, 50, T('may be uploaded', 'pode ser enviado'), T('public service', 'serviço público'))
    f.line(360, 160, 400, 162, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(380, 148, T('no', 'não'), size=9.5, fill='--paper-dim')
    box(f, 160, 225, 400, 40, T('4 write down: hash, where, what it said, when', '4 anotar: hash, onde, o que disse, quando'))
    return f, T('The upload is the last step and the optional one, never the first.',
                'O envio é o último passo e o opcional, nunca o primeiro.')


@figure('l19-indicators', 19)
def indicators():
    f = Fig('l19-indicators', 720, 250, T(
        'One suspicious file on the left becomes four kinds of indicator in the middle: a hash, a domain, '
        'an address and a technique. Each goes to a control of an earlier lesson on the right: the hash to '
        'antivirus signatures in lesson 7 and hunting in lesson 8, the domain to the resolver\'s blocklist '
        'in lesson 14, the address to firewall rules in lesson 10, the technique to detection rules in '
        'lesson 8.',
        'Um arquivo suspeito à esquerda vira quatro tipos de indicador no meio: um hash, um domínio, um '
        'endereço e uma técnica. Cada um vai para um controle de uma aula anterior à direita: o hash para '
        'as assinaturas de antivírus da aula 7 e a caça da aula 8, o domínio para a lista de bloqueio do '
        'resolvedor da aula 14, o endereço para as regras de firewall da aula 10, a técnica para as regras '
        'de detecção da aula 8.'))
    box(f, 20, 100, 140, 50, T('one file', 'um arquivo'), 'fatura-outubro.pdf', c='--amber')
    rows = [(T('hash', 'hash'), T('signatures, lesson 7; hunting, lesson 8', 'assinaturas, aula 7; caça, aula 8')),
            (T('domain', 'domínio'), T('resolver blocklist, lesson 14', 'lista do resolvedor, aula 14')),
            (T('address', 'endereço'), T('outbound rules, lesson 10', 'regras de saída, aula 10')),
            (T('technique', 'técnica'), T('detection rules, lesson 8', 'regras de detecção, aula 8'))]
    for i, (a, b) in enumerate(rows):
        y = 30 + i * 55
        box(f, 260, y, 120, 36, a, c='--phosphor')
        f.line(160, 125, 260, y + 18, stroke='--paper-dim', width=1.1, arrow=True)
        f.line(380, y + 18, 440, y + 18, stroke='--phosphor', width=1.2, arrow=True)
        f.text(448, y + 18, b, size=10, anchor='start')
    return f, T('Analysis is worth what it feeds into the controls.',
                'A análise vale o que ela alimenta nos controles.')
