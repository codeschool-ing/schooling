"""Lesson 1: what a diagram is for."""
from figures import Fig, T, figure, picture


@figure('l01-decorated', 1)
def decorated():
    f = Fig('l01-decorated', 720, 330, T(
        'Two drawings of Carcará. On the left, the printout on the wall: eight boxes named after '
        'products, such as PostgreSQL, Redis, RabbitMQ, the cloud provider and a phone, joined by '
        'nine arrows with no words on them. On the right, the diagram drawn to answer one question, '
        'which service takes the money when somebody buys a ticket: a passenger, the passenger app, '
        'the ticketing API, the booking database and the payment gateway, each with its type, joined '
        'by four labelled lines.',
        'Dois desenhos da Carcará. À esquerda, o impresso na parede: oito caixas com nomes de '
        'produtos, como PostgreSQL, Redis, RabbitMQ, o provedor de nuvem e um celular, ligadas por '
        'nove setas sem nenhuma palavra. À direita, o diagrama desenhado para responder a uma '
        'pergunta, qual serviço recebe o dinheiro quando alguém compra uma passagem: um passageiro, '
        'o app do passageiro, a API de passagens, o banco de reservas e o gateway de pagamento, cada '
        'um com seu tipo, ligados por quatro linhas com rótulo.'))
    f.text(175, 18, T('the printout on the wall', 'o impresso na parede'), size=11, weight='600')
    f.text(545, 18, T('drawn for one question', 'desenhado para uma pergunta'), size=11, weight='600')
    f.line(360, 30, 360, 315, stroke='--wire', width=1)
    P = dict(stroke='--paper-dim', width=1.2, arrow=True)
    boxes = {'phone': (70, 70), 'cloud': (200, 60), 'pg': (300, 110), 'redis': (90, 170),
             'mq': (220, 160), 'gw': (300, 230), 'bus': (80, 270), 'pg2': (200, 280)}
    names = {'phone': T('Phone', 'Celular'), 'cloud': T('Cloud', 'Nuvem'), 'pg': 'PostgreSQL',
             'redis': 'Redis', 'mq': 'RabbitMQ', 'gw': T('Payments', 'Pagamentos'),
             'bus': T('Bus', 'Ônibus'), 'pg2': 'PostgreSQL'}
    for k, (x, y) in boxes.items():
        f.rect(x - 42, y - 15, 84, 30, stroke='--paper-dim', fill='--panel', rx=8)
        f.text(x, y, names[k], size=9.5)
    for a, b in [('phone', 'cloud'), ('cloud', 'pg'), ('cloud', 'mq'), ('mq', 'redis'), ('redis', 'phone'),
                 ('mq', 'gw'), ('gw', 'pg'), ('bus', 'mq'), ('mq', 'pg2')]:
        (x1, y1), (x2, y2) = boxes[a], boxes[b]
        dx, dy = x2 - x1, y2 - y1
        n = (dx * dx + dy * dy) ** 0.5
        k1 = min(42 / abs(dx) if dx else 9e9, 15 / abs(dy) if dy else 9e9)
        f.arrow([(x1 + dx * k1, y1 + dy * k1), (x2 - dx * k1 * 1.08, y2 - dy * k1 * 1.08)], **P)
    # the right-hand diagram
    f.person(440, 90, [T('Passenger', 'Passageiro')], size=9.5)
    f.box(620, 75, 150, 46, T('Passenger app', 'App do passageiro'), sub=T('[web and mobile]', '[web e celular]'),
          size=9.5, stroke='--phosphor')
    f.box(620, 175, 150, 46, T('Ticketing API', 'API de passagens'), sub=T('[Kotlin service]', '[serviço Kotlin]'),
          size=9.5, stroke='--phosphor')
    f.box(450, 270, 150, 46, T('Booking database', 'Banco de reservas'), sub='[PostgreSQL]', size=9.5,
          stroke='--phosphor')
    f.box(620, 285, 150, 46, T('Payment gateway', 'Gateway de pagamento'),
          sub=T('[external system]', '[sistema externo]'), size=9.5, stroke='--paper-dim', dash='4 3')
    L = dict(stroke='--paper', width=1.3, arrow=True)
    f.arrow([(486, 80), (543, 76)], **L)
    f.tag(514, 62, T('buys', 'compra'), size=8.5)
    f.arrow([(620, 98), (620, 150)], **L)
    f.tag(628, 124, T('HTTPS: create booking', 'HTTPS: cria reserva'), size=8.5, anchor='start')
    f.arrow([(560, 198), (490, 245)], **L)
    f.tag(538, 205, T('SQL: writes', 'SQL: grava'), size=8.5, anchor='end')
    f.arrow([(620, 198), (620, 260)], **L)
    f.tag(650, 230, T('HTTPS: charges', 'HTTPS: cobra'), size=8.5, anchor='start')
    return f, T('The left picture asserts that eight things are connected. The right one says what each thing is and what travels along each line, so a reader can check it, and disagree with it.',
                'O desenho da esquerda afirma que oito coisas estão ligadas. O da direita diz o que cada coisa é e o que passa por cada linha, então quem lê pode conferir, e discordar.')


