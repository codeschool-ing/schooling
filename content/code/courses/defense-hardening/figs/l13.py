"""Lesson 13: honeypots and honeytokens."""
from figures import Fig, T, figure


@figure('l13-touch', 13)
def touch():
    f = Fig('l13-touch', 720, 210, T(
        'One touch and its record. desk connects to trap on port 445. bait.py accepts and closes the '
        'connection at once, and writes the time, the address 192.168.60.20 and the port to its JSON '
        'file and as a warning to the system log. From there the line goes to wherever the firm\'s '
        'alerts are read, and the response starts from the machine that touched the bait.',
        'Um toque e o registro dele. O desk conecta no trap na porta 445. O bait.py aceita e fecha a '
        'conexão na hora, e grava o horário, o endereço 192.168.60.20 e a porta no arquivo JSON e como '
        'aviso no log do sistema. Dali a linha vai para onde os alertas do escritório são lidos, e a '
        'resposta começa pela máquina que tocou a isca.'))
    f.rect(20, 70, 120, 50, stroke='--wire', fill='--panel', width=1.4, rx=3)
    f.text(80, 95, 'desk', size=11, mono=True, weight='600')
    f.rect(220, 70, 160, 50, stroke='--amber', fill='--panel', width=1.5, rx=3)
    f.text(300, 88, 'trap', size=11, mono=True, weight='600')
    f.text(300, 106, T('bait.py on 445', 'bait.py na 445'), size=9.5, fill='--paper-dim')
    f.line(140, 95, 220, 95, stroke='--paper-dim', width=1.4, arrow=True)
    f.text(180, 83, T('connects', 'conecta'), size=9, fill='--paper-dim')
    f.rect(450, 40, 250, 40, stroke='--wire', fill='--scan', width=1.2, rx=3)
    f.text(575, 60, 'touched: 192.168.60.20 on port 445', size=9, mono=True)
    f.rect(450, 110, 250, 40, stroke='--phosphor', fill='--panel', width=1.4, rx=3)
    f.text(575, 130, T('a person, within minutes', 'uma pessoa, em minutos'), size=10)
    f.line(380, 90, 450, 62, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(575, 80, 575, 110, stroke='--paper-dim', width=1.3, arrow=True)
    f.arrow([(575, 150), (575, 185), (80, 185), (80, 120)], stroke='--amber', width=1.3)
    f.text(330, 198, T('the response starts from desk', 'a resposta começa pelo desk'), size=9.5, fill='--amber')
    return f, T('Nobody\'s work connects to trap, so the one line is already the finding.',
                'O trabalho de ninguém conecta no trap, então a única linha já é o achado.')


@figure('l13-placement', 13)
def placement():
    f = Fig('l13-placement', 720, 260, T(
        'Where bait goes on a network like Jatobá\'s. The internet is outside the firm\'s firewall and '
        'holds no bait. Inside, among the servers beside web, a decoy server. Among the workstations '
        'beside desk, bait ports on an idle machine. Inside web itself, a honeytoken in a backup '
        'directory. Arrows show the path an intruder takes: from a workstation to the servers, and '
        'into the files of the server they reach.',
        'Onde fica a isca numa rede como a da Jatobá. A internet está fora do firewall do escritório '
        'e não tem isca. Dentro, entre os servidores ao lado do web, um servidor-isca. Entre as estações '
        'ao lado do desk, portas-isca numa máquina ociosa. Dentro do próprio web, um honeytoken num '
        'diretório de backup. As setas mostram o caminho de um invasor: de uma estação para os '
        'servidores, e para dentro dos arquivos do servidor que ele alcança.'))
    f.rect(20, 40, 120, 180, stroke='--wire', fill='--panel', width=1.2, rx=3, dash='5 3')
    f.text(80, 60, T('internet', 'internet'), size=10.5, weight='600')
    f.text(80, 130, T('no bait here', 'nada de isca'), size=9.5, fill='--paper-dim')
    f.line(150, 40, 150, 220, stroke='--paper-dim', width=2)
    f.text(158, 230, T('firewall', 'firewall'), size=9, anchor='start', fill='--paper-dim')
    f.rect(180, 40, 230, 180, stroke='--wire', fill='--panel', width=1.4, rx=3)
    f.text(195, 58, T('workstations', 'estações'), size=10.5, anchor='start', weight='600')
    f.rect(200, 80, 90, 36, stroke='--wire', fill='--scan', width=1.2, rx=3)
    f.text(245, 98, 'desk', size=10, mono=True)
    f.rect(300, 150, 95, 44, stroke='--amber', fill='--scan', width=1.4, rx=3)
    f.text(347, 166, T('idle machine,', 'máquina ociosa,'), size=9)
    f.text(347, 181, T('bait ports', 'portas-isca'), size=9, fill='--amber')
    f.rect(450, 40, 250, 180, stroke='--wire', fill='--panel', width=1.4, rx=3)
    f.text(465, 58, T('servers', 'servidores'), size=10.5, anchor='start', weight='600')
    f.rect(470, 80, 100, 60, stroke='--wire', fill='--scan', width=1.2, rx=3)
    f.text(520, 96, 'web', size=10, mono=True)
    f.rect(480, 108, 80, 24, stroke='--amber', fill='--panel', width=1.2, rx=2)
    f.text(520, 120, T('honeytoken', 'honeytoken'), size=8.5, fill='--amber')
    f.rect(590, 80, 95, 60, stroke='--amber', fill='--scan', width=1.4, rx=3)
    f.text(637, 100, T('decoy server', 'servidor-isca'), size=9, fill='--amber')
    f.text(637, 118, 'trap', size=9.5, mono=True)
    f.arrow([(290, 98), (470, 98)], stroke='--paper-dim', width=1.3, dash='4 3')
    f.text(352, 88, T('intruder looks around', 'o invasor olha em volta'), size=8.5, fill='--paper-dim')
    f.arrow([(570, 120), (590, 120)], stroke='--paper-dim', width=1.2, dash='4 3')
    return f, T('Bait sits on the path from the first machine to the next, and inside what they reach.',
                'A isca fica no caminho da primeira máquina para a seguinte, e dentro do que se alcança.')
