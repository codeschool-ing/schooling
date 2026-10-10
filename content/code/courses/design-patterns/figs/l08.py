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
