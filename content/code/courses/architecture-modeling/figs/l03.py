"""Lesson 3: the C4 model."""
from figures import Fig, T, figure, picture

IN, OUT = '--phosphor', '--paper-dim'


def el(f, x, y, w, h, name, kind, desc=None, ext=False, size=9.5, words=True):
    """A C4 element centred on x, y: name, [type: technology], and a description."""
    f.rect(x - w / 2, y - h / 2, w, h, stroke=OUT if ext else IN, fill='--panel', rx=5, width=1.5,
           dash='5 3' if ext else None)
    if not words:
        return
    rows = [(name, size, '--paper', '600'), (kind, size - 1.5, '--paper-dim', None)]
    if desc:
        rows += [(d, size - 1.5, '--paper-dim', None) for d in ([desc] if isinstance(desc, str) else desc)]
    gap = size * 1.3
    top = y - gap * (len(rows) - 1) / 2
    for i, (t, s, c, wt) in enumerate(rows):
        f.text(x, top + i * gap, t, size=s, fill=c, weight=wt)


def db(f, x, y, w, h, name, kind, desc=None, size=9.5):
    """A data-store container: a cylinder."""
    r = 7
    f.path(f'M{x - w / 2:.1f} {y - h / 2 + r:.1f} L{x - w / 2:.1f} {y + h / 2 - r:.1f} '
           f'A{w / 2:.1f} {r} 0 0 0 {x + w / 2:.1f} {y + h / 2 - r:.1f} L{x + w / 2:.1f} {y - h / 2 + r:.1f}',
           stroke=IN, fill='--panel', width=1.5)
    f.ellipse(x, y - h / 2 + r, w / 2, r, None, stroke=IN)
    rows = [(name, size, '--paper', '600'), (kind, size - 1.5, '--paper-dim', None)]
    if desc:
        rows.append((desc, size - 1.5, '--paper-dim', None))
    gap = size * 1.3
    top = y + 4 - gap * (len(rows) - 1) / 2
    for i, (t, s, c, wt) in enumerate(rows):
        f.text(x, top + i * gap, t, size=s, fill=c, weight=wt)


def legend(f, x, y):
    f.rect(x, y, 150, 74, stroke='--wire', fill='--panel', rx=3)
    f.text(x + 8, y + 12, T('Key', 'Legenda'), size=9, anchor='start', weight='600')
    f.rect(x + 8, y + 22, 18, 11, stroke=IN, fill='--panel', rx=2, width=1.4)
    f.text(x + 32, y + 28, T('in scope', 'no escopo'), size=8.5, anchor='start')
    f.rect(x + 8, y + 39, 18, 11, stroke=OUT, fill='--panel', rx=2, width=1.4, dash='4 2')
    f.text(x + 32, y + 45, T('outside the scope', 'fora do escopo'), size=8.5, anchor='start')
    f.line(x + 8, y + 62, x + 26, y + 62, stroke='--paper', width=1.2, dash='5 3')
    f.text(x + 32, y + 62, T('does not wait', 'não espera'), size=8.5, anchor='start')


