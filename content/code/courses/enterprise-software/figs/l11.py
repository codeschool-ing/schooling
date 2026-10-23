"""Lesson 11: Enterprise integration patterns (EIP)."""
import math

from figures import Fig, T, figure

# ---- simplified icons after the book's notation, each drawn in a frame centred on x, y


def _frame(f, x, y, stroke='--phosphor', w=54, h=38):
    f.rect(x - w / 2, y - h / 2, w, h, stroke=stroke, fill='--panel', width=1.4, rx=3)


def ic_router(f, x, y, stroke='--phosphor'):
    _frame(f, x, y, stroke)
    f.line(x - 20, y, x - 4, y, stroke='--paper', width=1.4)
    for dy in (-11, 0, 11):
        f.line(x - 4, y, x + 18, y + dy, stroke='--paper', width=1.4)


def ic_translator(f, x, y, stroke='--phosphor'):
    _frame(f, x, y, stroke)
    f.rect(x - 19, y - 5, 10, 10, stroke='--paper', fill='--panel', width=1.3, rx=0)
    f.line(x - 6, y, x + 4, y, stroke='--paper', width=1.3)
    f.circle(x + 13, y, 5.5, fill=None, stroke='--paper', width=1.3)


def ic_splitter(f, x, y, stroke='--phosphor'):
    _frame(f, x, y, stroke)
    f.rect(x - 20, y - 9, 12, 18, stroke='--paper', fill='--panel', width=1.3, rx=0)
    for dy in (-11, 0, 11):
        f.line(x - 6, y, x + 8, y + dy, stroke='--paper-dim', width=1)
        f.rect(x + 9, y + dy - 3.5, 8, 7, stroke='--paper', fill='--panel', width=1.2, rx=0)


def ic_aggregator(f, x, y, stroke='--phosphor'):
    _frame(f, x, y, stroke)
    for dy in (-11, 0, 11):
        f.rect(x - 17, y + dy - 3.5, 8, 7, stroke='--paper', fill='--panel', width=1.2, rx=0)
        f.line(x - 8, y + dy, x + 6, y, stroke='--paper-dim', width=1)
    f.rect(x + 8, y - 9, 12, 18, stroke='--paper', fill='--panel', width=1.3, rx=0)


def ic_enricher(f, x, y, stroke='--phosphor'):
    _frame(f, x, y, stroke)
    f.rect(x - 20, y - 4, 10, 10, stroke='--paper', fill='--panel', width=1.3, rx=0)
    f.line(x - 8, y + 1, x + 2, y + 1, stroke='--paper', width=1.3)
    f.rect(x + 5, y - 4, 10, 10, stroke='--paper', fill='--panel', width=1.3, rx=0)
    f.rect(x + 15, y - 4, 5, 10, stroke='--paper', fill='--paper', width=1.3, rx=0)
    f.line(x + 12, y - 15, x + 12, y - 6, stroke='--paper-dim', width=1)


def ic_channel(f, x, y, w=54):
    f.rect(x - w / 2, y - 7, w, 14, stroke='--paper-dim', fill='--panel', width=1.3, rx=7)
    f.path(f'M{x + w / 2 - 7:.1f} {y - 7:.1f} A 4 7 0 0 0 {x + w / 2 - 7:.1f} {y + 7:.1f}',
           stroke='--paper-dim', width=1.1)


def ic_message(f, x, y):
    f.rect(x - 13, y - 10, 26, 20, stroke='--paper', fill='--panel', width=1.3, rx=1)
    f.rect(x - 13, y - 10, 26, 6, stroke='--paper', fill='--phosphor', width=1.3, rx=1)


