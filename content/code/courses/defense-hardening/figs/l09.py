"""Lesson 9: DLP, data loss prevention."""
from figures import Fig, T, figure


@figure('l09-channels', 9)
def channels():
    f = Fig('l09-channels', 720, 300, T(
        'The workstation desk in the middle with five ways data leaves it. Mail goes through the '
        'firm\'s mail gateway, which can read attachments. Web uploads cross the network encrypted. '
        'A sync folder uploads in the background, also encrypted. A USB stick and a printer are '
        'actions on the machine itself. Only the endpoint sees all five while the file is still '
        'readable.',
        'A estação desk no meio, com cinco jeitos de os dados saírem dela. O e-mail passa pelo '
        'gateway de e-mail do escritório, que consegue ler anexos. Uploads pela web cruzam a rede '
        'cifrados. Uma pasta sincronizada envia em segundo plano, também cifrado. Um pendrive e uma '
        'impressora são ações na própria máquina. Só o endpoint vê os cinco enquanto o arquivo ainda '
        'está legível.'))
    f.rect(270, 110, 180, 80, stroke='--phosphor', fill='--panel', width=1.6, rx=3)
    f.text(360, 140, 'desk', size=13, mono=True, weight='600')
    f.text(360, 165, T('the file is readable here', 'aqui o arquivo é legível'), size=9.5, fill='--phosphor')
    doors = [
        (110, 50, T('mail', 'e-mail'), T('gateway reads attachments', 'gateway lê anexos')),
        (610, 50, T('web upload', 'upload pela web'), T('encrypted on the wire', 'cifrado na rede')),
        (610, 250, T('sync folder', 'pasta sincronizada'), T('encrypted on the wire', 'cifrado na rede')),
        (110, 250, T('USB stick', 'pendrive'), T('on the machine itself', 'na própria máquina')),
        (360, 268, T('printer', 'impressora'), T('on the machine itself', 'na própria máquina')),
    ]
    for x, y, name, note in doors:
        f.rect(x - 85, y - 22, 170, 44, stroke='--wire', fill='--panel', width=1.3, rx=3)
        f.text(x, y - 7, name, size=10.5, weight='600')
        f.text(x, y + 10, note, size=9, fill='--paper-dim')
    f.line(270, 125, 195, 65, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(450, 125, 525, 65, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(450, 175, 525, 235, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(270, 175, 195, 235, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(360, 190, 360, 246, stroke='--paper-dim', width=1.3, arrow=True)
    return f, T('Five doors. A network device reads one of them; the endpoint is in front of all five.',
                'Cinco portas. Um equipamento de rede lê uma delas; o endpoint fica na frente das cinco.')


@figure('l09-two-layers', 9)
def two_layers():
    f = Fig('l09-two-layers', 720, 250, T(
        'Two controls on desk. Top: a file copied into the outbox meets the guard, which runs the '
        'scanner and moves the client list to held, so the sync client never sees it. Bottom: curl '
        'reads the same file from docs, never passing the guard, and sends it towards trap; the '
        'egress rule drops it, while traffic to the portal on web is allowed.',
        'Dois controles no desk. Em cima: um arquivo copiado para o outbox encontra o guarda, que roda '
        'o scanner e move a lista de clientes para held, então o cliente de sincronização nunca a vê. '
        'Embaixo: o curl lê o mesmo arquivo de docs, sem passar pelo guarda, e o envia rumo ao trap; a '
        'regra de saída o descarta, enquanto o tráfego para o portal no web é permitido.'))
    f.text(20, 30, T('on the endpoint: the content', 'no endpoint: o conteúdo'), size=10.5, anchor='start',
           weight='600', fill='--paper-dim')
    f.rect(20, 50, 130, 40, stroke='--wire', fill='--panel', width=1.3, rx=3)
    f.text(85, 70, 'outbox/', size=10, mono=True)
    f.rect(210, 50, 170, 40, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(295, 70, T('guard: scan.py', 'guarda: scan.py'), size=10)
    f.rect(450, 50, 110, 40, stroke='--amber', fill='--panel', width=1.3, rx=3)
    f.text(505, 70, 'held/', size=10, mono=True)
    f.line(150, 70, 210, 70, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(380, 70, 450, 70, stroke='--amber', width=1.3, arrow=True)
    f.text(415, 98, T('personal data', 'dados pessoais'), size=9, fill='--amber')
    f.text(20, 140, T('on the network: the destination', 'na rede: o destino'), size=10.5, anchor='start',
           weight='600', fill='--paper-dim')
    f.rect(20, 160, 130, 40, stroke='--wire', fill='--panel', width=1.3, rx=3)
    f.text(85, 180, 'curl -T docs/…', size=10, mono=True)
    f.rect(210, 160, 170, 40, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(295, 180, T('egress allow-list', 'lista de saída'), size=10)
    f.rect(450, 140, 110, 34, stroke='--wire', fill='--panel', width=1.3, rx=3)
    f.text(505, 157, T('web: allowed', 'web: permitido'), size=9.5)
    f.rect(450, 190, 110, 34, stroke='--amber', fill='--panel', width=1.3, rx=3, dash='5 3')
    f.text(505, 207, T('trap: dropped', 'trap: descartado'), size=9.5, fill='--amber')
    f.line(150, 180, 210, 180, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(380, 172, 450, 157, stroke='--paper-dim', width=1.3, arrow=True)
    f.line(380, 188, 450, 207, stroke='--amber', width=1.3, arrow=True)
    f.text(640, 120, T('the upload never', 'o upload nunca'), size=9.5, fill='--paper-dim')
    f.text(640, 135, T('passed the guard', 'passou pelo guarda'), size=9.5, fill='--paper-dim')
    return f, T('The guard reads what goes into one folder. The allow-list reads only where traffic goes.',
                'O guarda lê o que entra numa pasta. A lista de saída só lê para onde o tráfego vai.')