@figure('l03-zoom', 3)
def zoom():
    f = Fig('l03-zoom', 720, 220, T(
        'The four C4 levels as successive zooms. Level 1, system context: one box for Carcará ticketing '
        'among people and other systems. Level 2, containers: the box opens into apps, an API and data '
        'stores. Level 3, components: one container, the ticketing API, opens into its main parts. '
        'Level 4, code: one component opens into classes. Each level takes one box of the level above '
        'and shows what is inside.',
        'Os quatro níveis do C4 como zooms sucessivos. Nível 1, contexto do sistema: uma caixa para a '
        'venda de passagens da Carcará entre pessoas e outros sistemas. Nível 2, containers: a caixa '
        'se abre em apps, uma API e repositórios de dados. Nível 3, componentes: um container, a API '
        'de passagens, se abre nas suas partes principais. Nível 4, código: um componente se abre em '
        'classes. Cada nível pega uma caixa do nível de cima e mostra o que tem dentro.'))
    titles = [(T('1 · System context', '1 · Contexto'), T('for everybody', 'para todo mundo')),
              (T('2 · Containers', '2 · Containers'), T('for technical people', 'para gente técnica')),
              (T('3 · Components', '3 · Componentes'), T('for the container\'s team', 'para o time do container')),
              (T('4 · Code', '4 · Código'), T('rarely drawn', 'raramente desenhado'))]
    for i, (a, b) in enumerate(titles):
        x0 = 14 + i * 178
        f.rect(x0, 30, 160, 140, stroke='--wire', fill='--ink', rx=4)
        f.text(x0 + 80, 16, a, size=10.5, weight='600')
        f.text(x0 + 80, 188, b, size=9.5, fill='--paper-dim')
        cx = x0 + 80
        if i == 0:
            f.rect(cx - 30, 85, 60, 30, stroke=IN, fill='--panel', rx=3, width=1.6)
            for px, py in [(cx - 60, 55), (cx + 60, 55), (cx - 60, 145), (cx + 60, 145)]:
                f.rect(px - 14, py - 9, 28, 18, stroke=OUT, fill='--panel', rx=3)
                f.line(px + (12 if px < cx else -12), py + (7 if py < 100 else -7),
                       cx + (-30 if px < cx else 30), 100 + (-10 if py < 100 else 10), stroke='--paper-dim', width=1)
        elif i == 1:
            f.rect(cx - 66, 40, 132, 120, stroke=IN, fill='--panel', rx=3, dash='4 3')
            for k, (px, py) in enumerate([(cx - 32, 65), (cx + 32, 65), (cx, 100), (cx - 32, 135), (cx + 32, 135)]):
                f.rect(px - 22, py - 11, 44, 22, stroke=IN, fill='--ink', rx=3, width=1.4)
            f.rect(cx - 22 - 3, 100 - 11 - 3, 50, 28, stroke='--amber', fill='none' if False else '--ink', rx=4, width=1.6)
            f.rect(cx - 22, 89, 44, 22, stroke=IN, fill='--ink', rx=3, width=1.4)
        elif i == 2:
            f.rect(cx - 66, 40, 132, 120, stroke='--amber', fill='--panel', rx=3, dash='4 3')
            for px, py in [(cx - 30, 62), (cx + 30, 62), (cx - 30, 100), (cx + 30, 100), (cx, 138)]:
                f.rect(px - 22, py - 10, 44, 20, stroke=IN, fill='--ink', rx=2, width=1.2)
        else:
            f.rect(cx - 66, 40, 132, 120, stroke='--amber', fill='--panel', rx=3, dash='4 3')
            for px, py in [(cx - 32, 70), (cx + 32, 70), (cx, 130)]:
                f.rect(px - 26, py - 18, 52, 36, stroke='--paper-dim', fill='--ink', rx=0, width=1.1)
                f.line(px - 26, py - 6, px + 26, py - 6, stroke='--paper-dim', width=1)
        if i < 3:
            f.arrow([(x0 + 162, 100), (x0 + 176, 100)], stroke='--amber', width=1.5)
    return f, T('Each diagram opens one box of the diagram before it. The audience narrows as the detail grows.',
                'Cada diagrama abre uma caixa do diagrama anterior. O público se estreita à medida que o detalhe cresce.')


