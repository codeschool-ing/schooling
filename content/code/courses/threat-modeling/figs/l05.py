"""Lesson 5: DREAD, LINDDUN and attack trees."""
from figures import Fig, T, figure

DREAD = [  # factor, carla, ana: the two scores the lesson's exercise produced for T01
    (T('Damage', 'Dano'), 6, 4),
    (T('Reproducibility', 'Reprodutibilidade'), 9, 8),
    (T('Exploitability', 'Explorabilidade'), 8, 5),
    (T('Affected users', 'Usuários afetados'), 3, 2),
    (T('Discoverability', 'Descoberta'), 7, 3),
]


@figure('l05-dread-raters', 5)
def dread_raters():
    f = Fig('l05-dread-raters', 720, 270, T(
        'Two people score the forged webhook, T01, with DREAD from 1 to 10. carla: damage 6, '
        'reproducibility 9, exploitability 8, affected users 3, discoverability 7, average 6.6. '
        'ana: 4, 8, 5, 2 and 3, average 4.4. The biggest gaps are discoverability, 7 against 3, '
        'and exploitability, 8 against 5.',
        'Duas pessoas pontuam o webhook forjado, T01, com DREAD de 1 a 10. carla: dano 6, '
        'reprodutibilidade 9, explorabilidade 8, usuários afetados 3, descoberta 7, média 6,6. '
        'ana: 4, 8, 5, 2 e 3, média 4,4. As maiores diferenças são descoberta, 7 contra 3, e '
        'explorabilidade, 8 contra 5.'))
    x0, y0, bh, step = 170, 30, 13, 40
    for i, (name, c, a) in enumerate(DREAD):
        y = y0 + i * step
        f.text(x0 - 10, y + bh, name, size=10.5, anchor='end', weight='600')
        for k, (v, fill) in enumerate(((c, '--phosphor'), (a, '--amber'))):
            yy = y + k * (bh + 2)
            f.rect(x0, yy, 30 * v, bh, stroke=None, fill=fill, rx=1)
            f.text(x0 + 30 * v + 6, yy + bh / 2, str(v), size=9.5, anchor='start')
    for v in range(0, 11, 2):
        f.line(x0 + 30 * v, y0 - 6, x0 + 30 * v, y0 + 5 * step - 6, stroke='--wire', width=0.8)
    mc = sum(d[1] for d in DREAD) / 5
    ma = sum(d[2] for d in DREAD) / 5
    dec = (lambda v: f'{v:.1f}') if True else None
    fmt = (lambda v: dec(v)) if T('en', 'pt') == 'en' else (lambda v: dec(v).replace('.', ','))
    f.rect(500, 60, 200, 30, stroke='--phosphor', fill='--panel', width=1.4)
    f.rect(510, 70, 10, 10, stroke=None, fill='--phosphor', rx=1)
    f.text(600, 75, T(f'carla: average {fmt(mc)}', f'carla: média {fmt(mc)}'), size=10.5, weight='600')
    f.rect(500, 100, 200, 30, stroke='--amber', fill='--panel', width=1.4)
    f.rect(510, 110, 10, 10, stroke=None, fill='--amber', rx=1)
    f.text(600, 115, T(f'ana: average {fmt(ma)}', f'ana: média {fmt(ma)}'), size=10.5, weight='600')
    f.text(600, 160, T('same threat, same facts,', 'mesma ameaça, mesmos fatos,'), size=10, fill='--paper-dim')
    f.text(600, 176, T('a gap of 2.2 points', 'uma diferença de 2,2 pontos'), size=10, fill='--paper-dim')
    f.text(x0 + 150, 250, T('score, 0 to 10', 'nota, de 0 a 10'), size=9.5, fill='--paper-dim')
    return f, T('Discoverability did most of the damage: carla assumed somebody will find the address, ana assumed nobody will.',
                'A descoberta fez a maior parte do estrago: a carla supôs que alguém vai achar o endereço, a ana supôs que ninguém vai.')


