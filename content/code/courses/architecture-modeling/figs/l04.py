"""Lesson 4: flows, state machines and context maps."""
from figures import Fig, T, figure, picture


def action(f, x, y, w, rows, size=9, h=30, words=True, stroke='--phosphor'):
    f.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill='--panel', rx=10, width=1.4)
    if words:
        f.lines(x, y, [rows] if isinstance(rows, str) else rows, size=size)


def bar(f, x, y, w):
    f.rect(x - w / 2, y - 3, w, 6, stroke=None, fill='--paper', rx=1)


def activity_drawing(f, words=True):
    t = f.text if words else (lambda *a, **k: None)
    lanes = [(20, 200, T('Passenger', 'Passageiro')), (200, 520, T('Ticketing', 'Venda de passagens')),
             (520, 700, T('Payment gateway', 'Gateway de pagamento'))]
    for x0, x1, n in lanes:
        f.rect(x0, 14, x1 - x0, 466, stroke='--wire', fill='--ink', rx=0, width=1)
        f.line(x0, 40, x1, 40, stroke='--wire', width=1)
        t((x0 + x1) / 2, 27, n, size=10, weight='600')
    A = dict(stroke='--paper', width=1.2)
    f.start(110, 62)
    f.arrow([(110, 69), (110, 86)], **A)
    action(f, 110, 102, 120, T('Ask to cancel', 'Pede cancelamento'), words=words)
    f.arrow([(170, 102), (298, 102)], **A)
    action(f, 360, 102, 120, T('Check departure', 'Confere a partida'), words=words)
    f.arrow([(360, 117), (360, 144)], **A)
    f.diamond(360, 158, 13)
    # after departure: left
    f.arrow([(347, 158), (296, 158)], **A)
    action(f, 250, 158, 90, [T('Refuse', 'Recusa')], words=words)
    t(322, 146, T('[after]', '[depois]'), size=8.5, fill='--amber', mono=True)
    # < 3 h: right
    f.arrow([(373, 158), (414, 158)], **A)
    action(f, 465, 158, 100, [T('Offer change', 'Oferece troca'), T('for a fee', 'com taxa')], h=36, words=words)
    t(394, 146, '[< 3 h]', size=8.5, fill='--amber', mono=True)
    # >= 3 h: down to fork
    f.arrow([(360, 171), (360, 205)], **A)
    t(366, 188, '[≥ 3 h]', size=8.5, anchor='start', fill='--amber', mono=True)
    bar(f, 360, 210, 140)
    f.arrow([(310, 213), (310, 250)], **A)
    f.arrow([(410, 213), (430, 250)], **A)
    action(f, 310, 265, 90, T('Release seat', 'Libera assento'), words=words)
    action(f, 440, 265, 100, T('Request refund', 'Pede estorno'), words=words)
    f.arrow([(490, 265), (550, 265)], **A)
    action(f, 610, 265, 110, T('Refund card', 'Estorna cartão'), words=words)
    f.arrow([(310, 280), (310, 330)], **A)
    f.arrow([(610, 280), (610, 336), (432, 336)], **A)
    bar(f, 360, 336, 140)
    f.diamond(360, 382, 11)
    f.arrow([(360, 339), (360, 370)], **A)
    f.arrow([(250, 173), (250, 382), (348, 382)], **A)
    f.arrow([(505, 176), (505, 382), (372, 382)], **A)
    f.arrow([(360, 393), (360, 412)], **A)
    action(f, 360, 427, 130, T('Notify passenger', 'Avisa o passageiro'), words=words)
    f.arrow([(360, 442), (360, 456)], **A)
    f.end(360, 467)


