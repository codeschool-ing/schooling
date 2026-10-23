"""Lesson 10: Queues and messaging in enterprise integration."""
from figures import Fig, T, figure


def _msg(f, x, y, label, stroke='--phosphor', w=34):
    f.box(x, y, w, 22, [label], size=10, mono=True, stroke=stroke, rx=2)


@figure('l10-shapes', 10)
def shapes():
    f = Fig('l10-shapes', 720, 330, T(
        'Three panels side by side. Queue: a producer puts m1, m2 and m3 on one queue; consumer A '
        'receives m1 and m3 and consumer B receives m2, so each message goes to one consumer. Topic: '
        'a publisher sends m1 to m3 to a topic, which copies all three into two subscriptions, each '
        'read by its own consumer, so every subscription gets a copy. Log: a producer appends to a '
        'log of six numbered positions, 0 to 5; reader A is at offset 3 and reader B at offset 5, '
        'and reading removes nothing.',
        'Três painéis lado a lado. Fila: um produtor põe m1, m2 e m3 numa fila; o consumidor A recebe '
        'm1 e m3 e o consumidor B recebe m2, então cada mensagem vai para um consumidor. Tópico: um '
        'publicador manda m1 a m3 para um tópico, que copia as três para duas assinaturas, cada uma '
        'lida pelo seu consumidor, então toda assinatura recebe uma cópia. Log: um produtor acrescenta '
        'a um log de seis posições numeradas, de 0 a 5; o leitor A está no offset 3 e o leitor B no '
        'offset 5, e ler não remove nada.'))
    # ---- queue
    x0 = 0
    f.text(x0 + 115, 18, T('queue', 'fila'), size=12, weight='600')
    f.box(x0 + 115, 52, 110, 28, [T('producer', 'produtor')], stroke='--wire')
    f.rect(x0 + 50, 104, 130, 34, stroke='--phosphor', fill='--ink')
    for i, m in enumerate(['m3', 'm2', 'm1']):
        _msg(f, x0 + 77 + i * 38, 121, m)
    f.arrow([(x0 + 115, 66), (x0 + 115, 102)], stroke='--paper-dim')
    f.box(x0 + 60, 214, 92, 28, [T('consumer A', 'consumidor A')], stroke='--wire')
    f.box(x0 + 170, 214, 92, 28, [T('consumer B', 'consumidor B')], stroke='--wire')
    f.arrow([(x0 + 95, 138), (x0 + 65, 198)], stroke='--phosphor')
    f.arrow([(x0 + 135, 138), (x0 + 165, 198)], stroke='--phosphor')
    f.text(x0 + 52, 168, 'm1, m3', size=10, mono=True, anchor='end')
    f.text(x0 + 172, 168, 'm2', size=10, mono=True, anchor='start')
    f.lines(x0 + 115, 276, [T('each message goes', 'cada mensagem vai'),
                            T('to one consumer', 'para um consumidor')], size=10.5, fill='--amber',
            italic=True)
    f.line(238, 30, 238, 310, stroke='--wire', width=1, dash='4 4')
    # ---- topic
    x0 = 242
    f.text(x0 + 118, 18, T('topic', 'tópico'), size=12, weight='600')
    f.box(x0 + 118, 52, 110, 28, [T('publisher', 'publicador')], stroke='--wire')
    f.box(x0 + 118, 104, 110, 26, [T('topic', 'tópico')], stroke='--phosphor')
    f.arrow([(x0 + 118, 66), (x0 + 118, 89)], stroke='--paper-dim')
    for cx, who in ((x0 + 62, T('subscription 1', 'assinatura 1')), (x0 + 174, T('subscription 2', 'assinatura 2'))):
        f.rect(cx - 52, 150, 104, 30, stroke='--phosphor', fill='--ink')
        for i, m in enumerate(['m3', 'm2', 'm1']):
            _msg(f, cx - 33 + i * 33, 165, m, w=28)
        f.text(cx, 192, who, size=9.5, fill='--paper-dim')
        f.box(cx, 230, 92, 28, [T('consumer', 'consumidor')], stroke='--wire')
        f.arrow([(cx, 200), (cx, 214)], stroke='--phosphor')
    f.arrow([(x0 + 100, 117), (x0 + 70, 148)], stroke='--phosphor')
    f.arrow([(x0 + 136, 117), (x0 + 166, 148)], stroke='--phosphor')
    f.lines(x0 + 118, 276, [T('every subscription', 'toda assinatura'),
                            T('gets a copy', 'recebe uma cópia')], size=10.5, fill='--amber',
            italic=True)
    f.line(482, 30, 482, 310, stroke='--wire', width=1, dash='4 4')
    # ---- log
    x0 = 486
    f.text(x0 + 117, 18, 'log', size=12, weight='600')
    f.box(x0 + 117, 52, 110, 28, [T('producer', 'produtor')], stroke='--wire')
    for i in range(6):
        _msg(f, x0 + 20 + i * 35, 121, f'm{i}', w=33)
        f.text(x0 + 20 + i * 35, 146, str(i), size=9.5, fill='--paper-dim', mono=True)
    f.arrow([(x0 + 117, 66), (x0 + 117, 80), (x0 + 195, 80), (x0 + 195, 108)], stroke='--paper-dim')
    f.text(x0 + 158, 92, T('append', 'acrescenta'), size=9.5, fill='--paper-dim')
    for cx, who, off in ((x0 + 125, T('reader A', 'leitor A'), T('offset 3', 'offset 3')),
                         (x0 + 195, T('reader B', 'leitor B'), T('offset 5', 'offset 5'))):
        f.box(cx, 214, 66, 28, [who], stroke='--wire')
        f.arrow([(cx, 200), (cx, 158)], stroke='--phosphor')
        f.text(cx, 244, off, size=10, fill='--paper-dim')
    f.lines(x0 + 117, 282, [T('reading removes nothing;', 'ler não remove nada;'),
                            T('each reader keeps its offset', 'cada leitor guarda seu offset')],
            size=10.5, fill='--amber', italic=True)
    return f, T('The same three messages under three models. A queue shares them out, a topic copies '
                'them, and a log keeps them and lets each reader remember where it stopped.',
                'As mesmas três mensagens em três modelos. Uma fila as reparte, um tópico as copia, e '
                'um log as guarda e deixa cada leitor lembrar onde parou.')


