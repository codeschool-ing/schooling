"""Lesson 12: WCAG's layers, its levels, and contrast as a number."""
import math

from figures import Fig, T, figure


@figure('l12-layers', 12)
def layers():
    f = Fig('l12-layers', 720, 360, T(
        'WCAG 2.2 in three layers. Four principles: perceivable, with 4 guidelines and 29 success '
        'criteria; operable, with 5 guidelines and 34; understandable, with 3 guidelines and 21; '
        'robust, with 1 guideline and 2. Only the success criteria are tested, for example 1.4.3 '
        'Contrast (Minimum), level AA. Below, the levels nest: 31 criteria at A, 24 more at AA for '
        '55 in all, and 31 more at AAA for 86.',
        'A WCAG 2.2 em três camadas. Quatro princípios: perceptível, com 4 diretrizes e 29 critérios '
        'de sucesso; operável, com 5 diretrizes e 34; compreensível, com 3 diretrizes e 21; robusto, '
        'com 1 diretriz e 2. Só os critérios de sucesso são testados, por exemplo 1.4.3 Contraste '
        '(mínimo), nível AA. Embaixo, os níveis se encaixam: 31 critérios no A, mais 24 no AA, 55 ao '
        'todo, e mais 31 no AAA, 86.'))
    heads = [(110, T('principle', 'princípio')), (330, T('guidelines', 'diretrizes')),
             (560, T('success criteria', 'critérios de sucesso'))]
    for x, h in heads:
        f.text(x, 22, h, size=11, weight='600', fill='--paper-dim')
    rows = [
        (T('perceivable', 'perceptível'), '1.1 – 1.4', T('4 guidelines', '4 diretrizes'), '29',
         '1.4.3 · AA'),
        (T('operable', 'operável'), '2.1 – 2.5', T('5 guidelines', '5 diretrizes'), '34', '2.1.1 · A'),
        (T('understandable', 'compreensível'), '3.1 – 3.3', T('3 guidelines', '3 diretrizes'), '21',
         '3.3.1 · A'),
        (T('robust', 'robusto'), '4.1', T('1 guideline', '1 diretriz'), '2', '4.1.2 · A'),
    ]
    for i, (p, nums, g, n, ex) in enumerate(rows):
        y = 52 + i * 46
        f.rect(40, y, 140, 34, stroke='--phosphor', fill='--scan', width=1.4)
        f.text(110, y + 17, p, size=11, weight='600')
        f.arrow([(184, y + 17), (246, y + 17)], stroke='--paper-dim')
        f.rect(250, y, 160, 34, stroke='--wire', fill='--panel')
        f.text(290, y + 17, nums, size=10, mono=True)
        f.text(372, y + 17, g, size=10)
        f.arrow([(414, y + 17), (466, y + 17)], stroke='--paper-dim')
        f.rect(470, y, 180, 34, stroke='--amber', fill='--panel', width=1.4)
        f.text(500, y + 17, n, size=12, weight='600', mono=True)
        f.text(590, y + 17, ex, size=10, mono=True)
    f.text(560, 245, T('only these are tested', 'só estes são testados'), size=10, fill='--amber')
    # the nested levels
    f.rect(40, 266, 640, 80, stroke='--wire', fill='--panel', rx=6)
    f.rect(50, 276, 400, 60, stroke='--paper-dim', fill='--scan', rx=5)
    f.rect(60, 286, 170, 40, stroke='--phosphor', fill='--panel', rx=4, width=1.4)
    f.text(145, 306, T('A · 31 criteria', 'A · 31 critérios'), size=10.5, weight='600')
    f.text(340, 306, T('AA · 24 more, 55 in all', 'AA · mais 24, 55 ao todo'), size=10.5,
           weight='600')
    f.text(565, 306, T('AAA · 31 more, 86', 'AAA · mais 31, 86'), size=10.5, weight='600')
    return f, T('Principles hold guidelines, guidelines hold success criteria, and only a criterion '
                'passes or fails. Conforming at AA means meeting every criterion in the two inner '
                'boxes.',
                'Princípios contêm diretrizes, diretrizes contêm critérios de sucesso, e só um critério '
                'passa ou reprova. Estar conforme no AA é atender a todo critério das duas caixas de '
                'dentro.')


@figure('l12-contrast', 12)
def contrast():
    f = Fig('l12-contrast', 720, 250, T(
        'A contrast scale from 1:1 to 21:1, drawn on a logarithmic axis, with three thresholds: 3:1 '
        'for large text and for the parts of controls, 4.5:1 for text at AA, 7:1 for text at AAA. '
        'The colours of the booking page sit on it: the grey note #999999 at 2.85, below every line; '
        '#777777 at 4.48, just under AA; #767676 at 4.54, just over it; the red border at 5.15; white '
        'on the dark red button at 10.20; the body text at 15.91.',
        'Uma escala de contraste de 1:1 a 21:1, num eixo logarítmico, com três limites: 3:1 para '
        'texto grande e partes de controles, 4.5:1 para texto no AA, 7:1 para texto no AAA. As cores '
        'da página de reserva estão nela: a nota cinza #999999 em 2.85, abaixo de todas as linhas; '
        '#777777 em 4.48, logo abaixo do AA; #767676 em 4.54, logo acima; a borda vermelha em 5.15; '
        'o branco no botão vermelho-escuro em 10.20; o texto do corpo em 15.91.'))
    x0, x1, y = 50, 680, 150

    def X(r):
        return x0 + (x1 - x0) * math.log(r) / math.log(21)

    f.line(x0, y, x1, y, stroke='--paper-dim', width=1.4)
    for r in (1, 2, 3, 4.5, 7, 10, 21):
        f.line(X(r), y - 4, X(r), y + 4, stroke='--paper-dim')
        f.text(X(r), y + 16, f'{r}:1', size=9.5, mono=True, fill='--paper-dim')
    for r, label, fill in ((3, T('AA large · non-text', 'AA grande · não texto'), '--paper'),
                           (4.5, T('AA text', 'AA texto'), '--amber'),
                           (7, T('AAA text', 'AAA texto'), '--paper')):
        f.line(X(r), 40, X(r), y, stroke=fill if fill == '--amber' else '--wire', width=1.4,
               dash='4 3')
        f.text(X(r), 30, label, size=10, fill=fill, weight='600' if fill == '--amber' else None)
    marks = [(2.85, '#999', 70), (4.48, '#777', 96), (4.54, '#767676', 122), (5.15, T('red border', 'borda vermelha'), 70),
             (10.20, T('Book button', 'botão Book'), 96), (15.91, T('body text', 'texto'), 70)]
    for r, label, ly in marks:
        f.circle(X(r), y, 5, fill='--phosphor' if r >= 4.5 else '--amber')
        f.line(X(r), y - 6, X(r), ly + 8, stroke='--paper-dim', width=0.8)
        mono = label.startswith('#')
        f.text(X(r) + (0 if r != 4.48 else -4), ly, label, size=10, mono=mono,
               anchor='middle' if r not in (4.48, 4.54) else ('end' if r == 4.48 else 'start'))
    f.text(360, 215, T('2.85 fails at every level; one step of grey separates 4.48 from 4.54',
                       '2.85 reprova em todo nível; um passo de cinza separa 4.48 de 4.54'),
           size=10.5, fill='--amber')
    return f, T('The booking page\'s colours on the contrast scale. Only the grey note falls under the '
                'lines that matter for it.',
                'As cores da página de reserva na escala de contraste. Só a nota cinza fica abaixo das '
                'linhas que valem para ela.')
