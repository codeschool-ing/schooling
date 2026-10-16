# lesson 19

@figure('l19-oracle', 19)
def l19_oracle(lang):
    t = {
        'en': dict(inp=['input', '60, thu 20:00'], prog=['the program'], res=['result', 'R$ 36,00'],
                   orc=['oracle', 'the rule, the counter,', 'the law, an example'], cmp='compare',
                   verdict=['verdict', 'wrong, according to', 'the statute: R$ 18,00'],
                   label='A test drawn as a flow. An input, age 60 at a Thursday 20:00 session, goes into the program, '
                         'which gives a result, R$ 36,00. Separately, an oracle, the rule, the counter, the law or an '
                         'example, says what the result should be. The two are compared, and the verdict is: wrong, '
                         'according to the statute, which says R$ 18,00.',
                   cap='Running the program gives a result. Only the oracle turns it into a verdict, and the verdict '
                       'names it.'),
        'pt': dict(inp=['entrada', '60, qui 20:00'], prog=['o programa'], res=['resultado', 'R$ 36,00'],
                   orc=['oráculo', 'a regra, a bilheteria,', 'a lei, um exemplo'], cmp='comparar',
                   verdict=['veredito', 'errado, segundo', 'o estatuto: R$ 18,00'],
                   label='Um teste desenhado como fluxo. Uma entrada, 60 anos numa sessão de quinta às 20:00, entra no '
                         'programa, que dá um resultado, R$ 36,00. Separadamente, um oráculo, a regra, a bilheteria, a '
                         'lei ou um exemplo, diz qual deveria ser o resultado. Os dois são comparados, e o veredito é: '
                         'errado, segundo o estatuto, que diz R$ 18,00.',
                   cap='Rodar o programa dá um resultado. Só o oráculo o transforma num veredito, e o veredito o '
                       'nomeia.'),
    }[lang]
    f = Fig('l19-oracle', 640, 220, t['label'])
    box(f, 10, 20, 120, 50, t['inp'], size=9.5, weights=['600', None])
    arrow(f, 131, 45, 169, 45)
    box(f, 170, 20, 130, 50, t['prog'], size=10, weights=['600'], fill='--ink')
    arrow(f, 301, 45, 339, 45)
    box(f, 340, 20, 120, 50, t['res'], size=9.5, weights=['600', None])
    box(f, 340, 140, 120, 66, t['orc'], size=9, weights=['600', None, None], stroke='--phosphor',
        fills=['--phosphor', '--paper', '--paper'])
    f.path('M461 45 C 500 45, 500 85, 520 95', stroke='--paper-dim', width=1.4, arrow=True)
    f.path('M461 173 C 500 173, 500 135, 520 125', stroke='--paper-dim', width=1.4, arrow=True)
    f.text(495, 110, t['cmp'], size=9, anchor='end', fill='--paper-dim')
    box(f, 522, 78, 110, 64, t['verdict'], size=9, weights=['600', None, None], stroke='--amber',
        fills=['--amber', '--paper', '--paper'])
    return f, t['cap']
