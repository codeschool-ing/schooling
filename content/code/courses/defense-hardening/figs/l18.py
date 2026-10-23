"""Lesson 18: inventory and configuration."""
from figures import Fig, T, figure


@figure('l18-loop', 18)
def loop():
    f = Fig('l18-loop', 720, 250, T(
        'Two sources meet in a comparison. On the left, the records: hosts.csv with five machines, and a '
        'baseline per role. On the right, measurement: a sweep of the network that finds seven machines, '
        'and a collection from each machine of what it runs. In the middle, the comparison produces '
        'findings, each with an owner, and the fixes change the machines, which the next measurement sees.',
        'Duas fontes se encontram numa comparação. À esquerda, os registros: o hosts.csv com cinco máquinas '
        'e uma linha de base por papel. À direita, a medição: uma varredura da rede que acha sete máquinas, '
        'e uma coleta, em cada máquina, do que ela roda. No meio, a comparação produz achados, cada um com '
        'um dono, e as correções mudam as máquinas, o que a próxima medição vê.'))
    def box(x, y, w, h, a, b, c='--wire'):
        f.rect(x, y, w, h, stroke=c, fill='--panel', width=1.5, rx=3)
        f.text(x + w / 2, y + h / 2 - 8, a, size=11, weight='600')
        f.text(x + w / 2, y + h / 2 + 10, b, size=9.5, fill='--paper-dim')
    f.text(110, 22, T('what the firm says', 'o que o escritório diz'), size=10.5, weight='600', fill='--paper-dim')
    f.text(610, 22, T('what is there', 'o que existe'), size=10.5, weight='600', fill='--paper-dim')
    box(30, 40, 160, 50, 'hosts.csv', T('five machines, owners', 'cinco máquinas, donos'))
    box(30, 120, 160, 50, 'baseline.json', T('what each role runs', 'o que cada papel roda'))
    box(530, 40, 160, 50, 'nmap -sn', T('seven machines answer', 'sete máquinas respondem'))
    box(530, 120, 160, 50, 'inventory.py', T('what each one runs', 'o que cada uma roda'))
    box(280, 75, 160, 60, 'drift.py', T('findings, with owners', 'achados, com donos'), c='--phosphor')
    for y in (65, 145):
        f.line(190, y, 280, 105, stroke='--paper-dim', width=1.2, arrow=True)
        f.line(530, y, 440, 105, stroke='--paper-dim', width=1.2, arrow=True)
    f.arrow([(360, 135), (360, 215), (610, 215), (610, 170)], stroke='--amber', width=1.3)
    f.text(485, 230, T('fixes change the machines; measure again', 'correções mudam as máquinas; meça de novo'),
           size=10, fill='--amber')
    return f, T('An inventory is a list checked against measurement, not a list.',
                'Um inventário é uma lista conferida contra medição, não uma lista.')


@figure('l18-consumers', 18)
def consumers():
    f = Fig('l18-consumers', 720, 270, T(
        'The inventory in the centre, with arrows out to the lessons that use it: lesson 1 takes the role, '
        'lessons 2 and 3 the groups to configure, lessons 4 and 5 the allowed devices, lessons 7 to 12 '
        'which machines have each control, lessons 13 and 14 the legitimate addresses, lesson 15 the '
        'servers and their administrators, lesson 16 the installed software and exposure, lesson 17 the '
        'rings and proof of each update.',
        'O inventário no centro, com setas para as aulas que o usam: a aula 1 pega o papel, as aulas 2 e 3 '
        'os grupos a configurar, as aulas 4 e 5 os dispositivos permitidos, as aulas 7 a 12 que máquinas '
        'têm cada controle, as aulas 13 e 14 os endereços legítimos, a aula 15 os servidores e quem os '
        'administra, a aula 16 o software instalado e a exposição, a aula 17 os anéis e a prova de cada '
        'atualização.'))
    cx, cy = 360, 135
    f.rect(cx - 70, cy - 25, 140, 50, stroke='--phosphor', fill='--panel', width=1.8, rx=3)
    f.text(cx, cy - 6, T('inventory', 'inventário'), size=12, weight='600')
    f.text(cx, cy + 12, T('lesson 18', 'aula 18'), size=9.5, fill='--paper-dim')
    items = [(T('lesson 1', 'aula 1'), T('the role', 'o papel'), 110, 40),
             (T('lessons 2, 3', 'aulas 2, 3'), T('groups to configure', 'grupos a configurar'), 360, 30),
             (T('lessons 4, 5', 'aulas 4, 5'), T('allowed devices', 'dispositivos permitidos'), 610, 40),
             (T('lessons 7 to 12', 'aulas 7 a 12'), T('which controls where', 'que controle onde'), 610, 135),
             (T('lessons 13, 14', 'aulas 13, 14'), T('legitimate addresses', 'endereços legítimos'), 610, 230),
             (T('lesson 15', 'aula 15'), T('servers, administrators', 'servidores, administradores'), 360, 240),
             (T('lesson 16', 'aula 16'), T('software, exposure', 'software, exposição'), 110, 230),
             (T('lesson 17', 'aula 17'), T('rings, proof', 'anéis, prova'), 110, 135)]
    for a, b, x, y in items:
        f.rect(x - 75, y - 20, 150, 40, stroke='--wire', fill='--panel', width=1.2, rx=3)
        f.text(x, y - 6, a, size=10, weight='600')
        f.text(x, y + 9, b, size=9.5, fill='--paper-dim')
        dx, dy = x - cx, y - cy
        sx = cx + (70 if dx > 5 else -70 if dx < -5 else 0)
        sy = cy + (25 if dy > 5 else -25 if dy < -5 else 0)
        ex = x - (75 if dx > 5 else -75 if dx < -5 else 0)
        ey = y - (20 if dy > 5 else -20 if dy < -5 else 0)
        if abs(dx) > 5 and abs(dy) > 5:
            ey = y
        f.line(sx, sy, ex, ey, stroke='--phosphor', width=1.1, arrow=True)
    return f, T('Every control in the course is applied to the inventory’s output.',
                'Todo controle do curso é aplicado ao que o inventário produz.')