def _lifelines(f, cols, top, bottom):
    for x, name, mono in cols:
        f.box(x, top, 112, 28, [name], mono=mono, stroke='--phosphor', size=10.5)
        f.line(x, top + 14, x, bottom, stroke='--wire', width=1, dash='3 4')


def _step(f, xa, xb, y, label, back=False, stroke=None, mono=False, fill='--paper'):
    d = 1 if xb > xa else -1
    st = stroke or ('--paper-dim' if back else '--phosphor')
    f.arrow([(xa + 4 * d, y), (xb - 6 * d, y)], stroke=st, width=1.3, dash='5 3' if back else None)
    f.text((xa + xb) / 2, y - 9, label, size=10, mono=mono, fill=fill)


def _cross(f, x, y):
    f.line(x - 7, y - 7, x + 7, y + 7, stroke='--amber', width=2.2)
    f.line(x - 7, y + 7, x + 7, y - 7, stroke='--amber', width=2.2)


@figure('l10-redelivery', 10)
def redelivery():
    f = Fig('l10-redelivery', 720, 340, T(
        'A sequence diagram read from top to bottom, with three lifelines: the broker, the consumer '
        'and the ledger database. The broker delivers m-2; the consumer inserts the payment and the '
        'ledger commits it. The consumer then crashes before acknowledging. The broker, which never '
        'heard an acknowledgement, still holds m-2 and delivers it again after a timeout. The '
        'consumer inserts the payment a second time and the ledger commits it, so the payment is '
        'recorded twice. Only then does the acknowledgement reach the broker.',
        'Um diagrama de sequência lido de cima para baixo, com três linhas de vida: o broker, o '
        'consumidor e o banco do razão. O broker entrega m-2; o consumidor insere o pagamento e o '
        'razão o grava. O consumidor então cai antes de confirmar. O broker, que nunca recebeu a '
        'confirmação, ainda guarda m-2 e o entrega de novo depois de um timeout. O consumidor insere '
        'o pagamento uma segunda vez e o razão grava, então o pagamento fica registrado duas vezes. '
        'Só então a confirmação chega ao broker.'))
    B, C, L = 110, 360, 610
    _lifelines(f, [(B, 'broker', False), (C, T('consumer', 'consumidor'), False),
                   (L, T('ledger', 'razão'), False)], 26, 312)
    _step(f, B, C, 70, T('deliver m-2', 'entrega m-2'))
    _step(f, C, L, 98, T('insert payment', 'insere pagamento'))
    _step(f, L, C, 126, T('committed', 'gravado'), back=True)
    _cross(f, C, 152)
    f.text(C + 16, 152, T('crash: no acknowledgement', 'queda: sem confirmação'), size=10.5,
           fill='--amber', anchor='start')
    f.lines(B - 6, 190, [T('timeout: m-2', 'timeout: m-2'), T('still held', 'ainda guardada')],
            size=10, fill='--paper-dim', anchor='end')
    _step(f, B, C, 218, T('deliver m-2 again', 'entrega m-2 de novo'))
    _step(f, C, L, 246, T('insert payment again', 'insere o pagamento de novo'), stroke='--amber')
    _step(f, L, C, 274, T('committed: recorded twice', 'gravado: registrado duas vezes'), back=True,
          fill='--amber')
    _step(f, C, B, 302, T('acknowledge', 'confirma'), back=True)
    return f, T('Acknowledging after the work loses nothing. A crash between the work and the '
                'acknowledgement means the work is done twice, unless the consumer can tell.',
                'Confirmar depois do trabalho não perde nada. Uma queda entre o trabalho e a '
                'confirmação faz o trabalho duas vezes, a menos que o consumidor perceba.')


