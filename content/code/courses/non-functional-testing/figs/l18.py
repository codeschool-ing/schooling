"""Lesson 18: a deleted key in the history, and who can read the environment."""
from figures import Fig, T, figure


@figure('l18-history', 18)
def history():
    f = Fig('l18-history', 720, 290, T(
        'A repository drawn as two commits and the files on disk. Commit 1 adds the key; commit 2 '
        'deletes the line. The files on disk no longer hold the key, and a scan of the files finds '
        'nothing. A scan of the history reads both commits and finds the key in commit 1. Below, '
        'four copies made before the deletion: your clone, a colleague\'s clone, a fork and a CI '
        'cache. Each of them holds commit 1, key included, and deleting the line reaches none of '
        'them.',
        'Um repositório desenhado como dois commits e os arquivos no disco. O commit 1 adiciona a '
        'chave; o commit 2 apaga a linha. Os arquivos no disco não guardam mais a chave, e uma '
        'varredura dos arquivos não acha nada. Uma varredura do histórico lê os dois commits e acha a '
        'chave no commit 1. Embaixo, quatro cópias feitas antes do apagamento: o seu clone, o clone '
        'de um colega, um fork e um cache de CI. Cada uma guarda o commit 1, com a chave, e apagar a '
        'linha não alcança nenhuma delas.'))
    f.text(360, 20, T('deleting the line changes the files, not the history',
                      'apagar a linha muda os arquivos, não o histórico'),
           size=11, weight='600', fill='--paper-dim')
    # what each scan reads
    f.line(60, 50, 460, 50, stroke='--phosphor', width=1.4)
    f.line(60, 46, 60, 54, stroke='--phosphor', width=1.4)
    f.line(460, 46, 460, 54, stroke='--phosphor', width=1.4)
    f.text(260, 40, T('gitleaks git: every commit', 'gitleaks git: todo commit'), size=10, fill='--paper')
    f.line(510, 50, 680, 50, stroke='--phosphor', width=1.4)
    f.line(510, 46, 510, 54, stroke='--phosphor', width=1.4)
    f.line(680, 46, 680, 54, stroke='--phosphor', width=1.4)
    f.text(595, 40, T('gitleaks dir: only these', 'gitleaks dir: só estes'), size=10, fill='--paper')
    # commits
    f.rect(60, 66, 170, 54, stroke='--amber', fill='--scan', width=1.6)
    f.text(145, 83, T('commit 1', 'commit 1'), size=10.5, weight='600')
    f.text(145, 103, T('adds the key', 'adiciona a chave'), size=10, fill='--amber')
    f.arrow([(230, 93), (286, 93)], stroke='--paper-dim')
    f.rect(290, 66, 170, 54, stroke='--wire', fill='--panel', width=1.2)
    f.text(375, 83, T('commit 2', 'commit 2'), size=10.5, weight='600')
    f.text(375, 103, T('deletes the line', 'apaga a linha'), size=10, fill='--paper-dim')
    f.rect(510, 66, 170, 54, stroke='--wire', fill='--ink', width=1.2, dash='5 4')
    f.text(595, 83, T('the files on disk', 'os arquivos no disco'), size=10.5, weight='600')
    f.text(595, 103, T('no key: no leaks found', 'sem chave: nada achado'), size=10, fill='--paper-dim')
    # copies
    f.text(360, 248, T('copies made before the deletion', 'cópias feitas antes do apagamento'),
           size=10, weight='600', fill='--paper-dim')
    f.line(145, 120, 145, 140, stroke='--amber', width=1.2, dash='4 3')
    f.line(70, 140, 650, 140, stroke='--amber', width=1.2, dash='4 3')
    copies = [T('your clone', 'o seu clone'), T('a colleague\'s clone', 'o clone de um colega'),
              T('a fork', 'um fork'), T('a CI cache', 'um cache de CI')]
    for i, name in enumerate(copies):
        x = 70 + i * 150
        f.line(x + 60, 140, x + 60, 176, stroke='--amber', width=1.2, dash='4 3', arrow=True)
        f.rect(x, 180, 120, 50, stroke='--wire', fill='--panel', width=1.1)
        f.text(x + 60, 197, name, size=10)
        f.text(x + 60, 215, T('has commit 1', 'tem o commit 1'), size=9.5, fill='--amber')
    f.text(360, 272, T('only revoking the key makes all of them harmless',
                       'só revogar a chave torna todas inofensivas'),
           size=10.5, fill='--amber')
    return f, T('Deleting the line makes a new commit. The one before it still holds the key, here and '
                'in every copy already made.',
                'Apagar a linha cria um commit novo. O anterior continua com a chave, aqui e em toda '
                'cópia já feita.')


