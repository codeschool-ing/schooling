#!/usr/bin/env python3
"""The figures of lesson 10: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, figure, main  # noqa: E402


@figure('l10-discount-rules', 10)
def discount_rules(lang):
    t = {
        'en': dict(
            rule='rule', rows=['student', 'member', '5 or more', 'R5 says', '1.1 gave'],
            yes='yes', no='no', checks=['lesson 9, sanity', 'lesson 10, regression'],
            label='The eight rules of the discount table as columns. Rows say whether the customer is a '
                  'student, a member, and booking five or more, then what R5 says and what 1.1 gave. '
                  'Rules 5 to 8, every rule with a student, are outlined as failures: R5 says 50% and '
                  '1.1 gave 0, 15, 10 and 15. Below, a row of marks shows that the sanity check of '
                  'lesson 9 looked at rules 3 and 4 only, and the regression run of lesson 10 at all '
                  'eight.',
            cap='The discount table on 1.1. The four failing rules are exactly the four with a '
                'student, and the sanity check had looked at two rules with none.'),
        'pt': dict(
            rule='regra', rows=['estudante', 'sócio', '5 ou mais', 'o R5 diz', 'a 1.1 deu'],
            yes='sim', no='não', checks=['aula 9, sanidade', 'aula 10, regressão'],
            label='As oito regras da tabela de desconto como colunas. As linhas dizem se o cliente é '
                  'estudante, sócio, e se reserva cinco ou mais, depois o que o R5 diz e o que a 1.1 '
                  'deu. As regras 5 a 8, toda regra com estudante, estão contornadas como falhas: o R5 '
                  'diz 50% e a 1.1 deu 0, 15, 10 e 15. Embaixo, uma linha de marcas mostra que a '
                  'verificação de sanidade da aula 9 olhou só as regras 3 e 4, e a rodada de regressão '
                  'da aula 10 olhou as oito.',
            cap='A tabela de desconto na 1.1. As quatro regras que falham são exatamente as quatro com '
                'estudante, e a verificação de sanidade tinha olhado duas regras sem estudante nenhum.'),
    }[lang]
    f = Fig('l10-discount-rules', 700, 260, t['label'])
    x0, cw = 178, 64
    rows_y = [60, 86, 112, 142, 168]
    combos = [(s, m, q) for s in (0, 1) for m in (0, 1) for q in (0, 1)]
    says = ['0%', '15%', '10%', '15%', '50%', '50%', '50%', '50%']
    gave = ['0%', '15%', '10%', '15%', '0%', '15%', '10%', '15%']
    f.text(x0 - 14, 32, t['rule'], size=10, anchor='end', fill='--paper-dim')
    for i, (s, m, q) in enumerate(combos):
        x = x0 + i * cw
        bad = says[i] != gave[i]
        f.rect(x + 3, 44, cw - 6, 138, stroke='--amber' if bad else '--wire',
               fill='--scan' if bad else '--panel', rx=3, width=1.6 if bad else 1.2)
        f.text(x + cw / 2, 32, str(i + 1), size=10.5, weight='600', mono=True)
        for k, v in enumerate((s, m, q)):
            f.text(x + cw / 2, rows_y[k], t['yes'] if v else t['no'], size=10,
                   fill='--paper' if v else '--paper-dim')
        f.text(x + cw / 2, rows_y[3], says[i], size=10.5, weight='600', mono=True)
        f.text(x + cw / 2, rows_y[4], gave[i], size=10.5, weight='600', mono=True,
               fill='--amber' if bad else '--phosphor')
        if i in (2, 3):
            f.circle(x + cw / 2, 206, 5, fill='--phosphor')
        f.circle(x + cw / 2, 232, 5, fill='--paper-dim')
    for k, name in enumerate(t['rows']):
        f.text(x0 - 14, rows_y[k], name, size=10, anchor='end', weight='600' if k >= 3 else None)
    f.text(x0 - 14, 206, t['checks'][0], size=10, anchor='end', fill='--phosphor')
    f.text(x0 - 14, 232, t['checks'][1], size=10, anchor='end', fill='--paper-dim')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
