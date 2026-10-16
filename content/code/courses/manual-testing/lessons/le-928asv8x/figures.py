#!/usr/bin/env python3
"""The figures of lesson 21: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, figure, main  # noqa: E402


@figure('l21-two-clocks', 21)
def two_clocks(lang):
    t = {
        'en': dict(
            rows=['machine set to São Paulo', 'machine set to UTC'],
            now='the same instant: 17:30 in São Paulo',
            cut='closes 19:00', reads='reads 17:30', reads2='reads 20:30',
            open='open', closed='closed',
            label='Two clock lines, one above the other, lined up so that the same instant sits at the '
                  'same place. The upper line is a machine set to São Paulo time, running from 14:00 to '
                  '22:00. The lower line is a machine set to UTC, whose labels run three hours ahead, '
                  'from 17:00 to 01:00. A vertical line marks one instant, 17:30 in São Paulo, which the '
                  'upper machine reads as 17:30 and the lower as 20:30. Each line has the booking cut-off '
                  'at 19:00 on its own clock: on the upper line that is to the right of the instant, so '
                  'booking is open; on the lower line it falls at 16:00 São Paulo time, to the left of '
                  'the instant, so booking is closed.',
            cap='One instant on two machines. Each closes booking at 19:00 by its own clock, and the UTC '
                'machine reaches 19:00 three hours sooner.'),
        'pt': dict(
            rows=['máquina no horário de São Paulo', 'máquina em UTC'],
            now='o mesmo instante: 17:30 em São Paulo',
            cut='fecha 19:00', reads='marca 17:30', reads2='marca 20:30',
            open='aberta', closed='fechada',
            label='Duas linhas de relógio, uma sobre a outra, alinhadas para que o mesmo instante fique no '
                  'mesmo lugar. A de cima é uma máquina no horário de São Paulo, de 14:00 a 22:00. A de '
                  'baixo é uma máquina em UTC, cujos rótulos vão três horas à frente, de 17:00 a 01:00. Uma '
                  'linha vertical marca um instante, 17:30 em São Paulo, que a máquina de cima lê como 17:30 '
                  'e a de baixo como 20:30. Cada linha tem o fechamento das reservas às 19:00 do seu próprio '
                  'relógio: na de cima ele fica à direita do instante, então a reserva está aberta; na de '
                  'baixo ele cai às 16:00 de São Paulo, à esquerda do instante, então a reserva está fechada.',
            cap='Um instante em duas máquinas. Cada uma fecha as reservas às 19:00 do próprio relógio, e a '
                'máquina em UTC chega às 19:00 três horas antes.'),
    }[lang]
    f = Fig('l21-two-clocks', 700, 300, t['label'])
    x0, x1 = 60, 660
    px = (x1 - x0) / 8            # São Paulo 14:00 to 22:00

    def sx(sp_hour):
        return x0 + (sp_hour - 14) * px

    rows = [(90, 0), (205, 3)]    # (y, hours this machine's clock runs ahead of São Paulo)
    for (y, ahead), name in zip(rows, t['rows']):
        f.text(x0, y - 40, name, size=10.5, anchor='start', weight='600')
        cx = sx(19 - ahead)
        f.rect(cx, y - 14, x1 - cx, 14, stroke='--amber', fill='--scan', rx=2, dash='4 3')
        f.line(x0, y, x1, y, stroke='--paper-dim', width=1.2)
        for h in range(14, 23):
            x = sx(h)
            f.line(x, y - 4, x, y + 4, stroke='--paper-dim', width=1)
            f.text(x, y + 16, f'{(h + ahead) % 24:02d}:00', size=9, fill='--paper-dim', mono=True)
        f.line(cx, y - 24, cx, y + 6, stroke='--amber', width=1.8)
        f.text(cx + 6, y - 22, t['cut'], size=9.5, anchor='start', fill='--amber')
    nx = sx(17.5)
    f.line(nx, 36, nx, 262, stroke='--phosphor', width=2)
    f.text(nx, 278, t['now'], size=10, fill='--phosphor', weight='600')
    for (y, _), mark, reads, state, side in ((rows[0], '--phosphor', t['reads'], t['open'], -1),
                                             (rows[1], '--amber', t['reads2'], t['closed'], 1)):
        f.circle(nx, y, 5, fill=mark)
        anchor = 'end' if side < 0 else 'start'
        f.text(nx + 8 * side, y + 34, reads, size=9.5, anchor=anchor, fill=mark)
        f.text(nx + 8 * side, y + 48, state, size=10, anchor=anchor, fill=mark, weight='600')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
