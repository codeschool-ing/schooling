"""Lesson 1: What an ERP is and why it constrains the architecture."""
from figures import Fig, T, figure


@figure('l01-estate', 1)
def estate():
    f = Fig('l01-estate', 720, 410, T(
        'A map of Serra Alta\'s systems. SAP ECC 6.0 sits in the middle. Above it, four systems '
        'connect to it: Salesforce, OpenText Documentum, IBM BPM, and SAP BW with BusinessObjects. '
        'To its left, Coleta on an IBM i sends it a file every night; to its right, Business Central '
        'at Mantiqueira. Below it runs the service bus, IBM Integration Bus with IBM MQ, which '
        'connects SAP to Rota, the Portal B2B and the outside world of banks, the tax authority and '
        'customers\' EDI. Microsoft 365 and Entra ID, bottom right, give everybody their sign-in.',
        'Um mapa dos sistemas da Serra Alta. O SAP ECC 6.0 fica no meio. Acima dele, quatro sistemas '
        'se ligam a ele: Salesforce, OpenText Documentum, IBM BPM, e SAP BW com BusinessObjects. À '
        'esquerda, o Coleta num IBM i manda um arquivo toda noite; à direita, o Business Central da '
        'Mantiqueira. Abaixo dele corre o barramento de serviços, IBM Integration Bus com IBM MQ, que '
        'liga o SAP ao Rota, ao Portal B2B e ao mundo de fora: bancos, a autoridade fiscal e o EDI '
        'dos clientes. Microsoft 365 e Entra ID, embaixo à direita, dão o login de todo mundo.'))
    top = [(95, 'Salesforce', T('sales and service', 'vendas e atendimento')),
           (270, 'Documentum', T('quality documents', 'documentos da qualidade')),
           (450, 'IBM BPM', T('three processes', 'três processos')),
           (625, 'BW + BusinessObjects', T('900 reports', '900 relatórios'))]
    for x, name, sub in top:
        f.box(x, 48, 156, 46, [], stroke='--wire')
        f.text(x, 41, name, size=11)
        f.text(x, 58, sub, size=9.5, fill='--paper-dim')
        f.arrow([(x, 72), (360 + (x - 360) * 0.25, 146)], stroke='--paper-dim', start=True)
    f.rect(260, 146, 200, 58, stroke='--phosphor', width=1.8)
    f.text(360, 167, 'SAP ECC 6.0', size=13, weight='600')
    f.text(360, 186, T('the ERP, since 2011', 'o ERP, desde 2011'), size=10, fill='--paper-dim')
    f.box(95, 175, 156, 46, [], stroke='--amber')
    f.text(95, 167, 'Coleta', size=11)
    f.text(95, 184, T('IBM i, RPG, 1996', 'IBM i, RPG, 1996'), size=9.5, fill='--paper-dim')
    f.arrow([(173, 175), (258, 175)], stroke='--amber', width=1.5)
    f.text(215, 162, T('nightly file', 'arquivo noturno'), size=9.5, fill='--paper')
    f.box(625, 175, 156, 46, [], stroke='--wire')
    f.text(625, 167, 'Business Central', size=11)
    f.text(625, 184, 'Mantiqueira', size=9.5, fill='--paper-dim')
    f.arrow([(547, 175), (462, 175)], stroke='--paper-dim', start=True)
    f.rect(150, 246, 420, 34, stroke='--phosphor', fill='--panel')
    f.text(360, 263, T('service bus: IBM Integration Bus + IBM MQ, about 70 flows',
                       'barramento: IBM Integration Bus + IBM MQ, cerca de 70 fluxos'), size=10.5)
    f.arrow([(360, 244), (360, 206)], stroke='--paper-dim', start=True)
    bottom = [(95, 'Rota', T('truck routes', 'rotas dos caminhões'), '--wire', None),
              (270, 'Portal B2B', T('4,000 bakeries', '4.000 padarias'), '--wire', None),
              (450, T('banks · SEFAZ · EDI', 'bancos · SEFAZ · EDI'), T('outside the company', 'fora da empresa'),
               '--wire', '4 3')]
    for x, name, sub, st, dash in bottom:
        f.box(x, 350, 156, 46, [], stroke=st, dash=dash)
        f.text(x, 342, name, size=11)
        f.text(x, 359, sub, size=9.5, fill='--paper-dim')
        f.arrow([(x, 325), (360 + (x - 360) * 0.45, 282)], stroke='--paper-dim', start=True)
    f.box(625, 350, 156, 46, [], stroke='--wire', dash='2 3')
    f.text(625, 342, 'Microsoft 365 + Entra ID', size=10.5)
    f.text(625, 359, T('everybody\'s sign-in', 'o login de todo mundo'), size=9.5, fill='--paper-dim')
    return f, T('Serra Alta\'s estate as Joana finds it. Everything is drawn around SAP because '
                'everything is arranged around it; the amber line is the oldest integration in the company.',
                'O parque da Serra Alta como a Joana o encontra. Tudo é desenhado em volta do SAP porque tudo '
                'se organiza em volta dele; a linha âmbar é a integração mais antiga da empresa.')