@figure('l01-arrow-meanings', 1)
def arrow_meanings():
    f = Fig('l01-arrow-meanings', 720, 300, T(
        'One unlabelled arrow from the passenger app to the ticketing API, and five things it is '
        'commonly taken to mean: the app calls the API; data flows from the app to the API; the app '
        'depends on the API, so a change to the API can break it; the app is part of, or owned by, '
        'the API; the app comes before the API in a sequence of steps. The first two describe the '
        'same conversation and can point in opposite directions.',
        'Uma seta sem rótulo do app do passageiro para a API de passagens, e cinco coisas que se '
        'costuma entender por ela: o app chama a API; dados vão do app para a API; o app depende da '
        'API, então uma mudança na API pode quebrá-lo; o app é parte da API, ou pertence a ela; o app '
        'vem antes da API numa sequência de passos. As duas primeiras descrevem a mesma conversa e '
        'podem apontar em sentidos opostos.'))
    f.box(110, 46, 150, 40, T('Passenger app', 'App do passageiro'), size=10)
    f.box(410, 46, 150, 40, T('Ticketing API', 'API de passagens'), size=10)
    f.arrow([(186, 46), (334, 46)], stroke='--paper', width=1.6)
    f.text(260, 30, '?', size=14, weight='600', fill='--amber')
    rows = [
        (T('calls', 'chama'), T('the app sends requests and waits for answers', 'o app manda pedidos e espera respostas')),
        (T('sends data to', 'manda dados para'), T('the order travels this way; the answer comes back the other way',
                                                   'o pedido vai por aqui; a resposta volta pelo outro lado')),
        (T('depends on', 'depende de'), T('change the API and the app may break', 'mude a API e o app pode quebrar')),
        (T('is part of', 'é parte de'), T('owned by, deployed with, or contained in', 'pertence, é implantado junto, ou está dentro')),
        (T('comes before', 'vem antes de'), T('a step in a process, not a call at all', 'um passo de um processo, nem é uma chamada')),
    ]
    for i, (k, v) in enumerate(rows):
        y = 112 + i * 36
        f.badge(48, y, i + 1)
        f.text(72, y, k, size=10.5, anchor='start', weight='600')
        f.text(210, y, v, size=10, anchor='start', fill='--paper-dim')
    f.text(612, 124, T('opposite', 'sentidos'), size=9.5, anchor='start', fill='--amber', italic=True)
    f.text(612, 138, T('directions', 'opostos'), size=9.5, anchor='start', fill='--amber', italic=True)
    f.path('M590 104 L600 104 L600 152 L590 152', stroke='--amber', width=1.2)
    return f, T('An arrow with no label leaves the reader to choose one of five meanings, and different readers choose differently without knowing it.',
                'Uma seta sem rótulo deixa quem lê escolher entre cinco significados, e leitores diferentes escolhem diferente sem saber.')


@figure('l01-four-plus-one', 1)
def four_plus_one():
    f = Fig('l01-four-plus-one', 720, 280, T(
        'Kruchten\'s 4+1 view model. Four views in the corners: logical, for designers; development, '
        'for developers; process, for performance and reliability; physical, for operations. In the '
        'middle, the scenarios, the use cases that connect all four and are used to check that they '
        'agree.',
        'O modelo 4+1 de Kruchten. Quatro visões nos cantos: lógica, para quem projeta; de '
        'desenvolvimento, para quem programa; de processo, para desempenho e confiabilidade; física, '
        'para operações. No meio, os cenários, os casos de uso que ligam as quatro e servem para '
        'conferir que elas concordam.'))
    cells = [(150, 60, T('Logical view', 'Visão lógica'), T('abstractions and relations', 'abstrações e relações'),
              T('for designers', 'para quem projeta')),
             (570, 60, T('Development view', 'Visão de desenvolvimento'), T('modules and owners', 'módulos e donos'),
              T('for developers', 'para quem programa')),
             (150, 220, T('Process view', 'Visão de processo'), T('what runs concurrently', 'o que roda ao mesmo tempo'),
              T('for performance', 'para desempenho')),
             (570, 220, T('Physical view', 'Visão física'), T('machines and networks', 'máquinas e redes'),
              T('for operations', 'para operações'))]
    for x, y, a, b, c in cells:
        f.box(x, y, 210, 66, a, sub=[b, c], size=11, stroke='--wire')
    f.ellipse(360, 140, 110, 44, None, stroke='--phosphor')
    f.text(360, 128, T('Scenarios (+1)', 'Cenários (+1)'), size=11, weight='600')
    f.text(360, 147, T('use cases walked', 'casos de uso percorridos'), size=9.5, fill='--paper-dim')
    f.text(360, 161, T('through all four', 'pelas quatro'), size=9.5, fill='--paper-dim')
    for x, y in [(255, 80), (465, 80), (255, 200), (465, 200)]:
        sx = 300 if x < 360 else 420
        sy = 112 if y < 140 else 168
        f.line(x, y, sx, sy, stroke='--phosphor', width=1.2, dash='4 3')
    return f, T('The four views answer four different questions. The scenarios are the check: one use case walked through every view finds the places where they disagree.',
                'As quatro visões respondem a quatro perguntas diferentes. Os cenários são a conferência: um caso de uso percorrido por todas as visões encontra os pontos em que elas discordam.')