def context_drawing(f, words=True):
    t = f.text if words else (lambda *a, **k: None)
    sysw = dict(words=words)
    el(f, 360, 170, 200, 70, T('Carcará ticketing', 'Venda de passagens Carcará'),
       T('[Software system]', '[Sistema de software]'), T('sells and checks bus tickets', 'vende e confere passagens'), **sysw)
    people = [(90, 60, T('Passenger', 'Passageiro')), (90, 170, T('Station agent', 'Agente de guichê')),
              (90, 280, T('Driver', 'Motorista'))]
    for x, y, n in people:
        f.circle(x, y - 30, 11, fill='--panel', stroke=IN, width=1.4)
        f.rect(x - 56, y - 17, 112, 40, stroke=IN, fill='--panel', rx=12, width=1.4)
        t(x, y - 1, n, size=9.5, weight='600')
        t(x, y + 12, T('[Person]', '[Pessoa]'), size=8, fill='--paper-dim')
    ext = [(630, 60, T('Payment gateway', 'Gateway de pagamento')), (630, 170, 'Frota'),
           (630, 280, T('Notification provider', 'Provedor de notificação'))]
    for x, y, n in ext:
        el(f, x, y, 160, 46, n, T('[Software system]', '[Sistema de software]'), ext=True, **sysw)
    P = dict(stroke='--paper', width=1.3)
    f.arrow([(146, 66), (262, 146)], **P)
    f.arrow([(146, 172), (258, 172)], **P)
    f.arrow([(146, 276), (262, 196)], **P)
    f.arrow([(460, 150), (550, 76)], **P)
    f.arrow([(550, 172), (460, 172)], **P)
    f.arrow([(460, 194), (550, 268)], **P)
    if words:
        f.tag(198, 80, T('buys tickets using', 'compra passagens'), size=8.5, anchor='start')
        f.tag(202, 162, T('sells at counters', 'vende no guichê'), size=8.5)
        f.tag(186, 270, T('checks tickets with', 'confere passagens'), size=8.5, anchor='start')
        f.tag(530, 120, T('charges cards and Pix', 'cobra cartão e Pix'), size=8.5, anchor='start')
        f.tag(505, 162, T('sends next day\'s trips', 'manda as viagens do dia'), size=8.5)
        f.tag(520, 224, T('sends tickets via', 'envia passagens por'), size=8.5, anchor='start')


@figure('l03-context', 3)
def context():
    f = Fig('l03-context', 720, 330, T(
        'The system context diagram of Carcará ticketing. In the middle, one box: Carcará ticketing, a '
        'software system that sells and checks bus tickets. On the left, three people: the passenger '
        'buys tickets using it, the station agent sells at counters, the driver checks tickets with it. '
        'On the right, three external software systems, drawn grey and dashed: the payment gateway, '
        'which charges cards and Pix; Frota, which sends the next day\'s trips; and the notification '
        'provider, through which tickets are sent.',
        'O diagrama de contexto da venda de passagens da Carcará. No meio, uma caixa: venda de '
        'passagens Carcará, um sistema de software que vende e confere passagens. À esquerda, três '
        'pessoas: o passageiro compra passagens com ele, o agente de guichê vende no guichê, o '
        'motorista confere passagens com ele. À direita, três sistemas de software externos, em cinza '
        'e tracejados: o gateway de pagamento, que cobra cartão e Pix; o Frota, que manda as viagens do '
        'dia seguinte; e o provedor de notificação, pelo qual as passagens são enviadas.'))
    context_drawing(f)
    return f, T('One box for the whole system, and only people and other systems around it. Frota is grey although Carcará owns it: grey means outside the scope, not outside the company.',
                'Uma caixa para o sistema inteiro, e só pessoas e outros sistemas em volta. O Frota é cinza embora seja da Carcará: cinza quer dizer fora do escopo, não fora da empresa.')


@picture('c4-context-shapes')
def context_picture():
    f = Fig('c4-context-shapes', 720, 330, '')
    context_drawing(f, words=False)
    return f


