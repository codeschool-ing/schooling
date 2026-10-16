"""Lesson 14: operational BI. A morning of deliveries from the Contagem
warehouse — fourteen routes, how far behind each one is at 11:00 — counted
against three alert thresholds, and the delivery board drawn from the same day."""
import book as B

LESSON = 'le-dnd4q6aj'

# Wednesday 14 January 2026, 11:00. One row per route: number, area, minutes
# behind the plan, orders (stops) planned for the day, delivered so far, and
# orders whose promised window has already closed undelivered.
ROUTES = [
    (1, 'Contagem Centro', 0, 22, 9, 0),
    (2, 'Eldorado', 6, 18, 7, 0),
    (3, 'Betim', 12, 24, 8, 0),
    (4, 'Barreiro', 18, 20, 6, 0),
    (5, 'Pampulha', 3, 19, 8, 0),
    (6, 'Venda Nova', 35, 23, 5, 0),
    (7, 'Savassi', 9, 17, 7, 0),
    (8, 'Nova Lima', 22, 21, 6, 0),
    (9, 'Sabará', 0, 16, 7, 0),
    (10, 'Santa Luzia', 41, 22, 5, 1),
    (11, 'Ribeirão das Neves', 74, 25, 3, 3),
    (12, 'Ibirité', 15, 20, 7, 0),
    (13, 'Lagoa Santa', 27, 18, 5, 0),
    (14, 'Vespasiano', 8, 21, 8, 0),
]
THRESHOLDS = (15, 30, 60)
BOARD = 30          # the threshold Marcos's board uses


def alerts():
    """The table the student types, and one column per threshold."""
    rows = [['Route', 'Area', 'Behind'] + list(THRESHOLDS)]
    for k, (n, area, late, *_rest) in enumerate(ROUTES, start=2):
        rows.append([n, area, late] + [f'=IF($C{k}>={c}$1,1,0)' for c in 'DEF'])
    last = len(rows)
    rows.append(['Alerts', '', ''] + [f'=SUM({c}2:{c}{last})' for c in 'DEF'])
    got = B.report('lesson 14 — alerts at three thresholds', rows,
                   ['D2', 'D5', f'D{last + 1}', f'E{last + 1}', f'F{last + 1}'],
                   [f'=ROUND(AVERAGE(C2:C{last}),1)', f'=MEDIAN(C2:C{last})', f'=MAX(C2:C{last})',
                    f'=SUM(C2:C{last})',
                    f'=SUMPRODUCT((C2:C{last}>=20)*1)'])   # the drill's threshold of 20
    return got


def board_numbers():
    """The four numbers at the top of the board, from the same day."""
    rows = [['Route', 'Behind', 'Planned', 'Done', 'Missed']]
    for n, _, late, planned, done, missed in ROUTES:
        rows.append([n, late, planned, done, missed])
    last = len(rows)
    return B.report('lesson 14 — the board\'s four numbers', rows, [], [
        f'=SUM(C2:C{last})', f'=SUM(D2:D{last})', f'=SUM(E2:E{last})',
        f'=SUMPRODUCT((B2:B{last}>={BOARD})*(C2:C{last}-D2:D{last}))',
        f'=SUMPRODUCT((B2:B{last}<{BOARD})*1)',
        f'=SUM(C2:C{last})-SUM(D2:D{last})',
    ])


def freshness():
    """The morning the copy stopped: last copy at 09:20, noticed at 11:05."""
    return B.report('lesson 14 — how old the board was', [['x']], [], [
        '=(11*60+5)-(9*60+20)', '=2*10', '=2*286', '=60/10', '=ROUND(74/14,1)'])


# ----------------------------------------------------------------- figures