@figure('l05-linddun-flows', 5)
def linddun_flows():
    f = Fig('l05-linddun-flows', 720, 290, T(
        'The flows that carry personal data out of Vereda, with the LINDDUN categories each one '
        'raised. To the SMS provider: the patient’s phone, name, time and clinic; detecting, data '
        'disclosure, unawareness. To the payment gateway: name, CPF and amount; linking, data '
        'disclosure. Into the records database: every booking and note, kept with no end date; '
        'identifying, non-compliance.',
        'Os fluxos que levam dado pessoal para fora da Vereda, com as categorias do LINDDUN que '
        'cada um levantou. Para o provedor de SMS: telefone, nome, horário e clínica do paciente; '
        'detecção, divulgação de dados, desconhecimento. Para o gateway de pagamento: nome, CPF e '
        'valor; vinculação, divulgação de dados. Para dentro do banco de prontuários: todo '
        'agendamento e anotação, guardados sem data de fim; identificação, não conformidade.'))
    f.process(130, 145, 50, [T('Vereda', 'Vereda')], size=11)
    rows = [
        (50, T('SMS provider', 'Provedor de SMS'), T('phone, name, time, clinic', 'telefone, nome, horário, clínica'),
         [T('Detecting', 'Detecção'), T('Data disclosure', 'Divulgação de dados'), T('Unawareness', 'Desconhecimento')]),
        (145, T('Payment gateway', 'Gateway de pagamento'), T('name, CPF, amount', 'nome, CPF, valor'),
         [T('Linking', 'Vinculação'), T('Data disclosure', 'Divulgação de dados')]),
        (240, T('Records database', 'Banco de prontuários'), T('every booking and note, no end date', 'todo agendamento e anotação, sem data de fim'),
         [T('Identifying', 'Identificação'), T('Non-compliance', 'Não conformidade')]),
    ]
    for y, dest, what, cats in rows:
        if y == 240:
            f.store(300, y, 140, [dest], size=10)
        else:
            f.entity(300, y, 140, 36, [dest], size=10)
        f.arrow([(180 if y == 145 else 160, y if y == 145 else (y + 20 if y < 145 else y - 20)), (228, y)], stroke='--paper', width=1.3)
        f.text(300, y + 30, what, size=9, fill='--paper-dim')
        for k, c in enumerate(cats):
            f.rect(390 + k * 110, y - 13, 106, 26, stroke='--amber', fill='--panel', width=1.2, rx=3)
            f.text(443 + k * 110, y, c, size=9, weight='600', fill='--amber')
    return f, T('STRIDE asked whether an attacker could read these flows. LINDDUN asks whether they should carry what they carry, and whether the patient knows.',
                'O STRIDE perguntou se um atacante conseguiria ler estes fluxos. O LINDDUN pergunta se eles deveriam levar o que levam, e se o paciente sabe.')


