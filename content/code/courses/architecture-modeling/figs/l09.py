"""Lesson 9: IAF and ArchiMate."""
from figures import Fig, T, figure, picture

LEVELS = [(T('Contextual', 'Contextual'), T('why?', 'por quê?')), (T('Conceptual', 'Conceitual'), T('what?', 'o quê?')),
          (T('Logical', 'Lógico'), T('how?', 'como?')), (T('Physical', 'Físico'), T('with what?', 'com o quê?'))]
AREAS = [T('Business', 'Negócio'), T('Information', 'Informação'), T('Information systems', 'Sistemas de informação'),
         T('Technology', 'Tecnologia')]


def grid_drawing(f, words=True):
    t = f.text if words else (lambda *a, **k: None)
    x0, y0, cw, rh = 150, 50, 115, 52
    for j, a in enumerate(AREAS):
        t(x0 + cw * j + cw / 2, y0 - 16, a, size=9.5, weight='600')
    for i, (lv, q) in enumerate(LEVELS):
        y = y0 + i * rh
        f.rect(20, y + 4, 120, rh - 8, stroke='--amber', fill='--panel', rx=4, width=1.4)
        t(80, y + rh / 2 - 7, lv, size=10, weight='600')
        t(80, y + rh / 2 + 9, q, size=9, fill='--paper-dim', italic=True)
        for j in range(4):
            hi = (j == 2)
            f.rect(x0 + cw * j + 4, y + 4, cw - 8, rh - 8, stroke='--phosphor' if hi else '--wire', fill='--panel', rx=3,
                   width=1.5 if hi else 1)
    f.rect(x0 + 4 * cw + 4, y0 + 4, 50, 4 * rh - 8, stroke='--paper-dim', fill='--ink', rx=3, dash='4 3')
    f.rect(x0 + 4 * cw + 58, y0 + 4, 50, 4 * rh - 8, stroke='--paper-dim', fill='--ink', rx=3, dash='4 3')
    if words:
        for k, n in enumerate([T('security', 'segurança'), T('governance', 'governança')]):
            cx = x0 + 4 * cw + 29 + k * 54
            f.parts.append(f'<text x="{cx}" y="{y0 + 2 * rh}" text-anchor="middle" dominant-baseline="middle" '
                           f'font-family="\'IBM Plex Sans\', sans-serif" font-size="9" fill="var(--paper)" '
                           f'transform="rotate(-90 {cx} {y0 + 2 * rh})">{n}</text>')


@figure('l09-grid', 9)
def grid():
    f = Fig('l09-grid', 720, 270, T(
        'IAF\'s grid. Four rows are the abstraction levels, asked in order: contextual, why; conceptual, '
        'what; logical, how; physical, with what. Four columns are the aspect areas: business, '
        'information, information systems and technology. The information systems column is '
        'highlighted, the column the lesson walks down. Two vertical bands on the right, security and '
        'governance, cut across every row.',
        'A grade do IAF. Quatro linhas são os níveis de abstração, perguntados em ordem: contextual, por '
        'quê; conceitual, o quê; lógico, como; físico, com o quê. Quatro colunas são as áreas de aspecto: '
        'negócio, informação, sistemas de informação e tecnologia. A coluna de sistemas de informação '
        'aparece em destaque, a coluna que a aula percorre. Duas faixas verticais à direita, segurança e '
        'governança, atravessam todas as linhas.'))
    grid_drawing(f)
    return f, T('Each cell is justified by the one above it. A product choice in the bottom row with nothing above it in its column is visibly floating.',
                'Cada célula se justifica pela de cima. Uma escolha de produto na última linha sem nada acima dela na coluna aparece flutuando.')


@picture('iaf-grid')
def grid_picture():
    f = Fig('iaf-grid', 720, 270, '')
    grid_drawing(f, words=False)
    return f


