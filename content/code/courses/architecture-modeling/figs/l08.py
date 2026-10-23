"""Lesson 8: TOGAF."""
import math
from figures import Fig, T, figure, picture


@figure('l08-domains', 8)
def domains():
    f = Fig('l08-domains', 720, 290, T(
        'TOGAF\'s four architecture domains as stacked layers, each with Carcará\'s contents. Business: '
        'selling online and at 26 counters, boarding at the bus door, running the fleet. Data: '
        'passengers, bookings, tickets, trips, buses, payments. Application: ticketing, boarding app, '
        'station back office, Frota, finance package. Technology: one cloud region, drivers\' phones, '
        'station PCs and printers, station internet links. Data and application are bracketed together '
        'as the information systems architectures.',
        'Os quatro domínios de arquitetura do TOGAF como camadas empilhadas, cada uma com o conteúdo da '
        'Carcará. Negócio: vender online e em 26 guichês, embarcar na porta do ônibus, operar a frota. '
        'Dados: passageiros, reservas, passagens, viagens, ônibus, pagamentos. Aplicação: venda de '
        'passagens, app de embarque, back office das estações, Frota, pacote financeiro. Tecnologia: uma '
        'região de nuvem, celulares dos motoristas, PCs e impressoras das estações, links de internet das '
        'estações. Dados e aplicação aparecem agrupados como arquiteturas de sistemas de informação.'))
    rows = [(T('Business', 'Negócio'), T('selling online and at 26 counters · boarding at the door · running the fleet',
                                          'vender online e em 26 guichês · embarcar na porta · operar a frota'), '--amber'),
            (T('Data', 'Dados'), T('passengers · bookings · tickets · trips · buses · payments',
                                   'passageiros · reservas · passagens · viagens · ônibus · pagamentos'), '--phosphor'),
            (T('Application', 'Aplicação'), T('ticketing · boarding app · station back office · Frota · finance',
                                              'venda de passagens · app de embarque · back office · Frota · finanças'), '--phosphor'),
            (T('Technology', 'Tecnologia'), T('cloud region · drivers\' phones · station PCs and printers · links',
                                              'região de nuvem · celulares · PCs e impressoras · links'), '--paper-dim')]
    for i, (n, d, c) in enumerate(rows):
        y = 20 + i * 66
        f.rect(130, y, 560, 54, stroke=c, fill='--panel', rx=4, width=1.5)
        f.text(145, y + 18, n, size=11, anchor='start', weight='600')
        f.text(145, y + 37, d, size=9.5, anchor='start', fill='--paper-dim')
    f.path('M118 92 L108 92 L108 206 L118 206', stroke='--phosphor', width=1.3)
    f.text(98, 140, T('information', 'sistemas de'), size=9, anchor='end', fill='--phosphor')
    f.text(98, 154, T('systems', 'informação'), size=9, anchor='end', fill='--phosphor')
    return f, T('The business layer on top is what C4 does not draw. The other three are where the systems of lessons 2 and 3 live.',
                'A camada de negócio, no alto, é o que o C4 não desenha. As outras três são onde vivem os sistemas das aulas 2 e 3.')


def PHASES(): return [('A', T('Architecture Vision', 'Visão de Arquitetura')), ('B', T('Business', 'Negócio')),
          ('C', T('Information Systems', 'Sistemas de Informação')), ('D', T('Technology', 'Tecnologia')),
          ('E', T('Opportunities and Solutions', 'Oportunidades e Soluções')), ('F', T('Migration Planning', 'Planejamento de Migração')),
          ('G', T('Implementation Governance', 'Governança da Implementação')), ('H', T('Change Management', 'Gestão de Mudanças'))]


