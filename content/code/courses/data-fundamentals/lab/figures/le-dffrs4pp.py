from svg import Fig

# ---- event-time-and-processing-time: two clocks, and the Parque Barigui outage.
# Real events of Monday 6 October from stream/sensors.py: ST08's twelve between
# 08:15 and 08:56, and every fifth event of the other stations in that span.
X0, PX = 96, 13          # 08:15 at x=96, 13 px a minute


def x(hms):
    h, m, s = (int(v) for v in hms.split(':'))
    return round(X0 + ((h - 8) * 60 + m - 15 + s / 60) * PX, 1)


f = Fig('two-clocks', 720, 268,
        caption=('Each line joins one event’s two times. Most fall straight down: a few seconds '
                 'between happening and arriving. Parque Barigui’s fan out to 08:51:30, when its link '
                 'came back, and cross the events that happened after them.',
                 'Cada linha liga os dois horários de um evento. A maioria cai reta: poucos segundos '
                 'entre acontecer e chegar. As do Parque Barigui se abrem até 08:51:30, quando o link '
                 'voltou, e cruzam os eventos que aconteceram depois delas.'),
        label=('Two time axes from 08:15 to 09:00, event time above and arrival below. Lines from '
               'other stations are nearly vertical. Ten lines from Parque Barigui start between 08:20 '
               'and 08:48 on the upper axis and all end at 08:51:30 on the lower one.',
               'Dois eixos de tempo das 08:15 às 09:00, o tempo do evento em cima e a chegada embaixo. '
               'As linhas das outras estações são quase verticais. Dez linhas do Parque Barigui começam '
               'entre 08:20 e 08:48 no eixo de cima e todas terminam às 08:51:30 no de baixo.'))
TOP, BOT = 92, 206
f.text(14, 22, ('when it happened: event time', 'quando aconteceu: tempo do evento'), anchor='start',
       size=11.5, weight='600')
f.text(14, 246, ('when it arrived: processing time', 'quando chegou: tempo de processamento'),
       anchor='start', size=11.5, weight='600')
for y in (TOP, BOT):
    f.line(x('08:15:00'), y, x('09:00:00'), y, color='paper-dim', sw=1.5)
for t in ('08:15', '08:30', '08:45', '09:00'):
    f.line(x(t + ':00'), TOP - 5, x(t + ':00'), TOP, color='paper-dim')
    f.line(x(t + ':00'), BOT, x(t + ':00'), BOT + 5, color='paper-dim')
    f.text(x(t + ':00'), TOP - 14, t, size=10, mono=True, color='paper-dim')
    f.text(x(t + ':00'), BOT + 15, t, size=10, mono=True, color='paper-dim')
OTHERS = [('08:15:27', '08:15:30'), ('08:18:23', '08:18:27'), ('08:20:04', '08:20:07'),
          ('08:23:18', '08:23:21'), ('08:24:43', '08:24:45'), ('08:26:19', '08:26:23'),
          ('08:28:36', '08:28:38'), ('08:30:22', '08:30:25'), ('08:32:35', '08:32:37'),
          ('08:35:57', '08:35:58'), ('08:38:03', '08:38:07'), ('08:41:43', '08:41:47'),
          ('08:44:28', '08:44:32'), ('08:46:32', '08:46:33'), ('08:48:44', '08:48:45'),
          ('08:52:06', '08:52:10')]
for a, b in OTHERS:
    f.line(x(a), TOP, x(b), BOT, color='paper-dim', sw=1)
ST08 = [('08:16:35', '08:16:39'), ('08:18:46', '08:18:47')] + [
    (t, '08:51:30') for t in ('08:20:34', '08:25:34', '08:28:34', '08:30:53', '08:32:53',
                              '08:34:06', '08:39:39', '08:40:10', '08:42:27', '08:47:47')]
for a, b in ST08:
    f.line(x(a), TOP, x(b), BOT, color='amber', sw=1.6)
    f.circle(x(a), TOP, 2.6, fill='amber', stroke='amber', sw=1)
    f.circle(x(b), BOT, 2.6, fill='amber', stroke='amber', sw=1)
