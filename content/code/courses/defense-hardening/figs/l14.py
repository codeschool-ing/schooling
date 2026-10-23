"""Lesson 14: DNS sinkholes and reputation-based blocking."""
from figures import Fig, T, figure


def box(f, x, y, w, h, name, sub=None, stroke='--wire'):
    f.rect(x, y, w, h, stroke=stroke, fill='--panel', width=1.5, rx=3)
    f.text(x + w / 2, y + (h / 2 if not sub else h / 2 - 8), name, size=11, mono=True, weight='600')
    if sub:
        f.text(x + w / 2, y + h / 2 + 10, sub, size=9.5, fill='--paper-dim')


@figure('l14-chokepoint', 14)
def chokepoint():
    f = Fig('l14-chokepoint', 720, 280, T(
        'Two drawings of the same office. Above, before the lesson: desk, web and a laptop each send '
        'their name questions straight to resolvers outside the firm, and the firm sees none of them. '
        'Below, after: every machine asks dns, the firm\'s resolver, which keeps a log and forwards '
        'what it cannot answer to the internet.',
        'Dois desenhos do mesmo escritório. Em cima, antes da aula: desk, web e um notebook mandam '
        'cada um as suas perguntas de nome direto para resolvedores fora do escritório, e o '
        'escritório não vê nenhuma. Embaixo, depois: toda máquina pergunta ao dns, o resolvedor do '
        'escritório, que guarda um log e encaminha para a internet o que não sabe responder.'))
    f.text(20, 20, T('before: each machine asks whoever it was told to', 'antes: cada máquina pergunta a quem mandaram'),
           size=10.5, anchor='start', weight='600', fill='--paper-dim')
    for i, n in enumerate(['desk', 'web', T('laptop', 'notebook')]):
        box(f, 30 + i * 130, 40, 110, 34, n)
        f.line(85 + i * 130, 74, 560, 95, stroke='--amber', width=1.2, arrow=True)
    box(f, 560, 76, 140, 38, T('the internet', 'a internet'), stroke='--paper-dim')
    f.text(20, 152, T('after: one resolver, one log', 'depois: um resolvedor, um log'),
           size=10.5, anchor='start', weight='600', fill='--paper-dim')
    for i, n in enumerate(['desk', 'web', T('laptop', 'notebook')]):
        box(f, 30 + i * 130, 172, 110, 34, n)
        f.line(85 + i * 130, 206, 425 + i * 30, 222, stroke='--phosphor', width=1.2, arrow=True)
    box(f, 400, 222, 120, 44, 'dns', T('logs every question', 'registra cada pergunta'), stroke='--phosphor')
    box(f, 560, 224, 140, 38, T('the internet', 'a internet'), stroke='--paper-dim')
    f.line(520, 243, 560, 243, stroke='--paper-dim', width=1.2, arrow=True)
    return f, T('A resolver of your own is the one place every outbound conversation passes before it starts.',
                'Um resolvedor próprio é o único lugar por onde toda conversa de saída passa antes de começar.')


