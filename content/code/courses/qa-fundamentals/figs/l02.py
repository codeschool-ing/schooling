# lesson 2

@figure('l02-chain', 2)
def l02_chain(lang):
    t = {
        'en': dict(boxes=[['process', 'how it is made'], ['the code', 'internal quality'],
                          ['the running product', 'external quality'], ['in somebody’s hands', 'quality in use']],
                   fwd='influences', back='depends on',
                   ex=['review before merge', '`age > 60`', 'R$ 36,00 for sixty', 'a pensioner overcharged'],
                   label='Four boxes in a row: process, how it is made; the code, internal quality; the running product, '
                         'external quality; in somebody’s hands, quality in use. Arrows above run left to right, '
                         'labelled influences; arrows below run right to left, labelled depends on. Under each box is the '
                         'Cine Aurora example: review before merge, the line age greater than 60, R$ 36,00 for a '
                         'sixty-year-old, a pensioner overcharged.',
                   cap='The chain the standards draw. Each link makes the next more likely to be good and guarantees '
                       'nothing: the review was done, and the pensioner was still overcharged.'),
        'pt': dict(boxes=[['processo', 'como é feito'], ['o código', 'qualidade interna'],
                          ['o produto rodando', 'qualidade externa'], ['na mão de alguém', 'qualidade em uso']],
                   fwd='influencia', back='depende de',
                   ex=['revisão antes do merge', '`age > 60`', 'R$ 36,00 para sessenta', 'um aposentado cobrado a mais'],
                   label='Quatro caixas em fila: processo, como é feito; o código, qualidade interna; o produto rodando, '
                         'qualidade externa; na mão de alguém, qualidade em uso. Setas em cima vão da esquerda para a '
                         'direita, com o rótulo influencia; setas embaixo vão da direita para a esquerda, com o rótulo '
                         'depende de. Sob cada caixa está o exemplo do Cine Aurora: revisão antes do merge, a linha age '
                         'maior que 60, R$ 36,00 para quem tem sessenta, um aposentado cobrado a mais.',
                   cap='A cadeia que as normas desenham. Cada elo torna o seguinte mais provável de ser bom e não garante '
                       'nada: a revisão foi feita, e o aposentado foi cobrado a mais mesmo assim.'),
    }[lang]
    f = Fig('l02-chain', 680, 200, t['label'])
    w, h, gap, y = 140, 56, 32, 60
    for i, (a, b) in enumerate(t['boxes']):
        x = 14 + i * (w + gap)
        box(f, x, y, w, h, [a, b], stroke='--phosphor' if i == 0 else '--wire', size=10.5,
            weights=['600', None], fills=['--paper', '--paper-dim'])
        ex = t['ex'][i]
        mono = ex.startswith('`')
        f.text(x + w / 2, y + h + 50, ex.strip('`'), size=9.5, fill='--amber', mono=mono)
        f.line(x + w / 2, y + h, x + w / 2, y + h + 38, stroke='--wire', width=1, dash='2 3')
        if i:
            px = x - gap
            arrow(f, px + 3, y + 16, x - 3, y + 16, stroke='--phosphor')
            arrow(f, x - 3, y + h - 12, px + 3, y + h - 12, stroke='--paper-dim')
    f.text(14 + w + gap / 2, y - 14, t['fwd'], size=9.5, fill='--phosphor')
    f.text(14 + w + gap / 2, y + h + 14, t['back'], size=9.5, fill='--paper-dim')
    return f, t['cap']
