"""Lesson 12: sandboxing and running suspicious files in isolation."""
from figures import Fig, T, figure


@figure('l12-layers', 12)
def layers():
    f = Fig('l12-layers', 720, 250, T(
        'Four layers of isolation drawn side by side, each box\'s border as thick as its wall. A '
        'confined process shares the kernel with everything else. A container also shares that '
        'kernel. A virtual machine has its own kernel on top of a hypervisor. Another computer shares '
        'nothing. Cost grows from left to right along with the strength of the wall.',
        'Quatro camadas de isolamento lado a lado, a borda de cada caixa tão grossa quanto a parede. '
        'Um processo confinado divide o kernel com todo o resto. Um contêiner também divide '
        'esse kernel. Uma máquina virtual tem kernel próprio sobre um hipervisor. Outro computador não '
        'divide nada. O custo cresce da esquerda para a direita junto com a força da parede.'))
    cols = [(T('confined process', 'processo confinado'), T('shared kernel', 'kernel dividido'), 1.2),
            (T('container', 'contêiner'), T('shared kernel', 'kernel dividido'), 1.6),
            (T('virtual machine', 'máquina virtual'), T('its own kernel', 'kernel próprio'), 3.0),
            (T('another computer', 'outro computador'), T('nothing shared', 'nada dividido'), 4.6)]
    for i, (name, kern, w) in enumerate(cols):
        x = 30 + i * 172
        f.rect(x, 50, 150, 130, stroke='--phosphor', fill='--panel', width=w, rx=4)
        f.text(x + 75, 100, name, size=10.5, weight='600')
        f.text(x + 75, 120, kern, size=9.5, fill='--paper-dim')
    f.line(40, 210, 680, 210, stroke='--paper-dim', width=1.3, arrow=True)
    f.text(40, 230, T('thinner wall, nearly free', 'parede mais fina, quase de graça'), size=9.5, anchor='start',
           fill='--paper-dim')
    f.text(680, 230, T('thicker wall, real cost', 'parede mais grossa, custo real'), size=9.5, anchor='end',
           fill='--paper-dim')
    f.text(360, 26, T('the line drawn by each wall is its thickness', 'a espessura de cada borda é a da parede'),
           size=11, weight='600', fill='--paper-dim')
    return f, T('Choose the layer by what you fear: a flaw in a trusted program, or a file built to escape.',
                'Escolha a camada pelo que você teme: uma falha num programa confiável, ou um arquivo feito para escapar.')


@figure('l12-attempts', 12)
def attempts():
    f = Fig('l12-attempts', 720, 230, T(
        'The script\'s three attempts and the wall that stopped each one inside systemd-run. Listing '
        'the SSH directory meets ProtectHome, which shows an empty home: the answer is no such file. '
        'Writing to /etc meets ProtectSystem=strict: read-only file system. Connecting to '
        '192.168.60.66 meets PrivateNetwork: network unreachable.',
        'As três tentativas do script e a parede que parou cada uma dentro do systemd-run. Listar o '
        'diretório SSH encontra o ProtectHome, que mostra um home vazio: a resposta é arquivo '
        'inexistente. Gravar em /etc encontra o ProtectSystem=strict: sistema de arquivos somente '
        'leitura. Conectar a 192.168.60.66 encontra o PrivateNetwork: rede inalcançável.'))
    rows = [(T('list ~/.ssh', 'listar ~/.ssh'), 'ProtectHome=tmpfs', 'ENOENT'),
            (T('write /etc/relatorio-was-here', 'gravar /etc/relatorio-was-here'), 'ProtectSystem=strict', 'EROFS'),
            (T('connect to 192.168.60.66:8443', 'conectar a 192.168.60.66:8443'), 'PrivateNetwork=yes', 'ENETUNREACH')]
    f.text(130, 26, T('the script tries', 'o script tenta'), size=10.5, weight='600', fill='--paper-dim')
    f.text(400, 26, T('the wall', 'a parede'), size=10.5, weight='600', fill='--paper-dim')
    f.text(615, 26, T('the kernel answers', 'o kernel responde'), size=10.5, weight='600', fill='--paper-dim')
    for i, (attempt, wall, err) in enumerate(rows):
        y = 50 + i * 58
        f.rect(20, y, 230, 38, stroke='--wire', fill='--panel', width=1.3, rx=3)
        f.text(135, y + 19, attempt, size=9.5)
        f.rect(310, y, 180, 38, stroke='--phosphor', fill='--scan', width=1.4, rx=3)
        f.text(400, y + 19, wall, size=9.5, mono=True)
        f.rect(550, y, 130, 38, stroke='--amber', fill='--panel', width=1.3, rx=3)
        f.text(615, y + 19, err, size=9.5, mono=True, fill='--amber')
        f.line(250, y + 19, 310, y + 19, stroke='--paper-dim', width=1.3, arrow=True)
        f.line(490, y + 19, 550, y + 19, stroke='--paper-dim', width=1.3, arrow=True)
    return f, T('Three attempts, three walls, and an answer from the kernel for each.',
                'Três tentativas, três paredes, e uma resposta do kernel para cada uma.')
