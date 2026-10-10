#!/usr/bin/env python3
"""The figures of lesson 4: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, box, figure, main  # noqa: E402


@figure('l04-partitions', 4)
def partitions(lang):
    t = {
        'en': dict(
            rows=[('name length', 'R2', ['empty', '1 to 40', '41 or more']),
                  ('password length', 'R2', ['0 to 7', '8 to 64', '65 or more']),
                  ('tickets per order', 'R4', ['0 or fewer', '1 to 6', '7 or more'])],
            ok='accepted', no='refused', nan=['not a whole number', 'refused, with a sentence'],
            label='Three bars, one per field, each split into three partitions. Name length: empty, '
                  'refused; 1 to 40, accepted; 41 or more, refused. Password length: 0 to 7, refused; '
                  '8 to 64, accepted; 65 or more, refused. Tickets per order: 0 or fewer, refused; 1 to '
                  '6, accepted; 7 or more, refused; and beside that bar a dashed fourth partition, not a '
                  'whole number, refused with a sentence.',
            cap='The partitions of R2 and R4, as the requirements draw them. Each bar has one valid '
                'partition between two invalid ones, and the quantity has a fourth that is not on the '
                'number line at all. The widths are not to scale.'),
        'pt': dict(
            rows=[('tamanho do nome', 'R2', ['vazio', '1 a 40', '41 ou mais']),
                  ('tamanho da senha', 'R2', ['0 a 7', '8 a 64', '65 ou mais']),
                  ('ingressos por pedido', 'R4', ['0 ou menos', '1 a 6', '7 ou mais'])],
            ok='aceito', no='recusado', nan=['não é número inteiro', 'recusado, com uma frase'],
            label='Três barras, uma por campo, cada uma dividida em três partições. Tamanho do nome: '
                  'vazio, recusado; 1 a 40, aceito; 41 ou mais, recusado. Tamanho da senha: 0 a 7, '
                  'recusado; 8 a 64, aceito; 65 ou mais, recusado. Ingressos por pedido: 0 ou menos, '
                  'recusado; 1 a 6, aceito; 7 ou mais, recusado; e ao lado dessa barra uma quarta '
                  'partição tracejada, não é número inteiro, recusada com uma frase.',
            cap='As partições do R2 e do R4, como os requisitos as desenham. Cada barra tem uma partição '
                'válida entre duas inválidas, e a quantidade tem uma quarta que nem está na reta dos '
                'números. As larguras não estão em escala.'),
    }[lang]
    f = Fig('l04-partitions', 720, 230, t['label'])
    x0, widths = 160, [104, 190, 104]
    for r, (name, req, parts) in enumerate(t['rows']):
        y = 22 + r * 70
        f.text(20, y + 15, name, size=11, anchor='start', weight='600')
        f.text(20, y + 32, req, size=10, anchor='start', fill='--paper-dim', mono=True)
        x = x0
        for k, (part, w) in enumerate(zip(parts, widths)):
            valid = k == 1
            box(f, x, y, w - 4, 48, [part, t['ok'] if valid else t['no']],
                stroke='--phosphor' if valid else '--amber', fill='--scan' if valid else '--panel',
                fills=['--paper', '--phosphor' if valid else '--amber'], weights=['600', None], size=10.5)
            x += w
        if r == 2:
            box(f, x + 12, y, 150, 48, t["nan"], stroke='--amber', fill='--panel', dash='5 3',
                fills=['--paper', '--amber'], weights=['600', None], size=10.5)
    return f, t['cap']


@figure('l04-boundary', 4)
def boundary(lang):
    t = {
        'en': dict(
            parts=['empty', '1 to 40 characters', '41 or more'], line='boundary',
            axis='characters in the name',
            two='two-value: 0, 1, 40 and 41', three='three-value adds 2 and 39',
            label='A number line of name lengths: 0, 1 and 2, a break, then 39, 40 and 41. Shaded '
                  'behind it, the partitions empty, 1 to 40 characters, and 41 or more. Dashed lines '
                  'mark the two boundaries, between 0 and 1 and between 40 and 41. The values 0, 1, '
                  '40 and 41 are filled circles, the two-value boundary values; 2 and 39 are hollow '
                  'circles, the values three-value analysis adds.',
            cap='The boundaries of R2\'s name length. Two-value analysis tests the four filled values, '
                'one on each side of each line; three-value analysis adds the hollow ones, the next '
                'value inside.'),
        'pt': dict(
            parts=['vazio', '1 a 40 caracteres', '41 ou mais'], line='fronteira',
            axis='caracteres no nome',
            two='dois valores: 0, 1, 40 e 41', three='três valores: mais 2 e 39',
            label='Uma reta de tamanhos de nome: 0, 1 e 2, uma quebra, depois 39, 40 e 41. Ao fundo, as '
                  'partições vazio, 1 a 40 caracteres e 41 ou mais. Linhas tracejadas marcam as duas '
                  'fronteiras, entre 0 e 1 e entre 40 e 41. Os valores 0, 1, 40 e 41 são círculos '
                  'cheios, os valores de fronteira da análise de dois valores; 2 e 39 são círculos '
                  'vazados, os que a análise de três valores acrescenta.',
            cap='As fronteiras do tamanho do nome no R2. A análise de dois valores testa os quatro '
                'valores cheios, um de cada lado de cada linha; a de três valores acrescenta os vazados, '
                'o valor seguinte do lado de dentro.'),
    }[lang]
    f = Fig('l04-boundary', 660, 250, t['label'])
    xs = {0: 150, 1: 210, 2: 270, 39: 390, 40: 450, 41: 510}
    ay = 130
    # the partitions, behind the line
    bands = [(110, 180, t['parts'][0], False), (180, 480, t['parts'][1], True),
             (480, 560, t['parts'][2], False)]
    for a, b, name, valid in bands:
        f.rect(a + 2, 52, b - a - 4, 110, stroke='--phosphor' if valid else '--amber',
               fill='--scan' if valid else '--panel', rx=3)
        f.text((a + b) / 2, 68, name, size=10.5, weight='600',
               fill='--phosphor' if valid else '--amber')
    # the line stops at each band's edge, so the boundary is a gap in it
    for a, b in ((118, 172), (188, 320), (340, 472), (488, 552)):
        f.line(a, ay, b, ay, stroke='--paper-dim', width=1.2)
    f.text(330, ay, '…', size=12, fill='--paper-dim')
    for b in (180, 480):
        f.line(b, 34, b, 176, stroke='--amber', width=1.6, dash='4 3')
        f.text(b, 26, t['line'], size=10, fill='--amber')
    for v, x in xs.items():
        filled = v in (0, 1, 40, 41)
        f.circle(x, ay, 7, fill='--phosphor' if filled else '--panel', stroke='--phosphor', width=1.6)
        f.text(x, ay + 22, str(v), size=10.5, mono=True)
    f.text(330, 190, t['axis'], size=10, fill='--paper-dim')
    f.circle(130, 222, 6, fill='--phosphor', stroke='--phosphor', width=1.6)
    f.text(144, 222, t['two'], size=10.5, anchor='start')
    f.circle(390, 222, 6, fill='--panel', stroke='--phosphor', width=1.6)
    f.text(404, 222, t['three'], size=10.5, anchor='start')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