@figure('l04-activity', 4)
def activity():
    f = Fig('l04-activity', 720, 490, T(
        'An activity diagram of cancelling a ticket, in three swimlanes: passenger, ticketing and the '
        'payment gateway. From the start node, the passenger asks to cancel; ticketing checks the '
        'departure; a decision splits three ways. After departure: refuse. Less than three hours '
        'before: offer a change for a fee. Three hours or more before: a fork starts two parallel '
        'flows, release the seat in ticketing, and request a refund, which the payment gateway '
        'carries out by refunding the card. A join waits for both. The three paths meet at a merge, '
        'ticketing notifies the passenger, and the activity ends.',
        'Um diagrama de atividade do cancelamento de uma passagem, em três raias: passageiro, venda de '
        'passagens e gateway de pagamento. Do nó inicial, o passageiro pede o cancelamento; a venda '
        'confere a partida; uma decisão se divide em três. Depois da partida: recusa. Menos de três '
        'horas antes: oferece troca com taxa. Três horas ou mais antes: um fork abre dois fluxos '
        'paralelos, liberar o assento na venda, e pedir o estorno, que o gateway de pagamento executa '
        'estornando o cartão. Um join espera os dois. Os três caminhos se encontram num merge, a venda '
        'avisa o passageiro, e a atividade termina.'))
    activity_drawing(f)
    return f, T('The fork says the refund and the seat release do not wait for each other; the join says the passenger hears nothing until both are done. The third guard is the case the written policy forgot.',
                'O fork diz que o estorno e a liberação do assento não esperam um pelo outro; o join diz que o passageiro não fica sabendo de nada até os dois terminarem. A terceira guarda é o caso que a política escrita esqueceu.')


@picture('activity-shapes')
def activity_picture():
    f = Fig('activity-shapes', 720, 490, '')
    activity_drawing(f, words=False)
    return f