def board_figure():
    by_delay = sorted(ROUTES, key=lambda r: -r[2])
    attention = [r for r in by_delay if r[2] >= BOARD]
    calm = [r for r in by_delay if r[2] < BOARD]
    planned = sum(r[3] for r in ROUTES)
    done = sum(r[4] for r in ROUTES)
    missed = sum(r[5] for r in ROUTES)
    risk = sum(r[3] - r[4] for r in attention)
    f = B.Fig('l14-board', 720, 420, (
        f'A mock of the delivery board for Wednesday 14 January 2026, data from 11:00. Four tiles: '
        f'{planned} orders for today, {done} delivered, {missed} late with the window missed, {risk} at '
        f'risk on routes 30 or more minutes behind. Then a list of the three routes that need '
        f'attention, most behind first, each with a suggested next step: route 11, Ribeirão das '
        f'Neves, 74 minutes behind; route 10, Santa Luzia, 41; route 6, Venda Nova, 35. Below, the '
        f'other {len(calm)} routes as small chips with their minutes behind, none needing action.',
        f'Um esboço do painel de entregas de quarta, 14 de janeiro de 2026, dados das 11:00. Quatro '
        f'blocos: {planned} pedidos para hoje, {done} entregues, {missed} atrasados com a janela perdida, '
        f'{risk} em risco em rotas 30 minutos ou mais atrasadas. Depois, a lista das três rotas que '
        f'precisam de atenção, da mais atrasada à menos, cada uma com um próximo passo sugerido: rota '
        f'11, Ribeirão das Neves, 74 minutos; rota 10, Santa Luzia, 41; rota 6, Venda Nova, 35. '
        f'Abaixo, as outras {len(calm)} rotas em pequenos blocos com os minutos de atraso, nenhuma '
        f'pedindo ação.'))
    f.rect(8, 8, 704, 404, fill='--panel', stroke='--wire')
    f.text(24, 36, ('Deliveries · Contagem warehouse · Wed 14 Jan 2026',
                    'Entregas · CD Contagem · qua 14 jan 2026'), size=14, weight=600)
    f.text(696, 36, ('data from 11:00 · 2 min old', 'dados das 11:00 · há 2 min'), size=12,
           anchor='end', fill='--paper-dim')
    tiles = [
        (str(planned), ('orders for today', 'pedidos para hoje'), False),
        (str(done), ('delivered', 'entregues'), False),
        (str(missed), ('late: window missed', 'atrasados: janela perdida'), True),
        (str(risk), ('at risk: routes 30+ min', 'em risco: rotas 30+ min'), True),
    ]
    for k, (num, label, hot) in enumerate(tiles):
        x = 24 + k * 170
        f.rect(x, 52, 158, 70, fill='--scan', stroke='--amber' if hot else '--wire',
               sw=2 if hot else 1)
        f.text(x + 14, 88, num, size=26, weight=600)
        f.text(x + 14, 110, label, size=11, fill='--paper-dim')
    f.text(24, 150, ('Needs attention: routes 30 or more minutes behind',
                     'Precisa de atenção: rotas 30 ou mais minutos atrasadas'), size=12, weight=600)
    cols = [(32, ('route', 'rota')), (80, ('area', 'região')), (232, ('behind', 'atraso')),
            (300, ('left', 'faltam')), (356, ('late', 'atras.')), (410, ('next step', 'próximo passo'))]
    for x, h in cols:
        f.text(x, 172, h, size=11, fill='--paper-dim')
    steps = {
        11: ('move 6 stops to route 14; call 3 customers', 'passar 6 paradas à rota 14; ligar a 3 clientes'),
        10: ('call 1 customer; check again at 11:30', 'ligar a 1 cliente; rever às 11:30'),
        6: ('check again at 11:30', 'rever às 11:30'),
    }
    for k, (n, area, late, planned_r, done_r, missed_r) in enumerate(attention):
        y = 182 + k * 32
        f.rect(24, y, 672, 26, fill='--scan', stroke='--amber' if k == 0 else '--wire',
               sw=2 if k == 0 else 1)
        ty = y + 17
        f.text(32, ty, str(n), size=12, mono=True)
        f.text(80, ty, area, size=12)
        f.text(232, ty, f'{late} min', size=12, mono=True, weight=600)
        f.text(300, ty, str(planned_r - done_r), size=12, mono=True)
        f.text(356, ty, str(missed_r), size=12, mono=True)
        f.text(410, ty, steps[n], size=12)
    f.text(24, 302, (f'The other {len(calm)} routes: under 30 minutes behind, no action',
                     f'As outras {len(calm)} rotas: menos de 30 minutos de atraso, sem ação'),
           size=12, weight=600)
    for k, (n, _, late, *_r) in enumerate(calm):
        x = 24 + k * 61
        f.rect(x, 314, 55, 40, fill='--scan', stroke='--wire', sw=1)
        f.text(x + 27.5, 330, (f'route {n}', f'rota {n}'), size=10, anchor='middle', fill='--paper-dim')
        f.text(x + 27.5, 347, f'{late} min', size=11, anchor='middle', mono=True)
    f.text(24, 388, ('Copied from the drivers\' app every 10 minutes. With no copy for 20 minutes, '
                     'this screen says so instead of showing numbers.',
                     'Copiado do aplicativo dos motoristas a cada 10 minutos. Sem cópia por 20 minutos, '
                     'a tela avisa em vez de mostrar números.'), size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'Marcos\'s board at 11:00. The exceptions come first and carry a next step; the routes that '
        'need nothing are reduced to chips, and the time of the data is in the header.',
        'O painel do Marcos às 11:00. As exceções vêm primeiro e trazem um próximo passo; as rotas que '
        'não pedem nada viram blocos pequenos, e a hora dos dados está no cabeçalho.'))


