"""Lesson 21: a dependency report narrowed to decisions, and a DAST alert's two axes."""
from figures import Fig, T, figure


@figure('l21-triage', 21)
def triage():
    f = Fig('l21-triage', 720, 250, T(
        'The pip-audit report on requests 2.31.0, narrowed step by step. Six lines in the report. '
        'Three advisories once the duplicates are removed: PYSEC-2026-1873, PYSEC-2026-1872 and '
        'PYSEC-2026-2275. None of the three reachable from notify.py. One decision that settles all '
        'three: upgrade to 2.33.0.',
        'O relatório do pip-audit sobre o requests 2.31.0, estreitado passo a passo. Seis linhas no '
        'relatório. Três alertas depois de tirar as duplicatas: PYSEC-2026-1873, PYSEC-2026-1872 e '
        'PYSEC-2026-2275. Nenhum dos três alcançável a partir do notify.py. Uma decisão que resolve os '
        'três: atualizar para a 2.33.0.'))
    f.text(360, 20, T('count decisions, not lines', 'conte decisões, não linhas'),
           size=11, weight='600', fill='--paper-dim')
    steps = [
        ('6', T('lines in the report', 'linhas no relatório'), T('each advisory printed twice', 'cada alerta impresso duas vezes')),
        ('3', T('advisories', 'alertas'), T('one per CVE', 'um por CVE')),
        ('0', T('reachable from notify.py', 'alcançáveis pelo notify.py'), T('grep found none of the conditions', 'o grep não achou nenhuma condição')),
        ('1', T('decision', 'decisão'), 'requests==2.33.0'),
    ]
    widths = [400, 340, 290, 240]
    for i, ((n, a, b), w) in enumerate(zip(steps, widths)):
        y = 44 + i * 50
        x = 200 - w / 2 + 160
        last = i == 3
        f.rect(x, y, w, 40, stroke='--phosphor' if last else '--wire', fill='--scan' if last else '--panel',
               width=1.4 if last else 1.1)
        f.text(x + 22, y + 20, n, size=16, weight='600', mono=True, fill='--amber' if last else '--paper')
        f.text(x + 44, y + 13, a, size=10.5, anchor='start', weight='600')
        f.text(x + 44, y + 29, b, size=9.5, anchor='start', fill='--paper-dim', mono=(i == 3))
    return f, T('Six lines became three advisories, none reachable, and one upgrade that closes all of '
                'them.',
                'Seis linhas viraram três alertas, nenhum alcançável, e uma atualização que fecha todos.')


@figure('l21-alert', 21)
def alert():
    f = Fig('l21-alert', 720, 290, T(
        'A grid with a DAST alert\'s risk down the side, High, Medium and Low, and the rule\'s '
        'confidence across the top, Low, Medium and High. In the top right, high risk and high '
        'confidence: confirm it and fix it before release. Along the high-confidence column the '
        'urgency falls with the risk. Along the low-confidence column every cell says confirm by '
        'hand first. Informational alerts sit below the grid: read, not filed.',
        'Uma grade com o risco de um alerta DAST na lateral, alto, médio e baixo, e a confiança da '
        'regra no topo, baixa, média e alta. No canto superior direito, risco alto e confiança alta: '
        'confirme e corrija antes da entrega. Na coluna de confiança alta a urgência cai com o risco. '
        'Na coluna de confiança baixa toda célula diz confirme à mão primeiro. Alertas informativos '
        'ficam abaixo da grade: lidos, não registrados.'))
    f.text(360, 20, T('risk and confidence are read together', 'risco e confiança se leem juntos'),
           size=11, weight='600', fill='--paper-dim')
    cols = [T('Low', 'baixa'), T('Medium', 'média'), T('High', 'alta')]
    rows = [T('High', 'alto'), T('Medium', 'médio'), T('Low', 'baixo')]
    x0, y0, cw, ch = 170, 70, 170, 50
    f.text(x0 + 1.5 * cw, 40, T('confidence', 'confiança'), size=10, weight='600', fill='--paper-dim')
    f.text(70, y0 + 1.5 * ch, T('risk', 'risco'), size=10, weight='600', fill='--paper-dim')
    for j, c in enumerate(cols):
        f.text(x0 + j * cw + cw / 2, 58, c, size=10)
    cells = [
        [T('confirm by hand first', 'confirme à mão primeiro'), T('confirm, then fix', 'confirme, depois corrija'), T('fix before release', 'corrija antes da entrega')],
        [T('confirm by hand first', 'confirme à mão primeiro'), T('confirm, then plan', 'confirme, depois planeje'), T('plan the fix', 'planeje a correção')],
        [T('confirm by hand first', 'confirme à mão primeiro'), T('note it', 'anote'), T('fix when convenient', 'corrija quando der')],
    ]
    for i, r in enumerate(rows):
        f.text(x0 - 12, y0 + i * ch + ch / 2, r, size=10, anchor='end')
        for j in range(3):
            hot = i == 0 and j == 2
            f.rect(x0 + j * cw + 2, y0 + i * ch + 2, cw - 4, ch - 4,
                   stroke='--amber' if hot else '--wire', fill='--scan' if hot else '--panel',
                   width=1.6 if hot else 1)
            f.text(x0 + j * cw + cw / 2, y0 + i * ch + ch / 2, cells[i][j], size=10,
                   fill='--amber' if hot else '--paper')
    f.rect(x0 + 2, y0 + 3 * ch + 14, 3 * cw - 4, 34, stroke='--wire', fill='--ink', width=1, dash='4 3')
    f.text(x0 + 1.5 * cw, y0 + 3 * ch + 31, T('Informational: read, not filed', 'informativo: lido, não registrado'),
           size=10, fill='--paper-dim')
    return f, T('An alert\'s risk says how bad it would be; its confidence says how sure the rule is. '
                'Neither decides alone.',
                'O risco de um alerta diz quão grave seria; a confiança diz quão segura a regra está. '
                'Nenhum dos dois decide sozinho.')
