from svg import Fig

# polling: the same hour of rides ending, collected by two polling schedules.
RIDES = [3, 7, 11, 34, 41, 44, 52]          # minutes after 08:00


def x(m):
    return 100 + 10 * m


p = Fig('polling', 720, 250,
        caption=('The same seven rides, polled every fifteen minutes and every minute. Fresher data '
                 'costs calls, and most of the extra calls find nothing.',
                 'As mesmas sete viagens, consultadas a cada quinze minutos e a cada minuto. Dado mais '
                 'fresco custa chamadas, e a maioria das chamadas extras não encontra nada.'),
        label=('A time line from 08:00 to 09:00 with seven rides ending. Polled every fifteen minutes, '
               'there are four calls: three find rides and one comes back empty, and the ride that '
               'ended at 08:03 waits twelve minutes. Polled every minute, there are sixty calls: seven '
               'find a ride and fifty-three come back empty.',
               'Uma linha do tempo das 08:00 às 09:00 com sete viagens terminando. Consultando a cada '
               'quinze minutos, são quatro chamadas: três encontram viagens e uma volta vazia, e a '
               'viagem que terminou às 08:03 espera doze minutos. Consultando a cada minuto, são '
               'sessenta chamadas: sete encontram uma viagem e cinquenta e três voltam vazias.'))
for m, t in ((0, '08:00'), (15, '08:15'), (30, '08:30'), (45, '08:45'), (60, '09:00')):
    p.text(x(m), 30, t, size=10, color='paper-dim', mono=True)
# every fifteen minutes
p.text(88, 100, ('every 15 min', 'a cada 15 min'), size=11, anchor='end', weight='600')
p.line(x(0), 100, x(60), 100, color='wire')
for m, found in ((15, ('3 new', '3 novas')), (30, ('empty', 'vazia')), (45, ('3 new', '3 novas')),
                 (60, ('1 new', '1 nova'))):
    p.line(x(m), 86, x(m), 114, color='phosphor', sw=2)
    p.text(x(m), 127, found, size=10, color='amber' if found[0] == 'empty' else 'paper')
for m in RIDES:
    p.circle(x(m), 100, 4, fill='amber', stroke='amber')
p.line(x(3), 70, x(15), 70, color='paper-dim', sw=1.2)
p.line(x(3), 65, x(3), 75, color='paper-dim', sw=1.2)
p.line(x(15), 65, x(15), 75, color='paper-dim', sw=1.2)
p.text(x(9), 56, ('waits 12 min', 'espera 12 min'), size=10)
p.text(x(30), 150, ('4 calls: 1 comes back empty, and a ride waits up to 15 minutes',
                    '4 chamadas: 1 volta vazia, e uma viagem espera até 15 minutos'),
       size=10.5, color='paper-dim')
# every minute
p.text(88, 195, ('every minute', 'a cada minuto'), size=11, anchor='end', weight='600')
p.line(x(0), 195, x(60), 195, color='wire')
busy = {m + 1 for m in RIDES}
for m in range(1, 61):
    p.line(x(m), 187, x(m), 203, color='phosphor' if m in busy else 'wire',
           sw=2 if m in busy else 1)
for m in RIDES:
    p.circle(x(m), 195, 4, fill='amber', stroke='amber')
p.text(x(30), 228, ('60 calls: 7 find a ride, 53 come back empty',
                    '60 chamadas: 7 encontram uma viagem, 53 voltam vazias'),
       size=10.5, color='paper-dim')

# watermark: the late ride that a plain watermark never asks for.
def t(minutes_after_0940):
    return 80 + 20 * minutes_after_0940


w = Fig('watermark', 720, 232,
        caption=('A row carries the time it was written and becomes visible when it commits. Reading a '
                 'few minutes before the watermark is what catches the one that committed late.',
                 'Uma linha carrega a hora em que foi escrita e fica visível quando é confirmada. Ler '
                 'alguns minutos antes da marca d’água é o que pega a que foi confirmada tarde.'),
        label=('A time line from 09:40 to 10:10. Rides written up to 09:59 were copied at 10:00, which '
               'set the watermark to 09:59. Ride R000041 is stamped 09:57 but committed at 10:01. The '
               'next run with no overlap reads only above 09:59 and misses it; with a ten-minute '
               'overlap it reads above 09:49 and finds it, with the rides at 10:02 and 10:04.',
               'Uma linha do tempo das 09:40 às 10:10. As viagens escritas até 09:59 foram copiadas às '
               '10:00, o que pôs a marca d’água em 09:59. A viagem R000041 tem o carimbo 09:57, mas foi '
               'confirmada às 10:01. A execução seguinte sem sobreposição lê só acima de 09:59 e a '
               'perde; com dez minutos de sobreposição lê acima de 09:49 e a encontra, junto com as '
               'viagens das 10:02 e das 10:04.'))
