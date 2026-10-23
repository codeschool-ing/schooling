"""Lesson 15: jump server and controlled administrative access."""
from figures import Fig, T, figure


def box(f, x, y, w, h, name, sub=None, stroke='--wire'):
    f.rect(x, y, w, h, stroke=stroke, fill='--panel', width=1.5, rx=3)
    f.text(x + w / 2, y + (h / 2 if not sub else h / 2 - 8), name, size=11, mono=True, weight='600')
    if sub:
        f.text(x + w / 2, y + h / 2 + 10, sub, size=9.5, fill='--paper-dim')


@figure('l15-one-door', 15)
def one_door():
    f = Fig('l15-one-door', 720, 270, T(
        'Two drawings of administrative access. On the left, before: admin, desk and a laptop each have '
        'a line straight to web and to db, six paths in all. On the right, after: admin has one line to '
        'jump, and jump has one line to each server; desk and the laptop have no line to any server.',
        'Dois desenhos do acesso administrativo. À esquerda, antes: admin, desk e um notebook têm cada um '
        'uma linha direta para o web e para o db, seis caminhos ao todo. À direita, depois: o admin tem '
        'uma linha para o jump, e o jump tem uma linha para cada servidor; o desk e o notebook não têm '
        'linha para servidor nenhum.'))
    f.text(170, 22, T('before: every machine is a way in', 'antes: toda máquina é uma entrada'), size=10.5,
           weight='600', fill='--paper-dim')
    f.text(540, 22, T('after: one door', 'depois: uma porta'), size=10.5, weight='600', fill='--paper-dim')
    left = ['admin', 'desk', T('laptop', 'notebook')]
    for i, n in enumerate(left):
        box(f, 20, 50 + i * 70, 100, 36, n)
    for j, n in enumerate(['web', 'db']):
        box(f, 230, 80 + j * 90, 100, 36, n)
    for i in range(3):
        for j in range(2):
            f.line(120, 68 + i * 70, 230, 98 + j * 90, stroke='--amber', width=1.1, arrow=True)
    for i, n in enumerate(left):
        box(f, 390, 50 + i * 70, 100, 36, n)
    box(f, 520, 50, 80, 36, 'jump', stroke='--phosphor')
    for j, n in enumerate(['web', 'db']):
        box(f, 620, 120 + j * 70, 80, 36, n)
        f.line(580, 86, 640, 120 + j * 70, stroke='--phosphor', width=1.2, arrow=True)
    f.line(490, 68, 520, 68, stroke='--phosphor', width=1.2, arrow=True)
    f.text(460, 255, T('desk and the laptop reach no server', 'desk e notebook não alcançam servidor nenhum'),
           size=10, fill='--phosphor')
    return f, T('Six paths to audit before, one after. The servers decide which, not the administrators.',
                'Seis caminhos para auditar antes, um depois. Quem decide são os servidores, não os administradores.')


@figure('l15-chain', 15)
def chain():
    f = Fig('l15-chain', 720, 230, T(
        'The chain the rules make. admin connects to jump on port 22, allowed by jump\'s firewall. jump '
        'connects to web on port 22, allowed by web\'s firewall and by PermitOpen web:22 on jump. desk '
        'trying jump is refused by jump\'s firewall, and desk trying web directly is refused by web\'s '
        'firewall, which counts it.',
        'A corrente que as regras formam. O admin conecta no jump na porta 22, permitido pelo firewall do '
        'jump. O jump conecta no web na porta 22, permitido pelo firewall do web e pelo PermitOpen web:22 '
        'no jump. O desk tentando o jump é recusado pelo firewall do jump, e o desk tentando o web direto é '
        'recusado pelo firewall do web, que conta a tentativa.'))
    box(f, 30, 50, 120, 44, 'admin', '192.168.60.30')
    box(f, 300, 50, 120, 44, 'jump', '192.168.60.40', stroke='--phosphor')
    box(f, 570, 50, 120, 44, 'web', '192.168.60.10')
    box(f, 300, 160, 120, 44, 'desk', '192.168.60.20')
    f.line(150, 72, 300, 72, stroke='--phosphor', width=1.4, arrow=True)
    f.text(225, 60, T('ssh, allowed', 'ssh, permitido'), size=9.5, fill='--phosphor')
    f.line(420, 72, 570, 72, stroke='--phosphor', width=1.4, arrow=True)
    f.text(495, 60, T('only web:22', 'só web:22'), size=9.5, fill='--phosphor')
    f.line(360, 160, 360, 100, stroke='--amber', width=1.3, arrow=True, dash='4 3')
    f.text(370, 132, T('refused by jump', 'recusado pelo jump'), size=9.5, anchor='start', fill='--amber')
    f.line(420, 182, 610, 100, stroke='--amber', width=1.3, arrow=True, dash='4 3')
    f.text(530, 160, T('refused and counted by web', 'recusado e contado pelo web'), size=9.5, anchor='start',
           fill='--amber')
    return f, T('Every arrow is a rule you can read, and every refusal is counted.',
                'Cada seta é uma regra que dá para ler, e cada recusa é contada.')
