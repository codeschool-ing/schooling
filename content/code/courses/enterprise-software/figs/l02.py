"""Lesson 2: SAP: ERP, HANA and Business Objects."""
from figures import Fig, T, figure


@figure('l02-transports', 2)
def transports():
    f = Fig('l02-transports', 720, 300, T(
        'Three SAP systems side by side, each a complete installation with its own database. DEV, '
        'development, holds client 100; QAS, quality, holds client 200 for testing and client 300 '
        'for training; PRD, production, holds client 100 and cannot be edited. A transport request, '
        'DEVK900123, is released in DEV and imported into QAS, where key users test it; the same '
        'request, unchanged, is then imported into PRD, on Tuesday or Thursday evenings and never '
        'in the first five working days of the month.',
        'Três sistemas SAP lado a lado, cada um uma instalação completa com banco de dados próprio. '
        'DEV, desenvolvimento, tem o mandante 100; QAS, qualidade, tem o mandante 200 para testes e '
        'o 300 para treinamento; PRD, produção, tem o mandante 100 e não pode ser editado. Uma '
        'requisição de transporte, DEVK900123, é liberada no DEV e importada no QAS, onde os '
        'usuários-chave a testam; a mesma requisição, sem alteração, é depois importada no PRD, às '
        'terças ou quintas à noite e nunca nos cinco primeiros dias úteis do mês.'))
    systems = [
        (120, 'DEV', T('development', 'desenvolvimento'), ['100'], '--wire'),
        (360, 'QAS', T('quality', 'qualidade'), ['200', '300'], '--wire'),
        (600, 'PRD', T('production', 'produção'), ['100'], '--phosphor'),
    ]
    for x, sid, name, clients, stroke in systems:
        f.rect(x - 95, 60, 190, 130, stroke=stroke, width=1.5)
        f.text(x, 80, sid, size=13, weight='600', mono=True)
        f.text(x, 98, name, size=10.5, fill='--paper-dim')
        n = len(clients)
        for i, c in enumerate(clients):
            cx = x + (i - (n - 1) / 2) * 84
            f.box(cx, 132, 76, 30, [T('client ', 'mandante ') + c], size=10, stroke='--wire',
                  fill='--scan')
        f.text(x, 172, T('own database', 'banco próprio'), size=9.5, fill='--paper-dim',
               italic=True)
    for cx in (240, 480):
        f.box(cx, 44, 104, 24, ['DEVK900123'], size=10, mono=True, stroke='--phosphor')
        f.line(cx, 56, cx, 104, stroke='--phosphor', width=1, dash='2 3')
    for x1, x2, label in [(215, 265, T('import', 'importa')), (455, 505, T('import', 'importa'))]:
        f.arrow([(x1 + 2, 125), (x2 - 4, 125)], stroke='--phosphor', width=1.5)
        f.text((x1 + x2) / 2, 112, label, size=9.5, fill='--paper-dim')
    f.text(360, 16, T('the same request moves on, unchanged',
                      'a mesma requisição segue adiante, sem alteração'),
           size=10, fill='--paper-dim', italic=True)
    notes = [
        (120, [T('a change is made and', 'a mudança é feita e'),
               T('recorded in a request', 'gravada numa requisição')]),
        (360, [T('key users test it', 'os usuários-chave'),
               T('against realistic data', 'testam com dados realistas')]),
        (600, [T('Tue and Thu evenings;', 'terça e quinta à noite;'),
               T('never in the close week', 'nunca na semana do fechamento')]),
    ]
    for x, rows in notes:
        f.lines(x, 218, rows, size=10)
    f.text(600, 252, T('nobody edits PRD directly', 'ninguém edita o PRD diretamente'), size=10,
           fill='--amber', italic=True)
    f.text(360, 282, T('every system that talks to SAP needs a test counterpart pointed at QAS, '
                       'never at PRD',
                       'todo sistema que conversa com o SAP precisa de um par de teste apontado '
                       'para o QAS, nunca para o PRD'),
           size=10, fill='--paper-dim')
    return f, T('The road to production. A change is recorded once in DEV and the same request '
                'moves on; production is never edited in place.',
                'O caminho até a produção. Uma mudança é gravada uma vez no DEV e a mesma '
                'requisição segue adiante; a produção nunca é editada no lugar.')


