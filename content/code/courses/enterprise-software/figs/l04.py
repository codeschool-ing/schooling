"""Lesson 4: Salesforce: CRM, platform and customisation."""
from figures import Fig, T, figure


@figure('l04-tenants', 4)
def tenants():
    f = Fig('l04-tenants', 720, 330, T(
        'Four orgs side by side at the top: Serra Alta\'s org, two other companies\' orgs, and a '
        'box for the thousands more. Each holds its own metadata and its own rows. Below them a '
        'dashed amber line, the governor limits, applies to every org alike: per transaction, 100 '
        'SOQL queries, 150 DML statements and 10 seconds of CPU. Under the line is one platform: '
        'shared application servers, shared tables where a field is a row of metadata rather than a '
        'column, and three releases a year arriving for every org at once.',
        'Quatro orgs lado a lado no alto: a org da Serra Alta, as orgs de duas outras empresas e uma '
        'caixa para as milhares restantes. Cada uma guarda seus próprios metadados e suas próprias '
        'linhas. Abaixo delas, uma linha tracejada âmbar, os governor limits, vale para todas as '
        'orgs igualmente: por transação, 100 consultas SOQL, 150 comandos DML e 10 segundos de CPU. '
        'Sob a linha está uma plataforma só: servidores de aplicação compartilhados, tabelas '
        'compartilhadas em que um campo é uma linha de metadados e não uma coluna, e três releases '
        'por ano chegando a todas as orgs ao mesmo tempo.'))
    orgs = [
        (100, T("Serra Alta's org", 'org da Serra Alta'), '--phosphor'),
        (273, T("a bank's org", 'org de um banco'), '--wire'),
        (446, T("a hospital's org", 'org de um hospital'), '--wire'),
        (619, T('thousands more', 'milhares de outras'), '--wire'),
    ]
    for x, name, stroke in orgs:
        f.box(x, 70, 158, 84, [], stroke=stroke)
        f.text(x, 46, name, size=11, weight='600')
        f.text(x, 74, T('its metadata', 'seus metadados'), size=10, fill='--paper-dim')
        f.text(x, 94, T('its rows', 'suas linhas'), size=10, fill='--paper-dim')
        f.line(x, 114, x, 156, stroke='--paper-dim', width=1.2)
        f.arrow([(x, 176), (x, 196)], stroke='--paper-dim', width=1.2)
    f.line(24, 150, 696, 150, stroke='--amber', width=1.6, dash='6 4')
    f.text(360, 166, T('governor limits, the same for every org: per transaction, 100 SOQL queries, '
                       '150 DML statements, 10 s of CPU',
                       'governor limits, iguais para todas as orgs: por transação, 100 consultas '
                       'SOQL, 150 comandos DML, 10 s de CPU'),
           size=10, fill='--amber')
    f.rect(24, 198, 672, 112, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(360, 222, T('one platform', 'uma plataforma só'), size=12, weight='600')
    f.text(360, 248, T('shared application servers and shared tables, every row stamped with its org',
                       'servidores de aplicação e tabelas compartilhados, cada linha marcada com a sua org'),
           size=10)
    f.text(360, 268, T('a field you add is a row of metadata, not a column you own',
                       'um campo que você cria é uma linha de metadados, não uma coluna sua'),
           size=10)
    f.text(360, 288, T('three releases a year, arriving for every org at once',
                       'três releases por ano, chegando a todas as orgs ao mesmo tempo'),
           size=10, fill='--paper-dim')
    return f, T('What multitenant means. Every org runs on the same code and the same tables; the fence '
                'between them and the platform is the governor limits, and it is the same fence for all.',
                'O que multitenant quer dizer. Toda org roda no mesmo código e nas mesmas tabelas; a '
                'cerca entre elas e a plataforma são os governor limits, e é a mesma cerca para todas.')


@figure('l04-sandboxes', 4)
def sandboxes():
    f = Fig('l04-sandboxes', 720, 300, T(
        'A change travelling from left to right through four orgs. A Developer sandbox holds the '
        'configuration and no records; Talita builds the change there. A Partial Copy holds the '
        'configuration and a sample of records; three sales managers test it. A Full sandbox holds '
        'the configuration and all the records; the SAP integration is tested there at production '
        'volume. Production is where the 140 reps work. Above them, a git repository holds the '
        'metadata as files: the change is retrieved from the Developer sandbox into it and deployed '
        'from it to each of the other three. A note underneath says that each step to the right carries more of '
        'production\'s data, and is guarded more like it.',
        'Uma mudança indo da esquerda para a direita por quatro orgs. Um sandbox Developer tem a '
        'configuração e nenhum registro; Talita constrói a mudança ali. Um Partial Copy tem a '
        'configuração e uma amostra dos registros; três gerentes de vendas a testam. Um Full tem a '
        'configuração e todos os registros; a integração com o SAP é testada ali com o volume da '
        'produção. A produção é onde trabalham os 140 representantes. Acima deles, um repositório git '
        'guarda os metadados como arquivos: a mudança é recuperada do sandbox Developer para ele e '
        'implantada a partir dele em cada um dos outros três. Uma nota embaixo diz que cada passo para a direita carrega '
        'mais dados da produção, e é protegido mais como ela.'))
    f.box(360, 40, 420, 40, [], stroke='--phosphor')
    f.text(360, 40, T('git repository: the org\'s metadata as files',
                      'repositório git: os metadados da org como arquivos'), size=11, weight='600')
    cols = [
        (95, 'Developer', T('configuration only', 'só a configuração'),
         T('Talita builds', 'Talita constrói')),
        (270, 'Partial Copy', T('configuration + a sample', 'configuração + amostra'),
         T('sales managers test', 'gerentes de vendas testam')),
        (445, 'Full', T('configuration + all records', 'configuração + tudo'),
         T('SAP integration at volume', 'integração SAP com volume')),
        (620, T('production', 'produção'), T('the real records', 'os registros reais'),
         T('140 reps', '140 representantes')),
    ]
    for i, (x, name, holds, who) in enumerate(cols):
        f.box(x, 190, 160, 92, [], stroke='--phosphor' if i == 3 else '--wire')
        f.text(x, 162, name, size=11, weight='600')
        f.text(x, 190, holds, size=10)
        f.text(x, 214, who, size=10, fill='--paper-dim', italic=True)
        if i < 3:
            f.arrow([(x + 82, 190), (cols[i + 1][0] - 84, 190)], stroke='--paper-dim', width=1.2)
    f.arrow([(95, 142), (180, 62)], stroke='--phosphor', width=1.3)
    f.text(126, 96, T('retrieve', 'recuperar'), size=10, anchor='end')
    for x in (270, 445, 620):
        f.arrow([(x, 62), (x, 142)], stroke='--paper-dim', width=1.2, dash='5 3')
    f.text(452, 102, T('deploy', 'implantar'), size=10, anchor='start')
    f.text(360, 268, T('each step to the right carries more of production\'s data, and is guarded more like it',
                       'cada passo para a direita carrega mais dados da produção, e é protegido mais como ela'),
           size=10, fill='--amber', italic=True)
    return f, T('The path of a change at Serra Alta. Only the Full sandbox has production\'s volume, '
                'which is why the integration is tested there and nowhere else.',
                'O caminho de uma mudança na Serra Alta. Só o sandbox Full tem o volume da produção, e '
                'é por isso que a integração é testada ali e em nenhum outro lugar.')


@figure('l04-calls', 4)
def calls():
    f = Fig('l04-calls', 720, 300, T(
        'Three horizontal bars on one scale, the API requests used in 24 hours on the month-end '
        'night. Each bar starts with the 45,000 requests of the other integrations. The first adds '
        '68,000 for two REST calls per invoice and reaches 113,000, past an amber line at Serra '
        'Alta\'s allowance of 100,000. The second adds 170 requests for sObject Collections of 200 '
        'invoices each. The third adds 11 requests for one Bulk API 2.0 job. The last two additions '
        'are too small to see at this scale.',
        'Três barras horizontais na mesma escala, as requisições de API usadas em 24 horas na noite '
        'de fechamento do mês. Cada barra começa com as 45.000 requisições das outras integrações. A '
        'primeira soma 68.000 de duas chamadas REST por fatura e chega a 113.000, passando de uma '
        'linha âmbar na cota da Serra Alta, 100.000. A segunda soma 170 requisições de sObject '
        'Collections com 200 faturas cada. A terceira soma 11 requisições de um job do Bulk API 2.0. '
        'As duas últimas somas são pequenas demais para aparecer nesta escala.'))
    x0, scale = 220, 380 / 125000
    rows = [
        (T('two REST calls per invoice', 'duas chamadas REST por fatura'), 68000, '113,000', '113.000'),
        (T('sObject Collections, 200 per call', 'sObject Collections, 200 por chamada'), 170,
         '45,170', '45.170'),
        (T('one Bulk API 2.0 job', 'um job do Bulk API 2.0'), 11, '45,011', '45.011'),
    ]
    for i, (label, extra, en, pt) in enumerate(rows):
        y = 80 + i * 62
        f.text(x0 - 12, y, label, size=10, anchor='end')
        f.rect(x0, y - 13, 45000 * scale, 26, stroke=None, fill='--scan', rx=2)
        f.rect(x0 + 45000 * scale, y - 13, max(extra * scale, 1.5), 26, stroke=None,
               fill='--phosphor', rx=2)
        f.text(x0 + (45000 + extra) * scale + 8, y, T(en, pt), size=10, anchor='start', mono=True)
    ax = x0 + 100000 * scale
    f.line(ax, 46, ax, 63, stroke='--amber', width=1.6, dash='6 4')
    f.line(ax, 97, ax, 236, stroke='--amber', width=1.6, dash='6 4')
    f.text(ax, 34, T('allowance: 100,000 per 24 h', 'cota: 100.000 por 24 h'), size=10, fill='--amber')
    f.line(x0, 236, x0 + 125000 * scale, 236, stroke='--wire', width=1)
    for v, en, pt in ((0, '0', '0'), (50000, '50,000', '50.000'), (100000, '100,000', '100.000')):
        f.line(x0 + v * scale, 236, x0 + v * scale, 241, stroke='--wire', width=1)
        f.text(x0 + v * scale, 252, T(en, pt), size=9.5, fill='--paper-dim', mono=True)
    f.rect(x0, 268, 14, 12, stroke=None, fill='--scan', rx=2)
    f.text(x0 + 20, 274, T('other integrations, 45,000', 'outras integrações, 45.000'), size=10,
           anchor='start', fill='--paper-dim')
    f.rect(x0 + 230, 268, 14, 12, stroke=None, fill='--phosphor', rx=2)
    f.text(x0 + 250, 274, T('the invoice sync', 'a sincronização de faturas'), size=10,
           anchor='start', fill='--paper-dim')
    return f, T('The month-end night three ways, on one scale. Only the first crosses the allowance; '
                'the other two change the number of requests, not the speed.',
                'A noite de fechamento de três jeitos, na mesma escala. Só o primeiro passa da cota; '
                'os outros dois mudam o número de requisições, não a velocidade.')


@figure('l04-ownership', 4)
def ownership():
    f = Fig('l04-ownership', 720, 360, T(
        'SAP ECC on the left and Salesforce on the right, each listing the fields it owns. SAP owns '
        'the legal name, CNPJ and state registration, the fiscal address, the sold-to, ship-to, '
        'bill-to and payer structure, the credit limit and payment terms, and the invoices with '
        'what is overdue. Salesforce owns contacts, opportunities and visits, cases, and the rep '
        'who owns the account. Between them, a solid arrow from SAP to Salesforce carries read-only '
        'copies of SAP\'s fields every night; a dashed arrow from Salesforce to SAP carries the '
        'request to create a customer. At the bottom, the two ids each side keeps: the SAP customer '
        'number on the Account, as a unique external id, and the 18-character Salesforce Id on the '
        'SAP customer.',
        'O SAP ECC à esquerda e o Salesforce à direita, cada um listando os campos de que é dono. O '
        'SAP é dono da razão social, do CNPJ e da inscrição estadual, do endereço fiscal, da '
        'estrutura de parceiros (emissor da ordem, recebedor da mercadoria, recebedor da fatura, pagador), do limite de crédito e '
        'das condições de pagamento, e das faturas com o que está vencido. O Salesforce é dono dos '
        'contatos, das oportunidades e visitas, dos casos e do representante dono da conta. Entre '
        'eles, uma seta cheia do SAP para o Salesforce leva toda noite cópias somente leitura dos '
        'campos do SAP; uma seta tracejada do Salesforce para o SAP leva o pedido de criação de '
        'cliente. Embaixo, os dois ids que cada lado guarda: o número de cliente SAP na Account, como '
        'external id único, e o Id de 18 caracteres do Salesforce no cliente do SAP.'))
    sap = [T('legal name, CNPJ, state registration', 'razão social, CNPJ, inscrição estadual'),
           T('fiscal address', 'endereço fiscal'),
           T('sold-to, ship-to, bill-to, payer', 'emissor, recebedores, pagador'),
           T('credit limit, payment terms', 'limite de crédito, condições de pagamento'),
           T('invoices and what is overdue', 'faturas e o que está vencido')]
    sf = [T('contacts: buyers, category managers', 'contatos: compradores, gerentes'),
          T('opportunities and visits', 'oportunidades e visitas'),
          T('cases: complaints, recalls', 'casos: reclamações, recalls'),
          T('the rep who owns the account', 'o representante dono da conta')]
    for x, title, rows, sub in ((130, 'SAP ECC', sap, T('owns what is invoiced', 'dono do que se fatura')),
                                (590, 'Salesforce', sf, T('owns the relationship', 'dono do relacionamento'))):
        f.rect(x - 115, 20, 230, 230, stroke='--phosphor', fill='--panel', width=1.4)
        f.text(x, 42, title, size=12, weight='600')
        f.text(x, 62, sub, size=10, fill='--paper-dim', italic=True)
        for i, r in enumerate(rows):
            f.rect(x - 103, 80 + i * 32, 206, 24, stroke='--wire', fill='--panel', rx=3)
            f.text(x, 92 + i * 32, r, size=10)
    f.arrow([(250, 112), (470, 112)], stroke='--phosphor', width=1.5)
    f.lines(360, 140, [T('nightly: read-only', 'toda noite: cópias'),
                       T('copies of SAP\'s fields', 'somente leitura')], size=10)
    f.arrow([(470, 196), (250, 196)], stroke='--paper-dim', width=1.4, dash='5 3')
    f.lines(360, 222, [T('request to create', 'pedido de criação'),
                       T('a new customer', 'de um cliente novo')], size=10, fill='--paper-dim')
    f.rect(15, 270, 690, 74, stroke='--amber', fill='--panel', width=1.2, dash='5 3')
    f.text(360, 288, T('the ids each side keeps', 'os ids que cada lado guarda'), size=11, weight='600')
    f.text(190, 312, T('on the SAP customer:', 'no cliente do SAP:'), size=10, fill='--paper-dim')
    f.text(190, 330, T('the 18-character Salesforce Id', 'o Id de 18 caracteres do Salesforce'), size=10)
    f.text(530, 312, T('on the Account, unique external id:', 'na Account, external id único:'),
           size=10, fill='--paper-dim')
    f.text(530, 330, 'SAP_Customer_Number__c', size=10, mono=True)
    return f, T('One owner per field. Each copy is read-only where it lands, and each side stores the '
                'other\'s id, so nothing has to be matched by name or by CNPJ.',
                'Um dono por campo. Cada cópia é somente leitura onde chega, e cada lado guarda o id '
                'do outro, então nada precisa ser casado por nome ou por CNPJ.')
