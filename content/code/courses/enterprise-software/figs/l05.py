"""Lesson 5: Document management (DMS) and the EMC/OpenText case."""
from figures import Fig, T, figure


@figure('l05-lifecycle', 5)
def lifecycle():
    f = Fig('l05-lifecycle', 720, 330, T(
        'Two parts. Above, the states of a controlled document: draft, in review, approved and '
        'superseded, in a row, with withdrawn below approved. Draft goes to review when it is sent; '
        'review goes back to draft when it is returned, or on to approved; approved becomes superseded '
        'when a new version takes effect, or withdrawn when there is no successor. Below, the history '
        'of procedure POP-JF-PAS-004 on two time lines. The latest version moves through 1.0, 1.1, '
        '1.2 and 2.0. The version in force on line 2 stays 1.0 through both drafts and the approval, '
        'and changes to 2.0 only on the effective date, a week after approval.',
        'Duas partes. Em cima, os estados de um documento controlado: rascunho, em revisão, aprovado e '
        'substituído, em fila, com retirado abaixo de aprovado. O rascunho vai para revisão quando é '
        'enviado; a revisão volta para rascunho quando é devolvida, ou segue para aprovado; o aprovado '
        'vira substituído quando uma nova versão entra em vigor, ou retirado quando não há sucessor. '
        'Embaixo, a história do procedimento POP-JF-PAS-004 em duas linhas do tempo. A versão mais '
        'recente passa por 1.0, 1.1, 1.2 e 2.0. A versão em vigor na linha 2 continua 1.0 durante os '
        'dois rascunhos e a aprovação, e só passa a 2.0 na data de vigência, uma semana depois da '
        'aprovação.'))
    xs = [90, 270, 450, 630]
    names = [T('draft', 'rascunho'), T('in review', 'em revisão'), T('approved', 'aprovado'),
             T('superseded', 'substituído')]
    for x, n in zip(xs, names):
        f.box(x, 50, 120, 36, [n], size=11.5, stroke='--phosphor')
    f.box(450, 128, 120, 32, [T('withdrawn', 'retirado')], size=11, stroke='--wire')
    f.arrow([(152, 44), (208, 44)], stroke='--phosphor', width=1.3)
    f.text(180, 30, T('send', 'enviar'), size=10, fill='--paper-dim')
    f.path('M208 62 C190 82 170 82 152 62', stroke='--paper-dim', width=1.3, dash='5 3', arrow=True)
    f.text(180, 88, T('returned', 'devolvido'), size=10, fill='--paper-dim')
    f.arrow([(332, 50), (388, 50)], stroke='--phosphor', width=1.3)
    f.text(360, 36, T('approve', 'aprovar'), size=10, fill='--paper-dim')
    f.arrow([(512, 50), (568, 50)], stroke='--phosphor', width=1.3)
    f.lines(540, 84, [T('successor', 'sucessor'), T('takes effect', 'em vigor')], size=10,
            fill='--paper-dim')
    f.arrow([(450, 70), (450, 110)], stroke='--paper-dim', width=1.3)
    f.text(442, 92, T('no successor', 'sem sucessor'), size=10, fill='--paper-dim', anchor='end')

    f.line(20, 168, 700, 168, stroke='--wire', width=1, dash='3 4')
    f.text(20, 186, 'POP-JF-PAS-004', size=10.5, anchor='start', mono=True, weight='600')
    # time axis positions for the procedure's history
    t = {'1.0': 120, '1.1': 290, '1.2': 400, '2.0': 500, 'eff': 590}
    f.text(150, 214, T('latest version', 'versão mais recente'), size=10.5, anchor='end',
           fill='--paper-dim')
    f.text(150, 262, T('in force on line 2', 'em vigor na linha 2'), size=10.5, anchor='end',
           fill='--paper-dim')
    f.line(160, 214, 700, 214, stroke='--wire', width=1)
    for v in ('1.1', '1.2', '2.0'):
        f.circle(t[v], 214, 5, fill='--phosphor')
        f.text(t[v], 198, v, size=10.5, mono=True)
    f.circle(170, 214, 5, fill='--phosphor')
    f.text(170, 198, '1.0', size=10.5, mono=True)
    f.rect(160, 252, t['eff'] - 160, 20, stroke='--wire', fill='--scan', rx=3)
    f.text((160 + t['eff']) / 2, 262, T('1.0 in force', '1.0 em vigor'), size=10.5)
    f.rect(t['eff'], 252, 700 - t['eff'], 20, stroke='--phosphor', fill='--panel', rx=3)
    f.text((t['eff'] + 700) / 2, 262, T('2.0 in force', '2.0 em vigor'), size=10.5)
    f.line(t['2.0'], 220, t['2.0'], 249, stroke='--paper-dim', width=1, dash='3 3')
    f.line(t['2.0'], 275, t['2.0'], 296, stroke='--paper-dim', width=1, dash='3 3')
    f.text(t['2.0'], 306, T('approved', 'aprovada'), size=10, fill='--paper-dim')
    f.line(t['eff'], 220, t['eff'], 296, stroke='--amber', width=1.2, dash='3 3')
    f.text(t['eff'] + 6, 306, T('effective date', 'data de vigência'), size=10, fill='--amber',
           anchor='start')
    f.text(345, 236, T('drafts under review: the line still works to 1.0',
                       'rascunhos em revisão: a linha ainda segue a 1.0'),
           size=10, fill='--paper-dim', italic=True)
    return f, T('Draft, review, approval, and then superseded or withdrawn. The latest version is not the '
                'one in force: 2.0 exists for a week before the line works to it.',
                'Rascunho, revisão, aprovação, e depois substituído ou retirado. A versão mais recente não '
                'é a que está em vigor: a 2.0 existe uma semana antes de a linha passar a segui-la.')


