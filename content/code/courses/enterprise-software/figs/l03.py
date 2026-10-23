"""Lesson 3: Microsoft Dynamics and the Microsoft ecosystem inside the company."""
from figures import Fig, T, figure


@figure('l03-family', 3)
def family():
    f = Fig('l03-family', 720, 360, T(
        'The Dynamics family as four lines of descent, read left to right. Axapta became Dynamics '
        'AX, then Dynamics 365 for Operations in 2016, and is sold today as Dynamics 365 Finance and '
        'Supply Chain Management. Navision became Dynamics NAV and, in 2018, Business Central, which '
        'Mantiqueira has run since 2019. Axapta and Navision were both bought by Microsoft in 2002. '
        'Dynamics CRM became Dynamics 365 Sales and Customer Service, which are built on Dataverse. '
        'Common Data Service was renamed Dataverse in 2020; it is the data under the CRM apps and '
        'Power Apps, and the two ERPs keep their own databases outside it.',
        'A família Dynamics como quatro linhas de descendência, lidas da esquerda para a direita. O '
        'Axapta virou Dynamics AX, depois Dynamics 365 for Operations em 2016, e hoje é vendido como '
        'Dynamics 365 Finance e Supply Chain Management. O Navision virou Dynamics NAV e, em 2018, '
        'Business Central, que a Mantiqueira roda desde 2019. Axapta e Navision foram comprados pela '
        'Microsoft em 2002. O Dynamics CRM virou Dynamics 365 Sales e Customer Service, construídos '
        'sobre o Dataverse. O Common Data Service foi renomeado Dataverse em 2020; ele guarda os dados '
        'dos apps de CRM e do Power Apps, e os dois ERPs mantêm bancos próprios fora dele.'))
    cols = [80, 235, 400, 605]
    widths = [130, 130, 150, 200]
    heads = [T('origin', 'origem'), T('Dynamics era', 'era Dynamics'), '', T('sold today', 'vendido hoje')]
    for x, h in zip(cols, heads):
        if h:
            f.text(x, 22, h, size=10, fill='--paper-dim', italic=True)
    f.rect(12, 40, 136, 168, stroke='--amber', fill='--ink', dash='4 3')
    f.lines(80, 184, [T('bought by', 'compradas pela'), T('Microsoft, 2002', 'Microsoft, 2002')], size=9.5, fill='--amber')

    def node(c, y, rows, stroke='--wire', h=40, mono=False):
        f.box(cols[c], y, widths[c], h, rows, size=10.5, stroke=stroke, mono=mono)

    def link(c1, c2, y):
        f.arrow([(cols[c1] + widths[c1] / 2 + 2, y), (cols[c2] - widths[c2] / 2 - 3, y)],
                stroke='--paper-dim', width=1.2)

    # Axapta line
    y = 70
    node(0, y, ['Axapta'])
    node(1, y, ['Dynamics AX'])
    node(2, y, ['Dynamics 365', 'for Operations, 2016'])
    node(3, y, ['Finance', 'Supply Chain Management'], stroke='--phosphor')
    for a, b in ((0, 1), (1, 2), (2, 3)):
        link(a, b, y)
    # Navision line
    y = 145
    node(0, y, ['Navision'])
    node(1, y, ['Dynamics NAV'])
    node(3, y, ['Business Central, 2018'], stroke='--phosphor')
    link(0, 1, y)
    link(1, 3, y)
    f.text(cols[3], y + 30, T('Mantiqueira, since 2019', 'Mantiqueira, desde 2019'), size=9.5, fill='--amber')
    # CRM line
    y = 225
    node(1, y, ['Dynamics CRM'])
    node(3, y, ['Dynamics 365 Sales,', 'Customer Service'], stroke='--phosphor')
    link(1, 3, y)
    # Dataverse line
    y = 315
    node(1, y, ['Common Data Service'])
    node(3, y, ['Dataverse, 2020', T('also under Power Apps', 'também sob o Power Apps')], stroke='--phosphor', h=44)
    link(1, 3, y)
    f.arrow([(cols[3], 246), (cols[3], 292)], stroke='--paper-dim', width=1.2, dash='4 3')
    f.text(cols[3] + 8, 270, T('built on', 'construídos sobre'), size=9.5, fill='--paper-dim', anchor='start')
    f.text(cols[2], 345, T('the ERPs keep their own databases', 'os ERPs mantêm bancos próprios'),
           size=9.5, fill='--amber', italic=True)
    return f, T('Four lines of descent under one brand. The two ERPs came from different companies and keep their own data; only the CRM apps and Power Apps live in Dataverse.',
                'Quatro linhas de descendência sob uma marca. Os dois ERPs vieram de empresas diferentes e guardam os próprios dados; só os apps de CRM e o Power Apps moram no Dataverse.')


