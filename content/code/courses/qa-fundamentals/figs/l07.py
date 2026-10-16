# lesson 7

@figure('l07-paths', 7)
def l07_paths(lang):
    t = {
        'en': dict(rows=['adult', 'child', 'over sixty'], cols=['matinée', 'evening', 'Wed matinée', 'Wed evening'],
                   cov='taken', empty='never taken', stack='reduction and Wednesday: never taken',
                   label='A grid of customers against sessions. Rows: adult, child, over sixty. Columns: matinée, evening, '
                         'Wednesday matinée, Wednesday evening. The seven cases take five of these cells: adult at a '
                         'matinée, adult in the evening, child in the evening, over sixty in the evening, adult on a '
                         'Wednesday evening. The four cells combining a child or someone over sixty with a Wednesday are '
                         'outlined as never taken.',
                   cap='Students are left out to fit; the student case sits in the evening column, and no student on '
                       'a Wednesday was ever run either. The outlined cells are where the stacking defect lives.'),
        'pt': dict(rows=['adulto', 'criança', 'mais de sessenta'], cols=['matinê', 'noite', 'matinê de quarta', 'noite de quarta'],
                   cov='percorrido', empty='nunca percorrido', stack='desconto e quarta: nunca percorrido',
                   label='Uma grade de clientes contra sessões. Linhas: adulto, criança, mais de sessenta. Colunas: matinê, '
                         'noite, matinê de quarta, noite de quarta. Os sete casos percorrem cinco dessas células: adulto na '
                         'matinê, adulto à noite, criança à noite, mais de sessenta à noite, adulto numa noite de quarta. As '
                         'quatro células que combinam uma criança ou alguém com mais de sessenta com uma quarta estão '
                         'destacadas como nunca percorridas.',
                   cap='Os estudantes ficaram de fora para caber; o caso do estudante fica na coluna da noite, e nenhum '
                       'estudante numa quarta foi rodado também. As células destacadas são onde mora o defeito da soma de '
                       'descontos.'),
    }[lang]
    rows = t['rows'][:3]
    covered = {(0, 0), (0, 1), (1, 1), (2, 1), (0, 3)}
    f = Fig('l07-paths', 640, 230, t['label'])
    x0, cw, y0, rh = 160, 112, 44, 44
    for j, c in enumerate(t['cols']):
        f.text(x0 + j * cw + cw / 2, 28, c, size=10, weight='600')
    for i, r in enumerate(rows):
        y = y0 + i * rh
        f.text(x0 - 10, y + rh / 2, r, size=10, anchor='end', weight='600')
        for j in range(4):
            x = x0 + j * cw
            stack = i > 0 and j >= 2
            on = (i, j) in covered
            f.rect(x + 3, y + 3, cw - 6, rh - 6, stroke='--amber' if stack else ('--phosphor' if on else '--wire'),
                   fill='--panel', width=1.8 if stack else 1.1, dash=None if (on or stack) else '3 3')
            f.text(x + cw / 2, y + rh / 2, t['cov'] if on else t['empty'], size=9.5,
                   fill='--amber' if stack else ('--phosphor' if on else '--paper-dim'))
    f.text(x0 + 3 * cw, y0 + 3 * rh + 22, t['stack'], size=9.5, anchor='end', fill='--amber', weight='600')
    return f, t['cap']
