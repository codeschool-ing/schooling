"""Lesson 8: CQRS."""
from figures import Fig, T, figure


@figure('l08-split', 8)
def split():
    f = Fig('l08-split', 720, 320, T(
        'The CQRS split for the library. On the left, the desk. Along the top, the command side: '
        'the desk sends a command such as LendCopy to handle, which calls the write model, '
        'Lending, which holds only who has each copy and who is waiting, and enforces the rules. '
        'When a command succeeds, Lending publishes an event such as CopyLent. A projector on the '
        'right receives the event and updates the read model along the bottom, an availability '
        'table with one row per title, its author, the copies on the shelf and the number waiting. '
        'The query side: the desk asks the read model with a SELECT and gets rows back, without '
        'going near the write model.',
        'A divisão do CQRS para a biblioteca. À esquerda, o balcão. Em cima, o lado dos comandos: o '
        'balcão manda um comando como LendCopy para handle, que chama o modelo de escrita, Lending, '
        'que guarda só quem está com cada exemplar e quem está esperando, e aplica as regras. Quando '
        'um comando dá certo, Lending publica um evento como CopyLent. Um projetor à direita recebe '
        'o evento e atualiza o modelo de leitura embaixo, uma tabela de disponibilidade com uma linha '
        'por título, o autor, os exemplares na estante e quantos esperam. O lado das consultas: o '
        'balcão pergunta ao modelo de leitura com um SELECT e recebe linhas de volta, sem chegar '
        'perto do modelo de escrita.'))
    f.text(360, 22, T('command side: rules, one model', 'lado dos comandos: regras, um modelo'),
           size=11, weight='600')
    f.text(360, 304, T('query side: shaped for screens, as many as needed', 'lado das consultas: moldado para as telas, quantos forem precisos'),
           size=11, weight='600')
    f.line(150, 162, 580, 162, stroke='--wire', width=1, dash='4 4')
    f.box(75, 162, 110, 46, [T('the desk', 'o balcão')], stroke='--phosphor', size=11)
    f.box(270, 80, 110, 34, ['handle()'], mono=True, stroke='--phosphor', size=10.5)
    f.klass(400, 50, 150, 'Lending', ['holder', 'waiting'], ['lend()', 'give_back()'])
    f.box(640, 162, 100, 34, [T('projector', 'projetor')], stroke='--phosphor', size=10.5)
    f.klass(380, 206, 190, 'availability', ['title, author', 'on_shelf, waiting'], [], stereo='«table»')
    # command path
    f.arrow([(75, 139), (75, 80), (213, 80)], stroke='--phosphor', width=1.4)
    f.text(140, 70, 'LendCopy', size=9.5, mono=True)
    f.arrow([(325, 80), (398, 80)], stroke='--phosphor', width=1.4)
    f.text(362, 70, 'lend', size=9.5, mono=True)
    f.arrow([(550, 80), (640, 80), (640, 143)], stroke='--amber', width=1.4)
    f.text(596, 70, 'CopyLent', size=9.5, mono=True, fill='--amber')
    f.arrow([(640, 179), (640, 240), (572, 240)], stroke='--amber', width=1.4)
    f.text(668, 212, 'UPDATE', size=9.5, mono=True, fill='--amber')
    # query path
    f.arrow([(75, 185), (75, 236), (378, 236)], stroke='--phosphor', width=1.4)
    f.text(220, 226, 'SELECT', size=9.5, mono=True)
    f.arrow([(378, 260), (95, 260), (95, 187)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.text(220, 271, T('rows', 'linhas'), size=9.5, fill='--paper-dim')
    return f, T('Commands go through the rules and change the write model; an event carries the change to the read model, which answers every query.',
                'Os comandos passam pelas regras e mudam o modelo de escrita; um evento leva a mudança ao modelo de leitura, que responde a toda consulta.')


@figure('l08-lag', 8)
def lag():
    f = Fig('l08-lag', 720, 270, T(
        'A timeline of the asynchronous run of lag.py, left to right. Upper lane, the write model: '
        'C1 is lent to Bia, then C2 to Caio, and after each the write model knows the new number of '
        'copies on the shelf, 1 and then 0. Lower lane, the read model: it still says 2 after both '
        'loans, because the two events are waiting in the outbox. When the worker runs, it applies '
        'both and the read model says 0. The stretch between the first loan and the worker run is '
        'the window in which a query sees the old value.',
        'Uma linha do tempo da execução assíncrona de lag.py, da esquerda para a direita. Faixa de '
        'cima, o modelo de escrita: C1 é emprestado à Bia, depois C2 ao Caio, e depois de cada um o '
        'modelo de escrita sabe o novo número de exemplares na estante, 1 e depois 0. Faixa de baixo, '
        'o modelo de leitura: ele continua dizendo 2 depois dos dois empréstimos, porque os dois '
        'eventos estão esperando na caixa de saída. Quando o worker roda, aplica os dois e o modelo '
        'de leitura diz 0. O trecho entre o primeiro empréstimo e a execução do worker é a janela '
        'em que uma consulta vê o valor antigo.'))
    f.text(20, 70, T('write model', 'modelo de escrita'), size=11, weight='600', anchor='start')
    f.text(20, 170, T('read model', 'modelo de leitura'), size=11, weight='600', anchor='start')
    f.line(230, 170, 570, 170, stroke='--scan', width=40)
    f.arrow([(140, 70), (700, 70)], stroke='--paper-dim', width=1.2)
    f.arrow([(140, 170), (700, 170)], stroke='--paper-dim', width=1.2)
    f.text(690, 248, T('time', 'tempo'), size=10, fill='--paper-dim', anchor='end')
    for x, label, shelf in ((230, 'lend C1', '1'), (380, 'lend C2', '0')):
        f.circle(x, 70, 5, fill='--phosphor')
        f.text(x, 48, label, size=10, mono=True)
        f.text(x + 40, 88, T(f'on shelf {shelf}', f'na estante {shelf}'), size=10, fill='--paper-dim')
        f.arrow([(x, 76), (x, 108)], stroke='--amber', width=1.2, dash='4 3')
        f.text(x, 120, T('event queued', 'evento na fila'), size=9.5, fill='--amber', italic=True)
    f.text(160, 188, T('on shelf 2', 'na estante 2'), size=10, fill='--paper-dim')
    f.text(400, 205, T('stale: on shelf 2, events waiting', 'desatualizado: na estante 2, eventos esperando'),
           size=10, fill='--amber', italic=True)
    f.circle(570, 170, 5, fill='--amber')
    f.text(570, 140, T('worker applies both', 'o worker aplica os dois'), size=10, fill='--amber')
    f.text(630, 188, T('on shelf 0', 'na estante 0'), size=10, fill='--paper-dim')
    return f, T('The write model is right at once; the read model is right after the worker has run. The shaded stretch is the lag a reader can see.',
                'O modelo de escrita fica certo na hora; o de leitura, depois que o worker roda. O trecho sombreado é o atraso que um leitor consegue ver.')