@figure('l03-identity', 3)
def identity():
    f = Fig('l03-identity', 720, 380, T(
        'Serra Alta\'s tenant, Entra ID with about 2,150 accounts, sits in the middle. On the left, '
        'the payroll run by an outside provider reaches it only through an HR ticket, about three '
        'working days late. On the right, four systems sign in through the tenant: Microsoft 365, '
        'Salesforce by SAML, Rota by OpenID Connect and the Portal B2B back office. Below, three '
        'systems keep their own passwords and the tenant reaches none of them: SAP ECC, Documentum '
        'and Coleta. At the bottom right, inside Mantiqueira\'s old tenant, Business Central and its '
        '41 users, each with a second identity.',
        'O tenant da Serra Alta, Entra ID com cerca de 2.150 contas, fica no meio. À esquerda, a folha '
        'de pagamento operada por um fornecedor externo só chega a ele por um chamado do RH, uns três '
        'dias úteis atrasado. À direita, quatro sistemas autenticam pelo tenant: Microsoft 365, '
        'Salesforce por SAML, Rota por OpenID Connect e a retaguarda do Portal B2B. Embaixo, três '
        'sistemas mantêm senhas próprias e o tenant não alcança nenhum deles: SAP ECC, Documentum e '
        'Coleta. No canto inferior direito, dentro do tenant antigo da Mantiqueira, o Business '
        'Central e seus 41 usuários, cada um com uma segunda identidade.'))
    # payroll
    f.box(85, 130, 140, 44, [T('payroll', 'folha de pagamento'), T('outside provider', 'fornecedor externo')], size=10.5)
    f.arrow([(157, 130), (233, 130)], stroke='--amber', width=1.3, dash='5 3')
    f.lines(195, 100, [T('HR ticket,', 'chamado do RH,'), T('~3 working days', '~3 dias úteis')], size=9.5, fill='--amber')
    # tenant
    f.box(320, 130, 170, 64, [T("Serra Alta's tenant", 'tenant da Serra Alta'), 'Entra ID',
                              T('~2,150 accounts', '~2.150 contas')], size=10.5, stroke='--phosphor', fill='--scan')
    # trusted systems
    f.text(600, 22, T('sign in through the tenant', 'entram pelo tenant'), size=10, fill='--paper-dim', italic=True)
    trusted = [('Microsoft 365', 50), (T('Salesforce, SAML', 'Salesforce, SAML'), 100),
               (T('Rota, OpenID Connect', 'Rota, OpenID Connect'), 150),
               (T('Portal B2B back office', 'retaguarda do Portal B2B'), 200)]
    for label, y in trusted:
        f.box(600, y, 190, 34, [label], size=10.5, stroke='--phosphor')
        f.arrow([(406, 130 + (y - 125) * 0.25), (503, y)], stroke='--phosphor', width=1.2)
    # own passwords
    f.text(240, 238, T('own passwords: the tenant reaches none of these',
                       'senhas próprias: o tenant não alcança nenhum'), size=10, fill='--amber', italic=True)
    for i, (rows) in enumerate([['SAP ECC'], ['Documentum'], [T('Coleta, IBM i', 'Coleta, IBM i')]]):
        f.box(90 + i * 150, 290, 130, 40, rows, size=10.5, stroke='--amber', dash='5 3')
    # Mantiqueira
    f.rect(490, 250, 220, 120, stroke='--wire', fill='--ink', dash='4 3')
    f.text(600, 268, T("Mantiqueira's old tenant", 'tenant antigo da Mantiqueira'), size=10, fill='--paper-dim')
    f.box(600, 318, 180, 50, ['Business Central', T('41 users, second identity', '41 usuários, 2ª identidade')],
          size=10.5, stroke='--amber')
    return f, T('Who the tenant reaches. Disabling one account closes the right-hand column and leaves the four systems at the bottom to separate tickets.',
                'Quem o tenant alcança. Desativar uma conta fecha a coluna da direita e deixa os quatro sistemas de baixo para chamados separados.')