@figure('l02-columns', 2)
def columns():
    f = Fig('l02-columns', 720, 300, T(
        'The same three order lines stored two ways. Each line has four fields: order, material, '
        'plant and quantity. In a row store the twelve values lie one row after another, so the '
        'three quantities are scattered and summing them means reading every row whole. In a '
        'column store the values lie one column after another, so the three quantities sit in one '
        'block and the sum reads only that block. The plant column is stored as a dictionary of '
        'three plants and a two-bit code per line.',
        'As mesmas três linhas de pedido guardadas de dois jeitos. Cada linha tem quatro campos: '
        'pedido, material, centro e quantidade. Num armazenamento por linha os doze valores ficam '
        'uma linha depois da outra, então as três quantidades ficam espalhadas e somá-las exige '
        'ler cada linha inteira. Num armazenamento por coluna os valores ficam uma coluna depois da '
        'outra, então as três quantidades ficam num bloco só e a soma lê só esse bloco. A coluna de '
        'centro é guardada como um dicionário de três centros e um código de dois bits por linha.'))
    rows = [('4711', 'UHT-1L', 'JF01', '1200'),
            ('4712', 'BUT-200', 'LV01', '300'),
            ('4713', 'UHT-1L', 'JF01', '950')]
    w, gap, group = 50, 2, 10
    x0 = (720 - (12 * w + 8 * gap + 2 * group)) / 2

    def strip(y, cells, per):
        x = x0
        for i, (value, hot) in enumerate(cells):
            if i and i % per == 0:
                x += group
            elif i:
                x += gap
            f.rect(x, y, w, 30, stroke='--phosphor' if hot else '--wire',
                   fill='--scan' if hot else '--panel', width=1.5 if hot else 1)
            f.text(x + w / 2, y + 15, value, size=10, mono=True)
            x += w

    f.text(x0, 34, T('row store: one row after another', 'por linha: uma linha depois da outra'),
           size=11, weight='600', anchor='start')
    strip(48, [(v, j == 3) for r in rows for j, v in enumerate(r)], 4)
    f.text(x0, 96, T('to sum the quantities, every row is read whole',
                     'para somar as quantidades, cada linha é lida inteira'),
           size=10, fill='--amber', anchor='start', italic=True)
    f.text(x0, 144, T('column store: one column after another',
                      'por coluna: uma coluna depois da outra'),
           size=11, weight='600', anchor='start')
    cols = list(zip(*rows))
    strip(158, [(v, j == 3) for j, c in enumerate(cols) for v in c], 3)
    f.text(x0, 206, T('to sum the quantities, one block is read',
                      'para somar as quantidades, um bloco só é lido'),
           size=10, fill='--phosphor', anchor='start', italic=True)
    f.text(x0, 248, T('the plant column, compressed:', 'a coluna de centro, comprimida:'),
           size=10, anchor='start', fill='--paper-dim')
    f.text(x0 + 200, 248, 'JF01=0  BA01=1  LV01=2', size=10, mono=True, anchor='start')
    f.text(x0 + 370, 248, T('then one 2-bit code a line:', 'e um código de 2 bits por linha:'),
           size=10, anchor='start', fill='--paper-dim')
    f.text(x0 + 560, 248, '0 2 0', size=10, mono=True, anchor='start')
    f.text(360, 282, T('the field names, in order: order, material, plant, quantity',
                       'os campos, na ordem: pedido, material, centro, quantidade'),
           size=10, fill='--paper-dim')
    return f, T('One table, two layouts. A row store keeps a record together; a column store keeps '
                'a field together, which is what a sum over millions of lines wants.',
                'Uma tabela, dois arranjos. O armazenamento por linha mantém o registro junto; o '
                'por coluna mantém o campo junto, que é o que uma soma sobre milhões de linhas '
                'precisa.')


