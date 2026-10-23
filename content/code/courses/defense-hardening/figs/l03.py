"""Lesson 3: Group Policy and centralised configuration."""
from figures import Fig, T, figure


@figure('l03-lsdou', 3)
def lsdou():
    f = Fig('l03-lsdou', 720, 300, T(
        'Group Policy processing order for one computer in the OU Reception, inside the OU Jatoba, '
        'inside the domain. Step 1, the local policy, sets the screen lock to 30 minutes. Step 2, the '
        'site, sets nothing. Step 3, the domain baseline, sets 15 minutes. Step 4a, the OU Jatoba, '
        'sets nothing. Step 4b, the OU Reception, sets 5 minutes. Each later step overwrites the one '
        'before, so the computer locks after 5 minutes, the value of the last and most specific '
        'container.',
        'Ordem de processamento da Política de Grupo para um computador na UO Recepção, dentro da UO '
        'Jatoba, dentro do domínio. Passo 1, a política local, põe o bloqueio de tela em 30 minutos. '
        'Passo 2, o site, não define nada. Passo 3, a linha de base do domínio, põe 15 minutos. Passo '
        '4a, a UO Jatoba, não define nada. Passo 4b, a UO Recepção, põe 5 minutos. Cada passo '
        'posterior sobrescreve o anterior, então o computador bloqueia depois de 5 minutos, o valor '
        'do último e mais específico contêiner.'))
    steps = [('1', T('local policy', 'política local'), T('lock after 30 min', 'bloqueia em 30 min')),
             ('2', T('site', 'site'), T('(nothing set)', '(nada definido)')),
             ('3', T('domain baseline', 'linha de base do domínio'), T('lock after 15 min', 'bloqueia em 15 min')),
             ('4a', T('OU Jatoba', 'UO Jatoba'), T('(nothing set)', '(nada definido)')),
             ('4b', T('OU Reception', 'UO Recepção'), T('lock after 5 min', 'bloqueia em 5 min'))]
    for i, (n, name, val) in enumerate(steps):
        x = 20 + i * 140
        last = i == 4
        f.rect(x, 60, 120, 90, stroke='--phosphor' if last else '--wire', fill='--panel', width=1.5, rx=3)
        f.text(x + 60, 80, n, size=12, weight='600', mono=True)
        f.text(x + 60, 104, name, size=10)
        f.text(x + 60, 128, val, size=9.5, fill='--phosphor' if last else '--paper-dim')
        if i < 4:
            f.line(x + 120, 105, x + 140, 105, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(360, 34, T('processed in this order; a later setting overwrites an earlier one',
                      'processados nesta ordem; uma configuração posterior sobrescreve a anterior'),
           size=10.5, fill='--paper-dim')
    f.rect(470, 190, 230, 60, stroke='--phosphor', fill='--scan', width=1.2, rx=3)
    f.text(585, 210, T('the reception computer', 'o computador da recepção'), size=10)
    f.text(585, 232, T('locks after 5 minutes', 'bloqueia depois de 5 minutos'), size=10.5, weight='600', fill='--phosphor')
    f.line(640, 150, 620, 190, stroke='--phosphor', width=1.4, arrow=True)
    f.text(20, 280, T('Enforced on the domain link would make step 3 win over 4a and 4b',
                      'Enforced no vínculo do domínio faria o passo 3 vencer o 4a e o 4b'),
           size=9.5, anchor='start', fill='--amber')
    return f, T('Local, site, domain, OU: the last one processed wins, and it is the most specific.',
                'Local, site, domínio, UO: o último processado vence, e é o mais específico.')


@figure('l03-vars', 3)
def ansible_vars():
    f = Fig('l03-vars', 720, 270, T(
        'Where each machine gets its two values. The file all.yml gives every machine 3 attempts and '
        'no X11 forwarding. The file workstations.yml overrides X11 forwarding to yes for desk. The '
        'file jump.yml overrides the attempts to 2 for jump. Result: web has 3 and no, desk has 3 '
        'and yes, jump has 2 and no. The more specific file wins.',
        'De onde cada máquina tira os seus dois valores. O arquivo all.yml dá a todas as máquinas 3 '
        'tentativas e nada de encaminhamento X11. O arquivo workstations.yml muda o X11 para yes no '
        'desk. O arquivo jump.yml muda as tentativas para 2 no jump. Resultado: web fica com 3 e no, '
        'desk com 3 e yes, jump com 2 e no. O arquivo mais específico vence.'))
    f.rect(20, 30, 680, 50, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(36, 55, 'group_vars/all.yml', size=10.5, anchor='start', mono=True, weight='600')
    f.text(330, 55, 'ssh_max_auth_tries: 3', size=10, mono=True)
    f.text(560, 55, 'x11_forwarding: "no"', size=10, mono=True)
    f.rect(250, 100, 220, 50, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(360, 116, 'group_vars/workstations.yml', size=10, mono=True, weight='600')
    f.text(360, 136, 'x11_forwarding: "yes"', size=10, mono=True)
    f.rect(490, 100, 210, 50, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(595, 116, 'host_vars/jump.yml', size=10, mono=True, weight='600')
    f.text(595, 136, 'ssh_max_auth_tries: 2', size=10, mono=True)
    for x, name, a, b, hi in [(130, 'web', '3', 'no', None), (360, 'desk', '3', 'yes', 'b'),
                              (595, 'jump', '2', 'no', 'a')]:
        f.rect(x - 90, 190, 180, 56, stroke='--phosphor', fill='--scan', width=1.2, rx=3)
        f.text(x, 206, name, size=11, mono=True, weight='600')
        f.text(x - 40, 228, a, size=11, mono=True, fill='--phosphor' if hi == 'a' else '--paper')
        f.text(x + 30, 228, b, size=11, mono=True, fill='--phosphor' if hi == 'b' else '--paper')
        src = 80 if not hi else 150
        f.line(x, src, x, 190, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(130, 140, T('nothing more specific', 'nada mais específico'), size=9.5, fill='--paper-dim')
    return f, T('A host file beats a group file, and a named group beats all.',
                'Um arquivo de host vence um de grupo, e um grupo nomeado vence o all.')
