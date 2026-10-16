#!/usr/bin/env python3
"""The figures of lesson 22: python3 figures.py redraws them in both languages."""
import os
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
from figlib import Fig, figure, main  # noqa: E402


@figure('l22-two-links', 22)
def two_links(lang):
    t = {
        'en': dict(
            rows=['link A, as R3 says', 'link A, in boxoffice 1.1', 'link B'],
            dead='stops working', both='two live links: defect 10',
            events=[('sign-up:', 'link A sent'), ('new link asked:', 'link B sent'),
                    ('24 hours', 'after A'), ('24 hours', 'after B')],
            time='time',
            label='A timeline with three bars. Events along the bottom: sign-up, when link A is sent; a '
                  'request for a new link, when link B is sent; 24 hours after A; and 24 hours after B. '
                  'The first bar, link A as R3 says, is live from sign-up until the new link is asked for, '
                  'and stops working there. The second bar, link A in boxoffice 1.1, stays live until 24 '
                  'hours after sign-up, so from the request for a new link until then two links are live '
                  'at once, which is defect 10. The third bar, link B, is live from its request until 24 '
                  'hours after it.',
            cap='How long each confirmation link lives. R3 ends link A when link B is sent; boxoffice 1.1 '
                'lets it run its full 24 hours.'),
        'pt': dict(
            rows=['link A, como diz o R3', 'link A, no boxoffice 1.1', 'link B'],
            dead='para de funcionar', both='dois links vivos: defeito 10',
            events=[('cadastro:', 'link A enviado'), ('novo link pedido:', 'link B enviado'),
                    ('24 horas', 'depois do A'), ('24 horas', 'depois do B')],
            time='tempo',
            label='Uma linha do tempo com três barras. Eventos ao longo da base: o cadastro, quando o link A '
                  'é enviado; o pedido de um novo link, quando o link B é enviado; 24 horas depois do A; e '
                  '24 horas depois do B. A primeira barra, o link A como diz o R3, fica viva do cadastro '
                  'até o pedido do novo link, e para de funcionar ali. A segunda, o link A no boxoffice 1.1, '
                  'fica viva até 24 horas depois do cadastro, então do pedido do novo link até lá há dois '
                  'links vivos ao mesmo tempo, que é o defeito 10. A terceira, o link B, fica viva do pedido '
                  'até 24 horas depois dele.',
            cap='Quanto tempo cada link de confirmação vive. O R3 encerra o link A quando o link B é enviado; '
                'o boxoffice 1.1 o deixa correr as 24 horas inteiras.'),
    }[lang]
    f = Fig('l22-two-links', 700, 250, t['label'])

    def sx(hours):
        return 190 + hours * 15

    a0, b0, a1, b1 = sx(0), sx(6), sx(24), sx(30)
    axis = 180
    for x in (a0, b0, b1):
        f.line(x, 26, x, axis, stroke='--wire', width=1, dash='3 3')
    # A's 24 hours end inside link B's bar, so that line stops short of it
    f.line(a1, 26, a1, 128, stroke='--wire', width=1, dash='3 3')
    f.line(a1, 152, a1, axis, stroke='--wire', width=1, dash='3 3')
    rows = [40, 90, 140]
    for y, name in zip(rows, t['rows']):
        f.text(20, y, name, size=10, anchor='start', weight='600')
    # link A as R3 says: live until B is sent, then dead
    f.rect(a0, rows[0] - 8, b0 - a0, 16, stroke='--phosphor', fill='--scan', rx=3)
    f.line(b0, rows[0], a1, rows[0], stroke='--paper-dim', width=1.2, dash='4 4')
    f.text(b0 + 10, rows[0] - 14, t['dead'], size=9.5, anchor='start', fill='--paper-dim')
    # link A in boxoffice 1.1: live for the full 24 hours, the overlap marked
    f.rect(a0, rows[1] - 8, b0 - a0, 16, stroke='--phosphor', fill='--scan', rx=3)
    f.rect(b0, rows[1] - 8, a1 - b0, 16, stroke='--amber', fill='--scan', rx=3)
    f.text((b0 + a1) / 2, rows[1], t['both'], size=9.5, fill='--amber', weight='600')
    # link B
    f.rect(b0, rows[2] - 8, b1 - b0, 16, stroke='--phosphor', fill='--scan', rx=3)
    f.line(a0 - 10, axis, b1 + 30, axis, stroke='--paper-dim', width=1.2, arrow=True)
    f.text(b1 + 30, axis - 12, t['time'], size=9.5, anchor='end', fill='--paper-dim')
    for x, (l1, l2) in zip((a0, b0, a1, b1), t['events']):
        f.text(x, axis + 18, l1, size=9, fill='--paper-dim')
        f.text(x, axis + 31, l2, size=9, fill='--paper-dim')
    return f, t['cap']


if __name__ == '__main__':
    main(__file__)