def threshold_figure():
    by_delay = sorted(ROUTES, key=lambda r: -r[2])
    counts = {t: sum(1 for r in ROUTES if r[2] >= t) for t in THRESHOLDS}
    f = B.Fig('l14-thresholds', 720, 330, (
        'Fourteen vertical bars, one per route, sorted from most behind to least: 74, 41, 35, 27, '
        '22, 18, 15, 12, 9, 8, 6, 3, 0 and 0 minutes. Three dashed lines cross them. At 15 minutes, '
        f'{counts[15]} bars reach the line; at 30 minutes, {counts[30]}; at 60 minutes, {counts[60]}.',
        'Catorze barras verticais, uma por rota, da mais atrasada à menos: 74, 41, 35, 27, 22, 18, '
        '15, 12, 9, 8, 6, 3, 0 e 0 minutos. Três linhas tracejadas as cruzam. Em 15 minutos, '
        f'{counts[15]} barras alcançam a linha; em 30, {counts[30]}; em 60, {counts[60]}.'))
    x0, x1, y0, top = 70, 540, 270, 40
    scale = (y0 - top) / 80
    for v in (0, 20, 40, 60, 80):
        y = y0 - v * scale
        f.line(x0 - 6, y, x0, y, stroke='--paper-dim', sw=1)
        f.text(x0 - 10, y + 4, str(v), size=11, anchor='end', mono=True, fill='--paper-dim')
    f.line(x0, top - 6, x0, y0, stroke='--paper-dim', sw=1)
    f.line(x0, y0, x1, y0, stroke='--paper-dim', sw=1)
    f.text(24, 24, ('minutes behind plan at 11:00', 'minutos de atraso às 11:00'), size=12,
           fill='--paper-dim')
    step = (x1 - x0) / len(by_delay)
    for k, (n, _, late, *_r) in enumerate(by_delay):
        x = x0 + k * step + 6
        h = max(late * scale, 1.5)
        f.bar(x, y0 - h, step - 12, h, fill='--amber' if late >= BOARD else '--phosphor')
        f.text(x + (step - 12) / 2, y0 + 16, str(n), size=11, anchor='middle', mono=True,
               fill='--paper-dim')
    f.text((x0 + x1) / 2, y0 + 40, ('route, most behind first', 'rota, da mais atrasada à menos'),
           size=12, anchor='middle', fill='--paper-dim')
    for t in THRESHOLDS:
        y = y0 - t * scale
        f.line(x0, y, x1 + 8, y, stroke='--paper', sw=1.2, dash='5 4')
        n = counts[t]
        f.text(x1 + 14, y + 4, (f'{t} min: {n} alert' + ('s' if n != 1 else ''),
                                f'{t} min: {n} alerta' + ('s' if n != 1 else '')), size=12)
    B.place(LESSON, f, (
        'The same fourteen routes against three thresholds. At 15 minutes half the fleet raises an '
        'alert; at 60, only the route that is already lost does. The bars in red are what the '
        'board shows at 30.',
        'As mesmas catorze rotas contra três limiares. Em 15 minutos, metade da frota dispara alerta; '
        'em 60, só a rota que já está perdida. As barras em vermelho são o que o painel mostra em 30.'))


def main():
    alerts()
    board_numbers()
    freshness()
    board_figure()
    threshold_figure()


if __name__ == '__main__':
    main()