@figure('l05-retention', 5)
def retention():
    f = Fig('l05-retention', 720, 290, T(
        'A time line from 2026 to 2034 for the certificate of batch L2603-0112. The batch is made on '
        '14 March 2026. The retention clock starts at the end of 2026 and runs five years, to 1 '
        'January 2032, when the certificate becomes eligible for disposal. A legal hold placed in 2031 '
        'covers that date, so the disposal run of January 2032 skips it. The hold is lifted in 2033 and '
        'the certificate is destroyed in the run of January 2034, which leaves a record of the disposal.',
        'Uma linha do tempo de 2026 a 2034 para o certificado do lote L2603-0112. O lote é produzido em '
        '14 de março de 2026. O prazo de guarda começa no fim de 2026 e corre cinco anos, até 1º de '
        'janeiro de 2032, quando o certificado pode ser descartado. Uma retenção legal aplicada em 2031 '
        'cobre essa data, então a rodada de descarte de janeiro de 2032 o pula. A retenção é suspensa '
        'em 2033 e o certificado é destruído na rodada de janeiro de 2034, que deixa um registro do '
        'descarte.'))
    x0, step = 60, 72

    def X(year):
        return x0 + (year - 2026) * step

    f.line(x0 - 10, 150, X(2034) + 20, 150, stroke='--wire', width=1.2)
    for y in range(2026, 2035):
        f.line(X(y), 145, X(y), 155, stroke='--wire', width=1)
        f.text(X(y), 168, str(y), size=10, fill='--paper-dim')
    made = X(2026) + step * 0.2
    f.circle(made, 150, 5, fill='--phosphor')
    f.lines(made, 112, [T('batch made', 'lote produzido'), T('14 Mar 2026', '14 mar 2026')], size=10)
    f.line(made, 124, made, 143, stroke='--paper-dim', width=1)
    # the retention period
    f.rect(X(2027), 60, X(2032) - X(2027), 22, stroke='--phosphor', fill='--panel', rx=3)
    f.text((X(2027) + X(2032)) / 2, 71, T('5 years from the end of 2026', '5 anos a partir do fim de 2026'),
           size=10.5)
    f.line(X(2027), 82, X(2027), 143, stroke='--phosphor', width=1, dash='3 3')
    f.line(X(2032), 82, X(2032), 143, stroke='--phosphor', width=1, dash='3 3')
    f.lines(X(2032), 36, [T('eligible for disposal', 'pode ser descartado'), T('1 Jan 2032', '1º jan 2032')],
            size=10, fill='--paper')
    # the hold
    hs, he = X(2031) + step * 0.4, X(2033) + step * 0.5
    f.rect(hs, 190, he - hs, 22, stroke='--amber', fill='--scan', rx=3)
    f.text((hs + he) / 2, 201, T('legal hold', 'retenção legal'), size=10.5, fill='--amber')
    f.text(X(2032), 230, T('Jan 2032 run: skipped', 'rodada de jan 2032: pulado'), size=10,
           fill='--paper-dim')
    f.line(X(2032), 176, X(2032), 188, stroke='--paper-dim', width=1, dash='2 3')
    f.circle(X(2034), 150, 6, fill='--amber')
    f.lines(X(2034) - 4, 258, [T('destroyed, Jan 2034,', 'destruído em jan 2034,'),
                               T('disposal recorded', 'descarte registrado')], size=10, anchor='end')
    f.line(X(2034), 176, X(2034), 244, stroke='--amber', width=1, dash='3 3')
    return f, T('The clock starts at an event, not at the batch date, and a hold beats the clock. '
                'The certificate outlives its period by two years because of one lawsuit.',
                'O prazo começa num evento, não na data do lote, e a retenção legal vence o prazo. '
                'O certificado sobrevive dois anos além do período por causa de um processo.')


