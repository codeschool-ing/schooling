import random
from datetime import date, timedelta

from svg import Fig

# month: thirty mornings of September as bars, with the objective and the agreement as two lines.
# The ages are month.py's own, recomputed from the same seed, so the drawing is the capture.
rng = random.Random(9)
AGES = []
for n in range(30):
    failed = 0
    if rng.random() < 0.15:
        failed = rng.randint(1, 4)
    AGES.append(20 + 60 * failed)
assert sorted(a for a in AGES if a > 120) == [140, 200], AGES

f = Fig('month', 720, 290,
        caption=('Thirty mornings of September 2025. Two crossed the objective the team set itself, and '
                 'neither reached the agreement with the city.',
                 'Trinta manhãs de setembro de 2025. Duas passaram do objetivo que o time definiu para si, '
                 'e nenhuma chegou ao acordo com a prefeitura.'),
        label=('A bar chart of the age of the rides data at 09:00 on each of the thirty mornings of '
               'September 2025. Twenty-seven bars sit at twenty minutes and one, on 3 September, at an '
               'hour and twenty, still inside the objective. On 16 September the age is 2 '
               'hours 20 minutes and on 23 September 3 hours 20 minutes, both above the two-hour '
               'objective line and below the four-hour agreement line.',
               'Um gráfico de barras com a idade dos dados de viagens às 09:00 em cada uma das trinta '
               'manhãs de setembro de 2025. Vinte e sete barras ficam em vinte minutos e uma, em 3 de '
               'setembro, em uma hora e vinte, ainda dentro do objetivo. Em 16 de setembro '
               'a idade é de 2 horas e 20 minutos e em 23 de setembro de 3 horas e 20 minutos, as duas '
               'acima da linha do objetivo de duas horas e abaixo da linha do acordo de quatro horas.'))
X0, Y0, W, H = 70, 250, 600, 210          # plot area: x from X0, baseline at Y0, 4.5 h is H tall
HOUR = H / 4.5
BW = W / 30
# axes
f.line(X0, Y0, X0 + W, Y0, color='paper-dim')
f.line(X0, Y0, X0, Y0 - H, color='paper-dim')
for h in range(0, 5):
    y = round(Y0 - h * HOUR, 1)
    f.text(X0 - 8, y, f'{h} h', size=10, anchor='end', color='paper-dim', mono=True)
f.text(X0 - 8, 22, ('age at 09:00', 'idade às 09:00'), size=10.5, anchor='start', color='paper')
# bars
for i, age in enumerate(AGES):
    hgt = round(age / 60 * HOUR, 1)
    x = round(X0 + i * BW + 3, 1)
    over = age > 120
    f.rect(x, round(Y0 - hgt, 1), round(BW - 6, 1), hgt, fill='amber' if over else 'paper-dim',
           stroke='amber' if over else 'paper-dim', sw=1, rx=1)
for d in (1, 8, 15, 22, 29):
    f.text(round(X0 + (d - 1) * BW + BW / 2, 1), Y0 + 14, f'{d:02d}/09', size=9.5, color='paper-dim',
           mono=True)
# the two lines
y2 = round(Y0 - 2 * HOUR, 1)
y4 = round(Y0 - 4 * HOUR, 1)
f.line(X0, y2, X0 + W, y2, color='phosphor', sw=2, dash='6 4')
f.line(X0, y4, X0 + W, y4, color='amber', sw=2, dash='6 4')
f.text(X0 + 8, y2 - 10, ('objective (SLO): at most 2 h', 'objetivo (SLO): no máximo 2 h'),
       size=10.5, anchor='start', color='phosphor', weight='600')
f.text(X0 + 8, y4 - 10, ('agreement with the city (SLA): at most 4 h',
                             'acordo com a prefeitura (SLA): no máximo 4 h'),
       size=10.5, anchor='start', color='amber', weight='600')
# callouts over the two breaches
for i, age in enumerate(AGES):
    if age > 120:
        x = round(X0 + i * BW + BW / 2, 1)
        y = round(Y0 - age / 60 * HOUR - 9, 1)
        f.text(x, y, f'{age // 60}h{age % 60:02d}', size=10, color='paper', mono=True)

# doors: four decisions at Roda Livre, placed by how much it costs to undo them.
g = Fig('doors', 720, 230,
        caption=('Four decisions from this lesson, placed by what it costs to undo them. Only the last '
                 'one cannot be undone at all, and it is the cheapest to make.',
                 'Quatro decisões desta aula, posicionadas pelo custo de desfazê-las. Só a última não '
                 'pode ser desfeita de jeito nenhum, e é a mais barata de tomar.'),
        label=('A horizontal axis runs from two-way doors, cheap to undo and decided fast, to one-way '
               'doors, impossible to undo and decided slowly. Along it: the dashboard tool, a week to '
               'redo the charts; the format of the raw files, every kept file rewritten; the analytical '
               'database, months to move every query and load; deleting raw files after thirty days, '
               'which cannot be undone.',
               'Um eixo horizontal vai das portas de mão dupla, baratas de desfazer e decididas rápido, '
               'às portas de mão única, impossíveis de desfazer e decididas devagar. Ao longo dele: a '
               'ferramenta de painéis, uma semana para refazer os gráficos; o formato dos arquivos '
               'brutos, todo arquivo guardado reescrito; o banco analítico, meses para mudar cada '
               'consulta e carga; apagar os arquivos brutos depois de trinta dias, o que não pode ser '
               'desfeito.'))
AY = 120
g.arrow(40, AY, 684, AY, color='paper-dim')
g.text(40, AY + 20, ('two-way door: decide fast', 'mão dupla: decida rápido'), size=10.5,
       anchor='start', color='phosphor', weight='600')
g.text(684, AY - 18, ('one-way door: decide slowly', 'mão única: decida devagar'), size=10.5,
       anchor='end', color='amber', weight='600')
DOORS = [
    (110, 'up', ('the dashboard tool', 'a ferramenta de painéis'),
     ('a week to redo charts', 'uma semana de gráficos'), 'phosphor'),
    (280, 'down', ('the raw file format', 'o formato dos brutos'),
     ('rewrite every kept file', 'reescrever cada arquivo'), 'wire'),
    (450, 'up', ('the analytical database', 'o banco analítico'),
     ('months: every query moves', 'meses: toda consulta muda'), 'wire'),
    (612, 'down', ('delete raw after 30 days', 'apagar brutos após 30 dias'),
     ('cannot be undone', 'não pode ser desfeito'), 'amber'),
]
for x, side, title, detail, stroke in DOORS:
    g.circle(x, AY, 6, fill='panel', stroke=stroke, sw=2)
    if side == 'up':
        g.box(x - 82, 22, 164, 52, [detail], title=title, stroke=stroke, size=10.5)
        g.line(x, 74, x, AY - 7, color='paper-dim')
    else:
        g.box(x - 82, 166, 164, 52, [detail], title=title, stroke=stroke, size=10.5)
        g.line(x, AY + 7, x, 166, color='paper-dim')

FIGURES = [f, g]