@figure('l03-containers', 3)
def containers():
    f = Fig('l03-containers', 720, 520, T(
        'The container diagram of Carcará ticketing. Inside a dashed boundary named Carcará ticketing: '
        'the passenger web app, a single-page app in TypeScript; the mobile app, Kotlin and Swift; the '
        'ticketing API, Kotlin with Spring Boot; the seat-hold store, Redis; the booking database, '
        'PostgreSQL; the message broker, RabbitMQ; the notification worker, Kotlin; the boarding sync '
        'service, Go; and the boarding app, Android. Both passenger apps call the ticketing API over '
        'HTTPS with JSON. The API reads and writes holds in Redis and bookings in PostgreSQL, and '
        'publishes ticket events to the broker, a dashed line meaning it does not wait. The worker '
        'consumes the events and sends tickets through the notification provider. The boarding app '
        'syncs ticket lists and scans with the boarding sync service, which reads bookings. Outside the '
        'boundary: the payment gateway, called by the API, and Frota, which sends trips to the API.',
        'O diagrama de containers da venda de passagens da Carcará. Dentro de uma fronteira tracejada '
        'chamada venda de passagens Carcará: o app web do passageiro, uma single-page app em '
        'TypeScript; o app móvel, Kotlin e Swift; a API de passagens, Kotlin com Spring Boot; o store '
        'de bloqueios, Redis; o banco de reservas, PostgreSQL; o broker de mensagens, RabbitMQ; o worker '
        'de notificação, Kotlin; o serviço de sincronização do embarque, Go; e o app de embarque, '
        'Android. Os dois apps do passageiro chamam a API de passagens por HTTPS com JSON. A API lê e '
        'grava bloqueios no Redis e reservas no PostgreSQL, e publica eventos de passagem no broker, '
        'uma linha tracejada que quer dizer que ela não espera. O worker consome os eventos e envia as '
        'passagens pelo provedor de notificação. O app de embarque sincroniza listas de passagens e '
        'leituras com o serviço de sincronização, que lê as reservas. Fora da fronteira: o gateway de '
        'pagamento, chamado pela API, e o Frota, que manda viagens para a API.'))
    f.rect(20, 30, 520, 476, stroke=IN, fill='--ink', rx=4, dash='6 4')
    f.text(30, 44, T('Carcará ticketing [Software system]', 'Venda de passagens Carcará [Sistema de software]'),
           size=9.5, anchor='start', weight='600', fill='--phosphor')
    C = T('[Container: ', '[Container: ')
    el(f, 120, 90, 170, 54, T('Passenger web app', 'App web do passageiro'), C + 'TypeScript SPA]',
       T('search, buy, show tickets', 'busca, compra, mostra'), size=9.5)
    el(f, 330, 90, 170, 54, T('Mobile app', 'App móvel'), C + 'Kotlin, Swift]',
       T('the same, on phones', 'o mesmo, no celular'), size=9.5)
    el(f, 225, 205, 190, 58, T('Ticketing API', 'API de passagens'), C + 'Kotlin, Spring Boot]',
       T('bookings, holds, payments', 'reservas, bloqueios, pagamentos'), size=9.5)
    db(f, 85, 330, 120, 66, T('Seat holds', 'Bloqueios'), '[Redis]', T('10-minute holds', 'de 10 minutos'), size=9)
    db(f, 240, 330, 130, 66, T('Booking DB', 'Banco de reservas'), '[PostgreSQL]', T('bookings, tickets', 'reservas, passagens'), size=9)
    el(f, 420, 320, 150, 50, T('Message broker', 'Broker'), '[RabbitMQ]', size=9.5)
    el(f, 455, 445, 150, 54, T('Notification worker', 'Worker de notificação'), C + 'Kotlin]', size=9.5)
    el(f, 300, 460, 130, 50, T('Boarding sync', 'Sincronização'), C + 'Go]', size=9.5)
    el(f, 95, 460, 140, 50, T('Boarding app', 'App de embarque'), C + 'Android]', size=9.5)
    el(f, 630, 160, 150, 46, T('Payment gateway', 'Gateway de pagamento'), T('[Software system]', '[Sistema]'), ext=True)
    el(f, 630, 255, 150, 46, 'Frota', T('[Software system]', '[Sistema]'), ext=True)
    el(f, 630, 360, 150, 46, T('Notification provider', 'Provedor de notificação'), T('[Software system]', '[Sistema]'), ext=True)
    P = dict(stroke='--paper', width=1.3)
    f.arrow([(140, 117), (200, 175)], **P)
    f.arrow([(310, 117), (250, 175)], **P)
    f.tag(225, 150, 'HTTPS/JSON', size=8.5, mono=True)
    f.arrow([(170, 234), (110, 296)], **P)
    f.tag(122, 258, 'RESP', size=8.5, anchor='end', mono=True)
    f.arrow([(230, 234), (238, 296)], **P)
    f.tag(242, 268, 'SQL', size=8.5, anchor='start', mono=True)
    f.arrow([(300, 230), (380, 294)], stroke='--paper', width=1.3, dash='5 3')
    f.tag(348, 252, T('publishes events', 'publica eventos'), size=8.5, anchor='start')
    f.arrow([(435, 345), (450, 416)], **P)
    f.tag(448, 380, T('consumes', 'consome'), size=8.5, anchor='start')
    f.arrow([(530, 430), (560, 384)], **P)
    f.tag(562, 412, T('sends via', 'envia por'), size=8.5, anchor='start')
    f.arrow([(320, 200), (554, 165)], **P)
    f.tag(450, 172, T('charges', 'cobra'), size=8.5)
    f.arrow([(554, 252), (320, 214)], **P)
    f.tag(470, 222, T('sends trips', 'manda viagens'), size=8.5)
    f.arrow([(166, 460), (233, 460)], **P)
    f.tag(200, 494, T('syncs lists, scans', 'sincroniza listas'), size=8.5)
    f.arrow([(290, 435), (255, 366)], **P)
    f.tag(280, 396, T('reads', 'lê'), size=8.5, anchor='start')
    return f, T('Nine containers, each with a type, a technology and a job. The dashed line to the broker is the reason a slow SMS provider cannot slow a purchase down.',
                'Nove containers, cada um com tipo, tecnologia e função. A linha tracejada até o broker é o motivo de um provedor de SMS lento não conseguir atrasar uma compra.')


