#!/usr/bin/env python3
"""The figures of lesson 14: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, Plot, figure, main  # noqa: E402


@figure('l14-load-curve', 14)
def load_curve(lang):
    t = {
        'en': dict(
            x='people using it at once', y='response time',
            peak='expected peak', bend='the bend', fail='requests fail',
            load='load test: still flat at the peak?',
            stress='stress test: where does it bend, and how does it fail?',
            label='A line graph with people using it at once along the bottom and response time up '
                  'the side, with no numbers on either axis. The line runs almost flat, bends, then '
                  'climbs steeply, and past the climb crosses mark requests that fail. A dashed '
                  'vertical line marks the expected peak on the flat part. A bracket over the flat '
                  'part up to the peak is labelled load test: still flat at the peak? A '
                  'bracket over the bend and the climb is labelled stress test: where does it bend, '
                  'and how does it fail?',
            cap='The typical shape of response time against load, not a measurement of boxoffice. '
                'A load test checks the expected peak; a stress test goes looking for the bend.'),
        'pt': dict(
            x='pessoas usando ao mesmo tempo', y='tempo de resposta',
            peak='pico esperado', bend='a curva', fail='requisições falham',
            load='teste de carga: ainda plano no pico?',
            stress='teste de estresse: onde dobra, e como falha?',
            label='Um gráfico de linha com pessoas usando ao mesmo tempo na base e tempo de resposta '
                  'na lateral, sem números em nenhum eixo. A linha corre quase plana, dobra e depois '
                  'sobe forte, e depois da subida cruzes marcam requisições que falham. Uma linha '
                  'vertical tracejada marca o pico esperado na parte plana. Uma chave sobre a parte '
                  'plana até o pico diz teste de carga: ainda plano no pico? Uma chave '
                  'sobre a curva e a subida diz teste de estresse: onde dobra, e como falha?',
            cap='A forma típica do tempo de resposta contra a carga, não uma medição do boxoffice. O '
                'teste de carga confere o pico esperado; o teste de estresse vai atrás da curva.'),
    }[lang]
    f = Fig('l14-load-curve', 680, 330, t['label'])
    p = Plot(f, 70, 80, 640, 280, 0, 100, 0, 100)
    f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1.2)
    f.line(p.x0, p.y0 - 10, p.x0, p.y1, stroke='--paper-dim', width=1.2)
    f.text((p.x0 + p.x1) / 2, p.y1 + 20, t['x'], size=10.5, weight='600')
    f.text(p.x0, p.y0 - 22, t['y'], size=10.5, anchor='start', weight='600')

    def rt(x):
        return 8 + 0.04 * x + 120 * max(0.0, (x - 58) / 30) ** 2.4

    p.curve(rt, 0, 82, stroke='--phosphor', width=2.2)
    for x in (85, 90, 95):
        cx, cy = p.sx(x), p.sy(min(96, rt(82) + (x - 82) * 1.2))
        f.line(cx - 5, cy - 5, cx + 5, cy + 5, stroke='--amber', width=2)
        f.line(cx - 5, cy + 5, cx + 5, cy - 5, stroke='--amber', width=2)
    f.text(p.sx(90), p.sy(96) - 16, t['fail'], size=10, fill='--amber')
    p.vline(40, stroke='--paper-dim', dash='4 3', top=p.y0 + 70)
    f.text(p.sx(40), p.y0 + 58, t['peak'], size=10, fill='--paper-dim')
    f.text(p.sx(66) + 8, p.sy(rt(66)) + 2, t['bend'], size=10, anchor='start', fill='--paper-dim')

    def bracket(a, b, y, colour, text, anchor='middle', tx=None):
        x1, x2 = p.sx(a), p.sx(b)
        f.path(f'M{x1:.1f} {y + 8:.1f} L{x1:.1f} {y:.1f} L{x2:.1f} {y:.1f} L{x2:.1f} {y + 8:.1f}',
               stroke=colour, width=1.5)
        f.text(tx if tx is not None else (x1 + x2) / 2, y - 11, text, size=10, anchor=anchor,
               fill=colour)

    bracket(0, 40, 225, '--phosphor', t['load'], anchor='start', tx=p.sx(0))
    bracket(55, 82, 42, '--amber', t['stress'], anchor='end', tx=p.sx(82))
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