@figure('l11-notation', 11)
def notation():
    f = Fig('l11-notation', 720, 186, T(
        'Six simplified icons in the notation of Enterprise Integration Patterns, each with its name '
        'and how many messages go in and come out. Message channel: a tube that carries messages. '
        'Message: a small block with a header band on top of the body. Content-based router: one '
        'line in, forking to three outputs; one message in, one out on one of several channels. '
        'Message translator: a square in, a circle out; one in, one out, changed. Splitter: one large '
        'block in, three small ones out; one in, many out. Aggregator: three small blocks in, one '
        'large one out; many in, one out.',
        'Seis ícones simplificados na notação de Enterprise Integration Patterns, cada um com o nome e '
        'quantas mensagens entram e saem. Canal de mensagens: um tubo que leva mensagens. Mensagem: um '
        'bloco pequeno com uma faixa de cabeçalho sobre o corpo. Roteador baseado em conteúdo: uma '
        'linha entra e se divide em três saídas; uma mensagem entra e sai uma, por um de vários canais. '
        'Tradutor de mensagens: entra um quadrado, sai um círculo; entra uma, sai uma, transformada. '
        'Splitter: entra um bloco grande, saem três pequenos; entra uma, saem várias. Agregador: entram '
        'três blocos pequenos, sai um grande; entram várias, sai uma.'))
    cols = [
        (ic_channel, [T('message', 'canal de'), T('channel', 'mensagens')], T('carries messages', 'leva mensagens')),
        (ic_message, [T('message', 'mensagem')], T('header + body', 'cabeçalho + corpo')),
        (ic_router, [T('content-based', 'roteador baseado'), T('router', 'em conteúdo')], T('1 in, 1 out of n', 'entra 1, sai 1 de n')),
        (ic_translator, [T('message', 'tradutor de'), T('translator', 'mensagens')], T('1 in, 1 out, changed', 'entra 1, sai 1 mudada')),
        (ic_splitter, ['splitter'], T('1 in, many out', 'entra 1, saem várias')),
        (ic_aggregator, [T('aggregator', 'agregador')], T('many in, 1 out', 'entram várias, sai 1')),
    ]
    for i, (draw, name, count) in enumerate(cols):
        x = 60 + i * 120
        draw(f, x, 48)
        f.lines(x, 100 if len(name) == 2 else 93, name, size=10.5, weight='600')
        f.text(x, 134, count, size=10, fill='--paper-dim')
    f.text(360, 168, T('a flow is drawn as these icons joined by channels; the count of messages in and out is what each icon promises',
                       'um fluxo é desenhado com esses ícones ligados por canais; o número de mensagens que entram e saem é o que cada ícone promete'),
           size=10, fill='--amber', italic=True)
    return f, T('Six of the 65, simplified from the book. Each icon promises how many messages go in and how many come out, which is what makes a drawn flow checkable by counting.',
                'Seis dos 65, simplificados a partir do livro. Cada ícone promete quantas mensagens entram e quantas saem, e é isso que torna um fluxo desenhado verificável por contagem.')


