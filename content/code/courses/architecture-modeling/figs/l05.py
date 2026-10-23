"""Lesson 5: architecture decision records."""
from figures import Fig, T, figure


@figure('l05-anatomy', 5)
def anatomy():
    f = Fig('l05-anatomy', 720, 300, T(
        'The five parts of a decision record, stacked as on the page, each with the question it answers '
        'for a reader two years later. Title: what was decided? Status: does this still apply? Context: '
        'what was true, and what pulled each way? Decision: what exactly will be done? Consequences: '
        'what became true because of it, good and bad?',
        'As cinco partes de um registro de decisão, empilhadas como na página, cada uma com a pergunta '
        'que responde para um leitor dois anos depois. Título: o que foi decidido? Status: isto ainda '
        'vale? Contexto: o que era verdade, e o que puxava para cada lado? Decisão: o que exatamente '
        'será feito? Consequências: o que passou a ser verdade por causa dela, de bom e de ruim?'))
    f.rect(30, 16, 300, 270, stroke='--paper-dim', fill='--panel', rx=3, width=1.3)
    parts = [(T('Title', 'Título'), 30, '9. Hold seats in Redis…', T('what was decided?', 'o que foi decidido?')),
             (T('Status', 'Status'), 30, 'Accepted, 2025-05-12', T('does this still apply?', 'isto ainda vale?')),
             (T('Context', 'Contexto'), 72, '- 1,800 holds/min at peak…', T('what was true, what pulled each way?', 'o que era verdade, o que puxava?')),
             (T('Decision', 'Decisão'), 44, 'We will hold each seat…', T('what exactly will be done?', 'o que exatamente será feito?')),
             (T('Consequences', 'Consequências'), 60, '- CPU falls below 60%…', T('what became true, good and bad?', 'o que virou verdade, bom e ruim?'))]
    y = 26
    for name, h, sample, q in parts:
        f.rect(40, y, 280, h, stroke='--wire', fill='--ink', rx=2, width=1)
        f.text(50, y + 12, name, size=9.5, anchor='start', weight='600', fill='--phosphor')
        f.text(50, y + 24, sample, size=8.5, anchor='start', fill='--paper-dim', mono=True)
        f.arrow([(330, y + h / 2), (372, y + h / 2)], stroke='--paper-dim', width=1.1)
        f.text(380, y + h / 2, q, size=10, anchor='start')
        y += h + 6
    return f, T('A record is short because each part answers one question a later reader will have, and nothing else.',
                'Um registro é curto porque cada parte responde a uma pergunta que um leitor futuro vai ter, e a nada mais.')


@figure('l05-lifecycle', 5)
def lifecycle():
    f = Fig('l05-lifecycle', 720, 230, T(
        'The life of a decision record as a state machine. It starts Proposed. Review accepts it, moving '
        'it to Accepted, or rejects it, moving it to Rejected. From Accepted, it can become Deprecated, '
        'when it no longer applies and nothing replaces it, or Superseded, when a newer record replaces '
        'it; the newer record points back with supersedes.',
        'A vida de um registro de decisão como máquina de estados. Começa Proposto. A revisão o aceita, '
        'levando a Aceito, ou o rejeita, levando a Rejeitado. De Aceito, pode virar Obsoleto, quando '
        'deixa de valer e nada o substitui, ou Substituído, quando um registro mais novo toma o seu '
        'lugar; o mais novo aponta de volta com substitui.'))
    f.start(30, 90)
    f.arrow([(37, 90), (78, 90)], stroke='--paper', width=1.3)
    f.state(140, 90, 120, 40, T('Proposed', 'Proposto'))
    f.state(370, 90, 120, 40, T('Accepted', 'Aceito'))
    f.state(370, 190, 120, 40, T('Rejected', 'Rejeitado'))
    f.state(600, 40, 140, 40, T('Deprecated', 'Obsoleto'))
    f.state(600, 140, 140, 40, T('Superseded', 'Substituído'))
    A = dict(stroke='--paper', width=1.3)
    f.arrow([(200, 90), (308, 90)], **A)
    f.text(254, 80, T('accepted in review', 'aceito na revisão'), size=8.5)
    f.arrow([(160, 110), (310, 185)], **A)
    f.text(214, 168, T('rejected', 'rejeitado'), size=8.5, anchor='end')
    f.arrow([(430, 80), (528, 48)], **A)
    f.text(470, 50, T('no longer applies', 'deixa de valer'), size=8.5, anchor='end')
    f.arrow([(430, 100), (528, 134)], **A)
    f.text(478, 136, T('replaced by ADR-N', 'substituído pelo ADR-N'), size=8.5, anchor='end')
    f.text(370, 126, T('text frozen from here', 'texto congelado daqui em diante'), size=8.5, fill='--amber', italic=True)
    return f, T('Only a proposed record changes freely. After that, the one edit a record receives is the change of its own status.',
                'Só um registro proposto muda livremente. Depois disso, a única edição que um registro recebe é a mudança do próprio status.')


