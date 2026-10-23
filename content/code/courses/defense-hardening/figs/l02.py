"""Lesson 2: secure configuration guides and automation."""
from figures import Fig, T, figure


@figure('l02-fix-and-check', 2)
def fix_and_check():
    f = Fig('l02-fix-and-check', 720, 290, T(
        'Two programs look at the same SSH server from different sides. On the left, the playbook on '
        'admin writes the file 10-hardening.conf and nothing else. In the middle, sshd reads every '
        'file in sshd_config.d in name order and keeps the first value of each setting. Somebody '
        'adds 05-quickfix.conf, which sorts first, so root logins are allowed again. On the right, '
        'check.sh asks sshd -T for the effective value and reports JAT-04 as failed. The playbook, '
        'which only knows its own file, reports changed=0.',
        'Dois programas olham o mesmo servidor SSH por lados diferentes. À esquerda, o playbook no '
        'admin grava o arquivo 10-hardening.conf e mais nada. No meio, o sshd lê cada arquivo de '
        'sshd_config.d em ordem de nome e guarda o primeiro valor de cada opção. Alguém acrescenta '
        '05-quickfix.conf, que vem primeiro na ordem, e o login de root volta a ser permitido. À '
        'direita, o check.sh pergunta ao sshd -T o valor efetivo e informa JAT-04 como reprovado. O '
        'playbook, que só conhece o próprio arquivo, informa changed=0.'))
    f.rect(20, 40, 170, 70, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(105, 62, 'harden.yml', size=11, mono=True, weight='600')
    f.text(105, 84, T('writes its own file', 'grava o próprio arquivo'), size=9.5, fill='--paper-dim')
    f.text(105, 132, 'changed=0', size=10.5, mono=True, fill='--amber')
    f.text(105, 150, T('it sees nothing wrong', 'não vê nada errado'), size=9.5, fill='--amber')
    f.rect(255, 30, 210, 210, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(360, 50, 'sshd_config.d/', size=11, mono=True, weight='600')
    f.rect(270, 70, 180, 50, stroke='--amber', fill='--scan', width=1.2, rx=2)
    f.text(282, 86, '05-quickfix.conf', size=10, anchor='start', mono=True, fill='--amber')
    f.text(282, 104, 'PermitRootLogin yes', size=9.5, anchor='start', mono=True)
    f.rect(270, 130, 180, 50, stroke='--wire', fill='--scan', width=1.2, rx=2)
    f.text(282, 146, '10-hardening.conf', size=10, anchor='start', mono=True)
    f.text(282, 164, 'PermitRootLogin no', size=9.5, anchor='start', mono=True)
    f.text(360, 205, T('read in name order;', 'lidos em ordem de nome;'), size=9.5, fill='--paper-dim')
    f.text(360, 221, T('the first value is kept', 'o primeiro valor fica'), size=9.5, fill='--paper-dim')
    f.line(190, 75, 270, 150, stroke='--paper-dim', width=1.4, arrow=True)
    f.rect(530, 40, 170, 70, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(615, 62, 'check.sh', size=11, mono=True, weight='600')
    f.text(615, 84, T('asks sshd -T', 'pergunta ao sshd -T'), size=9.5, fill='--paper-dim')
    f.line(465, 95, 530, 80, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(615, 132, 'FAIL JAT-04', size=10.5, mono=True, fill='--amber')
    f.text(615, 150, T('it sees the effect', 'vê o efeito'), size=9.5, fill='--phosphor')
    f.text(360, 272, T('the fix knows its file; the check knows the result', 'a correção conhece o arquivo; a verificação conhece o resultado'),
           size=10, fill='--paper-dim')
    return f, T('A playbook can only report what it changed. A check reports what is true.',
                'Um playbook só sabe informar o que mudou. Uma verificação informa o que é verdade.')


@figure('l02-wrong-release', 2)
def wrong_release():
    f = Fig('l02-wrong-release', 720, 240, T(
        'Why every rule came back not applicable. The 22.04 data stream holds 291 rules for the CIS '
        'Level 1 server profile, and each rule names the platforms it applies to, up to Ubuntu '
        '22.04. Before any test runs, OpenSCAP compares that list with the machine, which is Ubuntu '
        '24.04. No platform matches, so the test is never run and the result is notapplicable, for '
        'all 291 rules.',
        'Por que todas as regras voltaram como não aplicáveis. O data stream do 22.04 tem 291 regras '
        'para o perfil CIS Nível 1 de servidor, e cada regra cita as plataformas a que se aplica, até '
        'o Ubuntu 22.04. Antes de qualquer teste, o OpenSCAP compara essa lista com a máquina, que é '
        'Ubuntu 24.04. Nenhuma plataforma bate, então o teste nunca roda e o resultado é '
        'notapplicable, para as 291 regras.'))
    f.rect(20, 50, 200, 140, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(120, 72, 'ssg-ubuntu2204-ds.xml', size=10.5, mono=True, weight='600')
    f.text(120, 100, T('291 rules in the profile', '291 regras no perfil'), size=9.5)
    f.text(120, 124, T('each applies to', 'cada uma vale para'), size=9.5, fill='--paper-dim')
    f.text(120, 146, 'ubuntu_linux:22.04', size=10, mono=True)
    f.text(120, 166, T('(and older)', '(e anteriores)'), size=9.5, fill='--paper-dim')
    f.rect(270, 80, 180, 80, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(360, 104, T('platform check', 'conferência de plataforma'), size=10.5, weight='600')
    f.text(360, 128, T('before any test', 'antes de qualquer teste'), size=9.5, fill='--paper-dim')
    f.line(220, 120, 270, 120, stroke='--paper-dim', width=1.4, arrow=True)
    f.rect(500, 50, 200, 60, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(600, 72, 'web', size=11, mono=True, weight='600')
    f.text(600, 92, 'VERSION_ID="24.04"', size=10, mono=True)
    f.line(500, 85, 450, 105, stroke='--paper-dim', width=1.4, arrow=True)
    f.rect(500, 140, 200, 60, stroke='--amber', fill='--scan', width=1.2, rx=3)
    f.text(600, 162, '291 notapplicable', size=10.5, mono=True, fill='--amber')
    f.text(600, 182, T('nothing was tested', 'nada foi testado'), size=9.5)
    f.line(450, 140, 500, 165, stroke='--amber', width=1.4, arrow=True)
    return f, T('The scanner refused before it measured. A guide written for another release has no results to give.',
                'O scanner recusou antes de medir. Um guia escrito para outra versão não tem resultado a dar.')