def anatomy_drawing(f, words=True):
    """The anatomy diagram, with or without its lettering."""
    t = f.text if words else (lambda *a, **k: None)
    f.rect(20, 20, 680, 300, stroke='--wire', fill='--ink', rx=6)
    t(46, 42, T('Carcará ticket sales: containers', 'Vendas da Carcará: containers'), size=12, anchor='start',
      weight='600')
    t(46, 60, T('checked 2 March 2026 · owner: Tainá', 'conferido em 2 de março de 2026 · dona: Tainá'),
      size=9, anchor='start', fill='--paper-dim')
    f.rect(60, 90, 420, 200, stroke='--amber', fill='--ink', rx=2, dash='6 4')
    t(70, 104, T('Carcará cloud account', 'Conta de nuvem da Carcará'), size=9, anchor='start', fill='--amber',
      italic=True)
    f.rect(90, 130, 150, 50, stroke='--phosphor', fill='--panel', rx=4, width=1.4)
    t(165, 147, T('Ticketing API', 'API de passagens'), size=10, weight='600')
    t(165, 164, T('[Kotlin service]', '[serviço Kotlin]'), size=8.5, fill='--paper-dim')
    f.rect(300, 220, 150, 50, stroke='--phosphor', fill='--panel', rx=4, width=1.4)
    t(375, 237, T('Booking database', 'Banco de reservas'), size=10, weight='600')
    t(375, 254, '[PostgreSQL]', size=8.5, fill='--paper-dim')
    f.arrow([(240, 165), (330, 218)], stroke='--paper', width=1.3)
    if words:
        f.tag(292, 178, T('SQL: writes bookings', 'SQL: grava reservas'), size=8.5, anchor='start')
    f.rect(520, 90, 160, 120, stroke='--wire', fill='--panel', rx=3)
    t(530, 104, T('Legend', 'Legenda'), size=9.5, anchor='start', weight='600')
    f.rect(532, 116, 22, 14, stroke='--phosphor', fill='--panel', rx=2)
    t(562, 123, T('our container', 'container nosso'), size=8.5, anchor='start')
    f.rect(532, 140, 22, 14, stroke='--paper-dim', fill='--panel', rx=2, dash='4 3')
    t(562, 147, T('external system', 'sistema externo'), size=8.5, anchor='start')
    f.line(532, 170, 554, 170, stroke='--paper', width=1.3)
    t(562, 170, T('call, waits', 'chamada, espera'), size=8.5, anchor='start')
    f.line(532, 192, 554, 192, stroke='--amber', width=1.3, dash='6 4')
    t(562, 192, T('our network', 'nossa rede'), size=8.5, anchor='start')


@figure('l01-anatomy', 1)
def anatomy():
    f = Fig('l01-anatomy', 720, 340, T(
        'The anatomy of a readable diagram. At the top, a title saying what is shown, Carcará ticket '
        'sales: containers, and under it the date it was checked and its owner. A dashed amber '
        'boundary named Carcará cloud account. Inside it, two elements, each with a name and a type '
        'in brackets: Ticketing API, a Kotlin service, and Booking database, PostgreSQL. A line '
        'between them labelled SQL: writes bookings. On the right, a legend explaining the solid '
        'box, the dashed box, the solid line and the dashed boundary.',
        'A anatomia de um diagrama legível. No alto, um título dizendo o que é mostrado, Vendas da '
        'Carcará: containers, e embaixo dele a data em que foi conferido e a dona. Uma fronteira '
        'âmbar tracejada chamada Conta de nuvem da Carcará. Dentro dela, dois elementos, cada um com '
        'nome e tipo entre colchetes: API de passagens, um serviço Kotlin, e Banco de reservas, '
        'PostgreSQL. Uma linha entre eles com o rótulo SQL: grava reservas. À direita, uma legenda '
        'explicando a caixa contínua, a caixa tracejada, a linha contínua e a fronteira tracejada.'))
    anatomy_drawing(f)
    for n, (x, y) in enumerate([(28, 42), (165, 196), (300, 198), (700, 150), (28, 60)], 1):
        f.badge(x, y, n)
    return f, T('1 a title with the scope, 2 a type on every element, 3 a label on every line, 4 a legend for every kind of mark, 5 a date and an owner.',
                '1 um título com o escopo, 2 um tipo em cada elemento, 3 um rótulo em cada linha, 4 uma legenda para cada tipo de marca, 5 uma data e um dono.')


@picture('anatomy')
def anatomy_picture():
    f = Fig('anatomy', 720, 340, '')
    anatomy_drawing(f, words=False)
    return f