@figure('l01-before-after', 1)
def before_after():
    f = Fig('l01-before-after', 720, 330, T(
        'Two panels. On the left, before the ERP: three systems, sales, stock and accounting, each '
        'with its own database holding its own copy of the customer and the product, joined by files '
        'sent every night, and a spreadsheet of differences made at the end of every month. On the '
        'right, an ERP: six modules, sales, purchasing and stock, finance, controlling, production '
        'and quality, all standing on one database that holds the master data once and the '
        'transactions that refer to it.',
        'Dois painéis. À esquerda, antes do ERP: três sistemas, vendas, estoque e contabilidade, cada '
        'um com o próprio banco guardando a própria cópia do cliente e do produto, ligados por '
        'arquivos enviados toda noite, e uma planilha de diferenças feita no fim de cada mês. À '
        'direita, um ERP: seis módulos, vendas, compras e estoque, finanças, controladoria, produção '
        'e qualidade, todos apoiados num único banco que guarda os dados mestres uma vez e as '
        'transações que se referem a eles.'))
    f.text(175, 20, T('before: one system per department', 'antes: um sistema por departamento'), size=12, weight='600')
    f.text(545, 20, T('after: modules over one database', 'depois: módulos sobre um banco só'), size=12, weight='600')
    f.line(360, 36, 360, 310, stroke='--wire', dash='3 4')
    names = [T('sales', 'vendas'), T('stock', 'estoque'), T('accounting', 'contabilidade')]
    xs = [65, 175, 285]
    for x, n in zip(xs, names):
        f.box(x, 70, 96, 34, [n], stroke='--wire', size=10.5)
        f.rect(x - 40, 120, 80, 62, stroke='--wire', fill='--ink')
        f.text(x, 136, T('customer', 'cliente'), size=9.5, fill='--paper-dim')
        f.text(x, 152, T('product', 'produto'), size=9.5, fill='--paper-dim')
        f.text(x, 168, T('its own copy', 'cópia própria'), size=9.5, fill='--paper-dim')
        f.line(x, 87, x, 120, stroke='--wire')
    for a, b in ((0, 1), (1, 2)):
        f.arrow([(xs[a] + 42, 151), (xs[b] - 44, 151)], stroke='--paper-dim')
    f.text(120, 200, T('nightly file', 'arquivo noturno'), size=9.5)
    f.text(230, 200, T('nightly file', 'arquivo noturno'), size=9.5)
    f.rect(40, 232, 270, 56, stroke='--amber', fill='--panel')
    f.text(175, 250, T('every month: a spreadsheet of differences', 'todo mês: uma planilha de diferenças'), size=10.5)
    f.text(175, 270, T('and a column headed "explanation"', 'e uma coluna chamada "explicação"'), size=10, fill='--paper-dim')
    mods = ['SD', 'MM', 'FI', 'CO', 'PP', 'QM']
    subs = [T('sales', 'vendas'), T('stock', 'estoque'), T('finance', 'finanças'),
            T('costs', 'custos'), T('production', 'produção'), T('quality', 'qualidade')]
    for i, (m, s) in enumerate(zip(mods, subs)):
        x = 410 + i * 54
        f.box(x, 80, 48, 48, [], stroke='--phosphor')
        f.text(x, 72, m, size=11, weight='600', mono=True)
        f.text(x, 91, s, size=8.5, fill='--paper-dim')
        f.line(x, 104, x, 150, stroke='--phosphor-dim')
    f.rect(384, 150, 324, 76, stroke='--phosphor', fill='--ink', width=1.6)
    f.text(546, 170, T('one database', 'um banco só'), size=12, weight='600')
    f.text(546, 190, T('master data, once: customers, materials, suppliers',
                       'dados mestres, uma vez: clientes, materiais, fornecedores'), size=9.5, fill='--paper-dim')
    f.text(546, 207, T('transactions that point at it: orders, invoices, payments',
                       'transações que apontam para eles: pedidos, notas, pagamentos'), size=9.5, fill='--paper-dim')
    f.text(546, 262, T('no file to arrive late, no copy to drift', 'nenhum arquivo para atrasar, nenhuma cópia para divergir'),
           size=10.5, fill='--phosphor')
    return f, T('What an ERP replaced. The copies on the left were each correct by their own rules, which '
                'is why they disagreed; on the right there is one record of each thing and every module reads it.',
                'O que o ERP substituiu. As cópias da esquerda estavam certas cada uma pelas próprias regras, e é '
                'por isso que discordavam; à direita há um registro de cada coisa e todo módulo lê o mesmo.')


