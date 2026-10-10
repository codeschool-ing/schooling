"""Lesson 21: compliance reporting. Twelve of Ipê Crédito's loans counted against two
definitions that share a name (90 days for the report, 30 for collections), the same report
re-run on live data after a back-dated payment, Ipê's reporting calendar as a mock, and the
path from the source systems to a submitted report."""
import book as B

LESSON = 'le-tdaf4j5a'

# Twelve personal loans at 31 December 2025, chosen to show every case rather than drawn as a
# sample: days overdue on that date, and the balance outstanding in thousands of reais.
LOANS = [(0, 8.4), (0, 12.0), (12, 5.6), (35, 9.8), (0, 15.2), (95, 7.1), (41, 6.3), (0, 11.5),
         (130, 4.2), (8, 10.0), (62, 7.7), (0, 9.6)]
# In February 2026 loan 6's payment, received on 20 December, is entered with that date, so
# on live data it was 70 days overdue at 31 December rather than 95.
LATE_ENTRY = (6, 70)


def table(loans, title, extra=()):
    rows = [['Loan', 'Days overdue', 'Balance', '90+', '30+']]
    for k, (d, b) in enumerate(loans, start=2):
        rows.append([k - 1, d, b, f'=IF(B{k}>=90,1,0)', f'=IF(B{k}>=30,1,0)'])
    n = len(loans) + 1
    rows.append(['Total', '', f'=SUM(C2:C{n})', f'=SUM(D2:D{n})', f'=SUM(E2:E{n})'])
    t = n + 1
    return B.report(title, rows, [f'C{t}', f'D{t}', f'E{t}', 'D7', 'E7'], [
        f'=SUMPRODUCT(C2:C{n},D2:D{n})', f'=SUMPRODUCT(C2:C{n},E2:E{n})',
        f'=ROUND(D{t}/{len(loans)}*100,1)', f'=ROUND(E{t}/{len(loans)}*100,1)',
        f'=ROUND(SUMPRODUCT(C2:C{n},D2:D{n})/C{t}*100,1)',
        f'=ROUND(SUMPRODUCT(C2:C{n},E2:E{n})/C{t}*100,1)',
    ] + list(extra))


def two_names():
    return table(LOANS, 'lesson 21 — one book, two definitions')


def rerun():
    loans = list(LOANS)
    i, d = LATE_ENTRY
    loans[i - 1] = (d, loans[i - 1][1])
    return table(loans, 'lesson 21 — the same report re-run on live data in February')


# ------------------------------------------------------------------ figures

CAL = [
    (('Central Bank: credit data (SCR)', 'Banco Central: dados de crédito (SCR)'),
     ('monthly', 'mensal'), ('Fernanda', 'Fernanda'), ('snapshot frozen, in review', 'foto congelada, em revisão'), 'amber'),
    (('Tax authority: monthly filing', 'Receita: declaração mensal'),
     ('monthly', 'mensal'), ('finance', 'financeiro'), ('submitted, archived', 'enviado, arquivado'), 'ok'),
    (('Board: risk appetite report', 'Conselho: relatório de apetite a risco'),
     ('monthly', 'mensal'), ('Fernanda', 'Fernanda'), ('not started: due in 9 days', 'não iniciado: vence em 9 dias'), 'wait'),
    (('Data subject requests (LGPD)', 'Pedidos de titulares (LGPD)'),
     ('as they come', 'quando chegam'), ('privacy officer', 'encarregado'), ('2 open, oldest 6 days', '2 abertos, o mais antigo há 6 dias'), 'amber'),
    (('Annual audit: loan book', 'Auditoria anual: carteira'),
     ('yearly', 'anual'), ('finance', 'financeiro'), ('snapshot of 31 Dec kept', 'foto de 31/12 guardada'), 'ok'),
]