@figure('l03-components', 3)
def components():
    f = Fig('l03-components', 720, 420, T(
        'The component diagram of the ticketing API. Inside a dashed boundary named ticketing API: the '
        'booking controller and the payment controller receive HTTP requests from the passenger apps; '
        'both call the booking service, which holds the rules. The booking service uses the seat-hold '
        'client, which talks to Redis, the fare quote client, which talks to pricing, the payment '
        'adapter, which talks to the payment gateway, and the booking repository, which talks to '
        'PostgreSQL. A webhook handler receives confirmations from the payment gateway and calls the '
        'booking service.',
        'O diagrama de componentes da API de passagens. Dentro de uma fronteira tracejada chamada API '
        'de passagens: o controller de reservas e o controller de pagamentos recebem pedidos HTTP dos '
        'apps do passageiro; os dois chamam o serviço de reservas, que guarda as regras. O serviço de '
        'reservas usa o cliente de bloqueios, que fala com o Redis, o cliente de cotação, que fala com '
        'o pricing, o adaptador de pagamento, que fala com o gateway de pagamento, e o repositório de '
        'reservas, que fala com o PostgreSQL. Um tratador de webhook recebe confirmações do gateway de '
        'pagamento e chama o serviço de reservas.'))
    el(f, 230, 30, 220, 40, T('Passenger apps', 'Apps do passageiro'), T('[Containers]', '[Containers]'), ext=True, size=9)
    f.rect(20, 70, 520, 270, stroke=IN, fill='--ink', rx=4, dash='6 4')
    f.text(30, 84, T('Ticketing API [Container]', 'API de passagens [Container]'), size=9.5, anchor='start',
           weight='600', fill='--phosphor')
    K = T('[Component]', '[Componente]')
    el(f, 130, 125, 160, 44, T('Booking controller', 'Controller de reservas'), K, size=9)
    el(f, 330, 125, 160, 44, T('Payment controller', 'Controller de pagamento'), K, size=9)
    el(f, 230, 205, 180, 50, T('Booking service', 'Serviço de reservas'), K, T('the rules', 'as regras'), size=9.5)
    el(f, 455, 205, 130, 44, T('Webhook handler', 'Tratador de webhook'), K, size=9)
    row = [(90, T('Seat-hold client', 'Cliente de bloqueios')), (215, T('Fare quote client', 'Cliente de cotação')),
           (340, T('Payment adapter', 'Adaptador')), (465, T('Booking repository', 'Repositório'))]
    for x, n in row:
        el(f, x, 295, 116, 44, n, K, size=8.5)
    outs = [(90, 'Redis'), (215, 'Pricing'), (340, T('Payment gateway', 'Gateway')), (465, 'PostgreSQL')]
    for x, n in outs:
        el(f, x, 385, 116, 40, n, T('[outside]', '[fora]'), ext=True, size=9)
        f.arrow([(x, 317), (x, 363)], stroke='--paper', width=1.2)
    P = dict(stroke='--paper', width=1.2)
    f.arrow([(180, 50), (140, 101)], **P)
    f.arrow([(280, 50), (320, 101)], **P)
    f.arrow([(150, 147), (200, 178)], **P)
    f.arrow([(310, 147), (262, 178)], **P)
    f.arrow([(390, 205), (322, 205)], **P)
    for x, _ in row:
        f.arrow([(230 + (x - 277) * 0.35, 230), (x, 271)], **P)
    el(f, 650, 205, 120, 44, T('Payment gateway', 'Gateway'), T('[outside]', '[fora]'), ext=True, size=9)
    f.arrow([(590, 205), (522, 205)], **P)
    f.tag(556, 194, T('confirms', 'confirma'), size=8.5)
    return f, T('The container diagram\'s single arrow to the payment gateway is explained here by two: the adapter that calls it and the webhook handler it calls back.',
                'A seta única do diagrama de containers até o gateway de pagamento se explica aqui por duas: o adaptador que o chama e o tratador de webhook que ele chama de volta.')