@figure('l05-owners', 5)
def owners():
    f = Fig('l05-owners', 720, 270, T(
        'Two time lines from 1990 to 2026. The upper one is the owner of Documentum: Documentum itself '
        'from 1990, EMC from 2003, Dell EMC from 2016 and OpenText from 2017. The lower one is Serra '
        'Alta: it buys EMC Documentum in 2010, upgrades it last in 2015, renews support for the first '
        'time with OpenText in 2018, the year its implementation partner closes its content practice, '
        'and Joana arrives in 2026. Serra Alta made one purchase; the owner changed twice after it.',
        'Duas linhas do tempo de 1990 a 2026. A de cima é o dono do Documentum: a própria Documentum a '
        'partir de 1990, a EMC a partir de 2003, a Dell EMC a partir de 2016 e a OpenText a partir de '
        '2017. A de baixo é a Serra Alta: compra o EMC Documentum em 2010, faz a última atualização em '
        '2015, renova o suporte pela primeira vez com a OpenText em 2018, o ano em que o parceiro de '
        'implantação fecha sua área de conteúdo, e a Joana chega em 2026. A Serra Alta fez uma compra; '
        'o dono mudou duas vezes depois dela.'))
    x0, step = 110, 16.5

    def X(year):
        return x0 + (year - 1990) * step

    f.text(110, 42, T("Documentum's owner", 'dono do Documentum'), size=10.5, anchor='start',
           fill='--paper-dim')
    segs = [(1990, 2003, 'Documentum', '--wire'), (2003, 2016, 'EMC', '--wire'),
            (2016, 2017, '', '--amber'), (2017, 2026.6, 'OpenText', '--phosphor')]
    for a, b, name, stroke in segs:
        f.rect(X(a), 58, X(b) - X(a), 24, stroke=stroke, fill='--panel', rx=2)
        if name:
            f.text((X(a) + X(b)) / 2, 70, name, size=10.5)
    f.text(X(2016.5), 40, 'Dell EMC', size=10, fill='--amber')
    f.line(X(2016.5), 47, X(2016.5), 57, stroke='--amber', width=1)
    for y in (1990, 2000, 2010, 2020):
        f.text(X(y), 112, str(y), size=10, fill='--paper-dim')
        f.line(X(y), 100, X(y), 104, stroke='--wire', width=1)
    f.line(X(1990), 100, X(2026.6), 100, stroke='--wire', width=1)

    f.text(110, 160, 'Serra Alta', size=10.5, anchor='start', fill='--paper-dim')
    f.line(X(2010), 160, X(2026.6), 160, stroke='--phosphor', width=2)
    events = [
        (2010, 196, [T('buys EMC', 'compra o EMC'), 'Documentum']),
        (2015, 196, [T('last', 'última'), T('upgrade', 'atualização')]),
        (2018, 236, [T('first renewal with OpenText;', 'primeira renovação com OpenText;'),
                     T('partner closes its practice', 'parceiro fecha a área')]),
        (2026, 196, [T('Joana', 'Joana'), T('arrives', 'chega')]),
    ]
    for year, ty, rows in events:
        f.circle(X(year), 160, 5, fill='--phosphor')
        f.line(X(year), 166, X(year), ty - 14, stroke='--paper-dim', width=1)
        f.lines(X(year), ty, rows, size=10)
    for y in (2003, 2016, 2017):
        f.line(X(y), 84, X(y), 154, stroke='--amber', width=1, dash='2 3')
    return f, T('One purchase, three counterparties. The two sales after 2010 changed who Serra Alta '
                'pays and who decides the roadmap, and neither needed Serra Alta to sign anything new.',
                'Uma compra, três contrapartes. As duas vendas depois de 2010 mudaram a quem a Serra Alta '
                'paga e quem decide o roadmap, e nenhuma pediu que a Serra Alta assinasse nada.')


