"""Lesson 15: an afternoon, read out of a trail."""
from figures import Fig, T, figure


@figure('l15-timeline', 15)
def timeline():
    f = Fig('l15-timeline', 720, 300, T(
        'A timeline of the afternoon in the lesson\'s sample records, in UTC, from 12:00 to 16:00. At '
        '12:02 caio puts a bucket policy that makes clinic-exports public, and the exposure window '
        'opens. At 12:40 an anonymous caller at 198.51.100.77 is served 2026-10-14.csv, and at 13:15 '
        'another at 198.51.100.140 is served 2026-10-13.csv. At 14:03 dani\'s key tries StopLogging '
        'and is refused. At 15:30 ana deletes the bucket policy, and the window closes after 3 hours '
        'and 28 minutes. At 15:31 the first anonymous address comes back and is refused.',
        'Uma linha do tempo da tarde nos registros de exemplo da aula, em UTC, das 12:00 às 16:00. Às '
        '12:02 o caio aplica uma política de bucket que torna o clinic-exports público, e a janela de '
        'exposição abre. Às 12:40 um chamador anônimo em 198.51.100.77 recebe o 2026-10-14.csv, e às '
        '13:15 outro em 198.51.100.140 recebe o 2026-10-13.csv. Às 14:03 a chave da dani tenta '
        'StopLogging e é recusada. Às 15:30 a ana apaga a política do bucket, e a janela fecha depois '
        'de 3 horas e 28 minutos. Às 15:31 o primeiro endereço anônimo volta e é recusado.'))
    x0, x1, axis = 50, 690, 150

    def X(h, m):
        return x0 + (x1 - x0) * ((h - 12) * 60 + m) / 240

    f.rect(X(12, 2), axis - 34, X(15, 30) - X(12, 2), 68, stroke=None, fill='--scan', rx=0)
    f.text((X(12, 2) + X(15, 30)) / 2, axis - 24, T('public for 3 h 28 min', 'público por 3 h 28 min'),
           size=10, weight='600', fill='--amber')
    f.line(x0, axis, x1, axis, stroke='--paper-dim')
    for h in range(12, 17):
        f.line(X(h, 0), axis - 4, X(h, 0), axis + 4, stroke='--paper-dim')
        f.text(X(h, 0), axis + 16, f'{h}:00', size=9, fill='--paper-dim', mono=True)
    f.text(x1, axis + 30, 'UTC', size=9, fill='--paper-dim', anchor='end', mono=True)

    def mark(h, m, up, row, head, sub, colour):
        x = X(h, m)
        y = axis - 50 - row * 40 if up else axis + 52 + row * 40
        f.line(x, axis, x, y + (12 if up else -12), stroke=colour, dash='2 3')
        f.circle(x, axis, 4, fill=colour)
        anchor = 'start' if x < 560 else 'end'
        dx = 4 if anchor == 'start' else -4
        f.text(x + dx, y - 6, head, size=10, anchor=anchor, fill=colour)
        f.text(x + dx, y + 8, sub, size=9, anchor=anchor, fill='--paper-dim', mono=True)

    mark(12, 2, True, 0, T('caio makes it public', 'o caio o torna público'), 'PutBucketPolicy', '--amber')
    mark(12, 40, False, 0, T('served to an anonymous caller', 'servido a um chamador anônimo'),
         '198.51.100.77', '--amber')
    mark(13, 15, False, 1, T('served to another', 'servido a outro'), '198.51.100.140', '--amber')
    mark(14, 3, True, 1, T('dani\'s key, refused', 'a chave da dani, recusada'), 'StopLogging', '--phosphor')
    mark(15, 30, True, 0, T('ana closes it', 'a ana o fecha'), 'DeleteBucketPolicy', '--phosphor')
    mark(15, 31, False, 0, T('the first caller, refused', 'o primeiro chamador, recusado'),
         '198.51.100.77', '--phosphor')
    return f, T('The management events say when the window opened and closed; only the data events say '
                'what went through it.',
                'Os eventos de gerenciamento dizem quando a janela abriu e fechou; só os eventos de dados '
                'dizem o que passou por ela.')