@figure('l10-outbox', 10)
def outbox():
    f = Fig('l10-outbox', 720, 380, T(
        'A sequence diagram with five lifelines: the portal, the portal database, the relay, the '
        'queue and the consumer. The portal writes the payment and outbox row portal-1 in one '
        'transaction. The relay reads the unsent rows and publishes portal-1 to the queue, then '
        'stops before marking it sent. On restart it reads the unsent rows again, finds portal-1 '
        'still there, publishes it a second time, and marks it sent. The queue delivers both copies '
        'to the consumer, which applies the first and skips the second because its id is already '
        'processed.',
        'Um diagrama de sequência com cinco linhas de vida: o portal, o banco do portal, o relay, a '
        'fila e o consumidor. O portal grava o pagamento e a linha de outbox portal-1 numa transação. '
        'O relay lê as linhas não enviadas e publica portal-1 na fila, e então para antes de '
        'marcá-la como enviada. Ao reiniciar, lê de novo as linhas não enviadas, encontra portal-1 '
        'ainda ali, publica-a uma segunda vez e a marca como enviada. A fila entrega as duas cópias ao '
        'consumidor, que aplica a primeira e pula a segunda porque o id dela já foi processado.'))
    P, D, R, Q, C = 72, 216, 360, 504, 648
    _lifelines(f, [(P, 'portal', False), (D, T('portal database', 'banco do portal'), False),
                   (R, 'relay', False), (Q, T('queue', 'fila'), False),
                   (C, T('consumer', 'consumidor'), False)], 26, 352)
    f.text((P + D) / 2, 64, T('one transaction', 'uma transação'), size=9.5, fill='--paper-dim', italic=True)
    _step(f, P, D, 90, T('payment + portal-1', 'pagamento + portal-1'))
    _step(f, R, D, 128, T('read unsent', 'lê não enviadas'))
    _step(f, R, Q, 156, T('publish portal-1', 'publica portal-1'))
    _cross(f, R, 182)
    f.text(R + 16, 182, T('stops before marking sent', 'para antes de marcar enviada'), size=10,
           fill='--amber', anchor='start')
    _step(f, R, D, 216, T('read unsent: portal-1 again', 'lê não enviadas: portal-1 de novo'))
    _step(f, R, Q, 244, T('publish portal-1', 'publica portal-1'), stroke='--amber')
    _step(f, R, D, 272, T('mark sent', 'marca enviada'))
    _step(f, Q, C, 304, 'portal-1')
    f.text(C - 8, 318, T('applied', 'aplicada'), size=10, fill='--paper-dim', anchor='end')
    _step(f, Q, C, 340, 'portal-1', stroke='--amber')
    f.text(C - 8, 354, T('skipped: processed', 'pulada: processada'), size=10, fill='--paper-dim',
           anchor='end')
    return f, T('The outbox turns a lost message into a duplicated one, and the idempotent consumer '
                'turns the duplicate into nothing. The id is fixed in the outbox row, so both copies '
                'carry the same one.',
                'O outbox transforma uma mensagem perdida numa mensagem duplicada, e o consumidor '
                'idempotente transforma a duplicata em nada. O id é fixado na linha do outbox, então '
                'as duas cópias levam o mesmo.')