@figure('l01-order-to-cash', 1)
def order_to_cash():
    f = Fig('l01-order-to-cash', 720, 270, T(
        'Six documents in a row, each created from the one before: sales order, outbound delivery, '
        'goods issue, billing document with its NF-e, accounting document, incoming payment. A dashed '
        'line above says each document points at the one before it. Below the goods issue: stock '
        'falls by 600 cases and the cost moves to cost of goods sold, the first change to the books. '
        'Below the accounting document: the customer owes the amount. Below the payment: it clears '
        'the open item.',
        'Seis documentos em fila, cada um criado a partir do anterior: ordem de venda, remessa, saída '
        'de mercadoria, documento de faturamento com a NF-e, documento contábil, recebimento. Uma '
        'linha tracejada acima diz que cada documento aponta para o anterior. Sob a saída de '
        'mercadoria: o estoque cai 600 caixas e o custo vai para o custo das mercadorias vendidas, a '
        'primeira mudança nos livros. Sob o documento contábil: o cliente deve o valor. Sob o '
        'recebimento: ele baixa a partida em aberto.'))
    steps = [(T('sales', 'ordem de'), T('order', 'venda')),
             (T('outbound', 'remessa'), T('delivery', 'de saída')),
             (T('goods', 'saída de'), T('issue', 'mercadoria')),
             (T('billing', 'faturamento'), T('+ NF-e', '+ NF-e')),
             (T('accounting', 'documento'), T('document', 'contábil')),
             (T('incoming', 'recebimento'), T('payment', 'do cliente'))]
    days = [T('Monday', 'segunda'), T('Tuesday', 'terça'), T('Wednesday', 'quarta'),
            T('Wednesday', 'quarta'), T('Wednesday', 'quarta'), T('30 days on', '30 dias depois')]
    w, gap = 104, 16
    for i, ((a, b), d) in enumerate(zip(steps, days)):
        x = 8 + w / 2 + i * (w + gap)
        st = '--phosphor' if i in (2, 3, 4) else '--wire'
        f.rect(x - w / 2, 92, w, 52, stroke=st)
        rows = [r for r in (a, b) if r]
        f.lines(x, 118, rows, size=10.5)
        f.text(x, 160, d, size=9.5, fill='--paper-dim')
        if i < 5:
            f.arrow([(x + w / 2 + 1, 118), (x + w / 2 + gap - 1, 118)], stroke='--paper')
    f.arrow([(8 + w / 2 + 5 * (w + gap), 84), (8 + w / 2 + 5 * (w + gap), 66), (8 + w / 2, 66), (8 + w / 2, 84)],
            stroke='--paper-dim', dash='4 3')
    f.text(360, 52, T('each document points at the one before it', 'cada documento aponta para o anterior'),
           size=10.5, fill='--paper')
    notes = [(2, T('stock − 600 cases', 'estoque − 600 caixas'), T('cost of goods sold +', 'custo das vendas +')),
             (4, T('the customer owes', 'o cliente deve'), T('an open item', 'uma partida em aberto')),
             (5, T('clears the', 'baixa a partida'), T('open item', 'em aberto'))]
    for i, a, b in notes:
        x = 8 + w / 2 + i * (w + gap)
        f.line(x, 170, x, 190, stroke='--amber')
        f.text(x, 204, a, size=9.5, fill='--paper')
        f.text(x, 220, b, size=9.5, fill='--paper')
    f.text(250, 252, T('the three highlighted steps change the books', 'os três passos destacados mudam os livros'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Order to cash for 600 cases of UHT milk. Nothing is updated in place: each step adds a '
                'document, and an integration joins the chain at the step it represents.',
                'Do pedido ao recebimento para 600 caixas de leite UHT. Nada é alterado no lugar: cada passo '
                'acrescenta um documento, e uma integração entra na cadeia no passo que ela representa.')


@figure('l01-three-rings', 1)
def three_rings():
    f = Fig('l01-three-rings', 720, 300, T(
        'The ERP drawn as a box with a core inside it. The core is the vendor\'s programs and '
        'tables. A small amber patch inside the core is a modification: your code inside theirs, '
        'broken by every upgrade. The band around the core is configuration: choices the vendor '
        'built, carried through upgrades by the vendor. Outside the box, joined to its edge by a '
        'published interface, is an extension beside the ERP: yours to maintain, and not broken by '
        'the vendor\'s release.',
        'O ERP desenhado como uma caixa com um núcleo dentro. O núcleo são os programas e as tabelas '
        'do fornecedor. Uma pequena mancha âmbar dentro do núcleo é uma modificação: o seu código '
        'dentro do deles, quebrado a cada atualização. A faixa em volta do núcleo é a configuração: '
        'escolhas que o fornecedor construiu, levadas adiante pelo fornecedor nas atualizações. Fora '
        'da caixa, ligada à borda por uma interface publicada, fica uma extensão ao lado do ERP: sua '
        'para manter, e não quebrada pela versão nova do fornecedor.'))
    f.rect(20, 30, 430, 250, stroke='--phosphor', width=1.6)
    f.text(235, 50, T('configuration: choices the vendor built', 'configuração: escolhas que o fornecedor construiu'),
           size=11)
    f.text(235, 67, T('carried through upgrades by the vendor', 'levada adiante pelo fornecedor nas atualizações'),
           size=9.5, fill='--paper-dim')
    f.rect(70, 88, 330, 170, stroke='--wire', fill='--ink')
    f.text(235, 112, T('the vendor\'s programs and tables', 'os programas e tabelas do fornecedor'), size=11)
    f.rect(140, 150, 190, 74, stroke='--amber', fill='--panel', dash='4 3')
    f.text(235, 170, T('modification', 'modificação'), size=11, fill='--amber', weight='600')
    f.text(235, 189, T('your code inside theirs', 'seu código dentro do deles'), size=9.5)
    f.text(235, 205, T('broken by every upgrade', 'quebrado a cada atualização'), size=9.5)
    f.rect(500, 110, 200, 90, stroke='--phosphor')
    f.text(600, 132, T('extension beside', 'extensão ao lado'), size=11, weight='600')
    f.text(600, 153, T('yours to maintain', 'sua para manter'), size=9.5)
    f.text(600, 170, T('not broken by their release', 'não quebra com a versão deles'), size=9.5)
    f.arrow([(498, 155), (452, 155)], stroke='--paper', start=True)
    f.text(468, 232, T('a published interface', 'uma interface publicada'), size=9.5, fill='--paper-dim', anchor='start')
    f.line(475, 222, 475, 160, stroke='--paper-dim', dash='2 3')
    return f, T('Three places to put a change, from cheapest to dearest over the ERP\'s life: configuration, '
                'an extension beside it, and a modification inside it.',
                'Três lugares para pôr uma mudança, do mais barato ao mais caro ao longo da vida do ERP: '
                'configuração, uma extensão ao lado, e uma modificação dentro dele.')