@figure('l03-shadow', 3)
def shadow():
    f = Fig('l03-shadow', 720, 380, T(
        'Serra Alta\'s integrations in two kinds of line. Solid, the ones on Rui\'s map: Salesforce, '
        'the Portal B2B and the EDI provider connected to the ESB (IIB and MQ, about 70 flows), the '
        'ESB connected to SAP ECC, Coleta sending SAP a nightly file, and SAP extracting into SAP BW. '
        'Dashed and in amber, the ones the inventory found: 230 staff flows in Power Automate, 38 of '
        'them reaching SAP as the single user PA_FINANCEIRO, others writing to Teams, SharePoint and '
        'Excel; and about 140 Power BI reports reading SAP BW through the gateway.',
        'As integrações da Serra Alta em dois tipos de linha. Contínuas, as que estão no mapa do Rui: '
        'Salesforce, o Portal B2B e o provedor de EDI ligados ao ESB (IIB e MQ, uns 70 fluxos), o ESB '
        'ligado ao SAP ECC, o Coleta mandando ao SAP um arquivo noturno, e o SAP extraindo para o SAP '
        'BW. Tracejadas e em âmbar, as que o inventário achou: 230 fluxos de funcionários no Power '
        'Automate, 38 deles chegando ao SAP como o usuário único PA_FINANCEIRO, outros escrevendo no '
        'Teams, no SharePoint e no Excel; e cerca de 140 relatórios do Power BI lendo o SAP BW pelo '
        'gateway.'))
    # legend
    f.line(20, 26, 50, 26, stroke='--paper-dim', width=1.4)
    f.text(58, 26, T("on Rui's map", 'no mapa do Rui'), size=10, anchor='start')
    f.line(20, 48, 50, 48, stroke='--amber', width=1.6, dash='5 3')
    f.text(58, 48, T('found by the inventory', 'achadas no inventário'), size=10, anchor='start', fill='--amber')
    # top row
    for x, rows in ((280, ['Salesforce']), (420, ['Portal B2B']), (560, [T('EDI provider', 'provedor de EDI')])):
        f.box(x, 36, 120, 32, rows, size=10.5)
        f.line(x, 52, 420 + (x - 420) * 0.4, 94, stroke='--paper-dim', width=1.4)
    f.box(420, 112, 170, 36, [T('ESB: IIB + MQ, ~70 flows', 'ESB: IIB + MQ, ~70 fluxos')], size=10.5)
    f.line(420, 130, 420, 186, stroke='--paper-dim', width=1.4)
    f.box(420, 205, 140, 38, ['SAP ECC'], size=11, stroke='--phosphor', fill='--scan')
    f.box(150, 205, 120, 38, ['Coleta'], size=10.5)
    f.arrow([(210, 205), (348, 205)], stroke='--paper-dim', width=1.4)
    f.text(279, 194, T('nightly file', 'arquivo noturno'), size=9.5, fill='--paper-dim')
    f.box(630, 205, 110, 38, ['SAP BW'], size=10.5)
    f.arrow([(490, 205), (573, 205)], stroke='--paper-dim', width=1.4)
    # shadow row
    f.box(170, 330, 160, 44, ['Power Automate', T('230 staff flows', '230 fluxos de funcionários')], size=10.5, stroke='--amber')
    f.box(420, 330, 170, 44, ['Teams, SharePoint,', 'Excel'], size=10.5, stroke='--amber')
    f.box(630, 330, 120, 44, ['Power BI', T('~140 reports', '~140 relatórios')], size=10.5, stroke='--amber')
    f.arrow([(210, 307), (380, 226)], stroke='--amber', width=1.6, dash='5 3')
    f.text(205, 262, T('38 flows, one user:', '38 fluxos, um usuário:'), size=9.5, fill='--amber', anchor='end')
    f.text(205, 277, 'PA_FINANCEIRO', size=9.5, fill='--amber', anchor='end', mono=True)
    f.arrow([(251, 330), (333, 330)], stroke='--amber', width=1.6, dash='5 3')
    f.arrow([(630, 307), (630, 226)], stroke='--amber', width=1.6, dash='5 3')
    f.text(638, 266, T('via the gateway', 'pelo gateway'), size=9.5, fill='--amber', anchor='start')
    return f, T('The official map, and what the inventory drew over it. The dashed lines carry company data every day and none of them had an owner in IT.',
                'O mapa oficial, e o que o inventário desenhou por cima. As linhas tracejadas carregam dados da empresa todo dia, e nenhuma tinha dono na TI.')