w.arrow(70, 120, 696, 120, color='wire')
for m, lab in ((0, '09:40'), (10, '09:50'), (20, '10:00'), (30, '10:10')):
    w.text(t(m), 140, lab, size=10, color='paper-dim', mono=True)
w.line(t(19), 50, t(19), 214, color='amber', dash='5 4')
w.text(t(19) - 6, 52, ('watermark 09:59', 'marca d’água 09:59'), size=10, anchor='end',
       color='amber', weight='600')
w.line(t(20), 64, t(20), 112, color='paper-dim', dash='2 3')
w.text(t(20) + 6, 66, ('the copy at 10:00', 'a cópia das 10:00'), size=10, anchor='start')
for m in (1, 4, 7, 10, 13, 16, 19):
    w.circle(t(m), 120, 5, fill='paper-dim', stroke='paper-dim')
for m in (22, 24):
    w.circle(t(m), 120, 5, fill='phosphor', stroke='phosphor')
w.circle(t(17), 120, 6, fill='amber', stroke='amber')
w.text(t(17), 99, 'R000041', size=10, color='amber', mono=True)
w.text(t(17) + 8, 82, ('stamped 09:57, committed 10:01', 'carimbo 09:57, confirmada 10:01'),
       size=10, anchor='end')
w.rect(t(19), 162, t(30) - t(19), 20, fill='scan', stroke='phosphor')
w.text((t(19) + t(30)) / 2, 172, ('no overlap: above 09:59', 'sem sobreposição: acima de 09:59'),
       size=10)
w.rect(t(9), 192, t(30) - t(9), 20, fill='scan', stroke='phosphor', dash='4 3')
w.text((t(9) + t(30)) / 2, 202, ('ten-minute overlap: above 09:49',
                                 'dez minutos de sobreposição: acima de 09:49'), size=10)
w.text(t(4) - 10, 187, ('the run after 10:00 reads', 'a execução depois das 10:00 lê'), size=10,
       color='paper-dim')

# door: file checks refuse a file whole; row checks quarantine a row with its reason.
d = Fig('door', 720, 236,
        caption=('Two kinds of check on arrival. A file that fails is refused whole; a row that fails is '
                 'set aside with its reason, and never dropped.',
                 'Dois tipos de verificação na chegada. Um arquivo que falha é recusado inteiro; uma linha '
                 'que falha é separada com o motivo, e nunca descartada.'),
        label=('A delivery, a CSV file with the count of rows the source sent, goes first through checks '
               'on the file: the columns and the row count. If they fail, the file is refused whole and '
               'nothing is loaded. If they pass, each row goes through checks for a missing value, a '
               'range, uniqueness and a reference, and is either accepted or put in quarantine with '
               'its reason.',
               'Uma entrega, um arquivo CSV com a contagem de linhas que a origem enviou, passa primeiro '
               'pelas verificações do arquivo: as colunas e a contagem de linhas. Se falham, o arquivo é '
               'recusado inteiro e nada é carregado. Se passam, cada linha passa por verificações de '
               'valor ausente, faixa, unicidade e referência, e é aceita ou vai para a quarentena com o '
               'motivo.'))
d.box(14, 72, 124, 60, [('a CSV file', 'um arquivo CSV'), ('and its count', 'e a contagem')],
      title=('the delivery', 'a entrega'), size=10.5)
d.arrow(138, 102, 176, 102)
d.box(178, 57, 170, 90, [('the columns', 'as colunas'), ('the row count', 'a contagem de linhas')],
      title=('checks on the file', 'verificações do arquivo'), stroke='phosphor', size=10.5)
d.arrow(263, 147, 263, 177)
d.text(271, 162, ('fails', 'falha'), size=10, anchor='start', color='paper-dim')
d.box(178, 179, 170, 46, [('nothing is loaded', 'nada é carregado')],
      title=('refused whole', 'recusado inteiro'), stroke='amber', size=10.5)
d.arrow(348, 102, 386, 102)
d.text(367, 92, ('passes', 'passa'), size=10, color='paper-dim')
d.box(388, 32, 180, 140, [('a missing value', 'valor ausente'), ('a range', 'faixa'),
                          ('uniqueness', 'unicidade'), ('a reference', 'referência')],
      title=('checks on each row', 'verificações de cada linha'), stroke='phosphor', size=10.5)
d.arrow(568, 78, 594, 62)
d.box(596, 30, 112, 52, [('loaded', 'carregada')], title=('accepted', 'aceita'), size=10.5)
d.arrow(568, 126, 594, 142)
d.box(596, 116, 112, 68, [('the row,', 'a linha,'), ('and its reason', 'e o motivo')],
      title=('quarantine', 'quarentena'), stroke='amber', size=10.5)

FIGURES = [p, w, d]
