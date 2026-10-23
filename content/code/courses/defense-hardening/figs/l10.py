"""Lesson 10: host firewall and per-application rules."""
from figures import Fig, T, figure


@figure('l10-lateral', 10)
def lateral():
    f = Fig('l10-lateral', 720, 270, T(
        'Two machines on one segment. On web, two programs: nginx, run by the account www-data, and '
        'the portal, run by the account portal. From desk, connections to nginx on port 80 and to SSH '
        'on web are allowed. From web, the portal\'s attempt to open SSH on desk is refused by the '
        'per-account rule, and any new connection web starts towards desk is dropped by the outbound '
        'allow-list.',
        'Duas máquinas num segmento. No web, dois programas: o nginx, rodado pela conta www-data, e o '
        'portal, rodado pela conta portal. A partir do desk, conexões ao nginx na porta 80 e ao SSH do '
        'web são permitidas. A partir do web, a tentativa do portal de abrir o SSH do desk é recusada '
        'pela regra por conta, e qualquer conexão nova que o web inicie rumo ao desk é descartada pela '
        'lista de saída.'))
    f.rect(30, 50, 230, 190, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(42, 68, 'desk', size=12, anchor='start', mono=True, weight='600')
    f.rect(420, 50, 280, 190, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(432, 68, 'web', size=12, anchor='start', mono=True, weight='600')
    f.rect(470, 90, 200, 40, stroke='--phosphor', fill='--scan', width=1.2, rx=3)
    f.text(570, 104, 'nginx', size=10.5, mono=True)
    f.text(570, 120, T('account www-data', 'conta www-data'), size=9, fill='--paper-dim')
    f.rect(470, 170, 200, 40, stroke='--amber', fill='--scan', width=1.2, rx=3)
    f.text(570, 184, T('portal', 'portal'), size=10.5, mono=True)
    f.text(570, 200, T('account portal', 'conta portal'), size=9, fill='--paper-dim')
    f.line(260, 100, 470, 100, stroke='--phosphor', width=1.4, arrow=True)
    f.text(365, 90, T('port 80, 22: allowed', 'portas 80, 22: permitidas'), size=9.5, fill='--phosphor')
    f.line(470, 190, 260, 190, stroke='--amber', width=1.4, arrow=True, dash='5 3')
    f.text(365, 180, T('portal to desk:22', 'portal para desk:22'), size=9.5, fill='--amber')
    f.text(365, 207, T('refused: rule per account', 'recusado: regra por conta'), size=9, fill='--amber')
    f.text(365, 255, T('anything web starts: dropped by its outbound allow-list',
                       'o que o web iniciar: descartado pela lista de saída'), size=9.5, fill='--paper-dim')
    f.text(360, 24, T('the same segment, filtered on the host', 'o mesmo segmento, filtrado no host'), size=11,
           weight='600', fill='--paper-dim')
    return f, T('Nothing between the two machines filters anything. The rules live on web.',
                'Nada entre as duas máquinas filtra coisa alguma. As regras moram no web.')


@figure('l10-trace', 10)
def trace():
    f = Fig('l10-trace', 720, 260, T(
        'A packet from web to desk port 22 walking down the chain web_egress output, as nft monitor '
        'trace prints it. First the marking rule, meta nftrace set 1, verdict continue. Then the rules '
        'for loopback, established connections and DNS, which it does not match. Then the counter, '
        'verdict continue. At the bottom, the chain policy, drop.',
        'Um pacote do web para a porta 22 do desk descendo a chain web_egress output, como o nft monitor '
        'trace a imprime. Primeiro a regra que marca, meta nftrace set 1, veredito continue. Depois as '
        'regras de loopback, conexões estabelecidas e DNS, com que ele não bate. Depois o contador, '
        'veredito continue. Embaixo, a política da chain, drop.'))
    rows = [('meta nftrace set 1', T('marks it: continue', 'marca: continue'), '--phosphor'),
            ('oif "lo" accept', T('no match', 'não bate'), '--wire'),
            ('ct state established,related accept', T('no match', 'não bate'), '--wire'),
            ('ip daddr 192.168.60.53 udp dport 53 accept', T('no match', 'não bate'), '--wire'),
            ('counter', T('counts it: continue', 'conta: continue'), '--phosphor'),
            ('policy drop', T('the verdict', 'o veredito'), '--amber')]
    for i, (rule, what, c) in enumerate(rows):
        y = 30 + i * 37
        f.rect(140, y, 380, 28, stroke=c, fill='--panel', width=1.3, rx=3)
        f.text(152, y + 14, rule, size=10, anchor='start', mono=True)
        f.text(540, y + 14, what, size=9.5, anchor='start', fill='--paper-dim' if c == '--wire' else c)
    f.arrow([(110, 44), (110, 230)], stroke='--paper-dim', width=1.4)
    f.text(100, 24, T('web to desk:22', 'web para desk:22'), size=9.5, fill='--paper-dim')
    return f, T('The trace names the rule that decided, so nobody has to guess.',
                'O trace diz a regra que decidiu, então ninguém precisa adivinhar.')