@figure('l03-options', 3)
def options():
    f = Fig('l03-options', 720, 330, T(
        'Three panels, one per option, each with SAP ECC above and Business Central below. Option A, '
        'Mantiqueira into SAP ECC: one arrow carries everything once, Business Central is switched '
        'off, and the move is repeated in the S/4HANA project; R$ 2.1 million and 9 months. Option '
        'B, integrated in operations: five arrows in both directions for orders, deliveries, '
        'invoices, items and prices, every day; R$ 650 thousand, 5 months and about twelve flows to '
        'run. Option C, consolidated in finance: one arrow, the trial balance, once a month; R$ 190 '
        'thousand and 3 months.',
        'Três painéis, um por opção, cada um com o SAP ECC em cima e o Business Central embaixo. '
        'Opção A, Mantiqueira para o SAP ECC: uma seta leva tudo uma vez, o Business Central é '
        'desligado, e a mudança se repete no projeto de S/4HANA; R$ 2,1 milhões e 9 meses. Opção B, '
        'integrados na operação: cinco setas nos dois sentidos para pedidos, entregas, notas, itens e '
        'preços, todo dia; R$ 650 mil, 5 meses e uns doze fluxos para operar. Opção C, consolidados '
        'nas finanças: uma seta, o balancete, uma vez por mês; R$ 190 mil e 3 meses.'))
    panels = [
        (T('A: into SAP ECC', 'A: para o SAP ECC'),
         [T('R$ 2.1 million, 9 months,', 'R$ 2,1 milhões, 9 meses,'), T('then again into S/4HANA', 'e de novo para o S/4HANA')]),
        (T('B: integrated in operations', 'B: integrados na operação'),
         [T('R$ 650 thousand, 5 months,', 'R$ 650 mil, 5 meses,'), T('~12 flows to run', '~12 fluxos para operar')]),
        (T('C: consolidated in finance', 'C: consolidados nas finanças'),
         [T('R$ 190 thousand, 3 months,', 'R$ 190 mil, 3 meses,'), T('one monthly read', 'uma leitura por mês')]),
    ]
    for i, (title, note) in enumerate(panels):
        x0 = 10 + i * 237
        cx = x0 + 113
        f.rect(x0, 8, 226, 314, stroke='--wire', fill='--ink', dash='4 3')
        f.text(cx, 28, title, size=11, weight='600')
        f.box(cx, 70, 150, 34, ['SAP ECC'], size=10.5, stroke='--phosphor')
        dash = '5 3' if i == 0 else None
        f.box(cx, 210, 150, 34, ['Business Central'], size=10.5, stroke='--amber' if i == 0 else '--phosphor', dash=dash)
        f.lines(cx, 285, note, size=9.5, fill='--paper-dim')
        if i == 0:
            f.arrow([(cx, 192), (cx, 89)], stroke='--paper-dim', width=2.4)
            f.text(cx + 8, 140, T('everything, once', 'tudo, uma vez'), size=9.5, anchor='start')
            f.text(cx, 240, T('switched off', 'desligado'), size=9.5, fill='--amber', italic=True)
        elif i == 1:
            for k in range(5):
                x = cx - 60 + k * 30
                up = k % 2 == 0
                f.arrow([(x, 192), (x, 89)] if up else [(x, 89), (x, 192)], stroke='--paper-dim', width=1.3)
            f.text(cx, 240, T('orders, deliveries, invoices,', 'pedidos, entregas, notas,'), size=9.5, fill='--amber')
            f.text(cx, 254, T('items, prices: every day', 'itens, preços: todo dia'), size=9.5, fill='--amber')
        else:
            f.arrow([(cx, 192), (cx, 89)], stroke='--paper-dim', width=1.3)
            f.text(cx + 8, 132, T('trial balance,', 'balancete,'), size=9.5, anchor='start')
            f.text(cx + 8, 146, T('monthly', 'mensal'), size=9.5, anchor='start')
    return f, T('What crosses between the two ERPs under each option. The count of arrows is the coupling, and the cost of B is the one that keeps coming after the project ends.',
                'O que passa entre os dois ERPs em cada opção. A quantidade de setas é o acoplamento, e o custo de B é o que continua vindo depois que o projeto acaba.')
