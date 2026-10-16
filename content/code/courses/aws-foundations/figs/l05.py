"""Lesson 5: the landing zone, by hand and by Control Tower."""
from figures import Fig, T, figure


def built(f, x, y, w, h, rows, size=10):
    f.rect(x, y, w, h, stroke='--phosphor', fill='--panel', width=1.2)
    f.lines(x + w / 2, y + h / 2, rows, size=size)


def missing(f, x, y, w, h, rows, size=10):
    f.rect(x, y, w, h, stroke='--paper-dim', fill='--ink', width=1.2, dash='4 3')
    f.lines(x + w / 2, y + h / 2, rows, size=size, fill='--paper-dim', italic=True)


@figure('l05-compare', 5)
def compare():
    f = Fig('l05-compare', 720, 470, T(
        'The shop\'s landing zone, with what landing-zone.sh built in moto drawn solid and what '
        'Control Tower would add drawn dashed. Solid: the organisation and its SCPs in the management '
        'account; the OUs Security, Workloads and Sandbox; the accounts log-archive and security in '
        'Security; the guardrail protect-the-record on Security; security registered as GuardDuty\'s '
        'delegated administrator. Dashed, not run: Control Tower and Account Factory, IAM Identity '
        'Center, the organisation trail and the log bucket in log-archive, the Config aggregator in '
        'security, a Config recorder and the trail in every workload account, the controls of three '
        'kinds, and drift detection.',
        'A landing zone da loja, com o que o landing-zone.sh construiu no moto desenhado em traço '
        'contínuo e o que o Control Tower acrescentaria desenhado tracejado. Contínuo: a organização e '
        'as suas SCPs na conta de gerenciamento; as OUs Security, Workloads e Sandbox; as contas '
        'log-archive e security em Security; a barreira protect-the-record em Security; a security '
        'registrada como administradora delegada do GuardDuty. Tracejado, não rodado: o Control Tower '
        'e o Account Factory, o IAM Identity Center, a trilha da organização e o bucket de logs na '
        'log-archive, o agregador do Config na security, um gravador do Config e a trilha em cada '
        'conta de carga de trabalho, os controles dos três tipos e a detecção de drift.'))
    # the management account
    f.rect(20, 20, 330, 150, stroke='--phosphor', fill='--scan', width=1.5)
    f.text(36, 38, T('management account', 'conta de gerenciamento'), size=10.5, anchor='start',
           weight='600')
    built(f, 36, 54, 298, 30, [T('the organisation, its OUs and SCPs', 'a organização, OUs e SCPs')])
    missing(f, 36, 92, 298, 30, [T('Control Tower and Account Factory', 'Control Tower e Account Factory')])
    missing(f, 36, 130, 298, 30, [T('IAM Identity Center (lesson 11)', 'IAM Identity Center (lição 11)')])
    # the controls
    missing(f, 380, 20, 320, 150, [T('the controls, on every OU:', 'os controles, em toda OU:'),
                                   T('preventive (SCPs)', 'preventivos (SCPs)'),
                                   T('detective (Config rules)', 'detectivos (regras do Config)'),
                                   T('proactive (CloudFormation hooks)', 'proativos (hooks do CloudFormation)'),
                                   T('and drift detection', 'e a detecção de drift')], size=10.5)
    # Security
    f.rect(20, 200, 440, 220, stroke='--paper-dim', fill='--ink', width=1.4, rx=10)
    f.text(36, 218, 'Security', size=10.5, anchor='start', mono=True, weight='600')
    f.text(444, 218, 'protect-the-record', size=10, anchor='end', mono=True, fill='--amber')
    for x, name, rows in ((36, 'log-archive', None), (248, 'security', None)):
        f.rect(x, 234, 196, 172, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(x + 98, 250, name, size=10.5, mono=True, weight='600')
    missing(f, 48, 266, 172, 48, [T('organisation trail', 'trilha da organização'),
                                  T('delivers here', 'entrega aqui')])
    missing(f, 48, 324, 172, 70, [T('the log bucket', 'o bucket de logs'),
                                  T('for every account\'s', 'para os registros'),
                                  T('records', 'de toda conta')])
    built(f, 260, 266, 172, 48, [T('GuardDuty: delegated', 'GuardDuty: administradora'),
                                 T('administrator', 'delegada')])
    missing(f, 260, 324, 172, 70, [T('Config aggregator', 'agregador do Config'),
                                   T('and the security', 'e as notificações'),
                                   T('team\'s notifications', 'da segurança')])
    # Workloads and Sandbox
    f.rect(480, 200, 220, 120, stroke='--paper-dim', fill='--ink', width=1.4, rx=10)
    f.text(496, 218, 'Workloads', size=10.5, anchor='start', mono=True, weight='600')
    f.text(684, 218, 'Prod, Staging', size=9.5, anchor='end', mono=True, fill='--paper-dim')
    missing(f, 494, 234, 192, 72, [T('in every account:', 'em cada conta:'),
                                   T('a Config recorder', 'um gravador do Config'),
                                   T('and the trail', 'e a trilha')])
    f.rect(480, 340, 220, 80, stroke='--paper-dim', fill='--ink', width=1.4, rx=10)
    f.text(496, 358, 'Sandbox', size=10.5, anchor='start', mono=True, weight='600')
    missing(f, 494, 370, 192, 38, [T('the same, once accounts arrive', 'o mesmo, quando chegarem contas')])
    # the key
    f.rect(140, 438, 26, 16, stroke='--phosphor', fill='--panel', width=1.2)
    f.text(174, 446, T('built by landing-zone.sh, in moto', 'construído pelo landing-zone.sh, no moto'),
           size=10, anchor='start')
    f.rect(420, 438, 26, 16, stroke='--paper-dim', fill='--ink', width=1.2, dash='4 3')
    f.text(454, 446, T('Control Tower adds; not run', 'o Control Tower acrescenta; não rodado'),
           size=10, anchor='start')
    return f, T('The script built the tree. Everything that lives inside the accounts is still dashed.',
                'O script construiu a árvore. Tudo o que mora dentro das contas continua tracejado.')