f.line(x('08:20:00'), TOP - 32, x('08:51:30'), TOP - 32, color='amber', dash='4 3')
f.line(x('08:20:00'), TOP - 36, x('08:20:00'), TOP - 28, color='amber')
f.line(x('08:51:30'), TOP - 36, x('08:51:30'), TOP - 28, color='amber')
f.text(x('08:36:00'), TOP - 44, ('Parque Barigui’s link down', 'link do Parque Barigui fora'),
       size=10.5, color='paper')
f.line(452, 246, 476, 246, color='amber', sw=1.6)
f.text(482, 246, ('Parque Barigui (ST08)', 'Parque Barigui (ST08)'), anchor='start', size=10.5)
f.line(610, 246, 634, 246, color='paper-dim', sw=1)
f.text(640, 246, ('others', 'outras'), anchor='start', size=10.5)
f.text(x('08:53:00') + 8, BOT - 30, ('all ten sent', 'as dez enviadas'), anchor='start', size=10.5)
f.text(x('08:53:00') + 8, BOT - 16, ('at 08:51:30', 'às 08:51:30'), anchor='start', size=10.5)

# ---- windows: tumbling, sliding and session over one hour.
W0, WP = 150, 9          # 08:00 at x=150, 9 px a minute


def wx(m):
    return round(W0 + m * WP, 1)


g = Fig('windows', 720, 300,
        caption=('The same hour cut three ways. Tumbling windows share no event; sliding ones overlap, '
                 'so an event is counted in two; sessions are cut where one customer goes quiet.',
                 'A mesma hora cortada de três jeitos. Janelas fixas não dividem nenhum evento; as '
                 'deslizantes se sobrepõem, então um evento é contado em duas; as sessões são cortadas '
                 'onde um cliente fica parado.'),
        label=('A time axis from 08:00 to 09:00 with rides marked as dots. Tumbling: four adjacent '
               'fifteen-minute boxes. Sliding: thirty-minute boxes starting every fifteen minutes, '
               'overlapping. Session: one customer’s taps in three clusters, each cluster its own box, '
               'separated by gaps of more than ten minutes.',
               'Um eixo de tempo das 08:00 às 09:00 com viagens marcadas como pontos. Fixa: quatro '
               'caixas de quinze minutos lado a lado. Deslizante: caixas de trinta minutos começando a '
               'cada quinze, sobrepostas. Sessão: os toques de um cliente em três grupos, cada grupo '
               'numa caixa, separados por intervalos de mais de dez minutos.'))
for m, t in ((0, '08:00'), (15, '08:15'), (30, '08:30'), (45, '08:45'), (60, '09:00')):
    g.text(wx(m), 18, t, size=10, mono=True, color='paper-dim')
    g.line(wx(m), 28, wx(m), 262, color='wire', sw=1, dash='2 4')
g.text(14, 46, ('rides', 'viagens'), anchor='start', size=11, weight='600')
g.line(wx(0), 46, wx(60), 46, color='paper-dim', sw=1)
RIDES = [2, 5, 7, 9, 12, 16, 17, 20, 22, 23, 26, 29, 31, 33, 36, 38, 41, 44, 47, 52, 55, 58]
for m in RIDES:
    g.circle(wx(m), 46, 3, fill='phosphor', stroke='phosphor', sw=1)
g.text(14, 88, ('tumbling', 'fixa'), anchor='start', size=11, weight='600')
for i in range(4):
    g.box(wx(i * 15) + 2, 72, 15 * WP - 4, 32, '15 min', size=10, mono=True)
g.text(14, 150, ('sliding', 'deslizante'), anchor='start', size=11, weight='600')
g.box(wx(0) + 2, 122, 30 * WP - 4, 26, '08:00–08:30', size=10, mono=True)
g.box(wx(30) + 2, 122, 30 * WP - 4, 26, '08:30–09:00', size=10, mono=True)
g.box(wx(15) + 2, 154, 30 * WP - 4, 26, '08:15–08:45', size=10, mono=True, stroke='phosphor')
g.text(14, 228, ('session', 'sessão'), anchor='start', size=11, weight='600')
g.text(14, 244, ('one customer', 'um cliente'), anchor='start', size=10, color='paper-dim')
for a, b, taps in ((3, 11, (3, 5, 6, 9, 11)), (26, 29, (26, 27, 29)), (44, 56, (44, 47, 49, 53, 56))):
    g.rect(wx(a) - 8, 212, (b - a) * WP + 16, 34, fill='panel', stroke='amber')
    for m in taps:
        g.circle(wx(m), 229, 3, fill='amber', stroke='amber', sw=1)