@figure('l05-log', 5)
def log():
    f = Fig('l05-log', 720, 220, T(
        'Part of Carcará\'s decision log on a timeline from 2023 to 2025. ADR-0003, the payment company, '
        'accepted in 2023. ADR-0004, holds as rows in the booking database, accepted in 2023 and later '
        'marked superseded. ADR-0009, holds in Redis with a ten-minute expiry, accepted in May 2025, '
        'with an arrow back to ADR-0004 labelled supersedes. ADR-0011, payment confirmations by '
        'webhook. ADR-0014, refund a payment approved after its hold expired, accepted in July 2025.',
        'Parte do log de decisões da Carcará numa linha do tempo de 2023 a 2025. ADR-0003, a empresa de '
        'pagamento, aceito em 2023. ADR-0004, bloqueios como linhas no banco de reservas, aceito em '
        '2023 e depois marcado como substituído. ADR-0009, bloqueios no Redis com expiração de dez '
        'minutos, aceito em maio de 2025, com uma seta de volta ao ADR-0004 rotulada substitui. '
        'ADR-0011, confirmações de pagamento por webhook. ADR-0014, estornar um pagamento aprovado '
        'depois que o bloqueio expirou, aceito em julho de 2025.'))
    f.line(30, 180, 690, 180, stroke='--wire', width=1.5)
    for x, y in [(60, '2023'), (270, '2024'), (480, '2025')]:
        f.line(x, 174, x, 186, stroke='--wire', width=1.5)
        f.text(x, 200, y, size=9.5, fill='--paper-dim', mono=True)
    recs = [(90, 'ADR-0003', T('payment company', 'empresa de pagamento'), '--phosphor', False),
            (190, 'ADR-0004', T('holds in the database', 'bloqueios no banco'), '--paper-dim', True),
            (545, 'ADR-0009', T('holds in Redis', 'bloqueios no Redis'), '--phosphor', False),
            (600, 'ADR-0011', T('webhook confirmations', 'confirmação por webhook'), '--phosphor', False),
            (660, 'ADR-0014', T('refund late payments', 'estorna pago atrasado'), '--phosphor', False)]
    for i, (x, n, what, c, dash) in enumerate(recs):
        y = 120 if i % 2 == 0 else 60
        w = 116 if x < 650 else 100
        f.rect(x - w / 2, y - 22, w, 44, stroke=c, fill='--panel', rx=4, width=1.4, dash='5 3' if dash else None)
        f.text(x, y - 7, n, size=9.5, weight='600', mono=True)
        f.text(x, y + 9, what, size=8.5, fill='--paper-dim')
        f.circle(x, 180, 4, fill=c)
        f.text(x, 166, n[-2:], size=8, fill='--paper-dim', mono=True)
    f.text(190, 92, T('superseded', 'substituído'), size=8.5, fill='--amber', italic=True)
    f.path('M487 120 C380 120, 300 70, 250 66', stroke='--amber', width=1.3, arrow=True)
    f.text(380, 132, T('supersedes', 'substitui'), size=8.5, fill='--amber')
    return f, T('Both records about seat holds stay in the log. Each is true about its own time, and together they explain why the answer changed.',
                'Os dois registros sobre bloqueio de assento ficam no log. Cada um é verdade sobre o seu tempo, e juntos explicam por que a resposta mudou.')