@figure('l10-backoff', 10)
def backoff():
    f = Fig('l10-backoff', 720, 200, T(
        'A time axis from 0 to 31 seconds. Six attempts, marked at 0, 1, 3, 7, 15 and 31 seconds, '
        'all failing. Between them the waits double: 1, 2, 4, 8 and 16 seconds, 31 seconds of '
        'waiting in all. After the sixth attempt the message moves to the dead-letter queue, which '
        'has an owner, an alarm and a runbook.',
        'Um eixo de tempo de 0 a 31 segundos. Seis tentativas, marcadas em 0, 1, 3, 7, 15 e 31 '
        'segundos, todas falhando. Entre elas as esperas dobram: 1, 2, 4, 8 e 16 segundos, 31 '
        'segundos de espera no total. Depois da sexta tentativa a mensagem vai para a fila de '
        'mensagens mortas, que tem dono, alarme e runbook.'))
    x0, k, y = 30, 16, 110
    marks = [0, 1, 3, 7, 15, 31]
    for a, b in zip(marks, marks[1:]):
        f.rect(x0 + a * k + 2, y - 9, (b - a) * k - 4, 18, stroke=None, fill='--scan', rx=2)
        f.text(x0 + (a + b) / 2 * k, y - 22 if b - a < 4 else y, f'{b - a} s', size=10,
               fill='--paper' if b - a >= 4 else '--paper-dim')
    for i, t in enumerate(marks):
        f.circle(x0 + t * k, y, 5, fill='--amber')
        f.text(x0 + t * k, y + 22, f'{t}', size=9.5, fill='--paper-dim', mono=True)
    f.text(x0 + 15.5 * k, y + 44, T('seconds since the first attempt', 'segundos desde a primeira tentativa'),
           size=10, fill='--paper-dim')
    f.text(x0 + 15.5 * k, 46, T('6 attempts, all failed: 31 s of waiting', '6 tentativas, todas falharam: 31 s de espera'),
           size=11, weight='600')
    f.arrow([(x0 + 31 * k + 8, y), (600, y)], stroke='--amber', width=1.4)
    f.box(658, y, 112, 74, [T('dead-letter', 'fila de'), T('queue', 'mensagens mortas')],
          stroke='--amber', size=10.5)
    f.lines(658, 166, [T('owner · alarm', 'dono · alarme'), T('runbook', 'runbook')], size=10,
            fill='--paper-dim')
    return f, T('Exponential backoff: each wait doubles, so five retries cost 31 seconds and a sixth '
                'would add 32 more. When the attempts run out, the message is moved aside and the '
                'queue carries on.',
                'Backoff exponencial: cada espera dobra, então cinco retentativas custam 31 segundos e '
                'uma sexta somaria mais 32. Quando as tentativas acabam, a mensagem é posta de lado e '
                'a fila segue.')


