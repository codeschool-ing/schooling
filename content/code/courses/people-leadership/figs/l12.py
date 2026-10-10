"""Lesson 12: the shape of a promotion case."""
from figures import Fig, T, figure


@figure('l12-case', 12)
def case():
    f = Fig('l12-case', 720, 320, T(
        'A promotion case drawn as a document with four parts. At the top, the summary: the level '
        'and why, in two or three sentences. Then one section per row of the ladder, scope, autonomy, '
        'influence and craft, each made of a claim and the evidence for it, with dates and links. '
        'Then the gaps, said plainly. Then statements from people outside the team. Beside it, a '
        'note says the summary is what most panel members read, and the gaps section is what makes '
        'the rest believable.',
        'Um caso de promoção desenhado como documento de quatro partes. No topo, o resumo: o nível e '
        'o porquê, em duas ou três frases. Depois uma seção por linha da escada, escopo, autonomia, '
        'influência e ofício, cada uma feita de uma afirmação e das evidências, com datas e links. '
        'Depois as lacunas, ditas com clareza. Depois depoimentos de pessoas de fora do time. Ao '
        'lado, uma nota diz que o resumo é o que a maioria do comitê lê, e que a seção de lacunas é '
        'o que torna o resto crível.'))
    x, w = 40, 360
    f.rect(x, 20, w, 280, stroke='--paper-dim', fill='--panel', rx=6)
    f.rect(x + 16, 34, w - 32, 40, stroke='--phosphor', fill='--panel', rx=4)
    f.text(x + 30, 54, T('summary: the level, and why', 'resumo: o nível, e o porquê'), size=11.5,
           anchor='start', weight='600')
    rows = [T('scope', 'escopo'), T('autonomy', 'autonomia'), T('influence', 'influência'),
            T('craft', 'ofício')]
    for i, r in enumerate(rows):
        y = 86 + i * 36
        f.rect(x + 16, y, w - 32, 30, stroke='--wire', fill='--panel', rx=4)
        f.text(x + 30, y + 15, r, size=11, anchor='start', weight='600')
        f.text(x + 130, y + 15, T('claim, then evidence', 'afirmação, depois evidência'), size=10.5,
               anchor='start', fill='--paper-dim')
    f.rect(x + 16, 236, w - 32, 26, stroke='--amber', fill='--panel', rx=4)
    f.text(x + 30, 249, T('the gaps, said plainly', 'as lacunas, ditas com clareza'), size=11,
           anchor='start', weight='600')
    f.rect(x + 16, 268, w - 32, 24, stroke='--wire', fill='--panel', rx=4)
    f.text(x + 30, 280, T('statements from outside the team', 'depoimentos de fora do time'), size=11,
           anchor='start')
    f.arrow([(460, 54), (390, 54)], stroke='--paper-dim')
    f.lines(470, 54, [T('what most panel', 'o que a maior parte'),
                      T('members read', 'do comitê lê')], size=11, anchor='start')
    f.arrow([(460, 249), (390, 249)], stroke='--paper-dim')
    f.lines(470, 249, [T('what makes the rest', 'o que torna o'),
                       T('believable', 'resto crível')], size=11, anchor='start')
    f.arrow([(460, 155), (390, 155)], stroke='--paper-dim')
    f.lines(470, 155, [T('one claim per row,', 'uma afirmação por linha,'),
                       T('dated and checkable', 'datada e conferível')], size=11, anchor='start')
    return f, T('A case is read by strangers. Each part is there for a reader who never met the person.',
                'Um caso é lido por estranhos. Cada parte está lá para um leitor que nunca conheceu a pessoa.')
