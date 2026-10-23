"""Lesson 7: antivirus and antimalware."""
from figures import Fig, T, figure


@figure('l07-matches', 7)
def matches():
    f = Fig('l07-matches', 720, 250, T(
        'Which rule matched which file in this lesson. Four files across: invoice.txt, its exact copy, '
        'changed.txt which differs by one space, and an innocent training note that quotes the marker. '
        'Three rules down. The hash signature matched the original and the copy only. The content '
        'signature matched all three samples and also the note. The YARA rule, with the marker, the '
        'word invoice and a size limit, matched the same four.',
        'Que regra casou com que arquivo nesta aula. Quatro arquivos nas colunas: invoice.txt, a cópia '
        'exata, changed.txt que difere por um espaço, e uma nota de treinamento inocente que cita o '
        'marcador. Três regras nas linhas. A assinatura de hash casou só com o original e a cópia. A '
        'assinatura de conteúdo casou com as três amostras e também com a nota. A regra YARA, com o '
        'marcador, a palavra invoice e um limite de tamanho, casou com os mesmos quatro.'))
    cols = ['invoice.txt', 'copy.txt', 'changed.txt', 'notes.txt']
    rows = [(T('hash (.hsb)', 'hash (.hsb)'), [1, 1, 0, 0]),
            (T('content (.ndb)', 'conteúdo (.ndb)'), [1, 1, 1, 1]),
            (T('YARA rule', 'regra YARA'), [1, 1, 1, 1])]
    for j, c in enumerate(cols):
        f.text(260 + j * 115, 36, c, size=10, mono=True)
    f.text(605, 54, T('innocent', 'inocente'), size=9.5, fill='--amber')
    for i, (name, hits) in enumerate(rows):
        y = 70 + i * 50
        f.rect(20, y, 680, 40, stroke='--wire', fill='--panel', width=1.2, rx=3)
        f.text(36, y + 20, name, size=10.5, anchor='start', weight='600')
        for j, h in enumerate(hits):
            x = 260 + j * 115
            if h:
                fp = j == 3
                f.rect(x - 40, y + 8, 80, 24, stroke='--amber' if fp else '--phosphor', fill='--scan', width=1.2, rx=2)
                f.text(x, y + 20, T('false positive', 'falso positivo') if fp else T('found', 'achado'), size=9.5,
                       fill='--amber' if fp else '--phosphor')
            else:
                f.text(x, y + 20, 'OK', size=10, mono=True, fill='--paper-dim')
    f.text(360, 232, T('the broader the rule, the more it catches, wanted or not', 'quanto mais ampla a regra, mais ela pega, querendo ou não'),
           size=10, fill='--paper-dim')
    return f, T('Exact rules miss variants; broad rules catch innocent files.',
                'Regras exatas perdem variantes; regras amplas pegam arquivos inocentes.')


@figure('l07-moments', 7)
def moments():
    f = Fig('l07-moments', 720, 230, T(
        'The life of a file on a workstation, from left to right, and the three moments a scanner can '
        'look at it. At the gate, when it arrives by mail, download or USB stick. On access, every '
        'time it is opened, written or run. On a schedule, in the nightly scan, whether or not anybody '
        'touched it. Between scheduled scans, a file nobody opens is only seen on access if it is opened.',
        'A vida de um arquivo numa estação, da esquerda para a direita, e os três momentos em que um '
        'scanner pode olhá-lo. Na entrada, quando chega por e-mail, download ou pendrive. No acesso, '
        'toda vez que é aberto, gravado ou executado. No horário, na varredura noturna, alguém tenha '
        'tocado nele ou não. Entre varreduras agendadas, um arquivo que ninguém abre só é visto no '
        'acesso se for aberto.'))
    f.line(40, 120, 690, 120, stroke='--wire', width=1.6, arrow=True)
    steps = [(90, T('arrives', 'chega'), T('at the gate', 'na entrada')),
             (300, T('opened, written, run', 'aberto, gravado, executado'), T('on access', 'no acesso')),
             (560, T('every night', 'toda noite'), T('scheduled scan', 'varredura agendada'))]
    for x, ev, scan in steps:
        f.circle(x, 120, 6, fill='--phosphor')
        f.text(x, 96, ev, size=10)
        f.rect(x - 75, 145, 150, 34, stroke='--phosphor', fill='--scan', width=1.2, rx=3)
        f.text(x, 162, scan, size=10, weight='600', fill='--phosphor')
        f.line(x, 126, x, 145, stroke='--paper-dim', width=1.1)
    f.text(360, 210, T('the lab ran only on-demand scans', 'o laboratório só rodou varreduras sob demanda'),
           size=9.5, fill='--paper-dim')
    return f, T('Each moment covers a different gap; a desktop product uses all three.',
                'Cada momento cobre uma lacuna diferente; um produto de desktop usa os três.')
