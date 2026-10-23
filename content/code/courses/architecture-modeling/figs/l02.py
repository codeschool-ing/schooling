"""Lesson 2: five UML diagrams."""
from figures import Fig, T, figure, picture


# ------------------------------------------------------------------ the family

@figure('l02-family', 2)
def family():
    f = Fig('l02-family', 720, 300, T(
        'The fourteen UML diagram types in two families. Structure diagrams: class, component, '
        'deployment, object, package, composite structure and profile. Behaviour diagrams: use case, '
        'activity, state machine, and four interaction diagrams: sequence, communication, interaction '
        'overview and timing. Highlighted are the five this lesson draws, class, component, '
        'deployment, use case and sequence, and the two lesson 4 draws, activity and state machine.',
        'Os catorze tipos de diagrama da UML em duas famílias. Diagramas de estrutura: classes, '
        'componentes, implantação, objetos, pacotes, estrutura composta e perfil. Diagramas de '
        'comportamento: casos de uso, atividade, máquina de estados, e quatro diagramas de interação: '
        'sequência, comunicação, visão geral de interação e tempo. Em destaque, os cinco que esta '
        'aula desenha, classes, componentes, implantação, casos de uso e sequência, e os dois que a '
        'aula 4 desenha, atividade e máquina de estados.'))
    f.text(360, 18, T('UML 2.5.1: fourteen diagram types', 'UML 2.5.1: catorze tipos de diagrama'), size=12, weight='600')
    f.rect(20, 34, 300, 230, stroke='--wire', fill='--ink', rx=6)
    f.rect(340, 34, 360, 230, stroke='--wire', fill='--ink', rx=6)
    f.text(170, 52, T('Structure', 'Estrutura'), size=11, weight='600')
    f.text(520, 52, T('Behaviour', 'Comportamento'), size=11, weight='600')
    this, l4 = '--phosphor', '--amber'
    st = [(T('Class', 'Classes'), this), (T('Component', 'Componentes'), this),
          (T('Deployment', 'Implantação'), this), (T('Object', 'Objetos'), '--wire'),
          (T('Package', 'Pacotes'), '--wire'), (T('Composite structure', 'Estrutura composta'), '--wire'),
          (T('Profile', 'Perfil'), '--wire')]
    for i, (n, c) in enumerate(st):
        x = 95 + (i % 2) * 150
        y = 84 + (i // 2) * 44
        f.box(x, y, 136, 32, n, size=10, stroke=c, width=1.6 if c != '--wire' else 1.1,
              weight='600' if c != '--wire' else None)
    bh = [(T('Use case', 'Casos de uso'), this), (T('Activity', 'Atividade'), l4),
          (T('State machine', 'Máquina de estados'), l4)]
    for i, (n, c) in enumerate(bh):
        f.box(430, 84 + i * 44, 156, 32, n, size=10, stroke=c, width=1.6, weight='600')
    f.rect(518, 66, 172, 186, stroke='--paper-dim', fill='--panel', rx=4, dash='4 3')
    f.text(604, 80, T('Interaction', 'Interação'), size=9.5, fill='--paper-dim', italic=True)
    ia = [(T('Sequence', 'Sequência'), this), (T('Communication', 'Comunicação'), '--wire'),
          (T('Interaction overview', 'Visão geral de interação'), '--wire'), (T('Timing', 'Tempo'), '--wire')]
    for i, (n, c) in enumerate(ia):
        f.box(604, 106 + i * 38, 156, 28, n, size=9.5, stroke=c, width=1.6 if c != '--wire' else 1.1,
              weight='600' if c != '--wire' else None)
    f.rect(120, 278, 22, 12, stroke=this, fill='--panel', rx=2, width=1.6)
    f.text(150, 284, T('drawn in this lesson', 'desenhados nesta aula'), size=9.5, anchor='start')
    f.rect(380, 278, 22, 12, stroke=l4, fill='--panel', rx=2, width=1.6)
    f.text(410, 284, T('drawn in lesson 4', 'desenhados na aula 4'), size=9.5, anchor='start')
    return f, T('Seven of the fourteen do most of the work in architecture documents. The other seven are worth recognising and rarely worth drawing.',
                'Sete dos catorze fazem quase todo o trabalho em documentos de arquitetura. Os outros sete valem ser reconhecidos e raramente valem ser desenhados.')


# ------------------------------------------------------------------ use cases

def use_case_drawing(f, words=True):
    t = (lambda *a, **k: None) if not words else f.text
    f.rect(180, 24, 360, 290, stroke='--paper-dim', fill='--ink', rx=2, width=1.4)
    t(192, 40, T('Carcará ticketing', 'Venda de passagens da Carcará'), size=10.5, anchor='start', weight='600')
    uc = {'buy': (290, 100, 72, T('Buy a ticket', 'Comprar passagem')),
          'coupon': (452, 62, 66, T('Apply a coupon', 'Aplicar cupom')),
          'pay': (452, 170, 66, T('Take payment', 'Receber pagamento')),
          'sell': (290, 245, 80, T('Sell at the counter', 'Vender no guichê')),
          'board': (452, 275, 70, T('Board a passenger', 'Embarcar passageiro'))}
    for k, (x, y, rx, n) in uc.items():
        f.ellipse(x, y, rx, 22, None)
        t(x, y, n, size=9.5)
    f.actor(80, 92, T('Passenger', 'Passageiro') if words else None, size=9.5)
    f.actor(80, 235, T('Station agent', 'Agente de guichê') if words else None, size=9.5)
    f.actor(640, 150, T('Payment gateway', 'Gateway de pagamento') if words else None, size=9.5)
    f.actor(640, 262, T('Driver', 'Motorista') if words else None, size=9.5)
    A = dict(stroke='--paper-dim', width=1.3)
    f.line(96, 92, 218, 98, **A)
    f.line(96, 238, 210, 244, **A)
    f.line(624, 152, 518, 168, **A)
    f.line(624, 266, 522, 274, **A)
    f.arrow([(80, 212), (80, 140)], stroke='--paper-dim', width=1.3, head='hollow')
    D = dict(stroke='--paper', width=1.2, dash='5 3', head='open')
    f.arrow([(340, 116), (392, 155)], **D)
    f.arrow([(345, 230), (395, 186)], **D)
    f.arrow([(400, 72), (356, 88)], **D)
    if words:
        f.text(372, 128, '«include»', size=8.5, anchor='end', fill='--paper-dim', mono=True)
        f.text(376, 216, '«include»', size=8.5, anchor='end', fill='--paper-dim', mono=True)
        f.text(372, 66, '«extend»', size=8.5, anchor='end', fill='--paper-dim', mono=True)


@figure('l02-use-case', 2)
def use_case():
    f = Fig('l02-use-case', 720, 330, T(
        'A use case diagram of Carcará ticketing. Inside the system boundary, five use cases: buy a '
        'ticket, apply a coupon, take payment, sell at the counter and board a passenger. Outside it, '
        'four actors. The passenger is linked to buy a ticket; the station agent to sell at the '
        'counter, and the station agent generalises to passenger with a hollow-headed arrow. The '
        'payment gateway is linked to take payment, and the driver to board a passenger. Buy a ticket '
        'and sell at the counter both include take payment; apply a coupon extends buy a ticket.',
        'Um diagrama de casos de uso da venda de passagens da Carcará. Dentro da fronteira do '
        'sistema, cinco casos de uso: comprar passagem, aplicar cupom, receber pagamento, vender no '
        'guichê e embarcar passageiro. Fora dela, quatro atores. O passageiro liga-se a comprar '
        'passagem; o agente de guichê, a vender no guichê, e o agente de guichê generaliza passageiro, '
        'com uma seta de ponta vazada. O gateway de pagamento liga-se a receber pagamento, e o '
        'motorista a embarcar passageiro. Comprar passagem e vender no guichê incluem receber '
        'pagamento; aplicar cupom estende comprar passagem.'))
    use_case_drawing(f)
    return f, T('Actors outside the boundary, goals inside it. Include points at the shared step; extend points at the use case it may add to.',
                'Atores fora da fronteira, objetivos dentro dela. O include aponta para o passo compartilhado; o extend aponta para o caso de uso ao qual pode acrescentar algo.')


@picture('use-case-shapes')
def use_case_picture():
    f = Fig('use-case-shapes', 720, 330, '')
    use_case_drawing(f, words=False)
    return f


@figure('l02-use-case-wrong', 2)
def use_case_wrong():
    f = Fig('l02-use-case-wrong', 720, 300, T(
        'A use case diagram with four mistakes, numbered. One: a use case called login screen, a screen '
        'rather than a goal. Two: three use cases, search trips, choose seat and pay, joined by solid '
        'arrows showing their order. Three: the booking database drawn as an actor outside the '
        'boundary. Four: buy a ticket split into four included pieces: validate CPF, calculate fare, '
        'save booking and send e-mail.',
        'Um diagrama de casos de uso com quatro erros, numerados. Um: um caso de uso chamado tela de '
        'login, uma tela em vez de um objetivo. Dois: três casos de uso, buscar viagens, escolher '
        'assento e pagar, ligados por setas contínuas mostrando a ordem. Três: o banco de reservas '
        'desenhado como ator fora da fronteira. Quatro: comprar passagem quebrado em quatro pedaços '
        'incluídos: validar CPF, calcular tarifa, gravar reserva e enviar e-mail.'))
    f.rect(150, 20, 430, 270, stroke='--paper-dim', fill='--ink', rx=2, width=1.4)
    f.actor(70, 90, T('Passenger', 'Passageiro'), size=9.5)
    f.ellipse(260, 60, 62, 20, T('Login screen', 'Tela de login'), size=9.5)
    for i, (x, n) in enumerate([(230, T('Search trips', 'Buscar viagens')), (365, T('Choose seat', 'Escolher assento')),
                                (495, T('Pay', 'Pagar'))]):
        f.ellipse(x, 125, 58, 20, n, size=9.5)
    f.arrow([(288, 125), (305, 125)], stroke='--paper', width=1.3)
    f.arrow([(423, 125), (436, 125)], stroke='--paper', width=1.3)
    f.ellipse(260, 215, 60, 20, T('Buy a ticket', 'Comprar passagem'), size=9.5)
    parts = [(450, 168, T('Validate CPF', 'Validar CPF')), (450, 200, T('Calculate fare', 'Calcular tarifa')),
             (450, 232, T('Save booking', 'Gravar reserva')), (450, 264, T('Send e-mail', 'Enviar e-mail'))]
    for x, y, n in parts:
        f.ellipse(x, y, 54, 14, n, size=8.5)
        f.arrow([(320, 215), (x - 56, y)], stroke='--paper-dim', width=1.1, dash='5 3', head='open')
    f.line(86, 92, 198, 62, stroke='--paper-dim', width=1.3)
    f.line(86, 98, 172, 120, stroke='--paper-dim', width=1.3)
    f.line(86, 102, 200, 210, stroke='--paper-dim', width=1.3)
    f.actor(650, 200, T('Booking DB', 'Banco de reservas'), size=9.5)
    f.line(634, 205, 506, 232, stroke='--paper-dim', width=1.3)
    f.badge(198, 42, 1)
    f.badge(300, 100, 2)
    f.badge(676, 168, 3)
    f.badge(372, 192, 4)
    return f, T('Each of the four is correct notation, and each makes the diagram say something false about the system: a screen as a goal, time where there is none, a part outside its own system, a program drawn in ellipses.',
                'Cada um dos quatro usa a notação corretamente, e cada um faz o diagrama dizer algo falso sobre o sistema: uma tela como objetivo, tempo onde não há tempo, uma parte fora do próprio sistema, um programa desenhado em elipses.')


# ------------------------------------------------------------------ class diagrams

def RELS(): return [('association', 'plain', T('association', 'associação'), T('linked instances', 'instâncias ligadas')),
        ('aggregation', 'odiamond', T('aggregation', 'agregação'), T('loose part-of', 'parte de, frouxo')),
        ('composition', 'diamond', T('composition', 'composição'), T('owned part, same life', 'parte com a mesma vida')),
        ('generalisation', 'hollow', T('generalisation', 'generalização'), T('is a kind of', 'é um tipo de')),
        ('dependency', 'open', T('dependency', 'dependência'), T('uses, keeps no link', 'usa, sem guardar vínculo')),
        ('realisation', 'hollow', T('realisation', 'realização'), T('implements an interface', 'implementa uma interface'))]


def relations_drawing(f, words=True):
    for i, (key, head, name, meaning) in enumerate(RELS()):
        x0 = 150
        y = 26 + i * 40
        f.rect(x0, y - 14, 60, 28, stroke='--paper-dim', fill='--panel', rx=1)
        f.rect(x0 + 200, y - 14, 60, 28, stroke='--paper-dim', fill='--panel', rx=1)
        dash = '5 3' if key in ('dependency', 'realisation') else None
        if head == 'plain':
            f.line(x0 + 60, y, x0 + 200, y, stroke='--paper', width=1.4)
        elif head in ('diamond', 'odiamond'):
            f.arrow([(x0 + 200, y), (x0 + 60, y)], stroke='--paper', width=1.4, head=head)
        else:
            f.arrow([(x0 + 60, y), (x0 + 200, y)], stroke='--paper', width=1.4, head=head, dash=dash)
        if words:
            f.text(x0 + 275, y - 6, name, size=10.5, anchor='start', weight='600')
            f.text(x0 + 275, y + 9, meaning, size=9, anchor='start', fill='--paper-dim')


@figure('l02-class-relations', 2)
def class_relations():
    f = Fig('l02-class-relations', 720, 250, T(
        'The six relationship lines of a class diagram. Association: a plain solid line. Aggregation: a '
        'solid line with a hollow diamond at the whole. Composition: a solid line with a filled diamond '
        'at the whole. Generalisation: a solid line with a hollow triangle at the more general class. '
        'Dependency: a dashed line with an open arrowhead. Realisation: a dashed line with a hollow '
        'triangle at the interface.',
        'As seis linhas de relação de um diagrama de classes. Associação: uma linha contínua simples. '
        'Agregação: linha contínua com losango vazado no todo. Composição: linha contínua com losango '
        'cheio no todo. Generalização: linha contínua com triângulo vazado na classe mais geral. '
        'Dependência: linha tracejada com ponta de seta aberta. Realização: linha tracejada com '
        'triângulo vazado na interface.'))
    relations_drawing(f)
    return f, T('The symbol sits on the end that is the whole, the parent or the thing depended on. Solid against dashed and filled against hollow are the whole difference between four of them.',
                'O símbolo fica na ponta que é o todo, o pai ou aquilo de que se depende. Contínua contra tracejada e cheio contra vazado são a diferença inteira entre quatro delas.')


@picture('class-relations')
def class_relations_picture():
    f = Fig('class-relations', 720, 250, '')
    relations_drawing(f, words=False)
    return f


def booking_classes(f, wrong=False):
    f.cls(20, 30, 170, 'Passenger', ['name: String', 'cpf: Cpf'],
          None if not wrong else ['getName()', 'setName(n)', 'getCpf()', 'setCpf(c)', 'getEmail()', 'setEmail(e)'])
    f.cls(270, 22, 200, 'Booking', ['id: BookingId', 'status: BookingStatus'], ['pay(payment)', 'cancel(reason)'],
          stereo='«aggregate root»')
    f.cls(270, 205, 200, 'Ticket', ['seat: SeatNumber', 'fare: Money'] + (['bookingId: Long'] if wrong else []), None)
    f.cls(550, 205, 150, 'Trip', ['departure: DateTime', 'route: RouteId'], None)
    f.cls(550, 30, 150, 'Money', ['amount: Long', 'currency: Currency'], None, stereo='«value object»')
    f.cls(20, 215, 170, 'PricingPolicy', [], ['quote(trip): Money'])
    P = dict(stroke='--paper', width=1.4)
    # passenger -- booking
    if wrong:
        f.arrow([(190, 70), (270, 70)], head='open', start=True, **P)
    else:
        f.line(190, 70, 270, 70, **P)
    f.text(198, 62, '1', size=9.5, anchor='start', mono=True)
    f.text(262, 62, '*', size=9.5, anchor='end', mono=True)
    # booking -- ticket
    if wrong:
        f.arrow([(370, 140), (370, 205)], head='diamond', **P)
    else:
        f.arrow([(370, 205), (370, 140)], head='diamond', **P)
    f.text(378, 154, '1', size=9.5, anchor='start', mono=True)
    f.text(378, 196, '1..*', size=9.5, anchor='start', mono=True)
    # ticket -- trip
    if wrong:
        f.arrow([(550, 240), (470, 240)], head='diamond', **P)
    else:
        f.arrow([(470, 240), (550, 240)], head='open', **P)
    f.text(478, 232, '*', size=9.5, anchor='start', mono=True)
    f.text(542, 232, '1', size=9.5, anchor='end', mono=True)
    # booking ..> pricing
    f.arrow([(270, 120), (190, 220)], head='open', dash='5 3', stroke='--paper-dim', width=1.3)


@figure('l02-class', 2)
def class_diagram():
    f = Fig('l02-class', 720, 300, T(
        'A class diagram of Carcará\'s booking aggregate. Booking, marked aggregate root, with an id, a '
        'status and the operations pay and cancel. A passenger is linked to many bookings. Booking owns '
        'one or more tickets by composition, the filled diamond on the booking\'s end. Each ticket has '
        'a seat and a fare of type Money, and refers to exactly one trip, with an arrowhead pointing at '
        'the trip. Money is marked value object, with an amount and a currency. Booking has a dashed '
        'dependency on PricingPolicy, which quotes a fare for a trip.',
        'Um diagrama de classes do agregado de reserva da Carcará. Booking, marcada como raiz do '
        'agregado, com um id, um status e as operações pay e cancel. Um passageiro se liga a muitas '
        'reservas. Booking é dona de uma ou mais passagens por composição, o losango cheio do lado da '
        'reserva. Cada passagem tem um assento e uma tarifa do tipo Money, e aponta para exatamente '
        'uma viagem, com a ponta de seta na viagem. Money é marcada como objeto de valor, com valor e '
        'moeda. Booking tem uma dependência tracejada de PricingPolicy, que cota a tarifa de uma '
        'viagem.'))
    booking_classes(f)
    return f, T('Six classes, because the question was what a booking is made of. The diamond, the numbers and the one arrowhead are each a claim the code can confirm or deny.',
                'Seis classes, porque a pergunta era do que uma reserva é feita. O losango, os números e a única ponta de seta são, cada um, uma afirmação que o código pode confirmar ou desmentir.')


@figure('l02-class-wrong', 2)
def class_wrong():
    f = Fig('l02-class-wrong', 720, 310, T(
        'The same booking diagram with five mistakes, numbered. One: the composition diamond is on the '
        'ticket\'s end of the booking line, saying a ticket owns its booking. Two: Ticket carries '
        'bookingId: Long, a foreign key, beside the line that already is the reference. Three: Trip is '
        'drawn as a composed part of Ticket. Four: the passenger–booking line has arrowheads on both '
        'ends. Five: Passenger lists its getters and setters.',
        'O mesmo diagrama de reserva com cinco erros, numerados. Um: o losango de composição está do '
        'lado da passagem na linha da reserva, dizendo que a passagem é dona da reserva. Dois: Ticket '
        'tem bookingId: Long, uma chave estrangeira, ao lado da linha que já é a referência. Três: Trip '
        'aparece como parte composta de Ticket. Quatro: a linha entre passageiro e reserva tem pontas '
        'de seta nas duas extremidades. Cinco: Passenger lista seus getters e setters.'))
    booking_classes(f, wrong=True)
    f.badge(392, 180, 1, fill='--amber')
    f.badge(404, 265, 2, fill='--amber')
    f.badge(510, 256, 3, fill='--amber')
    f.badge(230, 48, 4, fill='--amber')
    f.badge(12, 130, 5, fill='--amber')
    return f, T('Every mark here is legal UML, which is why a reader will believe it.',
                'Toda marca aqui é UML válida, e é por isso que quem lê vai acreditar nela.')


# ------------------------------------------------------------------ sequence diagrams

def life(f, x, name, top, bottom, w=112, gaps=()):
    """A lifeline. `gaps` are the activations on it, which the dashed line stops at rather than
    crossing: figure-fit refuses a line through a box, and an activation is one."""
    f.box(x, top, w, 34, name, size=9.5, stroke='--phosphor')
    y = top + 17
    for a, b in sorted(gaps):
        if a > y:
            f.line(x, y, x, a, stroke='--paper-dim', width=1, dash='4 4')
        y = b
    if bottom > y:
        f.line(x, y, x, bottom, stroke='--paper-dim', width=1, dash='4 4')


def act(f, x, y1, y2):
    f.rect(x - 5, y1, 10, y2 - y1, stroke='--paper-dim', fill='--panel', rx=0, width=1)


def msg(f, x1, x2, y, label, kind='sync', size=9, above=True, mono=False):
    head = {'sync': 'fill', 'async': 'open', 'reply': 'open'}[kind]
    dash = '5 3' if kind == 'reply' else None
    s = 6 if x2 > x1 else -6
    f.arrow([(x1 + s, y), (x2 - s, y)], stroke='--paper', width=1.2, head=head, dash=dash)
    if label:
        f.text((x1 + x2) / 2, y - 7 if above else y + 11, label, size=size, mono=mono)


def frame(f, x, y, w, h, op, guards=()):
    """A combined fragment, drawn as four lines rather than a rectangle: the lifelines run through
    it on purpose, and a rectangle is a box figure-fit would say they cross."""
    f.path(f'M{x} {y} L{x + w} {y} L{x + w} {y + h} L{x} {y + h} Z', stroke='--amber', width=1.1)
    f.path(f'M{x} {y + 16} L{x + 30} {y + 16} L{x + 38} {y + 8} L{x + 38} {y}', stroke='--amber', width=1.1)
    f.text(x + 18, y + 9, op, size=9, weight='600', fill='--amber', mono=True)
    for gy, g in guards:
        f.text(x + 6, gy, g, size=9, anchor='start', fill='--amber', mono=True)


@figure('l02-sequence', 2)
def sequence():
    f = Fig('l02-sequence', 720, 470, T(
        'A sequence diagram of buying a ticket, with five lifelines: passenger app, ticketing API, '
        'seat-hold store, booking database and payment gateway. First request: the app sends POST '
        'bookings to the API; the API asks the seat-hold store to hold seat 14 for ten minutes and gets '
        'held back; it inserts the booking as pending payment; it answers 201 Created. Second request: '
        'the app sends POST payments; the API asks the gateway to charge the card. An alt fragment '
        'splits on the answer. If approved, the API marks the booking paid and answers with the ticket. '
        'If declined, the API sends release seat to the seat-hold store without waiting, and answers '
        'the app with the reason.',
        'Um diagrama de sequência da compra de passagem, com cinco linhas de vida: app do passageiro, '
        'API de passagens, store de bloqueio de assentos, banco de reservas e gateway de pagamento. '
        'Primeiro pedido: o app manda POST bookings para a API; a API pede ao store que bloqueie o '
        'assento 14 por dez minutos e recebe held de volta; grava a reserva como aguardando pagamento; '
        'responde 201 Created. Segundo pedido: o app manda POST payments; a API pede ao gateway que '
        'cobre o cartão. Um fragmento alt se divide pela resposta. Se aprovado, a API marca a reserva '
        'como paga e responde com a passagem. Se recusado, a API manda liberar o assento ao store sem '
        'esperar, e responde ao app com o motivo.'))
    X = [70, 215, 365, 510, 650]
    names = [T('Passenger app', 'App do passageiro'), T('Ticketing API', 'API de passagens'),
             T('Seat-hold store', 'Store de assentos'), T('Booking DB', 'Banco de reservas'),
             T('Payment gateway', 'Gateway de pagamento')]
    for i, (x, n) in enumerate(zip(X, names)):
        life(f, x, n, 28, 455, w=126, gaps=[(76, 200), (238, 448)] if i == 1 else [])
    act(f, X[1], 76, 200)
    act(f, X[1], 238, 448)
    msg(f, X[0], X[1], 80, 'POST /bookings', mono=True)
    msg(f, X[1], X[2], 106, T('hold seat 14, 10 min', 'bloqueia assento 14, 10 min'))
    msg(f, X[2], X[1], 128, 'held', kind='reply', mono=True)
    msg(f, X[1], X[3], 156, T('insert, pending payment', 'grava, aguardando pagamento'))
    msg(f, X[1], X[0], 192, '201 Created', kind='reply', mono=True)
    msg(f, X[0], X[1], 242, 'POST /payments', mono=True)
    msg(f, X[1], X[4], 270, T('charge card', 'cobra cartão'))
    frame(f, 120, 288, 592, 162, 'alt', [(328, '[approved]'), (392, '[declined]')])
    msg(f, X[4], X[1], 318, 'approved', kind='reply', mono=True)
    msg(f, X[1], X[3], 342, T('mark paid', 'marca como paga'))
    msg(f, X[1], X[0], 366, T('ticket', 'passagem'), kind='reply')
    f.line(120, 374, 712, 374, stroke='--amber', width=1, dash='6 3')
    msg(f, X[4], X[1], 398, 'declined', kind='reply', mono=True)
    msg(f, X[1], X[2], 420, T('release seat', 'libera assento'), kind='async')
    msg(f, X[1], X[0], 442, T('reason', 'motivo'), kind='reply')
    return f, T('Time runs down the page. The filled arrowheads wait for an answer; the open one in the declined branch does not. The seat is held before any money moves.',
                'O tempo desce pela página. As pontas cheias esperam resposta; a aberta, no ramo de recusa, não espera. O assento é bloqueado antes de qualquer dinheiro se mover.')


@figure('l02-sequence-webhook', 2)
def sequence_webhook():
    f = Fig('l02-sequence-webhook', 720, 360, T(
        'The payment again, after the fix, with four lifelines: passenger app, ticketing API, booking '
        'database and payment gateway. The API sends charge card with key B-4471 to the gateway. The '
        'answer is lost: a cross marks it, labelled timeout. The API retries the same charge with the '
        'same key, and the gateway answers already charged: approved, without charging again. Later, '
        'outside any request, the gateway sends payment approved for B-4471 to the API\'s webhook, an '
        'asynchronous message, and the API marks the booking paid.',
        'O pagamento de novo, depois da correção, com quatro linhas de vida: app do passageiro, API de '
        'passagens, banco de reservas e gateway de pagamento. A API manda cobrar cartão com a chave '
        'B-4471 ao gateway. A resposta se perde: um x a marca, com o rótulo timeout. A API repete a '
        'mesma cobrança com a mesma chave, e o gateway responde já cobrado: aprovado, sem cobrar de '
        'novo. Mais tarde, fora de qualquer pedido, o gateway manda pagamento aprovado para B-4471 ao '
        'webhook da API, uma mensagem assíncrona, e a API marca a reserva como paga.'))
    X = [80, 260, 440, 620]
    names = [T('Passenger app', 'App do passageiro'), T('Ticketing API', 'API de passagens'),
             T('Booking DB', 'Banco de reservas'), T('Payment gateway', 'Gateway de pagamento')]
    for i, (x, n) in enumerate(zip(X, names)):
        life(f, x, n, 28, 345, w=140, gaps=[(72, 210), (280, 330)] if i == 1 else [])
    act(f, X[1], 72, 210)
    msg(f, X[0], X[1], 76, 'POST /payments', mono=True)
    msg(f, X[1], X[3], 102, T('charge card, key = B-4471', 'cobra cartão, chave = B-4471'))
    f.path(f'M{X[3] - 6} 128 L{X[1] + 120} 128', stroke='--paper', width=1.2, dash='5 3')
    f.line(X[1] + 112, 121, X[1] + 126, 135, stroke='--amber', width=1.8)
    f.line(X[1] + 112, 135, X[1] + 126, 121, stroke='--amber', width=1.8)
    f.text(X[1] + 140, 140, T('timeout: the answer is lost', 'timeout: a resposta se perde'), size=9, anchor='start',
           fill='--amber')
    msg(f, X[1], X[3], 164, T('charge card, same key = B-4471', 'cobra cartão, mesma chave = B-4471'))
    msg(f, X[3], X[1], 192, T('already charged: approved', 'já cobrado: aprovado'), kind='reply')
    msg(f, X[1], X[0], 206, T('ticket', 'passagem'), kind='reply', above=False)
    f.line(30, 240, 700, 240, stroke='--wire', width=1, dash='2 4')
    f.text(36, 254, T('later, outside the request', 'mais tarde, fora do pedido'), size=9, anchor='start',
           fill='--paper-dim', italic=True)
    act(f, X[1], 280, 330)
    msg(f, X[3], X[1], 284, T('webhook: payment approved, B-4471', 'webhook: pagamento aprovado, B-4471'),
        kind='async')
    msg(f, X[1], X[2], 316, T('mark paid, if not already', 'marca como paga, se ainda não estiver'))
    return f, T('The key makes the retry safe; the webhook makes the lost answer harmless. Both are visible only on a picture that shows the moment between sent and answered.',
                'A chave torna a nova tentativa segura; o webhook torna inofensiva a resposta perdida. As duas coisas só aparecem num desenho que mostra o momento entre enviado e respondido.')


# ------------------------------------------------------------------ components

def component(f, x, y, w, h, name, stroke='--phosphor', dash=None):
    f.rect(x, y, w, h, stroke=stroke, fill='--panel', rx=2, width=1.5, dash=dash)
    f.rect(x + w - 22, y + 8, 14, 16, stroke='--paper-dim', fill='--panel', rx=1, width=1)
    f.rect(x + w - 26, y + 11, 8, 4, stroke='--paper-dim', fill='--panel', rx=0, width=1)
    f.rect(x + w - 26, y + 17, 8, 4, stroke='--paper-dim', fill='--panel', rx=0, width=1)
    f.text(x + 10, y + 14, '«component»', size=8, anchor='start', fill='--paper-dim', mono=True)
    f.text(x + w / 2 - 6, y + h / 2 + 7, name, size=10.5, weight='600')


def ball(f, x, y, toward, length=26):
    """A provided interface: a stick from (x, y) and a ball at its end."""
    dx, dy = toward
    bx, by = x + dx * length, y + dy * length
    f.line(x, y, bx - dx * 7, by - dy * 7, stroke='--paper', width=1.3)
    f.circle(bx, by, 7, fill='--panel', stroke='--paper', width=1.4)
    return bx, by


def socket(f, x, y, bx, by):
    """A required interface: a stick from (x, y) to a cup around the ball at (bx, by)."""
    import math
    dx, dy = bx - x, by - y
    n = math.hypot(dx, dy)
    ux, uy = dx / n, dy / n
    ex, ey = bx - ux * 11, by - uy * 11
    f.line(x, y, ex, ey, stroke='--paper', width=1.3)
    a = math.atan2(-uy, -ux)
    p1 = (bx + 11 * math.cos(a + 1.35), by + 11 * math.sin(a + 1.35))
    p2 = (bx + 11 * math.cos(a - 1.35), by + 11 * math.sin(a - 1.35))
    f.path(f'M{p1[0]:.1f} {p1[1]:.1f} A11 11 0 0 1 {p2[0]:.1f} {p2[1]:.1f}', stroke='--paper', width=1.4)


@figure('l02-component', 2)
def components():
    f = Fig('l02-component', 720, 300, T(
        'A component diagram of Carcará\'s sales. Four components: passenger app, ticketing, pricing and '
        'payment adapter, and the payment gateway, outside, dashed. Ticketing provides the interface '
        'Bookings, a ball, which the passenger app requires, a socket fitted round it. Pricing provides '
        'FareQuote, which ticketing requires. The payment adapter provides PaymentPort, which ticketing '
        'requires. The gateway provides its own API, which the payment adapter requires.',
        'Um diagrama de componentes das vendas da Carcará. Quatro componentes: app do passageiro, '
        'ticketing, pricing e adaptador de pagamento, e o gateway de pagamento, de fora, tracejado. '
        'Ticketing oferece a interface Bookings, uma bola, que o app do passageiro exige, com um '
        'soquete encaixado em volta. Pricing oferece FareQuote, que ticketing exige. O adaptador de '
        'pagamento oferece PaymentPort, que ticketing exige. O gateway oferece a própria API, que o '
        'adaptador exige.'))
    component(f, 20, 120, 160, 60, T('Passenger app', 'App do passageiro'))
    component(f, 280, 120, 160, 60, 'Ticketing')
    component(f, 280, 18, 160, 56, 'Pricing')
    component(f, 540, 120, 160, 60, T('Payment adapter', 'Adaptador'))
    component(f, 540, 222, 160, 56, T('Payment gateway', 'Gateway'), stroke='--paper-dim', dash='5 3')
    bx, by = ball(f, 280, 150, (-1, 0), 44)
    socket(f, 180, 150, bx, by)
    f.text(bx, by - 18, 'Bookings', size=9, mono=True)
    bx, by = ball(f, 360, 74, (0, 1), 22)
    socket(f, 360, 120, bx, by)
    f.text(bx + 16, by + 2, 'FareQuote', size=9, anchor='start', mono=True)
    bx, by = ball(f, 540, 150, (-1, 0), 48)
    socket(f, 440, 150, bx, by)
    f.text(bx, by - 18, 'PaymentPort', size=9, mono=True)
    bx, by = ball(f, 620, 222, (0, -1), 20)
    socket(f, 620, 180, bx, by)
    f.text(bx + 16, by + 2, 'Gateway API', size=9, anchor='start', mono=True)
    f.text(20, 236, T('ball: provided', 'bola: oferecida'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(20, 254, T('socket: required', 'soquete: exigida'), size=9.5, anchor='start', fill='--paper-dim')
    return f, T('Ticketing meets the rest only at three named interfaces. A partner company\'s fares would be a second provider of FareQuote, and nothing inside Ticketing would change.',
                'Ticketing encontra o resto só em três interfaces com nome. As tarifas de uma empresa parceira seriam um segundo fornecedor de FareQuote, e nada dentro de Ticketing mudaria.')


# ------------------------------------------------------------------ deployment

def artifact(f, x, y, w, name, size=8.5):
    f.rect(x, y, w, 30, stroke='--paper-dim', fill='--ink', rx=1, width=1)
    f.text(x + w / 2, y + 9, '«artifact»', size=7.5, fill='--paper-dim', mono=True)
    f.text(x + w / 2, y + 21, name, size=size, mono=True)


@figure('l02-deployment', 2)
def deployment():
    f = Fig('l02-deployment', 720, 380, T(
        'A deployment diagram of Carcará. A passenger\'s phone, a device, runs the carcara-app artifact. '
        'A cloud region node contains three execution environments: a container cluster running three '
        'replicas of the ticketing-api image, a managed PostgreSQL service holding the booking '
        'database, and a managed Redis holding seat holds. The driver\'s phone, a device multiplied by '
        '300, runs the boarding-app artifact and a local SQLite store of the day\'s tickets. The '
        'payment gateway is an external node with nothing drawn inside. Lines are labelled HTTPS '
        'between phones and the cluster and between the cluster and the gateway, and with the '
        'database protocols inside the region.',
        'Um diagrama de implantação da Carcará. O celular do passageiro, um dispositivo, roda o '
        'artefato carcara-app. Um nó de região de nuvem contém três ambientes de execução: um cluster '
        'de containers rodando três réplicas da imagem ticketing-api, um PostgreSQL gerenciado com o '
        'banco de reservas, e um Redis gerenciado com os bloqueios de assento. O celular do motorista, '
        'um dispositivo multiplicado por 300, roda o artefato boarding-app e um store SQLite local com '
        'as passagens do dia. O gateway de pagamento é um nó externo, sem nada desenhado dentro. As '
        'linhas têm o rótulo HTTPS entre os celulares e o cluster e entre o cluster e o gateway, e os '
        'protocolos de banco dentro da região.'))
    f.node(20, 40, 150, 90, T('Passenger phone', 'Celular do passageiro'), size=9.5)
    f.text(28, 69, '«device»', size=8, anchor='start', fill='--paper-dim', mono=True)
    artifact(f, 32, 86, 126, 'carcara-app')
    f.node(20, 230, 150, 120, T('Driver phone ×300', 'Celular do motorista ×300'), size=9.5)
    f.text(28, 259, '«device»', size=8, anchor='start', fill='--paper-dim', mono=True)
    artifact(f, 32, 272, 126, 'boarding-app')
    artifact(f, 32, 308, 126, 'tickets.sqlite')
    f.node(220, 40, 330, 320, T('Cloud region', 'Região de nuvem'), size=10)
    f.rect(236, 70, 298, 110, stroke='--phosphor', fill='--ink', rx=2, width=1.3)
    f.text(244, 84, '«executionEnvironment»', size=8, anchor='start', fill='--paper-dim', mono=True)
    f.text(244, 98, T('Container cluster', 'Cluster de containers'), size=9.5, anchor='start', weight='600')
    for i in range(3):
        artifact(f, 250 + i * 92, 120, 84, 'ticketing-api', size=8)
    f.text(385, 168, T('3 replicas', '3 réplicas'), size=9, fill='--paper-dim')
    f.rect(236, 230, 140, 110, stroke='--phosphor', fill='--ink', rx=2, width=1.3)
    f.text(244, 244, '«executionEnvironment»', size=7.5, anchor='start', fill='--paper-dim', mono=True)
    f.text(244, 258, T('Managed PostgreSQL', 'PostgreSQL gerenciado'), size=9, anchor='start', weight='600')
    artifact(f, 248, 290, 116, 'bookings')
    f.rect(392, 230, 142, 110, stroke='--phosphor', fill='--ink', rx=2, width=1.3)
    f.text(400, 244, '«executionEnvironment»', size=7.5, anchor='start', fill='--paper-dim', mono=True)
    f.text(400, 258, T('Managed Redis', 'Redis gerenciado'), size=9, anchor='start', weight='600')
    artifact(f, 404, 290, 118, 'seat-holds')
    f.node(590, 120, 110, 80, T('Payment gateway', 'Gateway'), size=9.5, stroke='--paper-dim')
    f.text(645, 170, T('(external)', '(externo)'), size=9, fill='--paper-dim')
    C = dict(stroke='--paper', width=1.3)
    f.line(170, 85, 236, 110, **C)
    f.text(203, 86, 'HTTPS', size=8.5, mono=True)
    f.line(170, 275, 236, 160, **C)
    f.text(214, 238, 'HTTPS', size=8.5, anchor='end', mono=True)
    f.line(534, 150, 590, 150, **C)
    f.text(562, 142, 'HTTPS', size=8.5, mono=True)
    f.line(306, 180, 306, 230, **C)
    f.text(312, 206, 'SQL', size=8.5, anchor='start', mono=True)
    f.line(462, 180, 462, 230, **C)
    f.text(468, 206, 'RESP', size=8.5, anchor='start', mono=True)
    return f, T('What the component diagram could not say: three replicas, a database reached over the network, and 300 phones that keep their own copy of the day\'s tickets.',
                'O que o diagrama de componentes não conseguia dizer: três réplicas, um banco alcançado pela rede, e 300 celulares que guardam a própria cópia das passagens do dia.')


# ------------------------------------------------------------------ five views

@figure('l02-five-views', 2)
def five_views():
    f = Fig('l02-five-views', 720, 190, T(
        'One scenario, a passenger buys a ticket, seen through the five diagrams. Use case: the goal and '
        'the boundary. Class: what the booking is made of. Sequence: the order of the calls and who '
        'waits. Component: which interfaces the calls go through. Deployment: which calls cross the '
        'network.',
        'Um cenário, um passageiro compra uma passagem, visto pelos cinco diagramas. Casos de uso: o '
        'objetivo e a fronteira. Classes: do que a reserva é feita. Sequência: a ordem das chamadas e '
        'quem espera. Componentes: por quais interfaces as chamadas passam. Implantação: quais chamadas '
        'atravessam a rede.'))
    f.rect(200, 10, 320, 30, stroke='--amber', fill='--panel', rx=15, width=1.4)
    f.text(360, 25, T('a passenger buys a ticket', 'um passageiro compra uma passagem'), size=10.5, weight='600')
    cols = [(T('use case', 'casos de uso'), T('the goal and', 'o objetivo e'), T('the boundary', 'a fronteira')),
            (T('class', 'classes'), T('what a booking', 'do que a reserva'), T('is made of', 'é feita')),
            (T('sequence', 'sequência'), T('the order and', 'a ordem e'), T('who waits', 'quem espera')),
            (T('component', 'componentes'), T('which interfaces', 'por quais'), T('the calls use', 'interfaces passam')),
            (T('deployment', 'implantação'), T('which calls cross', 'quais chamadas'), T('the network', 'cruzam a rede'))]
    for i, (a, b, c) in enumerate(cols):
        x = 76 + i * 142
        f.line(360, 40, x, 82, stroke='--paper-dim', width=1, dash='3 3')
        f.box(x, 130, 128, 92, a, sub=[b, c], size=11, stroke='--phosphor')
    return f, T('Walking one scenario through all five is how disagreements between them turn up, and sometimes the disagreement is in the code.',
                'Percorrer um cenário pelos cinco é como as discordâncias entre eles aparecem, e às vezes a discordância está no código.')