@figure('l03-dynamic', 3)
def dynamic():
    f = Fig('l03-dynamic', 720, 300, T(
        'A dynamic diagram of the purchase on the container boxes, with numbered relationships: 1, the '
        'mobile app creates a booking at the ticketing API; 2, the API holds the seat in the seat-hold '
        'store; 3, it writes the pending booking to the booking database; 4, the app pays; 5, the API '
        'charges the payment gateway; 6, it marks the booking paid; 7, it publishes ticket sold to the '
        'broker; 8, the notification worker sends the ticket.',
        'Um diagrama dinâmico da compra sobre as caixas de containers, com relações numeradas: 1, o app '
        'móvel cria a reserva na API de passagens; 2, a API bloqueia o assento no store; 3, grava a '
        'reserva pendente no banco de reservas; 4, o app paga; 5, a API cobra no gateway de pagamento; '
        '6, marca a reserva como paga; 7, publica passagem vendida no broker; 8, o worker de notificação '
        'envia a passagem.'))
    el(f, 100, 60, 150, 44, T('Mobile app', 'App móvel'), '[Container]')
    el(f, 360, 60, 170, 44, T('Ticketing API', 'API de passagens'), '[Container]')
    el(f, 620, 60, 150, 44, T('Payment gateway', 'Gateway'), T('[Software system]', '[Sistema]'), ext=True)
    db(f, 230, 200, 130, 60, T('Seat holds', 'Bloqueios'), '[Redis]', size=9)
    db(f, 400, 200, 130, 60, T('Booking DB', 'Banco de reservas'), '[PostgreSQL]', size=9)
    el(f, 600, 190, 140, 44, T('Message broker', 'Broker'), '[RabbitMQ]')
    el(f, 600, 270, 150, 40, T('Notification worker', 'Worker'), '[Container]', size=9)
    P = dict(stroke='--paper', width=1.3)
    f.arrow([(175, 52), (275, 52)], **P)
    f.tag(225, 42, T('1 create booking', '1 cria reserva'), size=8.5)
    f.arrow([(175, 70), (275, 70)], **P)
    f.tag(225, 84, T('4 pay', '4 paga'), size=8.5)
    f.arrow([(320, 82), (250, 168)], **P)
    f.tag(274, 120, T('2 hold seat', '2 bloqueia'), size=8.5, anchor='end')
    f.arrow([(370, 82), (395, 168)], **P)
    f.tag(390, 116, T('3 pending · 6 paid', '3 pendente · 6 paga'), size=8.5, anchor='start')
    f.arrow([(445, 60), (545, 60)], **P)
    f.tag(495, 50, T('5 charge', '5 cobra'), size=8.5)
    f.arrow([(430, 82), (560, 168)], stroke='--paper', width=1.3, dash='5 3')
    f.tag(512, 112, T('7 ticket sold', '7 vendida'), size=8.5, anchor='start')
    f.arrow([(600, 212), (600, 250)], **P)
    f.tag(608, 232, T('8 consumes, sends', '8 consome, envia'), size=8.5, anchor='start')
    return f, T('The same story as lesson 2\'s sequence diagram, told on boxes the reader already knows. The numbers carry the order; the layout carries the structure.',
                'A mesma história do diagrama de sequência da aula 2, contada sobre caixas que o leitor já conhece. Os números carregam a ordem; a disposição carrega a estrutura.')