@figure('l14-rpz', 14)
def rpz():
    f = Fig('l14-rpz', 720, 250, T(
        'Three questions from desk reach dns and leave with three different answers. web.jatoba.example '
        'is not on the list and gets its real address, 192.168.60.10. boletos-jatoba.example.net '
        'matches an entry written CNAME dot and gets NXDOMAIN. pagamento.cobranca-urgente.example.org '
        'matches a wildcard entry with an address and gets 192.168.60.53, the sinkhole.',
        'Três perguntas do desk chegam ao dns e saem com três respostas diferentes. '
        'web.jatoba.example não está na lista e recebe o endereço verdadeiro, 192.168.60.10. '
        'boletos-jatoba.example.net bate numa entrada escrita CNAME ponto e recebe NXDOMAIN. '
        'pagamento.cobranca-urgente.example.org bate numa entrada curinga com endereço e recebe '
        '192.168.60.53, o sinkhole.'))
    box(f, 290, 90, 140, 70, 'dns', T('reads feed.zone', 'lê o feed.zone'), stroke='--phosphor')
    rows = [('web.jatoba.example', T('not listed', 'fora da lista'), '192.168.60.10', '--phosphor'),
            ('boletos-jatoba.example.net', 'CNAME .', 'NXDOMAIN', '--amber'),
            ('pagamento.cobranca-urgente…', 'A 192.168.60.53', '192.168.60.53', '--amber')]
    for i, (q, rule, ans, c) in enumerate(rows):
        y = 50 + i * 60
        f.text(20, y, q, size=10, anchor='start', mono=True)
        f.line(220, y, 290, 125, stroke='--paper-dim', width=1.1, arrow=True)
        f.line(430, 125, 520, y, stroke=c, width=1.2, arrow=True)
        f.text(530, y - 8, rule, size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.text(530, y + 8, ans, size=10.5, anchor='start', mono=True, fill=c)
    f.text(360, 230, T('the question is the same; the list decides the answer',
                       'a pergunta é a mesma; a lista decide a resposta'), size=10, fill='--paper-dim')
    return f, T('A policy zone changes only the names it lists, and says why each time.',
                'Uma zona de política muda só os nomes que lista, e diz por quê a cada vez.')


@figure('l14-sinkhole', 14)
def sinkhole():
    f = Fig('l14-sinkhole', 720, 240, T(
        'The path of one download. One: desk asks dns for pagamento.cobranca-urgente.example.org. Two: '
        'dns answers 192.168.60.53, its own address, instead of the real one. Three: desk connects '
        'there and asks for /boleto.pdf. Four: the sinkhole answers with a page saying the site is '
        'blocked and writes a log line with the time, desk\'s address, the name and the path. The '
        'real site, drawn dashed, is never reached.',
        'O caminho de um download. Um: o desk pergunta ao dns por pagamento.cobranca-urgente.example.org. '
        'Dois: o dns responde 192.168.60.53, o próprio endereço, em vez do verdadeiro. Três: o desk '
        'conecta ali e pede /boleto.pdf. Quatro: o sinkhole responde com uma página dizendo que o '
        'site está bloqueado e grava uma linha de log com a hora, o endereço do desk, o nome e o '
        'caminho. O site verdadeiro, tracejado, nunca é alcançado.'))
    box(f, 30, 90, 110, 50, 'desk', '192.168.60.20')
    f.rect(300, 40, 200, 150, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(400, 58, 'dns  192.168.60.53', size=11, mono=True, weight='600')
    f.rect(315, 75, 170, 36, stroke='--wire', fill='--scan', width=1.1, rx=2)
    f.text(400, 93, T('unbound, with the list', 'unbound, com a lista'), size=10)
    f.rect(315, 125, 170, 50, stroke='--amber', fill='--scan', width=1.1, rx=2)
    f.text(400, 142, T('sinkhole on port 80', 'sinkhole na porta 80'), size=10)
    f.text(400, 160, T('logs who, which name, which path', 'registra quem, que nome, que caminho'), size=9.5,
           fill='--paper-dim')
    f.line(140, 100, 315, 90, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(225, 82, T('1 the name?', '1 o nome?'), size=9.5, fill='--paper-dim')
    f.line(315, 100, 140, 112, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(225, 118, T('2 it is .53', '2 é o .53'), size=9.5, fill='--paper-dim')
    f.line(140, 128, 315, 150, stroke='--amber', width=1.2, arrow=True)
    f.text(225, 160, T('3 GET /boleto.pdf', '3 GET /boleto.pdf'), size=9.5, fill='--amber')
    f.rect(570, 80, 130, 60, stroke='--paper-dim', fill='--panel', width=1.2, rx=3, dash='5 3')
    f.text(635, 104, T('the real site', 'o site verdadeiro'), size=10, fill='--paper-dim')
    f.text(635, 122, T('never reached', 'nunca alcançado'), size=9.5, fill='--paper-dim')
    f.text(400, 220, T('4 a page for the person, a log line for the defender',
                       '4 uma página para a pessoa, uma linha de log para quem defende'), size=10, fill='--amber')
    return f, T('The resolver changed one answer; the sinkhole turned the visit into a finding.',
                'O resolvedor mudou uma resposta; o sinkhole transformou a visita num achado.')