@figure('l10-ordering', 10)
def ordering():
    f = Fig('l10-ordering', 720, 300, T(
        'Two panels with the same arrivals, read from top to bottom. In both, instance B applies '
        'R$ 12,00, version 42, first, and instance A applies R$ 10,00, version 41, after it, because A '
        'was slow. Left, with no version check, the later write wins and the portal shows R$ 10,00 '
        'while SAP says R$ 12,00. Right, with a version check, A finds that 41 is older than the 42 '
        'already stored, changes no row, and the portal shows R$ 12,00.',
        'Dois painéis com as mesmas chegadas, lidos de cima para baixo. Nos dois, a instância B aplica '
        'R$ 12,00, versão 42, primeiro, e a instância A aplica R$ 10,00, versão 41, depois, porque A '
        'estava lenta. À esquerda, sem conferir a versão, a última escrita vence e o portal mostra '
        'R$ 10,00 enquanto o SAP diz R$ 12,00. À direita, conferindo a versão, A vê que 41 é mais '
        'antiga que a 42 já gravada, não muda nenhuma linha, e o portal mostra R$ 12,00.'))
    for x0, title, second, result, ok in (
            (0, T('no version check', 'sem conferir a versão'),
             T('A: sets R$ 10,00 (v41)', 'A: grava R$ 10,00 (v41)'),
             T('portal R$ 10,00, SAP R$ 12,00', 'portal R$ 10,00, SAP R$ 12,00'), False),
            (364, T('with a version check', 'conferindo a versão'),
             T('A: 41 < 42, no row changed', 'A: 41 < 42, nenhuma linha muda'),
             T('portal R$ 12,00, SAP R$ 12,00', 'portal R$ 12,00, SAP R$ 12,00'), True)):
        f.text(x0 + 178, 20, title, size=12, weight='600')
        f.box(x0 + 178, 58, 300, 30, [T('queue: v41 R$ 10,00, then v42 R$ 12,00', 'fila: v41 R$ 10,00, depois v42 R$ 12,00')],
              stroke='--wire')
        f.arrow([(x0 + 178, 74), (x0 + 178, 100)], stroke='--paper-dim')
        f.box(x0 + 178, 124, 300, 30, [T('B: sets R$ 12,00 (v42)', 'B: grava R$ 12,00 (v42)')],
              stroke='--phosphor')
        f.arrow([(x0 + 178, 140), (x0 + 178, 166)], stroke='--paper-dim')
        f.box(x0 + 178, 190, 300, 30, [second], stroke='--amber' if not ok else '--phosphor')
        f.arrow([(x0 + 178, 206), (x0 + 178, 232)], stroke='--paper-dim')
        f.box(x0 + 178, 256, 300, 32, [result], stroke='--amber' if not ok else '--phosphor',
              fill='--ink', fillt='--amber' if not ok else '--paper')
    f.line(360, 30, 360, 285, stroke='--wire', width=1, dash='4 4')
    return f, T('Two consumers finish the butter\'s two prices in the wrong order. Without a version the '
                'older price overwrites the newer; with one, the older price changes nothing.',
                'Dois consumidores terminam os dois preços da manteiga na ordem errada. Sem versão, o '
                'preço mais antigo sobrescreve o mais novo; com versão, o mais antigo não muda nada.')