@figure('l03-c4-wrong', 3)
def c4_wrong():
    f = Fig('l03-c4-wrong', 720, 300, T(
        'A container diagram with five mistakes, numbered. One: a box named booking service, a '
        'component, among containers. Two: a load balancer and a Kubernetes cluster drawn as '
        'containers. Three: two APIs, ticketing and back office, both writing to one database, with no '
        'owner named. Four: every line labelled uses. Five: a box named ticketing with no type and no '
        'technology.',
        'Um diagrama de containers com cinco erros, numerados. Um: uma caixa chamada serviço de '
        'reservas, um componente, entre containers. Dois: um balanceador de carga e um cluster '
        'Kubernetes desenhados como containers. Três: duas APIs, a de passagens e a de back office, as '
        'duas gravando num mesmo banco, sem dono nomeado. Quatro: toda linha com o rótulo usa. Cinco: '
        'uma caixa chamada ticketing sem tipo e sem tecnologia.'))
    el(f, 90, 60, 140, 44, T('Load balancer', 'Balanceador'), '[Container]')
    el(f, 90, 160, 140, 44, T('Kubernetes cluster', 'Cluster Kubernetes'), '[Container]')
    f.rect(260, 38, 140, 44, stroke=IN, fill='--panel', rx=5, width=1.5)
    f.text(330, 60, 'Ticketing', size=10, weight='600')
    el(f, 330, 160, 150, 44, T('Booking service', 'Serviço de reservas'), '[Component]')
    el(f, 560, 60, 150, 44, T('Back-office API', 'API de back office'), '[Container: Kotlin]')
    db(f, 470, 240, 150, 60, T('Shared database', 'Banco compartilhado'), '[PostgreSQL]', size=9)
    P = dict(stroke='--paper', width=1.3)
    for a, b, lbl in [((160, 60), (258, 60), (205, 50)), ((90, 82), (90, 136), (98, 110)),
                      ((330, 82), (330, 136), (338, 110)), ((370, 182), (440, 210), (414, 188)),
                      ((560, 82), (500, 208), (536, 140))]:
        f.arrow([a, b], **P)
        f.text(lbl[0], lbl[1], T('uses', 'usa'), size=8.5, anchor='start' if lbl != (205, 50) else 'middle')
    f.badge(330, 196, 1, fill='--amber')
    f.badge(20, 110, 2, fill='--amber')
    f.badge(560, 240, 3, fill='--amber')
    f.badge(250, 46, 4, fill='--amber')
    f.badge(410, 40, 5, fill='--amber')
    return f, T('Each box and line is drawable in any tool and wrong in C4\'s vocabulary. The checklist in this section finds all five.',
                'Cada caixa e cada linha se desenha em qualquer ferramenta e está errada no vocabulário do C4. A lista desta seção encontra os cinco.')
