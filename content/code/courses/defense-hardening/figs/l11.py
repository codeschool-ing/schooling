"""Lesson 11: HIPS and host intrusion prevention."""
from figures import Fig, T, figure


@figure('l11-dial', 11)
def dial():
    f = Fig('l11-dial', 720, 230, T(
        'One watch, two settings. On the left, detection: an event goes to a rule, the rule raises an '
        'alert, and a person decides. On the right, prevention: the same event and rule, and the '
        'program acts at once. Under them, a line from uncertain to certain: rules that can be wrong '
        'stay on the left, and only rules that are never wrong move to the right. fail2ban sits on the '
        'right; AIDE on the left.',
        'Uma vigilância, duas posições. À esquerda, detecção: um evento vai para uma regra, a regra gera '
        'um alerta e uma pessoa decide. À direita, prevenção: o mesmo evento e a mesma regra, e o '
        'programa age na hora. Embaixo, uma linha de incerto a certo: regras que podem errar ficam à '
        'esquerda, e só regras que nunca erram vão para a direita. O fail2ban fica à direita; o AIDE, à '
        'esquerda.'))
    for x, title, last, c in ((40, T('detection (HIDS)', 'detecção (HIDS)'), T('a person decides', 'uma pessoa decide'), '--phosphor'),
                              (380, T('prevention (HIPS)', 'prevenção (HIPS)'), T('the program acts', 'o programa age'), '--amber')):
        f.text(x + 150, 26, title, size=11, weight='600', fill='--paper-dim')
        for i, label in enumerate([T('event', 'evento'), T('rule', 'regra'), last]):
            bx = x + i * 105
            f.rect(bx, 45, 90, 36, stroke=c if i == 2 else '--wire', fill='--panel', width=1.3, rx=3)
            f.text(bx + 45, 63, label, size=9.5)
            if i < 2:
                f.line(bx + 90, 63, bx + 105, 63, stroke='--paper-dim', width=1.2, arrow=True)
    f.line(60, 140, 660, 140, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(60, 160, T('the rule can be wrong', 'a regra pode errar'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(660, 160, T('the rule is never wrong', 'a regra nunca erra'), size=9.5, anchor='end', fill='--paper-dim')
    f.circle(190, 140, 6, fill='--phosphor')
    f.text(190, 190, 'AIDE', size=10, mono=True)
    f.text(190, 206, T('a file changed: was it right?', 'um arquivo mudou: estava certo?'), size=9, fill='--paper-dim')
    f.circle(560, 140, 6, fill='--amber')
    f.text(560, 190, 'fail2ban', size=10, mono=True)
    f.text(560, 206, T('three failures in ten minutes', 'três falhas em dez minutos'), size=9, fill='--paper-dim')
    return f, T('Prevention is detection trusted to act alone, and only certain rules earn that.',
                'Prevenção é detecção com permissão de agir sozinha, e só regras certas merecem isso.')


@figure('l11-ban', 11)
def ban():
    f = Fig('l11-ban', 720, 200, T(
        'How fail2ban turns log lines into a ban. sshd writes a line for each failed login to the '
        'journal. fail2ban\'s filter for sshd matches the line and pulls out the address. The jail '
        'counts failures per address within findtime. At maxretry the action adds the address to a set '
        'in nftables, and a rule there rejects it on port 22 for bantime.',
        'Como o fail2ban transforma linhas de log num banimento. O sshd grava no journal uma linha por '
        'login que falhou. O filtro do fail2ban para o sshd casa a linha e tira dela o endereço. A jail '
        'conta as falhas por endereço dentro do findtime. No maxretry, a ação acrescenta o endereço a um '
        'conjunto no nftables, e uma regra ali o recusa na porta 22 durante o bantime.'))
    steps = [('sshd', T('logs each failure', 'registra cada falha')),
             (T('filter', 'filtro'), T('finds the address', 'acha o endereço')),
             ('jail', T('counts per address', 'conta por endereço')),
             (T('action', 'ação'), T('adds it to a set', 'põe num conjunto')),
             ('nftables', T('rejects port 22', 'recusa a porta 22'))]
    for i, (name, what) in enumerate(steps):
        x = 20 + i * 140
        c = '--amber' if i == 4 else '--wire'
        f.rect(x, 60, 120, 56, stroke=c, fill='--panel', width=1.4, rx=3)
        f.text(x + 60, 80, name, size=10.5, weight='600')
        f.text(x + 60, 100, what, size=9, fill='--paper-dim')
        if i < 4:
            f.line(x + 120, 88, x + 140, 88, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(300, 145, 'maxretry = 3, findtime = 10m', size=9.5, mono=True, fill='--paper-dim')
    f.text(580, 145, 'bantime = 10m', size=9.5, mono=True, fill='--paper-dim')
    f.text(360, 28, T('from a log line to a refused connection', 'de uma linha de log a uma conexão recusada'),
           size=11, weight='600', fill='--paper-dim')
    return f, T('The last box is the one that has to be checked: a ban is real only if the firewall refuses.',
                'A última caixa é a que precisa ser conferida: um banimento só é real se o firewall recusar.')