@figure('l05-attack-tree', 5)
def attack_tree():
    f = Fig('l05-attack-tree', 720, 300, T(
        'An attack tree with the goal mark a booking paid without paying at the root. It is an OR '
        'of three branches. Forge the gateway’s webhook, an AND of learn the webhook’s address, 1 '
        'day, and send a request the portal accepts, 1 day: 2 days. Change the status in the staff '
        'console, an AND of take over a staff account, 5 days, and reach the console, 2 days: 7 '
        'days. Change the row in the database, an AND of take over the reminder worker, 10 days, '
        'and use its owner account, 1 day: 11 days. The cheapest branch, 2 days, is the root’s '
        'value.',
        'Uma árvore de ataque com o objetivo marcar um agendamento como pago sem pagar na raiz. É '
        'um OU de três ramos. Forjar o webhook do gateway, um E de descobrir o endereço do webhook, '
        '1 dia, e mandar um pedido que o portal aceite, 1 dia: 2 dias. Mudar a situação no console '
        'da equipe, um E de tomar uma conta da equipe, 5 dias, e chegar ao console, 2 dias: 7 dias. '
        'Mudar a linha no banco, um E de tomar o worker de lembretes, 10 dias, e usar a conta de '
        'dono dele, 1 dia: 11 dias. O ramo mais barato, 2 dias, é o valor da raiz.'))
    f.rect(220, 12, 280, 40, stroke='--amber', fill='--panel', width=1.8)
    f.text(360, 26, T('mark a booking paid without paying', 'marcar como pago sem pagar'), size=10.5, weight='600')
    f.text(360, 42, T('OR  ·  cheapest: 2 days', 'OU  ·  mais barato: 2 dias'), size=9.5, fill='--amber')
    branches = [
        (120, T('forge the webhook', 'forjar o webhook'), 2, [(1, T('learn its address', 'descobrir o endereço'), ''),
                                                            (1, T('send one the portal accepts', 'mandar um que o portal aceite'), 'T01')]),
        (360, T('change it in the console', 'mudar no console'), 7, [(5, T('take over a staff account', 'tomar conta da equipe'), 'T03'),
                                                                   (2, T('reach the console', 'chegar ao console'), 'T12')]),
        (600, T('change the database row', 'mudar a linha no banco'), 11, [(10, T('take over the worker', 'tomar o worker'), ''),
                                                                         (1, T('use its owner account', 'usar a conta de dono'), 'T13')]),
    ]
    for x, name, total, leaves in branches:
        f.line(360, 52, x, 92, stroke='--paper-dim', width=1.2)
        f.rect(x - 100, 92, 200, 40, stroke='--phosphor', fill='--panel', width=1.5)
        f.text(x, 106, name, size=10, weight='600')
        f.text(x, 122, T(f'AND  ·  {total} days', f'E  ·  {total} dias'), size=9.5, fill='--phosphor')
        for k, (d, leaf, tid) in enumerate(leaves):
            lx = x - 56 + k * 112
            f.line(x, 132, lx, 180, stroke='--paper-dim', width=1.2)
            f.rect(lx - 54, 180, 108, 58, stroke='--paper-dim', fill='--panel', width=1.2)
            words = leaf.split()
            half = (len(words) + 1) // 2
            f.lines(lx, 202, [' '.join(words[:half]), ' '.join(words[half:])], size=9)
            f.text(lx, 226, T(f'{d} day' + ('s' if d > 1 else ''), f'{d} dia' + ('s' if d > 1 else '')), size=9, weight='600', fill='--paper-dim')
            if tid:
                f.text(lx, 254, tid, size=9, weight='600', fill='--amber', mono=True)
    f.text(360, 284, T('OR takes the cheapest child; AND adds its children up.', 'OU fica com o filho mais barato; E soma os filhos.'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Three of the leaves are threats already on the list. The days are the team’s estimates, and the tree’s value is in comparing them.',
                'Três das folhas são ameaças que já estão na lista. Os dias são estimativas da equipe, e o valor da árvore está em compará-las.')


@figure('l05-controls', 5)
def controls():
    f = Fig('l05-controls', 720, 230, T(
        'The cheapest route to the goal under four sets of controls, from tree.py. None: 2 days, '
        'through the webhook. Signature check: 7 days, through the console. Signature and a second '
        'factor: 11 days, through the worker. Signature, second factor and the console on the '
        'clinic network only: still 11 days. Signature, second factor and a least-privilege '
        'database account: unreachable.',
        'O caminho mais barato até o objetivo com quatro conjuntos de controles, a partir do '
        'tree.py. Nenhum: 2 dias, pelo webhook. Verificação de assinatura: 7 dias, pelo console. '
        'Assinatura e segundo fator: 11 dias, pelo worker. Assinatura, segundo fator e console só '
        'pela rede da clínica: ainda 11 dias. Assinatura, segundo fator e conta de banco com '
        'mínimo privilégio: inalcançável.'))
    rows = [(T('none', 'nenhum'), 2), ('signature', 7), ('signature, mfa', 11), ('signature, mfa, clinic-only', 11),
            ('signature, mfa, least-privilege', None)]
    for i, (label, days) in enumerate(rows):
        y = 18 + i * 40
        f.text(240, y + 13, label, size=10, anchor='end', mono=(i > 0))
        if days is None:
            f.rect(250, y, 440, 26, stroke='--phosphor', fill='--panel', width=1.2, rx=2, dash='5 3')
            f.text(470, y + 13, T('unreachable', 'inalcançável'), size=10, weight='600', fill='--phosphor')
        else:
            f.rect(250, y, 34 * days, 26, stroke=None, fill='--amber' if days == 2 else '--phosphor-dim', rx=2)
            f.text(250 + 34 * days + 8, y + 13, T(f'{days} days', f'{days} dias'), size=10, anchor='start', weight='600')
    return f, T('The fourth row is the one to remember: a control on a path that is already broken buys nothing.',
                'A quarta linha é a que vale lembrar: um controle num caminho que já está quebrado não compra nada.')