@figure('l02-doors', 2)
def doors():
    f = Fig('l02-doors', 720, 370, T(
        'SAP ECC drawn as a box with four doors on its edges. On the left, supermarket orders '
        'arrive from the EDI provider through the bus as IDocs, and Coleta sends its nightly file '
        'at 02:00. On the right, the Portal B2B creates orders by calling a BAPI over RFC, and '
        'checks available-to-promise through an OData service. Every door leads to SAP\'s own '
        'code, which prices, checks, numbers, records the document flow and checks authorisation, '
        'and only that code writes to the database. Below, a SQL client reaching for the database '
        'directly is crossed out: the tables are SAP\'s private model and not a door.',
        'O SAP ECC desenhado como uma caixa com quatro portas nas bordas. À esquerda, os pedidos '
        'dos supermercados chegam do provedor de EDI pelo barramento como IDocs, e o Coleta manda '
        'o arquivo noturno às 02:00. À direita, o Portal B2B cria pedidos chamando uma BAPI por '
        'RFC e consulta o disponível para promessa por um serviço OData. Toda porta leva ao código '
        'do próprio SAP, que calcula preço, verifica, numera, registra o fluxo de documentos e '
        'confere autorização, e só esse código escreve no banco. Embaixo, um cliente SQL tentando '
        'chegar ao banco diretamente está riscado: as tabelas são o modelo privado do SAP, não uma '
        'porta.'))
    f.rect(230, 40, 260, 260, stroke='--phosphor', width=1.6)
    f.text(360, 58, 'SAP ECC', size=12, weight='600')
    f.box(360, 150, 136, 80, [T("SAP's own code:", 'o código do SAP:'),
                              T('prices, checks,', 'preço, verificações,'),
                              T('numbers, document', 'números, fluxo de'),
                              T('flow, authorisation', 'documentos, autorização')],
          size=10, stroke='--wire', fill='--scan')
    f.box(360, 248, 150, 40, [T('database', 'banco de dados'),
                              T("SAP's private model", 'modelo privado do SAP')],
          size=10, stroke='--wire')
    f.arrow([(360, 191), (360, 226)], stroke='--phosphor', width=1.4)
    doors = [(230, 125, 'IDoc'), (230, 175, T('file', 'arquivo')),
             (490, 125, 'BAPI / RFC'), (490, 175, 'OData')]
    for x, y, label in doors:
        f.box(x, y, 82, 26, [label], size=10, stroke='--phosphor', fill='--panel')
        if x < 360:
            f.arrow([(x + 42, y), (290, y)], stroke='--phosphor', width=1.3)
        else:
            f.arrow([(x - 42, y), (430, y)], stroke='--phosphor', width=1.3)
    outside = [
        (95, 125, [T('supermarket orders,', 'pedidos dos supermercados,'),
                   T('EDI through the bus', 'EDI pelo barramento')]),
        (95, 175, [T('Coleta, its file', 'Coleta, o arquivo'),
                   T('every night at 02:00', 'toda noite às 02:00')]),
        (625, 125, [T('Portal B2B orders,', 'pedidos do Portal B2B,'),
                    T('through the bus', 'pelo barramento')]),
        (625, 175, [T('Portal B2B', 'Portal B2B'),
                    T('stock check', 'consulta de estoque')]),
    ]
    for x, y, rows in outside:
        f.box(x, y, 168, 42, rows, size=10, stroke='--wire')
        if x < 360:
            f.arrow([(x + 84, y), (230 - 43, y)], stroke='--phosphor', width=1.4)
        else:
            f.arrow([(x - 84, y), (490 + 43, y)], stroke='--phosphor', width=1.4)
    f.box(360, 345, 150, 30, [T('a SQL client', 'um cliente SQL')], size=10, stroke='--amber',
          dash='4 3')
    f.arrow([(360, 330), (360, 304)], stroke='--amber', width=1.4, dash='4 3')
    f.line(350, 307, 370, 323, stroke='--amber', width=2)
    f.line(370, 307, 350, 323, stroke='--amber', width=2)
    f.lines(560, 330, [T('not a door, for writing', 'não é porta, nem para escrever'),
                       T('or for reading', 'nem para ler')], size=10, fill='--amber', italic=True)
    return f, T('Four published doors, and every one leads through SAP\'s own code. The database is '
                'behind that code, not beside it.',
                'Quatro portas publicadas, e todas passam pelo código do próprio SAP. O banco fica '
                'atrás desse código, não ao lado dele.')