def adm_drawing(f, words=True):
    cx, cy, R = 360, 205, 130
    t = f.text if words else (lambda *a, **k: None)
    f.circle(cx, 36, 30, fill='--panel', stroke='--amber', width=1.6)
    t(cx, 36, T('Prelim.', 'Prelim.'), size=9.5, weight='600')
    f.line(cx, 66, cx, 76, stroke='--paper-dim', width=1.2)
    f.circle(cx, cy, 52, fill='--panel', stroke='--amber', width=1.6)
    t(cx, cy - 8, T('Requirements', 'Gerenciamento'), size=9.5, weight='600')
    t(cx, cy + 8, T('Management', 'de Requisitos'), size=9.5, weight='600')
    pts = []
    for i in range(8):
        a = -math.pi / 2 + (i + 0.5) * math.pi / 4
        pts.append((cx + R * math.cos(a), cy + R * math.sin(a) * 0.93))
    for i in range(8):
        a1 = -math.pi / 2 + (i + 0.5) * math.pi / 4 + 0.22
        a2 = -math.pi / 2 + (i + 1.5) * math.pi / 4 - 0.22
        p1 = (cx + R * math.cos(a1), cy + R * math.sin(a1) * 0.93)
        p2 = (cx + R * math.cos(a2), cy + R * math.sin(a2) * 0.93)
        f.path(f'M{p1[0]:.1f} {p1[1]:.1f} A{R} {R * 0.93:.1f} 0 0 1 {p2[0]:.1f} {p2[1]:.1f}', stroke='--paper-dim',
               width=1.2, arrow=True)
    for (x, y), (k, n) in zip(pts, PHASES()):
        f.line(x + (cx - x) * 0.22, y + (cy - y) * 0.22, x + (cx - x) * 0.55, y + (cy - y) * 0.55,
               stroke='--wire', width=1, dash='3 3')
        f.circle(x, y, 22, fill='--panel', stroke='--phosphor', width=1.6)
        t(x, y + 0.5, k, size=13, weight='600')
        if words:
            right = x > cx
            f.text(x + (30 if right else -30), y, n, size=9.5, anchor='start' if right else 'end')


@figure('l08-adm', 8)
def adm():
    f = Fig('l08-adm', 720, 370, T(
        'The ADM cycle. At the top, the Preliminary phase. Below it, a ring of eight phases joined '
        'clockwise by arrows: A Architecture Vision, B Business Architecture, C Information Systems '
        'Architectures, D Technology Architecture, E Opportunities and Solutions, F Migration Planning, '
        'G Implementation Governance, H Architecture Change Management, which leads back to A. In the '
        'centre, Requirements Management, joined to every phase.',
        'O ciclo ADM. No alto, a fase Preliminar. Abaixo dela, um anel de oito fases ligadas no sentido '
        'horário por setas: A Visão de Arquitetura, B Arquitetura de Negócio, C Arquiteturas de Sistemas '
        'de Informação, D Arquitetura de Tecnologia, E Oportunidades e Soluções, F Planejamento de '
        'Migração, G Governança da Implementação, H Gestão de Mudanças na Arquitetura, que leva de volta a '
        'A. No centro, o Gerenciamento de Requisitos, ligado a todas as fases.'))
    adm_drawing(f)
    return f, T('A ring, not a line: H leads back to A. The centre is the part people forget, and every phase both feeds it and draws from it.',
                'Um anel, não uma linha: H leva de volta a A. O centro é a parte que se esquece, e toda fase o alimenta e tira dele.')


@picture('adm-ring')
def adm_picture():
    f = Fig('adm-ring', 720, 370, '')
    adm_drawing(f, words=False)
    return f


@figure('l08-continuum', 8)
def continuum():
    f = Fig('l08-continuum', 720, 170, T(
        'The enterprise continuum as an arrow from generic on the left to specific on the right, with '
        'four kinds of architecture along it: foundation architectures, common systems architectures, '
        'industry architectures and organisation-specific architectures. Reuse means looking further '
        'left before designing.',
        'O continuum corporativo como uma seta do genérico, à esquerda, ao específico, à direita, com '
        'quatro tipos de arquitetura ao longo dela: arquiteturas de fundação, arquiteturas de sistemas '
        'comuns, arquiteturas da indústria e arquiteturas específicas da organização. Reutilizar é olhar '
        'mais para a esquerda antes de desenhar.'))
    f.arrow([(30, 110), (690, 110)], stroke='--paper-dim', width=2)
    f.text(30, 135, T('generic', 'genérico'), size=10, anchor='start', fill='--paper-dim', italic=True)
    f.text(690, 135, T('specific', 'específico'), size=10, anchor='end', fill='--paper-dim', italic=True)
    items = [(110, T('Foundation', 'Fundação'), T('true of almost anybody', 'vale para quase todos')),
             (277, T('Common systems', 'Sistemas comuns'), T('identity, payments', 'identidade, pagamentos')),
             (444, T('Industry', 'Indústria'), T('transport ticketing', 'bilhetagem de transporte')),
             (611, T('Organisation', 'Organização'), T('Carcará\'s own', 'a da Carcará'))]
    for x, n, d in items:
        f.box(x, 58, 150, 52, n, sub=d, size=10.5, stroke='--phosphor')
        f.circle(x, 110, 4, fill='--phosphor')
    f.text(360, 158, T('before designing, look further left', 'antes de desenhar, olhe mais para a esquerda'), size=9.5,
           fill='--amber', italic=True)
    return f, T('Carcará did not invent offline ticket validation: an industry reference design existed, and reading it saved weeks.',
                'A Carcará não inventou a validação de passagem sem rede: havia um desenho de referência da indústria, e lê-lo poupou semanas.')
