#!/usr/bin/env python3
"""The figures of lesson 19: python3 figures.py redraws them in both languages."""
import csv
import os
import re
import sys
sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..'))
from figlib import Fig, figure, main  # noqa: E402


def runs():
    """The two run columns of lesson 18's cases.csv, read from the lesson itself."""
    text = open(os.path.join(HERE, '..', 'le-1t81t6vm', 'a-spreadsheet-first.md'), encoding='utf-8').read()
    body = re.search(r'Save it as `cases\.csv`[^`]*?:\n+```\n(.*?)^```$', text, re.S | re.M).group(1)
    rows = list(csv.DictReader(body.splitlines()))
    def state(cell):
        return 'pass' if cell == 'passed' else 'fail' if cell.startswith('failed') else 'none'
    return [(r['id'], state(r['1.0']), state(r['1.1'])) for r in rows]


@figure('l19-two-runs', 19)
def two_runs(lang):
    rows = runs()
    n10 = sum(a != 'none' for _, a, _ in rows)
    p10 = sum(a == 'pass' for _, a, _ in rows)
    n11 = sum(b != 'none' for _, _, b in rows)
    p11 = sum(b == 'pass' for _, _, b in rows)
    r10, r11 = round(100 * p10 / n10), round(100 * p11 / n11)
    t = {
        'en': dict(fixed='fixed', broken='broken', new='new case',
                   sums=[f'{p10} passed of {n10} run: {r10}%', f'{p11} passed of {n11} run: {r11}%'],
                   legend=['passed', 'failed', 'not run'],
                   label=f'Two rows of seventeen cells, one per case, for the runs on 1.0 and 1.1. On 1.0, '
                         f'{p10} of the {n10} cases that ran passed, {r10}%, and three were not run. On 1.1, '
                         f'{p11} of {n11} passed, {r11}%. Under the cells: TC-05 and TC-09 are marked fixed, '
                         f'TC-10 broken, and TC-14, TC-15 and TC-17 new cases, which fail on 1.1.',
                   cap='The pass rate fell from 1.0 to 1.1 while 1.1 fixed two defects and broke one. The '
                       'three new cases, each written to check a defect already found, are what pulled it '
                       'down.'),
        'pt': dict(fixed='corrigido', broken='quebrado', new='caso novo',
                   sums=[f'{p10} aprovados de {n10} executados: {r10}%',
                         f'{p11} aprovados de {n11} executados: {r11}%'],
                   legend=['passou', 'falhou', 'não executado'],
                   label=f'Duas fileiras de dezessete células, uma por caso, para as execuções na 1.0 e na '
                         f'1.1. Na 1.0, {p10} dos {n10} casos que rodaram passaram, {r10}%, e três não foram '
                         f'executados. Na 1.1, {p11} de {n11} passaram, {r11}%. Embaixo das células: TC-05 e '
                         f'TC-09 marcados como corrigidos, TC-10 como quebrado, e TC-14, TC-15 e TC-17 como '
                         f'casos novos, que falham na 1.1.',
                   cap='A taxa de aprovação caiu da 1.0 para a 1.1 enquanto a 1.1 corrigia dois defeitos e '
                       'quebrava um. Os três casos novos, cada um escrito para conferir um defeito já '
                       'achado, são o que a puxou para baixo.'),
    }[lang]
    f = Fig('l19-two-runs', 720, 236, t['label'])
    x0, cw, gap = 60, 30, 4
    style = {'pass': ('--phosphor', '--scan', None), 'fail': ('--amber', '--panel', None),
             'none': ('--wire', '--panel', '3 3')}
    for i, (cid, a, b) in enumerate(rows):
        x = x0 + i * (cw + gap)
        f.text(x + cw / 2, 18, cid[3:], size=9, mono=True, fill='--paper-dim')
        for y, s in ((30, a), (64, b)):
            stroke, fill, dash = style[s]
            f.rect(x, y, cw, 26, stroke=stroke, fill=fill, rx=3, dash=dash, width=1.6)
            if s == 'fail':
                f.line(x + 8, y + 8, x + cw - 8, y + 18, stroke='--amber', width=1.6)
                f.line(x + cw - 8, y + 8, x + 8, y + 18, stroke='--amber', width=1.6)
    f.text(x0 - 12, 43, '1.0', size=10.5, anchor='end', mono=True, weight='600')
    f.text(x0 - 12, 77, '1.1', size=10.5, anchor='end', mono=True, weight='600')
    marks = {'TC-05': ('fixed', 0), 'TC-09': ('fixed', 0), 'TC-10': ('broken', 1),
             'TC-14': ('new', 0), 'TC-15': ('new', 1), 'TC-17': ('new', 0)}
    for i, (cid, _, _) in enumerate(rows):
        if cid not in marks:
            continue
        key, level = marks[cid]
        cx = x0 + i * (cw + gap) + cw / 2
        y = 108 + level * 16
        f.line(cx, 94, cx, y - 7, stroke='--paper-dim', width=1)
        f.text(cx, y, t[key], size=9, fill='--amber' if key == 'broken' else '--paper')
    f.text(x0, 158, t['sums'][0], size=10.5, anchor='start')
    f.text(x0, 178, t['sums'][1], size=10.5, anchor='start', weight='600')
    f.text(x0 - 12, 158, '1.0', size=10, anchor='end', mono=True, fill='--paper-dim')
    f.text(x0 - 12, 178, '1.1', size=10, anchor='end', mono=True, fill='--paper-dim')
    lx = x0
    for k, (s, word) in enumerate(zip(('pass', 'fail', 'none'), t['legend'])):
        stroke, fill, dash = style[s]
        f.rect(lx, 206, 18, 14, stroke=stroke, fill=fill, rx=2, dash=dash, width=1.4)
        if s == 'fail':
            f.line(lx + 5, 209, lx + 13, 217, stroke='--amber', width=1.4)
            f.line(lx + 13, 209, lx + 5, 217, stroke='--amber', width=1.4)
        f.text(lx + 26, 213, word, size=10, anchor='start', fill='--paper-dim')
        lx += 130
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
