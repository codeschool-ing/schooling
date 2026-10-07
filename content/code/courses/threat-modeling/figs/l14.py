"""Lesson 14: audit, its scope, its evidence and the preparation for it."""
from figures import Fig, T, figure


@figure('l14-parties', 14)
def parties():
    f = Fig('l14-parties', 720, 220, T(
        'Three kinds of audit, by who audits whom. A first-party audit is an organisation auditing '
        'itself, an internal audit. A second-party audit is a customer auditing its supplier: the '
        'insurer auditing Vereda. A third-party audit is an independent body auditing for a '
        'certificate or a report anybody can rely on. Vereda’s audit in November 2026 is second '
        'party.',
        'Três tipos de auditoria, por quem audita quem. Uma auditoria de primeira parte é uma '
        'organização auditando a si mesma, uma auditoria interna. Uma de segunda parte é um cliente '
        'auditando o seu fornecedor: a operadora auditando a Vereda. Uma de terceira parte é um '
        'organismo independente auditando para um certificado ou um relatório em que qualquer um '
        'pode confiar. A auditoria da Vereda em novembro de 2026 é de segunda parte.'))
    cols = [(T('first party', 'primeira parte'), T('Vereda audits', 'a Vereda audita'), T('itself', 'a si mesma'), '--paper-dim'),
            (T('second party', 'segunda parte'), T('the insurer audits', 'a operadora audita'), T('Vereda, its supplier', 'a Vereda, sua fornecedora'), '--phosphor'),
            (T('third party', 'terceira parte'), T('a certification body', 'um organismo certificador'), T('audits for everybody', 'audita para todos'), '--paper-dim')]
    for i, (name, a, b, c) in enumerate(cols):
        x = 30 + i * 230
        f.rect(x, 40, 200, 110, stroke=c, fill='--panel', width=1.6 if c == '--phosphor' else 1.2)
        f.text(x + 100, 62, name, size=11, weight='600')
        f.lines(x + 100, 108, [a, b], size=10)
    f.text(360, 178, T('Vereda in November 2026', 'a Vereda em novembro de 2026'), size=10, weight='600', fill='--phosphor')
    f.line(360, 168, 360, 150, arrow=True, stroke='--phosphor')
    f.text(360, 205, T('internal audit is ISO 27001 clause 9.2; certification is a third-party audit', 'auditoria interna é a cláusula 9.2 da ISO 27001; certificação é uma auditoria de terceira parte'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('Who audits decides what the report is for. A second-party audit answers one customer’s question, and its scope is what that customer cares about.',
                'Quem audita decide para que serve o relatório. Uma auditoria de segunda parte responde à pergunta de um cliente, e o escopo dela é o que esse cliente quer saber.')


@figure('l14-scope', 14)
def scope():
    f = Fig('l14-scope', 720, 280, T(
        'The scope of the insurer’s audit drawn on the portal’s level 1 diagram. Inside the scope '
        'line: the patient portal, the staff console, the reminder worker, the database and the exam '
        'file store. Outside it: the payment gateway, covered by its SOC 2 report; the SMS provider, '
        'covered by its contract; and the clinics’ premises and computers, which the insurer chose '
        'not to audit.',
        'O escopo da auditoria da operadora desenhado no diagrama de nível 1 do portal. Dentro da '
        'linha de escopo: o portal do paciente, o console da equipe, o worker de lembretes, o banco '
        'de dados e o armazenamento de exames. Fora dela: o gateway de pagamento, coberto pelo '
        'relatório SOC 2; o provedor de SMS, coberto pelo contrato; e as instalações e os '
        'computadores das clínicas, que a operadora escolheu não auditar.'))
    f.rect(170, 30, 380, 210, stroke='--phosphor', fill='--panel', width=1.6, rx=6, dash='8 4')
    f.text(182, 46, T('in scope', 'no escopo'), size=10, anchor='start', weight='600', fill='--phosphor')
    f.pbox(270, 90, 130, 38, [T('patient portal', 'portal do paciente')])
    f.pbox(450, 90, 130, 38, [T('staff console', 'console da equipe')])
    f.pbox(450, 160, 130, 38, [T('reminder worker', 'worker de lembretes')])
    f.store(270, 160, 130, [T('database', 'banco de dados')])
    f.store(270, 212, 130, [T('exam files', 'arquivos de exame')])
    outs = [(85, 70, [T('payment', 'gateway de'), T('gateway', 'pagamento')], T('SOC 2 report', 'relatório SOC 2')),
            (635, 160, [T('SMS', 'provedor'), T('provider', 'de SMS')], T('contract', 'contrato')),
            (635, 70, [T('clinics’', 'instalações'), T('premises', 'das clínicas')], T('not chosen', 'não escolhido'))]
    for x, y, rows, why in outs:
        f.entity(x, y, 120, 46, rows)
        f.text(x, y + 38, why, size=9.5, italic=True, fill='--amber')
    f.line(145, 80, 205, 85, arrow=True)
    f.line(515, 160, 575, 160, arrow=True)
    f.text(360, 265, T('everything outside the line is relied on, not tested', 'tudo fora da linha é presumido, não testado'),
           size=9.5, italic=True, fill='--paper-dim')
    return f, T('A scope drawn on the model can be argued about element by element. A scope written as “the portal” cannot, and each side reads it differently.',
                'Um escopo desenhado no modelo pode ser discutido elemento por elemento. Um escopo escrito como “o portal” não pode, e cada lado o lê de um jeito.')


@figure('l14-evidence', 14)
def evidence():
    f = Fig('l14-evidence', 720, 240, T(
        'Four ways to obtain evidence, from weakest to strongest. Inquiry: asking somebody, who says '
        'staff use a second factor. Observation: watching somebody sign in with one. Inspection: '
        'reading the console’s configuration, or a log of 40 sign-ins. Re-performance: the auditor '
        'tries to sign in without the second factor and is refused.',
        'Quatro jeitos de obter evidência, da mais fraca à mais forte. Indagação: perguntar a alguém, '
        'que diz que a equipe usa segundo fator. Observação: ver alguém entrar com um. Inspeção: ler '
        'a configuração do console, ou um log de 40 logins. Reexecução: o auditor tenta entrar sem o '
        'segundo fator e é recusado.'))
    steps = [(T('inquiry', 'indagação'), T('“yes, everybody uses it”', '“sim, todo mundo usa”'), 60),
             (T('observation', 'observação'), T('watching one sign-in', 'ver um login'), 95),
             (T('inspection', 'inspeção'), T('the configuration, a log of 40', 'a configuração, um log de 40'), 130),
             (T('re-performance', 'reexecução'), T('the auditor tries, and is refused', 'o auditor tenta, e é recusado'), 165)]
    for i, (name, ex, h) in enumerate(steps):
        x = 40 + i * 170
        f.rect(x, 210 - h, 150, h, stroke=None, fill='--phosphor' if i == 3 else '--phosphor-dim', rx=3)
        f.text(x + 75, 210 - h - 12, name, size=10.5, weight='600')
        f.text(x + 75, 224, ex, size=9, fill='--paper-dim')
    return f, T('Inquiry alone is never enough in an audit: what somebody says has to be backed by something the auditor reads or does.',
                'Indagação sozinha nunca basta numa auditoria: o que alguém diz precisa ser sustentado por algo que o auditor lê ou faz.')


@figure('l14-git', 14)
def git():
    rows = [(T('the content of each file at each commit', 'o conteúdo de cada arquivo em cada commit'), T('strong: every commit names its parent by hash', 'forte: cada commit nomeia o pai por hash'), '--phosphor'),
            (T('the order of the commits', 'a ordem dos commits'), T('strong, once pushed to a remote others use', 'forte, depois de enviado a um remoto que outros usam'), '--phosphor'),
            (T('the date of a commit', 'a data de um commit'), T('weak: the committer writes it', 'fraca: quem faz o commit a escreve'), '--amber'),
            (T('who wrote it', 'quem escreveu'), T('weak: a name in the config, unless signed', 'fraca: um nome na configuração, a não ser que assinado'), '--amber'),
            (T('that daniel approved RA-001', 'que o daniel aprovou o RA-001'), T('only what the file says', 'só o que o arquivo diz'), '--amber')]
    f = Fig('l14-git', 720, 260, T(
        'What a git history shows as evidence, and how strongly. The content of each file at each '
        'commit: strong, because every commit names its parent by hash. The order of the commits: '
        'strong once pushed to a remote others use. The date of a commit: weak, because the '
        'committer writes it. Who wrote it: weak, a name in the configuration, unless the commit is '
        'signed. That daniel approved RA-001: only what the file says.',
        'O que um histórico git mostra como evidência, e com que força. O conteúdo de cada arquivo '
        'em cada commit: forte, porque cada commit nomeia o pai por hash. A ordem dos commits: forte '
        'depois de enviada a um remoto que outros usam. A data de um commit: fraca, porque quem faz '
        'o commit a escreve. Quem escreveu: fraco, um nome na configuração, a não ser que o commit '
        'seja assinado. Que o daniel aprovou o RA-001: só o que o arquivo diz.'))
    for i, (what, how, c) in enumerate(rows):
        y = 20 + i * 46
        f.rect(20, y, 300, 36, stroke='--wire', fill='--panel', width=1)
        f.text(32, y + 18, what, size=10, anchor='start')
        f.rect(340, y, 360, 36, stroke=c, fill='--panel', width=1.4)
        f.text(352, y + 18, how, size=10, anchor='start', fill='--paper' if c == '--phosphor' else '--amber')
    return f, T('Git is excellent evidence of what changed and in what order, and weak evidence of when and by whom. A careful auditor knows which half they are reading.',
                'O git é ótima evidência do que mudou e em que ordem, e evidência fraca de quando e por quem. Um auditor cuidadoso sabe qual metade está lendo.')


@figure('l14-preparation', 14)
def preparation():
    f = Fig('l14-preparation', 720, 220, T(
        'Vereda’s preparation for the audit on a timeline. 2 October: the request list arrives. 6 '
        'October: pbc.py checks it and finds one item missing and one with nothing named. October: '
        'gaps are fixed or explained, and the answers rehearsed in a mock walkthrough. 9 to 11 '
        'November: fieldwork. 30 November: the report.',
        'A preparação da Vereda para a auditoria numa linha do tempo. 2 de outubro: chega a lista '
        'de pedidos. 6 de outubro: o pbc.py a confere e acha um item faltando e um sem nada nomeado. '
        'Outubro: as lacunas são corrigidas ou explicadas, e as respostas ensaiadas num walkthrough '
        'simulado. 9 a 11 de novembro: trabalho de campo. 30 de novembro: o relatório.'))
    x0, x1 = 50, 680
    m = lambda mo, d: x0 + ((mo - 10) * 31 + d - 1) / 61 * (x1 - x0)
    f.line(x0, 120, x1, 120, stroke='--paper-dim')
    marks = [((10, 2), T('request list', 'lista de pedidos'), T('2 Oct', '2 out'), 40),
             ((10, 6), T('pbc.py: 2 gaps', 'pbc.py: 2 lacunas'), T('6 Oct', '6 out'), 70),
             ((11, 9), T('fieldwork', 'trabalho de campo'), T('9–11 Nov', '9–11 nov'), 70),
             ((11, 30), T('report', 'relatório'), T('30 Nov', '30 nov'), 40)]
    for (mo, d), label, date, y in marks:
        x = m(mo, d)
        f.circle(x, 120, 6, fill='--phosphor')
        f.line(x, 114, x, y + 8, stroke='--paper-dim')
        f.text(x, y, label, size=10, weight='600', anchor='start' if x < 360 else 'end')
        f.text(x, 140, date, size=9.5, fill='--paper-dim')
    f.rect(m(10, 7), 160, m(11, 8) - m(10, 7), 22, stroke=None, fill='--phosphor-dim', rx=3)
    f.text((m(10, 7) + m(11, 8)) / 2, 171, T('fix or explain each gap; rehearse the walkthrough', 'corrigir ou explicar cada lacuna; ensaiar o walkthrough'), size=9.5)
    f.text(360, 205, T('nothing is created to look older than it is', 'nada é criado para parecer mais antigo do que é'), size=9.5, italic=True, fill='--amber')
    return f, T('Five weeks between the request and the fieldwork. Most of the value of an audit is spent in them, by the side being audited.',
                'Cinco semanas entre o pedido e o trabalho de campo. A maior parte do valor de uma auditoria é gasta nelas, pelo lado auditado.')


@figure('l14-finding', 14)
def finding():
    parts = [(T('condition', 'condição'), T('RA-002 was due for review on 2 October; it was not reviewed', 'o RA-002 vencia para revisão em 2 de outubro; não foi revisto')),
             (T('criteria', 'critério'), T('accepted risks are reviewed by their date (questionnaire, question 22)', 'riscos aceitos são revistos até a data (questionário, pergunta 22)')),
             (T('cause', 'causa'), T('nothing reminded the owner; acceptances.py is run by hand', 'nada lembrou o dono; o acceptances.py é rodado à mão')),
             (T('effect', 'efeito'), T('T06 is accepted on an estimate nobody has checked for six months', 'a T06 está aceita com uma estimativa que ninguém confere há seis meses')),
             (T('recommendation', 'recomendação'), T('run the check on a schedule, and tell the owner', 'rodar a checagem numa agenda, e avisar o dono'))]
    f = Fig('l14-finding', 720, 270, T(
        'The five parts of an audit finding, with RA-002 as the example. Condition: RA-002 was due '
        'for review on 2 October and was not reviewed. Criteria: accepted risks are reviewed by '
        'their date. Cause: nothing reminded the owner; the check is run by hand. Effect: T06 is '
        'accepted on an estimate nobody has checked for six months. Recommendation: run the check on '
        'a schedule, and tell the owner.',
        'As cinco partes de um achado de auditoria, com o RA-002 de exemplo. Condição: o RA-002 '
        'vencia para revisão em 2 de outubro e não foi revisto. Critério: riscos aceitos são revistos '
        'até a data. Causa: nada lembrou o dono; a checagem é rodada à mão. Efeito: a T06 está aceita '
        'com uma estimativa que ninguém confere há seis meses. Recomendação: rodar a checagem numa '
        'agenda, e avisar o dono.'))
    for i, (name, text) in enumerate(parts):
        y = 15 + i * 50
        f.rect(20, y, 130, 40, stroke='--phosphor' if i < 4 else '--amber', fill='--panel', width=1.4)
        f.text(85, y + 20, name, size=10.5, weight='600')
        f.rect(165, y, 535, 40, stroke='--wire', fill='--panel', width=1)
        f.text(178, y + 20, text, size=10, anchor='start')
    return f, T('A finding without a cause gets the symptom fixed: somebody reviews RA-002 this week, and RA-001 is overdue in April.',
                'Um achado sem causa faz corrigirem o sintoma: alguém revê o RA-002 nesta semana, e o RA-001 atrasa em abril.')