@figure('l18-reach', 18)
def reach():
    f = Fig('l18-reach', 720, 280, T(
        'A process, python3 account.py, started with PAYMENT_API_KEY in its environment, inside a '
        'dashed boundary labelled user ana. Inside the boundary, two ways to read the value, both '
        'allowed: the file /proc/<pid>/environ and the command ps eww. Outside the boundary, the '
        'user nobody asks for the same file and gets Permission denied. On the right, three ways '
        'the value leaves the process without anybody deciding it should: every child process '
        'inherits a copy, a log line or an error page can print it, and a crash report can collect '
        'it.',
        'Um processo, python3 account.py, iniciado com PAYMENT_API_KEY no ambiente, dentro de uma '
        'fronteira tracejada chamada usuário ana. Dentro da fronteira, dois jeitos de ler o valor, '
        'os dois permitidos: o arquivo /proc/<pid>/environ e o comando ps eww. Fora da fronteira, o '
        'usuário nobody pede o mesmo arquivo e recebe Permission denied. À direita, três jeitos de o '
        'valor sair do processo sem ninguém decidir: todo processo filho herda uma cópia, uma linha '
        'de log ou uma página de erro pode imprimi-lo, e um relatório de falha pode coletá-lo.'))
    f.text(360, 20, T('protected as well as the account that runs it, and no better',
                      'protegido tanto quanto a conta que o roda, e não mais'),
           size=11, weight='600', fill='--paper-dim')
    f.zone(30, 44, 420, 176, T('user ana', 'usuário ana'))
    # the process
    f.rect(200, 76, 220, 62, stroke='--phosphor', fill='--scan', width=1.6)
    f.text(310, 95, 'python3 account.py', size=10.5, weight='600', mono=True)
    f.text(310, 117, 'PAYMENT_API_KEY=…', size=10, mono=True, fill='--amber')
    # readers inside
    f.rect(48, 160, 170, 40, stroke='--wire', fill='--panel', width=1.1)
    f.text(133, 180, '/proc/<pid>/environ', size=10, mono=True)
    f.rect(240, 160, 110, 40, stroke='--wire', fill='--panel', width=1.1)
    f.text(295, 180, 'ps eww', size=10, mono=True)
    f.arrow([(200, 120), (150, 158)], stroke='--phosphor')
    f.arrow([(295, 138), (295, 158)], stroke='--phosphor')
    f.text(372, 180, T('reads it', 'lê'), size=10, anchor='start', fill='--phosphor')
    # nobody, outside
    f.rect(48, 236, 110, 30, stroke='--paper-dim', fill='--ink', width=1.2)
    f.text(103, 251, 'nobody', size=10, mono=True)
    f.text(170, 251, 'Permission denied', size=10, anchor='start', mono=True, fill='--amber')
    # copies that leave
    f.text(590, 56, T('and copies it carries out', 'e cópias que ele leva para fora'),
           size=10, weight='600', fill='--paper-dim')
    outs = [T('every child process', 'todo processo filho'),
            T('a log line, an error page', 'uma linha de log, uma página de erro'),
            T('a crash report', 'um relatório de falha')]
    for i, name in enumerate(outs):
        y = 92 + i * 52
        f.rect(490, y - 18, 200, 36, stroke='--amber', fill='--panel', width=1.2, dash='5 4')
        f.text(590, y, name, size=10)
        f.arrow([(420, 107), (486, y)], stroke='--amber', width=1.2)
    return f, T('The environment is readable by the account that runs the process, and travels with '
                'everything the process starts or prints.',
                'O ambiente pode ser lido pela conta que roda o processo, e viaja com tudo o que o '
                'processo inicia ou imprime.')