@figure('l02-reporting', 2)
def reporting():
    f = Fig('l02-reporting', 720, 290, T(
        'Serra Alta\'s reporting as four boxes from left to right. SAP ECC in production holds the '
        'current state of one system. Extractors load what changed each night into BW 7.5, which '
        'keeps history, such as the region each sale had when it happened. Universes sit on BW and '
        'hold the definitions, including two different definitions of Net sales. Web Intelligence '
        'reports sit on the universes: about 900, of which about 300 were not opened in a year. A '
        'dashed arrow from the reports back to production shows the alternative of reporting '
        'straight on SAP, which competes with order entry and has no history.',
        'Os relatórios da Serra Alta como quatro caixas da esquerda para a direita. O SAP ECC em '
        'produção guarda o estado atual de um sistema. Os extratores carregam toda noite o que '
        'mudou no BW 7.5, que guarda a história, como a região que cada venda tinha quando '
        'aconteceu. Os universos ficam sobre o BW e guardam as definições, inclusive duas '
        'definições diferentes de vendas líquidas. Os relatórios do Web Intelligence ficam sobre os '
        'universos: cerca de 900, dos quais cerca de 300 não foram abertos em um ano. Uma seta '
        'tracejada dos relatórios de volta à produção mostra a alternativa de relatar direto no '
        'SAP, que disputa com a entrada de pedidos e não tem história.'))
    boxes = [
        (95, ['SAP ECC', T('production', 'produção')], '--phosphor',
         [T('the current state', 'o estado atual'), T('of one system', 'de um sistema')]),
        (275, ['BW 7.5', T('the warehouse', 'o data warehouse')], '--wire',
         [T('history: the region', 'história: a região'), T('each sale had', 'de cada venda')]),
        (455, [T('universes', 'universos'), T('semantic layer', 'camada semântica')], '--wire',
         [T('definitions: two', 'definições: duas'), T('kinds of net sales', 'vendas líquidas')]),
        (635, ['Web Intelligence', T('reports', 'relatórios')], '--wire',
         [T('about 900; about 300', 'cerca de 900; cerca de'), T('unopened in a year', '300 sem abrir em um ano')]),
    ]
    for x, rows, stroke, note in boxes:
        f.box(x, 150, 146, 54, rows, size=10.5, stroke=stroke)
        f.lines(x, 214, note, size=10, fill='--paper-dim')
    for x1 in (95, 275, 455):
        f.arrow([(x1 + 74, 150), (x1 + 180 - 75, 150)], stroke='--phosphor', width=1.4)
    f.text(185, 104, T('extractors, nightly', 'extratores, à noite'), size=9.5,
           fill='--paper-dim')
    f.arrow([(635, 122), (635, 76), (95, 76), (95, 120)], stroke='--amber', width=1.3, dash='5 4')
    f.text(365, 62, T('reporting straight on production: no nightly load, but it competes with '
                      'order entry and keeps no history',
                      'relatar direto na produção: sem carga noturna, mas disputa com a entrada '
                      'de pedidos e não guarda história'),
           size=10, fill='--amber', italic=True)
    f.text(365, 266, T('live data answers questions about now; the warehouse answers questions '
                       'about then, and about more than one system',
                       'o dado ao vivo responde sobre o agora; o warehouse responde sobre o '
                       'passado, e sobre mais de um sistema'),
           size=10, fill='--paper-dim')
    return f, T('Three layers bought from SAP, and the shortcut around them. The shortcut gains '
                'freshness and loses history and breadth.',
                'Três camadas compradas da SAP, e o atalho em volta delas. O atalho ganha frescor e '
                'perde história e alcance.')
