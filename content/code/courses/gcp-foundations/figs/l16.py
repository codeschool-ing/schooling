"""Lesson 16: firewall rules."""
from figures import Fig, T, figure


@figure('l16-order', 16)
def order():
    f = Fig('l16-order', 720, 290, T(
        'One packet, SSH from 35.235.240.7 to a web machine tagged frozen, checked against the planner\'s '
        'rules in the order Google reads them. The rules are listed from the lowest priority number down: '
        'deny-ssh-to-frozen at 900, then allow-health-checks, allow-ssh-from-iap and allow-web-to-db at '
        '1000, then the implied deny ingress at 65535. The packet matches the first rule, at 900, and is '
        'denied; the rules below it are never read, including allow-ssh-from-iap, which would also have '
        'matched.',
        'Um pacote, SSH de 35.235.240.7 para uma máquina web com a tag frozen, conferido contra as regras do '
        'planner na ordem em que o Google as lê. As regras estão listadas do menor número de prioridade para '
        'baixo: deny-ssh-to-frozen em 900, depois allow-health-checks, allow-ssh-from-iap e allow-web-to-db '
        'em 1000, depois o deny implícito de entrada em 65535. O pacote casa com a primeira regra, em 900, e '
        'é negado; as regras abaixo dela nunca são lidas, inclusive a allow-ssh-from-iap, que também teria '
        'casado.'))
    f.rect(20, 110, 190, 60, stroke='--amber', fill='--panel', width=1.6)
    f.text(115, 128, T('one packet', 'um pacote'), size=9.5, fill='--paper-dim')
    f.text(115, 146, '35.235.240.7 → :22', size=9.5, mono=True)
    f.text(115, 162, 'web, tag frozen', size=9, mono=True, fill='--paper-dim')
    rows = [('900', 'deny-ssh-to-frozen', 'deny', T('matches: decides', 'casa: decide'), '--amber'),
            ('1000', 'allow-health-checks', 'allow', T('not read', 'não lida'), '--paper-dim'),
            ('1000', 'allow-ssh-from-iap', 'allow', T('would match; not read', 'casaria; não lida'), '--paper-dim'),
            ('1000', 'allow-web-to-db', 'allow', T('not read', 'não lida'), '--paper-dim'),
            ('65535', 'implied deny ingress', 'deny', T('not read', 'não lida'), '--paper-dim')]
    for i, (prio, name, action, note, colour) in enumerate(rows):
        y = 30 + i * 46
        first = i == 0
        f.rect(280, y, 420, 36, stroke='--amber' if first else '--wire', fill='--scan' if first else '--panel',
               width=1.6 if first else 1.2, dash=None if first else '4 3')
        f.text(320, y + 18, prio, size=10, mono=True)
        f.text(360, y + 18, name, size=10, mono=True, anchor='start')
        f.text(540, y + 18, action, size=9.5, mono=True, anchor='start', fill=colour)
        f.text(690, y + 18, note, size=9, anchor='end', fill=colour)
    f.arrow([(212, 130), (276, 50)], stroke='--amber', width=1.6)
    f.text(360, 278, T('lowest number first; at a tie, deny first; the first match decides',
                       'menor número primeiro; no empate, deny primeiro; a primeira que casa decide'),
           size=10)
    return f, T('The first rule that matches decides, and nothing below it is read.',
                'A primeira regra que casa decide, e nada abaixo dela é lido.')