@figure('l04-bpmn', 4)
def bpmn():
    f = Fig('l04-bpmn', 720, 330, T(
        'The same cancellation in BPMN, with three pools. The passenger and the payment company are '
        'collapsed pools, empty bands. Carcará\'s pool holds the process: a message start event, '
        'cancellation requested, receives a message flow from the passenger; a task checks the '
        'departure; an exclusive gateway marked X chooses; for three hours or more, a parallel gateway '
        'marked plus starts release seat and request refund; request refund sends a message to the '
        'payment company, and an intermediate event waits for the refund confirmed message; a second '
        'parallel gateway joins them; a task notifies the passenger and an end event closes the '
        'process. For less than three hours, a task offers a change and goes to the end.',
        'O mesmo cancelamento em BPMN, com três pools. O passageiro e a empresa de pagamento são '
        'pools recolhidos, faixas vazias. O pool da Carcará guarda o processo: um evento de início por '
        'mensagem, cancelamento pedido, recebe um fluxo de mensagem do passageiro; uma tarefa confere a '
        'partida; um gateway exclusivo marcado com X escolhe; para três horas ou mais, um gateway '
        'paralelo marcado com mais abre liberar assento e pedir estorno; pedir estorno manda uma '
        'mensagem à empresa de pagamento, e um evento intermediário espera a mensagem de estorno '
        'confirmado; um segundo gateway paralelo junta os dois; uma tarefa avisa o passageiro e um '
        'evento de fim encerra o processo. Para menos de três horas, uma tarefa oferece a troca e vai '
        'para o fim.'))
    def pool(y, h, name):
        f.rect(20, y, 680, h, stroke='--paper-dim', fill='--ink', rx=0, width=1.2)
        f.rect(20, y, 26, h, stroke='--paper-dim', fill='--panel', rx=0, width=1.2)
        f.text(33, y + h / 2, name, size=9, weight='600')
    pool(14, 34, T('P', 'P'))
    f.text(370, 31, T('Passenger (collapsed pool)', 'Passageiro (pool recolhido)'), size=9.5, fill='--paper-dim', italic=True)
    pool(70, 196, 'C')
    f.text(56, 84, 'Carcará', size=9.5, anchor='start', weight='600')
    pool(288, 34, T('G', 'G'))
    f.text(370, 305, T('Payment company (collapsed pool)', 'Empresa de pagamento (pool recolhido)'), size=9.5,
           fill='--paper-dim', italic=True)
    S = dict(stroke='--paper', width=1.2)
    f.circle(80, 150, 11, fill='--panel', stroke='--paper', width=1.2)
    f.rect(73, 145, 14, 10, stroke='--paper', fill='--panel', rx=0, width=1)
    f.path('M73 145 L80 151 L87 145', stroke='--paper', width=1)
    f.arrow([(91, 150), (112, 150)], **S)
    action(f, 155, 150, 82, [T('Check', 'Confere'), T('departure', 'partida')], h=36, stroke='--paper')
    f.arrow([(196, 150), (218, 150)], **S)
    f.diamond(232, 150, 14, stroke='--paper')
    f.text(232, 150.5, '×', size=13, weight='600')
    f.arrow([(232, 164), (232, 236), (272, 236)], **S)
    f.text(238, 200, '< 3 h', size=8.5, anchor='start', fill='--amber', mono=True)
    action(f, 320, 236, 92, T('Offer change', 'Oferece troca'), stroke='--paper')
    f.arrow([(366, 236), (650, 236), (650, 163)], **S)
    f.arrow([(246, 150), (268, 150)], **S)
    f.text(240, 126, '≥ 3 h', size=8.5, anchor='start', fill='--amber', mono=True)
    f.diamond(282, 150, 14, stroke='--paper')
    f.text(282, 150.5, '+', size=13, weight='600')
    f.arrow([(282, 136), (282, 112), (318, 112)], **S)
    f.arrow([(282, 164), (282, 186), (318, 186)], **S)
    action(f, 365, 112, 92, T('Release seat', 'Libera assento'), stroke='--paper')
    action(f, 365, 186, 92, T('Request refund', 'Pede estorno'), stroke='--paper')
    f.arrow([(411, 186), (440, 186)], **S)
    f.circle(452, 186, 11, fill='--panel', stroke='--paper', width=1.2)
    f.circle(452, 186, 8, fill=None, stroke='--paper', width=1)
    f.arrow([(463, 186), (492, 186), (492, 164)], **S)
    f.arrow([(411, 112), (492, 112), (492, 136)], **S)
    f.diamond(492, 150, 14, stroke='--paper')
    f.text(492, 150.5, '+', size=13, weight='600')
    f.arrow([(506, 150), (540, 150)], **S)
    action(f, 588, 150, 94, [T('Notify', 'Avisa o'), T('passenger', 'passageiro')], h=36, stroke='--paper')
    f.arrow([(635, 150), (638, 150)], **S)
    f.circle(650, 150, 11, fill='--panel', stroke='--paper', width=3)
    M = dict(stroke='--paper-dim', width=1.1, dash='5 3', head='open')
    f.circle(80, 50, 3, fill=None, stroke='--paper-dim', width=1)
    f.arrow([(80, 53), (80, 137)], **M)
    f.circle(365, 203, 3, fill=None, stroke='--paper-dim', width=1)
    f.arrow([(365, 206), (365, 286)], **M)
    f.circle(452, 288, 3, fill=None, stroke='--paper-dim', width=1)
    f.arrow([(452, 285), (452, 199)], **M)
    f.text(372, 262, T('refund', 'estorno'), size=8.5, anchor='start', fill='--paper-dim')
    f.text(458, 262, T('confirmed', 'confirmado'), size=8.5, anchor='start', fill='--paper-dim')
    return f, T('Inside Carcará\'s pool the steps follow each other; between pools only messages pass, drawn dashed. That line is the boundary lesson 3 drew as a grey box.',
                'Dentro do pool da Carcará, os passos se seguem; entre pools só passam mensagens, tracejadas. Essa linha é a fronteira que a aula 3 desenhou como uma caixa cinza.')