def calendar():
    f = B.Fig('l21-calendar', 720, 330, (
        'A mock of Ipê\'s compliance calendar on Monday 12 January 2026. Five rows, each with the '
        'report, how often it is due, its owner and its status: the Central Bank\'s credit data, '
        'monthly, Fernanda, snapshot frozen and in review; the monthly tax filing, finance, '
        'submitted and archived; the board\'s risk appetite report, Fernanda, not started and due in '
        '9 days; data subject requests under the LGPD, the privacy officer, 2 open, the oldest 6 days '
        'old; the annual audit of the loan book, finance, the 31 December snapshot kept.',
        'Maquete do calendário de obrigações da Ipê na segunda, 12 de janeiro de 2026. Cinco linhas, '
        'cada uma com o relatório, a frequência, o responsável e a situação: os dados de crédito para '
        'o Banco Central, mensal, Fernanda, foto congelada e em revisão; a declaração mensal à '
        'Receita, financeiro, enviada e arquivada; o relatório de apetite a risco para o conselho, '
        'Fernanda, não iniciado e vencendo em 9 dias; os pedidos de titulares pela LGPD, o '
        'encarregado, 2 abertos, o mais antigo há 6 dias; a auditoria anual da carteira, financeiro, '
        'a foto de 31 de dezembro guardada.'))
    f.rect(10, 10, 700, 310, fill='--ink', stroke='--wire', sw=1)
    f.text(28, 40, ('Ipê · compliance calendar', 'Ipê · calendário de obrigações'), size=15, weight=600)
    f.text(692, 40, ('Mon 12 Jan 2026', 'seg., 12/01/2026'), size=11, anchor='end', fill='--paper-dim')
    cols = [(28, ('report', 'relatório')), (290, ('due', 'frequência')),
            (380, ('owner', 'responsável')), (490, ('status', 'situação'))]
    y = 76
    for cx, lab in cols:
        f.text(cx, y, lab, size=11, fill='--paper-dim')
    f.line(28, y + 8, 692, y + 8, stroke='--wire', sw=1)
    y += 36
    for rep, due, owner, status, kind in CAL:
        if kind == 'amber':
            f.bar(18, y - 12, 4, 16, fill='--amber')
        f.text(28, y, rep, size=12)
        f.text(290, y, due, size=12, fill='--paper-dim')
        f.text(380, y, owner, size=12)
        f.text(490, y, status, size=12, fill='--paper' if kind != 'ok' else '--paper-dim')
        y += 38
    f.text(28, 304, ('each submitted report keeps: snapshot date, definition version, approver',
                     'cada relatório enviado guarda: data da foto, versão da definição, quem aprovou'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'A compliance calendar is an operational screen for reports: what is due, whose it is, and '
        'whether it can be reproduced. The rows that need somebody this week are marked.',
        'Um calendário de obrigações é uma tela operacional de relatórios: o que vence, de quem é e '
        'se pode ser reproduzido. As linhas que precisam de alguém nesta semana estão marcadas.'))


def path():
    f = B.Fig('l21-path', 720, 250, (
        'Five boxes left to right, joined by arrows: the source systems; the nightly copy; a frozen '
        'snapshot dated 31 December 2025; the report, computed with definition version 3; the '
        'submitted file, approved by a named person. Under the last three, what each keeps: the '
        'snapshot\'s date, the definition\'s version, the approver\'s name and date.',
        'Cinco caixas da esquerda para a direita, ligadas por setas: os sistemas de origem; a cópia '
        'noturna; uma foto congelada com data de 31 de dezembro de 2025; o relatório, calculado com a '
        'versão 3 da definição; o arquivo enviado, aprovado por uma pessoa com nome. Embaixo das três '
        'últimas, o que cada uma guarda: a data da foto, a versão da definição, o nome e a data de '
        'quem aprovou.'))
    boxes = [
        (('source systems', 'sistemas de origem'), ('lending, cards', 'crédito, cartões'), None),
        (('nightly copy', 'cópia noturna'), ('changes every day', 'muda todo dia'), None),
        (('frozen snapshot', 'foto congelada'), ('as at 31 Dec 2025', 'posição de 31/12/2025'),
         ('never edited', 'nunca editada')),
        (('the report', 'o relatório'), ('default = 90+ days', 'inadimplência = 90+ dias'),
         ('definition v3', 'definição v3')),
        (('submitted file', 'arquivo enviado'), ('approved by Fernanda', 'aprovado por Fernanda'),
         ('who, when, which file', 'quem, quando, qual arquivo')),
    ]
    w, h, gap, x, y = 124, 70, 25, 18, 60
    for i, (t, d, keep) in enumerate(boxes):
        bx = x + i * (w + gap)
        frozen = i >= 2
        f.rect(bx, y, w, h, fill='--panel', stroke='--phosphor' if frozen else '--wire')
        f.text(bx + w / 2, y + 28, t, size=12, anchor='middle', weight=600)
        f.text(bx + w / 2, y + 50, d, size=10, anchor='middle', fill='--paper-dim')
        if i < len(boxes) - 1:
            f.arrow(bx + w + 2, y + h / 2, bx + w + gap - 2, y + h / 2)
        if keep:
            f.line(bx + w / 2, y + h + 4, bx + w / 2, y + h + 26, stroke='--paper-dim', sw=1)
            f.text(bx + w / 2, y + h + 44, keep, size=11, anchor='middle')
    f.text(18, 30, ('changes', 'muda'), size=11, fill='--paper-dim')
    f.text(18 + 2 * (w + gap), 30, ('fixed from here on', 'fixo daqui em diante'), size=11,
           fill='--paper-dim')
    f.text(360, 225, ('re-run a year later from the snapshot, it gives the same answer',
                      'refeito um ano depois a partir da foto, dá a mesma resposta'),
           size=12, anchor='middle')
    B.place(LESSON, f, (
        'The path from the systems to a submitted report. Everything to the right of the snapshot is '
        'fixed and recorded, which is what lets the same number be produced again when somebody '
        'asks for it.',
        'O caminho dos sistemas até um relatório enviado. Tudo à direita da foto é fixo e '
        'registrado, e é isso que permite produzir o mesmo número de novo quando alguém pedir.'))


def main():
    two_names()
    rerun()
    calendar()
    path()


if __name__ == '__main__':
    main()