@figure('l05-links', 5)
def links():
    f = Fig('l05-links', 720, 340, T(
        'On the left, the batch in SAP: material 100231, batch L2610-0457, plant JF, and the id of its '
        'certificate document. On the right, the certificate in the DMS: its object id and the '
        'properties batch, material and plant. An arrow from the DMS to SAP is the document id written '
        'back to the batch; an arrow from SAP to the DMS is the batch key stored as properties, which is '
        'the source of truth. Below the DMS, a Service Cloud case asks for the certificate by batch and '
        'gets a link. Below SAP, in amber, the links that break: a file path on a file server, and a '
        'file name that two plants use.',
        'À esquerda, o lote no SAP: material 100231, lote L2610-0457, planta JF, e o id do documento do '
        'certificado. À direita, o certificado no DMS: o id do objeto e as propriedades lote, material '
        'e planta. Uma seta do DMS para o SAP é o id do documento gravado de volta no lote; uma seta do '
        'SAP para o DMS é a chave do lote guardada como propriedades, que é a fonte da verdade. Abaixo '
        'do DMS, um caso do Service Cloud pede o certificado pelo lote e recebe um link. Abaixo do SAP, '
        'em âmbar, os vínculos que quebram: um caminho num servidor de arquivos e um nome de arquivo '
        'usado por duas plantas.'))
    # SAP batch
    f.rect(30, 40, 230, 128, stroke='--phosphor', fill='--panel')
    f.text(145, 58, T('SAP: the batch', 'SAP: o lote'), size=11.5, weight='600')
    rows = ['material  100231', 'batch     L2610-0457', 'plant     JF', 'doc id    0901e24080003a7f']
    for i, r in enumerate(rows):
        f.text(44, 84 + i * 20, r, size=10.5, anchor='start', mono=True,
               fill='--phosphor' if i == 3 else '--paper')
    # DMS certificate
    f.rect(460, 40, 230, 128, stroke='--phosphor', fill='--panel')
    f.text(575, 58, T('DMS: the certificate', 'DMS: o certificado'), size=11.5, weight='600')
    rows = ['object id 0901e24080003a7f', 'batch     L2610-0457', 'material  100231', 'plant     JF']
    for i, r in enumerate(rows):
        f.text(474, 84 + i * 20, r, size=10.5, anchor='start', mono=True,
               fill='--phosphor' if i == 0 else '--paper')
    f.arrow([(270, 88), (450, 88)], stroke='--phosphor', width=1.5)
    f.text(360, 74, T('key stored as properties', 'chave guardada como propriedades'), size=10)
    f.text(360, 102, T('(source of truth)', '(fonte da verdade)'), size=10, fill='--paper-dim')
    f.arrow([(450, 144), (270, 144)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.text(360, 130, T('document id written back', 'id do documento gravado de volta'), size=10,
           fill='--paper-dim')
    # Service Cloud case
    f.box(575, 268, 230, 50, [T('Service Cloud case', 'caso no Service Cloud'),
                              T('asks by batch, gets a link', 'pede pelo lote, recebe um link')],
          size=10.5, stroke='--wire')
    f.arrow([(560, 242), (560, 172)], stroke='--phosphor', width=1.3)
    f.arrow([(590, 172), (590, 242)], stroke='--paper-dim', width=1.3, dash='5 3')
    f.text(552, 207, T('query', 'consulta'), size=10, anchor='end', fill='--paper-dim')
    f.text(598, 207, 'link', size=10, anchor='start', fill='--paper-dim')
    # what breaks
    f.rect(30, 214, 280, 110, stroke='--amber', fill='--panel', dash='4 3')
    f.text(170, 232, T('links that break', 'vínculos que quebram'), size=11, fill='--amber', weight='600')
    f.text(44, 256, r'\\jf-fs02\qualidade\...', size=10.5, anchor='start', mono=True)
    f.text(44, 272, T('the server is replaced', 'o servidor é trocado'), size=10, anchor='start',
           fill='--paper-dim')
    f.text(44, 294, 'CA-0457.pdf', size=10.5, anchor='start', mono=True)
    f.text(44, 310, T('two plants, one name', 'duas plantas, um nome'), size=10, anchor='start',
           fill='--paper-dim')
    return f, T('A link is a pair of ids. The certificate carries the batch key it was filed under, '
                'SAP keeps the document id, and nothing depends on where the file sits or what it is called.',
                'Um vínculo é um par de ids. O certificado leva a chave do lote sob a qual foi arquivado, '
                'o SAP guarda o id do documento, e nada depende de onde o arquivo está ou de como se chama.')