def state_drawing(f, words=True):
    t = f.text if words else (lambda *a, **k: None)
    st = {'held': (170, 130, T('Held', 'Reservada')), 'paid': (400, 130, T('Paid', 'Paga')),
          'boarded': (610, 50, T('Boarded', 'Embarcada')), 'refunded': (610, 150, T('Refunded', 'Estornada')),
          'noshow': (610, 250, T('No-show', 'Não embarcou')), 'expired': (170, 280, T('Expired', 'Expirada'))}
    for k, (x, y, n) in st.items():
        f.state(x, y, 120 if k != 'held' else 150, 40 if k != 'held' else 54, '' if True else n)
        if words:
            if k == 'held':
                f.text(x, y - 8, n, size=10.5, weight='600')
                f.text(x, y + 10, T('entry / start 10-min timer', 'entrada / timer de 10 min'), size=8, fill='--paper-dim', mono=True)
            else:
                f.text(x, y, n, size=10.5, weight='600')
    f.start(30, 130)
    A = dict(stroke='--paper', width=1.3)
    f.arrow([(37, 130), (93, 130)], **A)
    f.arrow([(245, 130), (338, 130)], **A)
    t(292, 120, T('payment approved', 'pagamento aprovado'), size=8.5)
    f.arrow([(170, 157), (170, 258)], **A)
    t(178, 200, T('10 min pass', 'passam 10 min'), size=8.5, anchor='start')
    t(178, 214, T('/ release seat', '/ libera assento'), size=8.5, anchor='start', mono=True)
    f.path('M140 103 C140 60, 200 60, 200 103', stroke='--paper', width=1.3, arrow=True)
    t(170, 56, T('payment declined', 'pagamento recusado'), size=8.5)
    f.arrow([(460, 120), (548, 58)], **A)
    t(492, 76, T('scanned at the door', 'lida na porta'), size=8.5, anchor='end')
    f.arrow([(460, 136), (548, 148)], **A)
    t(500, 158, T('cancelled [≥ 3 h]', 'cancelada [≥ 3 h]'), size=8.5, anchor='middle')
    t(500, 172, '/ ' + T('refund', 'estorno'), size=8.5, mono=True)
    f.arrow([(440, 150), (550, 240)], **A)
    t(470, 222, T('departed', 'partiu'), size=8.5, anchor='end')
    t(470, 236, T('[not scanned]', '[não lida]'), size=8.5, anchor='end', mono=True)


@figure('l04-state', 4)
def state():
    f = Fig('l04-state', 720, 310, T(
        'A state machine of a Carcará ticket. From the initial pseudostate, the ticket starts in Held, '
        'whose entry action starts a ten-minute timer. Payment declined is a transition from Held back '
        'to Held. Payment approved moves Held to Paid. Ten minutes passing moves Held to Expired and '
        'releases the seat. From Paid: scanned at the door moves to Boarded; cancelled, three hours or '
        'more before departure, refunds and moves to Refunded; departed without being scanned moves to '
        'No-show.',
        'Uma máquina de estados de uma passagem da Carcará. Do pseudoestado inicial, a passagem começa '
        'em Reservada, cuja ação de entrada inicia um timer de dez minutos. Pagamento recusado é uma '
        'transição de Reservada para ela mesma. Pagamento aprovado leva de Reservada a Paga. Passar dez '
        'minutos leva de Reservada a Expirada e libera o assento. De Paga: lida na porta leva a '
        'Embarcada; cancelada, três horas ou mais antes da partida, estorna e leva a Estornada; partiu '
        'sem ser lida leva a Não embarcou.'))
    state_drawing(f)
    return f, T('Seven transitions, each labelled event [guard] / action. The happy path is the top row; most of the value is in the other arrows.',
                'Sete transições, cada uma com o rótulo evento [guarda] / ação. O caminho feliz é a linha de cima; quase todo o valor está nas outras setas.')


@picture('state-shapes')
def state_picture():
    f = Fig('state-shapes', 720, 310, '')
    state_drawing(f, words=False)
    return f