@figure('l09-archimate', 9)
def archimate():
    f = Fig('l09-archimate', 720, 380, T(
        'A small ArchiMate view of Carcará in three layers. Business layer: the passenger, a business '
        'actor, assigned to the business process buy a ticket. Application layer: the application service '
        'ticket sales serves the process; the application component ticketing realises the service and '
        'accesses the data object booking. Technology layer: the technology service container runtime '
        'serves ticketing, and is realised by the node container cluster.',
        'Uma pequena visão ArchiMate da Carcará em três camadas. Camada de negócio: o passageiro, um ator '
        'de negócio, atribuído ao processo de negócio comprar passagem. Camada de aplicação: o serviço de '
        'aplicação venda de passagens serve o processo; o componente de aplicação sistema de vendas o '
        'realiza e acessa o objeto de dados reserva. Camada de tecnologia: o serviço de tecnologia runtime '
        'de containers serve o sistema de vendas, e é realizado pelo nó cluster de containers.'))
    bands = [(10, T('Business', 'Negócio'), '--amber'), (130, T('Application', 'Aplicação'), '--phosphor'),
             (250, T('Technology', 'Tecnologia'), '--paper-dim')]
    for y, n, c in bands:
        f.rect(10, y, 700, 112, stroke=c, fill='--ink', rx=4, width=1, dash='4 3')
        f.text(22, y + 14, n, size=9.5, anchor='start', fill=c, weight='600')
    # business
    f.rect(120, 40, 140, 50, stroke='--amber', fill='--panel', rx=2, width=1.4)
    f.circle(244, 52, 4, fill=None, stroke='--paper', width=1)
    f.line(244, 56, 244, 63, stroke='--paper', width=1)
    f.line(239, 59, 249, 59, stroke='--paper', width=1)
    f.text(182, 66, T('Passenger', 'Passageiro'), size=10, weight='600')
    f.rect(400, 40, 170, 50, stroke='--amber', fill='--panel', rx=12, width=1.4)
    f.path('M542 50 L556 50 L562 56 L556 62 L542 62 L548 56 Z', stroke='--paper', width=1)
    f.text(470, 66, T('Buy a ticket', 'Comprar passagem'), size=10, weight='600')
    f.circle(262, 65, 3, fill='--paper')
    f.arrow([(265, 65), (398, 65)], stroke='--paper', width=1.3)
    f.text(330, 56, T('assignment', 'atribuição'), size=8.5, fill='--paper-dim')
    # application
    f.rect(400, 140, 170, 36, stroke='--phosphor', fill='--panel', rx=18, width=1.4)
    f.text(485, 158, T('Ticket sales', 'Venda de passagens'), size=10, weight='600')
    f.arrow([(485, 140), (485, 92)], stroke='--paper', width=1.3, head='open')
    f.text(478, 112, T('serving', 'serve'), size=8.5, anchor='end', fill='--paper-dim')
    f.rect(400, 206, 170, 30, stroke='--phosphor', fill='--panel', rx=2, width=1.4)
    f.rect(552, 210, 12, 9, stroke='--paper', fill='--panel', rx=0, width=0.8)
    f.text(476, 221, T('Ticketing', 'Sistema de vendas'), size=10, weight='600')
    f.arrow([(470, 206), (470, 178)], stroke='--paper', width=1.2, dash='4 3', head='hollow')
    f.text(462, 192, T('realises', 'realiza'), size=8.5, anchor='end', fill='--paper-dim')
    f.rect(150, 196, 130, 40, stroke='--phosphor', fill='--panel', rx=0, width=1.4)
    f.line(150, 208, 280, 208, stroke='--phosphor', width=1)
    f.text(215, 223, T('Booking', 'Reserva'), size=10, weight='600')
    f.arrow([(400, 221), (282, 221)], stroke='--paper', width=1.1, dash='2 3', head='open')
    f.text(340, 212, T('accesses', 'acessa'), size=8.5, fill='--paper-dim')
    # technology
    f.rect(400, 268, 170, 34, stroke='--paper-dim', fill='--panel', rx=17, width=1.4)
    f.text(485, 285, T('Container runtime', 'Runtime de containers'), size=10, weight='600')
    f.arrow([(485, 268), (485, 236)], stroke='--paper', width=1.3, head='open')
    f.text(478, 254, T('serving', 'serve'), size=8.5, anchor='end', fill='--paper-dim')
    f.node(410, 322, 150, 26, None)
    f.text(485, 335, T('Container cluster', 'Cluster de containers'), size=10, weight='600')
    f.arrow([(485, 322), (485, 304)], stroke='--paper', width=1.2, dash='4 3', head='hollow')
    f.text(392, 315, T('realises', 'realiza'), size=8.5, anchor='end', fill='--paper-dim')
    return f, T('Each shape is a type of element and each line a type of relationship, both defined by the specification. Serving and realisation are as different here as composition and aggregation were in UML.',
                'Cada forma é um tipo de elemento e cada linha um tipo de relação, ambos definidos pela especificação. Servir e realizar são tão diferentes aqui quanto composição e agregação eram na UML.')