@figure('l11-split-route-aggregate', 11)
def split_route_aggregate():
    f = Fig('l11-split-route-aggregate', 720, 290, T(
        'The Vale Verde order flow from left to right. One EDI order with 40 lines for 12 stores enters '
        'a splitter, which produces 21 messages, one per store and plant: 12 for Juiz de Fora, 5 for '
        'Lavras and 4 for Alagoa. A content-based router reads the plant and sends the 4 Alagoa '
        'messages to Business Central and the other 17 to SAP. Both ERPs reply, and an aggregator '
        'matches the 21 replies by the order number. It completes at 21 replies or after 30 minutes, '
        'whichever comes first, and sends one confirmation to Vale Verde.',
        'O fluxo do pedido da Vale Verde, da esquerda para a direita. Um pedido EDI com 40 linhas para '
        '12 lojas entra num splitter, que produz 21 mensagens, uma por loja e fábrica: 12 para Juiz de '
        'Fora, 5 para Lavras e 4 para Alagoa. Um roteador baseado em conteúdo lê a fábrica e manda as 4 '
        'mensagens de Alagoa para o Business Central e as outras 17 para o SAP. Os dois ERPs respondem, '
        'e um agregador casa as 21 respostas pelo número do pedido. Ele fecha com 21 respostas ou depois '
        'de 30 minutos, o que vier primeiro, e manda uma confirmação para a Vale Verde.'))
    y = 130
    f.box(64, y, 108, 54, [T('Vale Verde order', 'pedido Vale Verde'), T('40 lines', '40 linhas'),
                           T('12 stores', '12 lojas')], size=10, stroke='--wire')
    f.arrow([(118, y), (162, y)], stroke='--paper-dim', width=1.3)
    ic_splitter(f, 192, y)
    f.text(192, y + 34, 'splitter', size=10, weight='600')
    f.arrow([(219, y), (276, y)], stroke='--paper-dim', width=1.3)
    f.lines(248, y - 34, [T('21', '21'), T('messages', 'mensagens')], size=10, fill='--paper')
    f.lines(248, y + 30, [T('12 + 5 + 4', '12 + 5 + 4')], size=10, fill='--paper-dim')
    ic_router(f, 306, y)
    f.lines(306, y + 40, [T('router', 'roteador'), T('by plant', 'por fábrica')], size=10)
    # the two branches
    f.arrow([(333, y - 8), (360, y - 8), (360, 62), (412, 62)], stroke='--paper-dim', width=1.3)
    f.arrow([(333, y + 8), (360, y + 8), (360, 198), (412, 198)], stroke='--paper-dim', width=1.3)
    f.text(386, 50, T('4 Alagoa', '4 Alagoa'), size=10, fill='--paper-dim')
    f.text(386, 186, T('17 others', '17 outras'), size=10, fill='--paper-dim')
    f.box(470, 62, 116, 40, ['Business Central', T('4 orders', '4 pedidos')], size=10, stroke='--wire')
    f.box(470, 198, 116, 40, ['SAP', T('17 orders', '17 pedidos')], size=10, stroke='--wire')
    f.arrow([(528, 62), (560, 62), (560, y - 8), (583, y - 8)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.arrow([(528, 198), (560, 198), (560, y + 8), (583, y + 8)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.text(548, y, T('replies', 'respostas'), size=10, fill='--paper-dim', anchor='end')
    ic_aggregator(f, 612, y)
    f.text(612, y + 34, T('aggregator', 'agregador'), size=10, weight='600')
    f.arrow([(639, y), (668, y)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.box(692, y, 44, 40, [T('1', '1')], size=12, stroke='--phosphor')
    f.lines(612, 236, [T('complete at 21 replies', 'fecha com 21 respostas'),
                       T('or after 30 minutes', 'ou depois de 30 minutos')], size=10, fill='--amber')
    f.text(692, y - 30, T('confirmation', 'confirmação'), size=10, fill='--paper-dim', anchor='end')
    f.text(360, 276, T('every message carries the order number as its correlation id, and the splitter writes 21 into each',
                       'toda mensagem leva o número do pedido como id de correlação, e o splitter escreve 21 em cada uma'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('A splitter, a router and an aggregator: the composed message processor. The aggregator can only count to 21 because the splitter told it; the timeout is what saves it when one reply never comes.',
                'Um splitter, um roteador e um agregador: o composed message processor. O agregador só consegue contar até 21 porque o splitter avisou; o timeout é o que o salva quando uma resposta nunca chega.')


def _pentagon(cx, cy, r):
    return [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
            for a in (-90, -18, 54, 126, 198)]


def _clip(p, q, hw, hh, hw2, hh2, pad=2):
    """The segment from p to q, cut where it leaves the box around p and enters the box around q."""
    dx, dy = q[0] - p[0], q[1] - p[1]

    def edge(w, h):
        s = min(w / abs(dx) if dx else 1e9, h / abs(dy) if dy else 1e9)
        return s

    s1, s2 = edge(hw + pad, hh + pad), edge(hw2 + pad, hh2 + pad)
    return (p[0] + dx * s1, p[1] + dy * s1, q[0] - dx * s2, q[1] - dy * s2)


@figure('l11-translators', 11)
def translators():
    f = Fig('l11-translators', 720, 312, T(
        'Two panels with the same five systems: EDI, Portal B2B, Salesforce, SAP and Business Central. '
        'Left, point to point: every system is joined to every other, ten lines, and each line needs a '
        'translator in each direction, so 5 times 4 is 20 translators. Right, with a canonical model: '
        'each system is joined only to a central canonical order, five lines, two translators each, so '
        '2 times 5 is 10 translators.',
        'Dois painéis com os mesmos cinco sistemas: EDI, Portal B2B, Salesforce, SAP e Business Central. '
        'À esquerda, ponto a ponto: cada sistema ligado a todos os outros, dez linhas, e cada linha '
        'precisa de um tradutor em cada sentido, então 5 vezes 4 dá 20 tradutores. À direita, com um '
        'modelo canônico: cada sistema ligado só a um pedido canônico central, cinco linhas, dois '
        'tradutores cada, então 2 vezes 5 dá 10 tradutores.'))
    names = ['EDI', 'Portal B2B', 'Salesforce', 'Business Central', 'SAP']
    f.text(180, 18, T('point to point', 'ponto a ponto'), size=12, weight='600')
    f.text(540, 18, T('canonical model', 'modelo canônico'), size=12, weight='600')
    left = _pentagon(180, 150, 104)
    for i in range(5):
        for j in range(i + 1, 5):
            f.line(*_clip(left[i], left[j], 52, 13, 52, 13), stroke='--wire', width=1.3)
    right = _pentagon(540, 160, 116)
    for p in right:
        f.line(*_clip((540, 160), p, 40, 16, 52, 13), stroke='--wire', width=1.3)
    f.box(540, 160, 80, 32, [T('canonical', 'pedido'), T('order', 'canônico')], size=10, stroke='--phosphor')
    for pts in (left, right):
        for (x, y), n in zip(pts, names):
            f.box(x, y, 104, 26, [n], size=10, stroke='--paper-dim')
    f.line(360, 30, 360, 290, stroke='--wire', width=1, dash='4 4')
    f.text(180, 290, T('10 lines × 2 = 20 translators: n(n − 1)', '10 linhas × 2 = 20 tradutores: n(n − 1)'),
           size=11, fill='--amber')
    f.text(540, 290, T('5 lines × 2 = 10 translators: 2n', '5 linhas × 2 = 10 tradutores: 2n'),
           size=11, fill='--phosphor')
    return f, T('Five systems that all talk to all. Point to point needs a translator for every ordered pair; a canonical model needs two per system. The left side grows with the square of n, the right side in a straight line.',
                'Cinco sistemas que falam todos com todos. Ponto a ponto precisa de um tradutor para cada par ordenado; um modelo canônico precisa de dois por sistema. O lado esquerdo cresce com o quadrado de n, o direito em linha reta.')


@figure('l11-trace', 11)
def trace():
    f = Fig('l11-trace', 720, 300, T(
        'Five hops of a farm payment from left to right, each with the identifier it knows the farm '
        'by. Coleta: producer 004417. SAP goods receipts: vendor 300417. SAP payment run: payment '
        'document 1500048213. IIB remittance flow: the CNAB line, with reference 1500048213. Bank '
        'return file: reference 1500048213, rejected, account closed. Hops one and two are joined by a '
        'mapping table from producer to vendor; hops three to five share one reference, carried end '
        'to end. Under the IIB flow a wire tap copies every message to a message store, searchable by '
        'vendor and by reference.',
        'Cinco saltos do pagamento de uma fazenda, da esquerda para a direita, cada um com o '
        'identificador pelo qual conhece a fazenda. Coleta: produtor 004417. Entradas de mercadoria no '
        'SAP: fornecedor 300417. Programa de pagamento no SAP: documento de pagamento 1500048213. Fluxo '
        'de remessa no IIB: a linha CNAB, com referência 1500048213. Arquivo de retorno do banco: '
        'referência 1500048213, rejeitado, conta encerrada. Os saltos um e dois se ligam por uma tabela '
        'de produtor para fornecedor; os saltos três a cinco compartilham uma referência, levada de '
        'ponta a ponta. Abaixo do fluxo do IIB, um wire tap copia cada mensagem para um message store, '
        'pesquisável por fornecedor e por referência.'))
    xs = [74, 218, 362, 506, 650]
    heads = ['Coleta', T('SAP receipts', 'SAP: entradas'), T('SAP payment run', 'SAP: pagamento'),
             T('IIB remittance', 'IIB: remessa'), T('bank return', 'retorno do banco')]
    ids = [[T('producer', 'produtor'), '004417'], [T('vendor', 'fornecedor'), '300417'],
           [T('payment doc', 'doc. pagamento'), '1500048213'], [T('CNAB line, ref', 'linha CNAB, ref.'), '1500048213'],
           [T('ref', 'ref.'), '1500048213']]
    y = 120
    for i, (x, h, (lab, num)) in enumerate(zip(xs, heads, ids)):
        stroke = '--phosphor' if i >= 2 else '--wire'
        f.rect(x - 64, y - 40, 128, 80, stroke=stroke, fill='--panel', width=1.4, rx=4)
        f.text(x, y - 24, f'{i + 1}', size=10, fill='--paper-dim')
        f.text(x, y - 8, h, size=10.5, weight='600')
        f.text(x, y + 10, lab, size=10, fill='--paper-dim')
        f.text(x, y + 26, num, size=10, mono=True)
        if i < 4:
            f.arrow([(x + 66, y), (xs[i + 1] - 66, y)], stroke='--paper-dim', width=1.3)
    f.text(650, y + 52, T('rejected: account closed', 'rejeitado: conta encerrada'), size=10, fill='--amber')
    # brackets above
    f.path(f'M{xs[0] - 60} 70 L{xs[0] - 60} 62 L{xs[1] + 60} 62 L{xs[1] + 60} 70', stroke='--amber', width=1.4)
    f.text((xs[0] + xs[1]) / 2, 48, T('joined by a mapping table', 'ligados por uma tabela de-para'), size=10, fill='--paper')
    f.path(f'M{xs[2] - 60} 70 L{xs[2] - 60} 62 L{xs[4] + 60} 62 L{xs[4] + 60} 70', stroke='--phosphor', width=1.4)
    f.text(xs[3], 48, T('one reference, carried end to end', 'uma referência, levada de ponta a ponta'), size=10, fill='--paper')
    # the wire tap
    f.circle(xs[3], y + 40, 3.5, fill='--phosphor')
    f.arrow([(xs[3], y + 44), (xs[3], 230)], stroke='--phosphor', width=1.3)
    f.text(xs[3] - 8, 200, 'wire tap', size=10, anchor='end', fill='--paper')
    f.box(xs[3], 252, 200, 40, [T('message store', 'message store'),
                                     T('search by vendor or by ref', 'busca por fornecedor ou por ref.')], size=10, stroke='--phosphor')
    return f, T('One farm, five hops, three identifiers. Where one reference is carried from the payment run to the bank and back, the trace is a search; where it is not, it is a join somebody has to do by hand.',
                'Uma fazenda, cinco saltos, três identificadores. Onde uma referência é levada do pagamento ao banco e de volta, o rastreamento é uma busca; onde não é, é um cruzamento que alguém tem de fazer à mão.')


@figure('l11-order-flow', 11)
def order_flow():
    f = Fig('l11-order-flow', 720, 330, T(
        'The supermarket order flow as Rui built it, drawn in the notation. Top row, left to right: '
        'the EDI provider; a translator from EANCOM to the XML order the bus uses; a content enricher that '
        'calls SAP once per order line, marked as finding 1; a splitter; a content-based router by '
        'plant, with a default exit to an invalid message channel. From the router, Alagoa orders go '
        'to Business Central and the rest to SAP. Bottom row, right to left: the replies reach an '
        'aggregator that completes only by count, with no timeout, marked as finding 2; a translator '
        'from the XML confirmation to an EANCOM ORDRSP; and the EDI provider again. A wire tap on '
        'the first channel copies every incoming order to a message store.',
        'O fluxo de pedidos de supermercado como Rui o construiu, desenhado na notação. Linha de cima, '
        'da esquerda para a direita: o provedor de EDI; um tradutor de EANCOM para o XML de pedido do barramento; '
        'um content enricher que chama o SAP uma vez por linha do pedido, marcado como achado 1; um '
        'splitter; um roteador baseado em conteúdo por fábrica, com uma saída padrão para um invalid '
        'message channel. Do roteador, os pedidos de Alagoa vão para o Business Central e o resto para '
        'o SAP. Linha de baixo, da direita para a esquerda: as respostas chegam a um agregador que só '
        'fecha por contagem, sem timeout, marcado como achado 2; um tradutor da confirmação em XML '
        'para um ORDRSP do EANCOM; e de novo o provedor de EDI. Um wire tap no primeiro canal copia '
        'cada pedido que chega para um message store.'))
    top, bot = 70, 238
    f.box(52, top, 84, 38, [T('EDI', 'provedor'), T('provider', 'de EDI')], size=10, stroke='--wire')
    f.arrow([(94, top), (136, top)], stroke='--paper-dim', width=1.3)
    ic_translator(f, 163, top)
    f.lines(163, top + 36, [T('translator', 'tradutor'), 'EANCOM → XML'], size=9.5)
    f.arrow([(190, top), (236, top)], stroke='--paper-dim', width=1.3)
    ic_enricher(f, 263, top, stroke='--amber')
    f.lines(263, top + 36, [T('enricher', 'enricher'), T('SAP, per line', 'SAP, por linha')], size=9.5)
    f.circle(263, top - 33, 9, fill='--panel', stroke='--amber', width=1.5)
    f.text(263, top - 33, '1', size=10, fill='--amber', weight='600')
    f.arrow([(290, top), (336, top)], stroke='--paper-dim', width=1.3)
    ic_splitter(f, 363, top)
    f.lines(363, top + 36, ['splitter', T('store × plant', 'loja × fábrica')], size=9.5)
    f.arrow([(390, top), (436, top)], stroke='--paper-dim', width=1.3)
    ic_router(f, 463, top)
    f.lines(463, top + 36, [T('router', 'roteador'), T('by plant', 'por fábrica')], size=9.5)
    # router exits
    f.arrow([(490, top - 10), (566, top - 10), (566, 40), (588, 40)], stroke='--paper-dim', width=1.3)
    f.arrow([(490, top), (588, top + 30)], stroke='--paper-dim', width=1.3)
    f.box(648, 40, 116, 30, ['Business Central'], size=10, stroke='--wire')
    f.box(648, top + 34, 116, 30, ['SAP'], size=10, stroke='--wire')
    f.arrow([(490, top + 10), (505, top + 10), (505, 160), (518, 160)], stroke='--amber', width=1.3, dash='3 3')
    f.box(576, 160, 112, 34, [T('invalid message', 'invalid message'), T('channel', 'channel')], size=9.5, stroke='--amber', dash='4 3')
    f.text(498, 134, T('default', 'padrão'), size=9.5, fill='--paper-dim', anchor='end')
    # replies down to the aggregator on the bottom row
    f.path(f'M706 {top + 34} L714 {top + 34}', stroke='--paper-dim', width=1.3, dash='5 3')
    f.arrow([(706, 40), (714, 40), (714, bot), (606, bot)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.text(706, 200, T('replies', 'respostas'), size=9.5, fill='--paper-dim', anchor='end')
    ic_aggregator(f, 577, bot, stroke='--amber')
    f.lines(577, bot + 36, [T('aggregator', 'agregador'), T('count, no timeout', 'contagem, sem timeout')], size=9.5)
    f.circle(577, bot - 33, 9, fill='--panel', stroke='--amber', width=1.5)
    f.text(577, bot - 33, '2', size=10, fill='--amber', weight='600')
    f.arrow([(550, bot), (430, bot)], stroke='--paper-dim', width=1.3, dash='5 3')
    ic_translator(f, 403, bot)
    f.lines(403, bot + 36, [T('translator', 'tradutor'), 'XML → ORDRSP'], size=9.5)
    f.arrow([(376, bot), (96, bot)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.box(52, bot, 84, 38, [T('EDI', 'provedor'), T('provider', 'de EDI')], size=10, stroke='--wire')
    # the wire tap on the first channel
    f.circle(108, top, 3.5, fill='--phosphor')
    f.arrow([(108, top + 4), (108, 150)], stroke='--phosphor', width=1.3)
    f.text(102, 124, 'wire tap', size=9.5, anchor='end')
    f.box(108, 166, 104, 30, [T('message store', 'message store')], size=10, stroke='--phosphor')
    return f, T('Rui\'s flow in the book\'s notation, with the two findings of Joana\'s review marked: an enricher that calls SAP once per line before the split, and an aggregator that can only finish by count. The dashed exit is the router\'s answer to a plant it does not know.',
                'O fluxo do Rui na notação do livro, com os dois achados da revisão da Joana marcados: um enricher que chama o SAP uma vez por linha antes do split, e um agregador que só consegue fechar por contagem. A saída tracejada é a resposta do roteador para uma fábrica que ele não conhece.')
