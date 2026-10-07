"""Lesson 13: control mapping, ISO 27001, the NIST CSF and SOC 2."""
import csv
import os

from figures import HERE, Fig, T, figure


def mapping():
    with open(os.path.join(HERE, 'lab', 'mapping.csv')) as fh:
        return list(csv.DictReader(fh))


@figure('l13-one-control', 13)
def one_control():
    f = Fig('l13-one-control', 720, 250, T(
        'One control answering three questions. On the left, the chain the model built: threat T03, '
        'a receptionist phished with no second factor, gives requirement R05, a second factor at '
        'every staff sign-in, which control C1 implements. On the right, three documents ask about '
        'the same control in their own terms: the insurer’s questionnaire, question 14, do staff '
        'use a second factor; ISO 27001 Annex A control 8.5, secure authentication; and NIST CSF '
        'outcome PR.AA-03, users, services and hardware are authenticated.',
        'Um controle respondendo a três perguntas. À esquerda, a cadeia que o modelo construiu: a '
        'ameaça T03, uma recepcionista vítima de phishing sem segundo fator, gera o requisito R05, '
        'segundo fator em todo login da equipe, que o controle C1 implementa. À direita, três '
        'documentos perguntam pelo mesmo controle nos seus próprios termos: o questionário da '
        'operadora, pergunta 14, a equipe usa segundo fator; o controle 8.5 do Anexo A da ISO '
        '27001, autenticação segura; e o resultado PR.AA-03 do NIST CSF, usuários, serviços e '
        'hardware são autenticados.'))
    chain = [(T('T03', 'T03'), T('staff phished', 'equipe vítima de phishing'), 40),
             (T('R05', 'R05'), T('second factor, always', 'segundo fator, sempre'), 110),
             (T('C1', 'C1'), T('second factor for staff', 'segundo fator para a equipe'), 180)]
    for code, name, y in chain:
        f.rect(30, y - 22, 220, 44, stroke='--phosphor' if code == 'C1' else '--paper-dim', fill='--panel', width=1.4)
        f.text(48, y, code, size=11, anchor='start', mono=True, weight='600')
        f.text(90, y, name, size=10, anchor='start')
    f.line(140, 62, 140, 88, arrow=True)
    f.line(140, 132, 140, 158, arrow=True)
    asks = [(T('insurer, question 14', 'operadora, pergunta 14'), T('“Do staff use a second factor?”', '“A equipe usa segundo fator?”'), 50),
            (T('ISO 27001, Annex A', 'ISO 27001, Anexo A'), T('8.5 secure authentication', '8.5 autenticação segura'), 125),
            (T('NIST CSF 2.0', 'NIST CSF 2.0'), T('PR.AA-03 users are authenticated', 'PR.AA-03 usuários autenticados'), 200)]
    for who, what, y in asks:
        f.rect(420, y - 26, 280, 52, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(434, y - 10, who, size=9.5, anchor='start', fill='--paper-dim')
        f.text(434, y + 9, what, size=10.5, anchor='start', weight='600')
    f.line(250, 180, 330, 180, stroke='--phosphor', width=1.3)
    f.line(330, 50, 330, 200, stroke='--phosphor', width=1.3)
    for y in (50, 125, 200):
        f.line(330, y, 420, y, stroke='--phosphor', width=1.3, arrow=True)
    return f, T('The model already decided C1, for a threat it can name. The mapping only says where each framework files that decision.',
                'O modelo já decidiu o C1, por uma ameaça que ele sabe nomear. O mapeamento só diz onde cada framework arquiva essa decisão.')


@figure('l13-files', 13)
def files():
    f = Fig('l13-files', 720, 230, T(
        'The four files the lab joins, and the column each join uses. threats.csv holds T01 to T17. '
        'requirements.csv names its threats in a column called threats. controls.csv names the '
        'threat it reduces in a column called risk. mapping.csv names a control in a column called '
        'control and adds an ISO 27001 reference and a NIST CSF reference. Every join is by id.',
        'Os quatro arquivos que o laboratório junta, e a coluna que cada junção usa. threats.csv '
        'guarda de T01 a T17. requirements.csv nomeia as suas ameaças numa coluna chamada threats. '
        'controls.csv nomeia a ameaça que reduz numa coluna chamada risk. mapping.csv nomeia um '
        'controle numa coluna chamada control e acrescenta uma referência da ISO 27001 e uma do '
        'NIST CSF. Toda junção é por id.'))
    def file(x, y, name, rows, c='--paper-dim'):
        f.rect(x, y, 150, 70, stroke=c, fill='--panel', width=1.4)
        f.text(x + 75, y + 16, name, size=10.5, mono=True, weight='600')
        f.lines(x + 75, y + 46, rows, size=9.5, fill='--paper-dim')
    file(30, 120, 'threats.csv', [T('T01 … T17', 'T01 … T17')], '--amber')
    file(30, 15, 'requirements.csv', [T('R01 … R19', 'R01 … R19')])
    file(290, 120, 'controls.csv', [T('C1 … C11', 'C1 … C11')])
    file(540, 120, 'mapping.csv', [T('ISO 27001 and', 'ISO 27001 e'), T('NIST CSF', 'NIST CSF')], '--phosphor')
    f.line(105, 85, 105, 120, arrow=True)
    f.text(115, 102, T('column threats', 'coluna threats'), size=9.5, anchor='start', mono=True, fill='--paper-dim')
    f.line(290, 155, 180, 155, arrow=True)
    f.text(235, 145, 'risk', size=9.5, mono=True, fill='--paper-dim')
    f.line(540, 155, 440, 155, arrow=True)
    f.text(490, 145, 'control', size=9.5, mono=True, fill='--paper-dim')
    f.text(360, 215, T('each arrow points at the file whose id it names', 'cada seta aponta para o arquivo cujo id ela nomeia'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('No file repeats another’s words. A threat renamed in threats.csv changes nothing in the other three, because they hold its id.',
                'Nenhum arquivo repete as palavras de outro. Uma ameaça renomeada em threats.csv não muda nada nos outros três, porque eles guardam o id dela.')


@figure('l13-iso-themes', 13)
def iso_themes():
    refs = {r for m in mapping() for r in m['iso27001'].split()}
    themes = [('5', T('organisational', 'organizacionais'), 37), ('6', T('people', 'pessoas'), 8),
              ('7', T('physical', 'físicos'), 14), ('8', T('technological', 'tecnológicos'), 34)]
    got = {p: sum(1 for r in refs if r.split('.')[0] == p) for p, _, _ in themes}
    f = Fig('l13-iso-themes', 720, 230, T(
        'The 93 controls of ISO 27001:2022 Annex A by theme, and how many of them Vereda’s eleven '
        f'controls reach. Organisational: {got["5"]} of 37. People: {got["6"]} of 8. Physical: '
        f'{got["7"]} of 14. Technological: {got["8"]} of 34.',
        'Os 93 controles do Anexo A da ISO 27001:2022 por tema, e quantos deles os onze controles '
        f'da Vereda alcançam. Organizacionais: {got["5"]} de 37. Pessoas: {got["6"]} de 8. Físicos: '
        f'{got["7"]} de 14. Tecnológicos: {got["8"]} de 34.'))
    k = 11
    for i, (p, name, total) in enumerate(themes):
        y = 30 + i * 45
        f.text(150, y + 12, f'{p}.x  {name}', size=10, anchor='end')
        f.rect(165, y, total * k, 24, stroke='--wire', fill='--panel', width=1, rx=2)
        if got[p]:
            f.rect(165, y, got[p] * k, 24, stroke=None, fill='--phosphor', rx=2)
        f.text(165 + total * k + 10, y + 12, T(f'{got[p]} of {total}', f'{got[p]} de {total}'), size=10,
               anchor='start', weight='600', fill='--amber' if got[p] == 0 else '--paper')
    f.text(360, 212, T('filled: an Annex A control at least one of C1 to C11 maps to', 'preenchido: um controle do Anexo A ao qual pelo menos um de C1 a C11 é mapeado'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('Ten Annex A controls out of 93, none of them about people or premises. That is what a model of one web portal reaches, and the rest of the statement of applicability is decided elsewhere.',
                'Dez controles do Anexo A de 93, nenhum sobre pessoas ou instalações. É o que um modelo de um portal web alcança, e o resto da declaração de aplicabilidade é decidido em outro lugar.')


@figure('l13-csf-functions', 13)
def csf_functions():
    cats = {r.split('-')[0] for m in mapping() for r in m['csf'].split()}
    funcs = [('GV', 'Govern', 'Governar', 6), ('ID', 'Identify', 'Identificar', 3), ('PR', 'Protect', 'Proteger', 5),
             ('DE', 'Detect', 'Detectar', 2), ('RS', 'Respond', 'Responder', 4), ('RC', 'Recover', 'Recuperar', 2)]
    got = {c: sum(1 for x in cats if x.startswith(c + '.')) for c, _, _, _ in funcs}
    f = Fig('l13-csf-functions', 720, 240, T(
        'The six functions of NIST CSF 2.0 and their 22 categories, with the categories Vereda’s '
        'controls reach. Govern: ' + f'{got["GV"]} of 6. Identify: {got["ID"]} of 3. Protect: '
        f'{got["PR"]} of 5. Detect: {got["DE"]} of 2. Respond: {got["RS"]} of 4. Recover: {got["RC"]} of 2.',
        'As seis funções do NIST CSF 2.0 e as suas 22 categorias, com as categorias que os '
        'controles da Vereda alcançam. Governar: ' + f'{got["GV"]} de 6. Identificar: {got["ID"]} de 3. '
        f'Proteger: {got["PR"]} de 5. Detectar: {got["DE"]} de 2. Responder: {got["RS"]} de 4. '
        f'Recuperar: {got["RC"]} de 2.'))
    w, gap = 100, 12
    x0 = (720 - 6 * w - 5 * gap) / 2
    for i, (code, en, pt, total) in enumerate(funcs):
        x = x0 + i * (w + gap)
        f.rect(x, 20, w, 40, stroke='--phosphor' if got[code] else '--paper-dim', fill='--panel', width=1.4)
        f.text(x + w / 2, 33, code, size=11, mono=True, weight='600')
        f.text(x + w / 2, 49, T(en, pt), size=9.5, fill='--paper-dim')
        for j in range(total):
            y = 75 + j * 22
            f.rect(x + 20, y, w - 40, 16, stroke='--wire', fill='--phosphor' if j < got[code] else '--panel', width=1, rx=2)
        f.text(x + w / 2, 215, T(f'{got[code]} of {total}', f'{got[code]} de {total}'), size=10, weight='600',
               fill='--paper' if got[code] else '--amber')
    return f, T('Every category the controls reach is in Protect. A threat model asks what could go wrong in a design, and its answers are mostly ways to stop it; noticing and recovering are questions it rarely asks.',
                'Toda categoria que os controles alcançam está em Proteger. Um modelo de ameaças pergunta o que pode dar errado num projeto, e as respostas são quase sempre jeitos de impedir; perceber e se recuperar são perguntas que ele raramente faz.')


@figure('l13-soc2-period', 13)
def soc2_period():
    f = Fig('l13-soc2-period', 720, 220, T(
        'Two kinds of SOC 2 report on one timeline. A Type I report looks at the design of the '
        'controls on a single date. A Type II report tests whether they operated over a period: '
        'the gateway’s covers 1 July 2025 to 30 June 2026, and was delivered in August 2026. The '
        'months after the period are covered only by the gateway’s own bridge letter, which no '
        'auditor tested.',
        'Dois tipos de relatório SOC 2 numa linha do tempo. Um relatório Tipo I olha o desenho dos '
        'controles numa única data. Um relatório Tipo II testa se eles funcionaram ao longo de um '
        'período: o do gateway cobre de 1º de julho de 2025 a 30 de junho de 2026, e foi entregue em '
        'agosto de 2026. Os meses depois do período são cobertos só pela carta-ponte do próprio '
        'gateway, que nenhum auditor testou.'))
    x0, x1 = 60, 680
    m = lambda y, mo: x0 + ((y - 2025) * 12 + (mo - 5)) / 18 * (x1 - x0)
    f.line(x0, 160, x1, 160, stroke='--paper-dim')
    names = {1: T('Jan', 'jan'), 4: T('Apr', 'abr'), 7: T('Jul', 'jul'), 10: T('Oct', 'out')}
    for y, mo in ((2025, 7), (2025, 10), (2026, 1), (2026, 4), (2026, 7), (2026, 10)):
        f.line(m(y, mo), 160, m(y, mo), 165, stroke='--paper-dim')
        f.text(m(y, mo), 178, f'{names[mo]} {y}', size=9, fill='--paper-dim')
    f.circle(m(2025, 7), 45, 6, fill='--paper-dim')
    f.text(m(2025, 7) + 12, 45, T('Type I: the design, on one date', 'Tipo I: o desenho, numa data'), size=10, anchor='start')
    f.rect(m(2025, 7), 80, m(2026, 7) - m(2025, 7), 20, stroke=None, fill='--phosphor', rx=3)
    f.text(m(2025, 7) + 8, 70, T('Type II: tested over twelve months', 'Tipo II: testado ao longo de doze meses'), size=10, anchor='start', weight='600')
    f.rect(m(2026, 7), 80, m(2026, 10) - m(2026, 7), 20, stroke='--amber', fill='--panel', rx=3, dash='4 3')
    f.text(m(2026, 7) + 4, 120, T('bridge letter: the gateway’s word only', 'carta-ponte: só a palavra do gateway'), size=9.5, anchor='start', fill='--amber')
    f.circle(m(2026, 8), 140, 5, fill='--paper')
    f.text(m(2026, 8) - 10, 140, T('report delivered', 'relatório entregue'), size=9.5, anchor='end')
    return f, T('A Type II report says the controls worked during its period, and says nothing about the months since.',
                'Um relatório Tipo II diz que os controles funcionaram durante o período dele, e não diz nada sobre os meses desde então.')


@figure('l13-cuec', 13)
def cuec():
    f = Fig('l13-cuec', 720, 260, T(
        'The gateway’s controls and the ones its report expects from customers, on either side of '
        'the trust boundary between Vereda and the gateway. The gateway signs every webhook it '
        'sends, protects its API, and keeps its keys; its auditor tested those. Its report then '
        'lists what customers must do for that to protect them: verify the webhook signature, '
        'which is Vereda’s R01 and control C3; keep the API key secret; and review who can use '
        'the gateway’s dashboard. The last two have no requirement in Vereda’s model.',
        'Os controles do gateway e os que o relatório dele espera dos clientes, dos dois lados da '
        'fronteira de confiança entre a Vereda e o gateway. O gateway assina todo webhook que '
        'manda, protege a sua API e guarda as suas chaves; o auditor dele testou isso. O relatório '
        'então lista o que os clientes precisam fazer para isso protegê-los: verificar a assinatura '
        'do webhook, que é o R01 e o controle C3 da Vereda; manter a chave da API em segredo; e '
        'revisar quem pode usar o painel do gateway. Os dois últimos não têm requisito no modelo '
        'da Vereda.'))
    f.text(180, 22, T('the gateway: tested by its auditor', 'o gateway: testado pelo auditor dele'), size=10, weight='600')
    f.text(540, 22, T('Vereda: complementary controls', 'Vereda: controles complementares'), size=10, weight='600')
    left = [T('signs every webhook it sends', 'assina todo webhook que manda'),
            T('rate-limits and logs its API', 'limita e registra a sua API'),
            T('rotates its signing keys', 'troca as suas chaves de assinatura')]
    right = [(T('verifies the signature', 'verifica a assinatura'), 'R01 · C3'),
             (T('keeps the API key secret', 'guarda a chave da API em segredo'), T('no requirement', 'sem requisito')),
             (T('reviews who uses the dashboard', 'revisa quem usa o painel'), T('no requirement', 'sem requisito'))]
    for i, s in enumerate(left):
        y = 50 + i * 60
        f.rect(40, y, 280, 40, stroke='--paper-dim', fill='--panel', width=1.2)
        f.text(180, y + 20, s, size=10)
    for i, (s, ref) in enumerate(right):
        y = 50 + i * 60
        c = '--amber' if i else '--phosphor'
        f.rect(400, y, 280, 40, stroke=c, fill='--panel', width=1.4)
        f.text(414, y + 20, s, size=10, anchor='start')
        f.text(668, y + 20, ref, size=9.5, anchor='end', mono=True, fill='--amber' if i else '--paper-dim')
    f.boundary([(360, 40), (360, 230)], T('trust boundary', 'fronteira de confiança'), (366, 244), size=9.5)
    f.line(320, 70, 400, 70, arrow=True, stroke='--phosphor')
    return f, T('A SOC 2 report is half a control. The other half is listed in it as the customer’s job, and only the customer can check that it is done.',
                'Um relatório SOC 2 é metade de um controle. A outra metade está listada nele como trabalho do cliente, e só o cliente pode conferir se está feita.')


@figure('l13-drift', 13)
def drift():
    rows = [('A.9.4.2', T('secure log-on procedures', 'procedimentos de logon seguro'), '8.5', T('secure authentication', 'autenticação segura')),
            ('A.9.2.3', T('management of privileged access rights', 'gestão de direitos de acesso privilegiado'), '8.2', T('privileged access rights', 'direitos de acesso privilegiado')),
            ('A.13.1.3', T('segregation in networks', 'segregação de redes'), '8.22', T('segregation of networks', 'segregação de redes')),
            ('A.18.1.4', T('privacy and protection of PII', 'privacidade e proteção de PII'), '5.34', T('privacy and protection of PII', 'privacidade e proteção de PII'))]
    f = Fig('l13-drift', 720, 240, T(
        'Four controls renumbered between the 2013 and 2022 editions of ISO 27001 Annex A. A.9.4.2, '
        'secure log-on procedures, became 8.5, secure authentication. A.9.2.3, management of '
        'privileged access rights, became 8.2. A.13.1.3, segregation in networks, became 8.22. '
        'A.18.1.4, privacy and protection of PII, became 5.34.',
        'Quatro controles renumerados entre as edições de 2013 e 2022 do Anexo A da ISO 27001. O '
        'A.9.4.2, procedimentos de logon seguro, virou 8.5, autenticação segura. O A.9.2.3, gestão '
        'de direitos de acesso privilegiado, virou 8.2. O A.13.1.3, segregação de redes, virou 8.22. '
        'O A.18.1.4, privacidade e proteção de PII, virou 5.34.'))
    f.text(185, 20, T('ISO 27001:2013', 'ISO 27001:2013'), size=10.5, weight='600', fill='--paper-dim')
    f.text(545, 20, T('ISO 27001:2022', 'ISO 27001:2022'), size=10.5, weight='600')
    for i, (old, oname, new, nname) in enumerate(rows):
        y = 40 + i * 48
        f.rect(20, y, 330, 36, stroke='--wire', fill='--panel', width=1, dash='4 3')
        f.text(32, y + 18, old, size=10, anchor='start', mono=True, fill='--paper-dim')
        f.text(108, y + 18, oname, size=9.5, anchor='start', fill='--paper-dim')
        f.rect(390, y, 310, 36, stroke='--phosphor', fill='--panel', width=1.2)
        f.text(402, y + 18, new, size=10, anchor='start', mono=True, weight='600')
        f.text(450, y + 18, nname, size=9.5, anchor='start')
        f.line(350, y + 18, 390, y + 18, arrow=True)
    f.text(360, 230, T('a mapping kept as numbers ages with the edition it was written against', 'um mapeamento guardado como números envelhece com a edição contra a qual foi escrito'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('The control is the same and its number is not. A mapping that names the edition it used can be translated; one that does not is silently wrong.',
                'O controle é o mesmo e o número não. Um mapeamento que diz a edição que usou pode ser traduzido; um que não diz está errado em silêncio.')