g.text(wx(18.5), 268, ('a 15-minute gap', 'um intervalo de 15 min'), size=10, color='paper')
g.text(wx(36.5), 268, ('a 15-minute gap', 'um intervalo de 15 min'), size=10, color='paper')
g.text(wx(30), 290, ('a session ends after 10 minutes with no tap', 'uma sessão fecha depois de 10 minutos sem toque'),
       size=10.5, color='paper-dim')

# ---- lambda-and-kappa
k = Fig('lambda-kappa', 720, 330,
        caption=('Lambda computes the answer twice and merges the two; Kappa computes it once and, to '
                 'change it, replays the log into a new output.',
                 'A Lambda calcula a resposta duas vezes e junta as duas; a Kappa calcula uma vez e, para '
                 'mudá-la, reproduz o log numa saída nova.'),
        label=('Lambda: events go to a batch layer that recomputes nightly from all raw events and to '
               'a speed layer that streams the hours since; a serving layer merges both for readers. '
               'Kappa: events go to a log that keeps them in order; one stream job reads it into an '
               'output, and a new version replays the log from offset 0 into a second output.',
               'Lambda: os eventos vão para uma camada de lote que recalcula toda noite a partir de '
               'todos os eventos brutos e para uma camada de velocidade que processa como fluxo as horas '
               'desde então; uma camada de serviço junta as duas para os leitores. Kappa: os eventos vão '
               'para um log que os guarda em ordem; um job de fluxo o lê para uma saída, e uma versão '
               'nova reproduz o log desde o offset 0 numa segunda saída.'))
k.text(14, 20, 'Lambda', anchor='start', size=12.5, weight='600', color='phosphor')
k.box(14, 70, 112, 46, ('events', 'eventos'))
k.box(176, 38, 210, 48, [('all raw events,', 'todos os eventos brutos,'),
                          ('recomputed every night', 'recalculados toda noite')],
      title=('batch layer', 'camada de lote'), size=10)
k.box(176, 100, 210, 48, [('the hours since the last', 'as horas desde o último'),
                           ('batch, as a stream', 'lote, como fluxo')],
      title=('speed layer', 'camada de velocidade'), size=10)
k.box(436, 66, 130, 54, [('merges the two', 'junta as duas')],
      title=('serving layer', 'camada de serviço'), size=10, stroke='phosphor')
k.box(608, 70, 98, 46, ('readers', 'leitores'))
k.arrow(126, 86, 174, 62)
k.arrow(126, 100, 174, 124)
k.arrow(386, 62, 434, 84)
k.arrow(386, 124, 434, 102)
k.arrow(566, 93, 606, 93)
k.line(14, 172, 706, 172, color='wire', sw=1, dash='3 4')
k.text(14, 192, 'Kappa', anchor='start', size=12.5, weight='600', color='phosphor')
k.box(14, 236, 112, 46, ('events', 'eventos'))
k.box(170, 222, 150, 74, [('every event kept,', 'cada evento guardado,'), ('in order', 'em ordem')],
      title=('the log', 'o log'), size=10, stroke='phosphor')
k.box(374, 206, 160, 42, ('stream job v1', 'job de fluxo v1'), size=10.5)
k.box(374, 268, 160, 46, [('stream job v2,', 'job de fluxo v2,'),
                           ('replaying from offset 0', 'reproduzindo desde o offset 0')],
      size=10, dash='5 4', stroke='amber')
k.box(584, 206, 122, 42, ('output v1', 'saída v1'), size=10.5)
k.box(584, 270, 122, 42, ('output v2', 'saída v2'), size=10.5, dash='5 4', stroke='amber')
k.arrow(126, 259, 168, 259)
k.arrow(320, 248, 372, 228)
k.arrow(320, 272, 372, 290, dash='4 3')
k.arrow(534, 227, 582, 227)
k.arrow(534, 291, 582, 291, dash='4 3')

FIGURES = [f, g, k]