@figure('l04-context-map', 4)
def context_map():
    f = Fig('l04-context-map', 720, 380, T(
        'Carcará\'s context map. Fleet, the Frota system, is upstream of Sales, and Sales has an '
        'anticorruption layer at its end. Pricing is upstream of Sales as customer and supplier. Sales '
        'and Payments are in partnership. The payment gateway, external, is upstream of Payments as an '
        'open host service, and Payments has an anticorruption layer. Sales is upstream of Boarding '
        'with an open host service and published language, and Boarding is conformist. Sales is '
        'upstream of Notifications with an open host service, and Notifications is conformist. '
        'Finance stands alone: separate ways.',
        'O mapa de contextos da Carcará. Frota é upstream de Vendas, e Vendas tem uma camada '
        'anticorrupção na sua ponta. Preços é upstream de Vendas como fornecedor e cliente. Vendas e '
        'Pagamentos estão em parceria. O gateway de pagamento, externo, é upstream de Pagamentos como '
        'serviço de host aberto, e Pagamentos tem uma camada anticorrupção. Vendas é upstream de '
        'Embarque com serviço de host aberto e linguagem publicada, e Embarque é conformista. Vendas é '
        'upstream de Notificações com serviço de host aberto, e Notificações é conformista. Finanças '
        'fica sozinha: caminhos separados.'))
    def ctx(x, y, n, team, ext=False):
        f.rect(x - 75, y - 24, 150, 48, stroke='--paper-dim' if ext else '--phosphor', fill='--panel', rx=16,
               width=1.5, dash='5 3' if ext else None)
        f.text(x, y - 6, n, size=10.5, weight='600')
        f.text(x, y + 10, team, size=8.5, fill='--paper-dim')
    ctx(110, 60, T('Fleet', 'Frota'), T('Frota, bought in 2009', 'sistema comprado em 2009'))
    ctx(360, 60, T('Pricing', 'Preços'), T('Pricing team', 'time de Preços'))
    ctx(360, 190, T('Sales', 'Vendas'), T('Sales team', 'time de Vendas'))
    ctx(610, 190, T('Payments', 'Pagamentos'), T('Payments team', 'time de Pagamentos'))
    ctx(610, 60, T('Payment gateway', 'Gateway de pagamento'), T('another company', 'outra empresa'), ext=True)
    ctx(110, 320, T('Boarding', 'Embarque'), T('Boarding team', 'time de Embarque'))
    ctx(360, 320, T('Notifications', 'Notificações'), T('Platform team', 'time de Plataforma'))
    ctx(610, 320, T('Finance', 'Finanças'), T('finance department', 'departamento financeiro'))
    L = dict(stroke='--paper', width=1.4)
    def ud(x, y, s, anchor='middle'):
        f.text(x, y, s, size=9, weight='700', fill='--amber', mono=True, anchor=anchor)
    f.line(170, 82, 288, 158, **L)
    ud(186, 104, 'U'); ud(282, 148, 'D')
    f.rect(288, 158, 30, 16, stroke='--amber', fill='--ink', rx=2, width=1.2)
    f.text(303, 166, 'ACL', size=8.5, mono=True)
    f.line(360, 84, 360, 166, **L)
    ud(370, 98, 'U', 'start'); ud(370, 152, 'D', 'start')
    f.text(380, 125, 'C/S', size=9, anchor='start', mono=True)
    f.line(435, 190, 535, 190, **L)
    f.text(485, 180, T('partnership', 'parceria'), size=9)
    f.line(610, 84, 610, 166, **L)
    ud(620, 98, 'U', 'start'); ud(620, 152, 'D', 'start')
    f.text(620, 112, 'OHS', size=8.5, anchor='start', mono=True)
    f.text(620, 140, 'ACL', size=8.5, anchor='start', mono=True)
    f.line(300, 212, 170, 296, **L)
    ud(286, 230, 'U'); ud(182, 286, 'D')
    f.text(296, 246, 'OHS/PL', size=8.5, anchor='start', mono=True)
    f.text(166, 266, 'CF', size=8.5, anchor='end', mono=True)
    f.line(360, 214, 360, 296, **L)
    ud(370, 228, 'U', 'start'); ud(370, 284, 'D', 'start')
    f.text(384, 228, 'OHS', size=8.5, anchor='start', mono=True)
    f.text(384, 284, 'CF', size=8.5, anchor='start', mono=True)
    f.text(610, 360, T('separate ways', 'caminhos separados'), size=9, fill='--paper-dim', italic=True)
    return f, T('U is upstream, whose model wins; D is downstream, which adapts. The abbreviation at each end says how. No line carries an arrowhead, because none of them is a call.',
                'U é upstream, cujo modelo prevalece; D é downstream, que se adapta. A sigla em cada ponta diz como. Nenhuma linha tem ponta de seta, porque nenhuma é uma chamada.')
