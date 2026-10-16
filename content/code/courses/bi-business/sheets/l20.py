"""Lesson 20: a factory through lesson 17's four questions, at Serra Azul Embalagens, an
invented plastic-packaging factory in Joinville with 14 injection-moulding machines on three
shifts. One machine's shift taken apart by OEE; the shift supervisor's screen; MTBF, MTTR and
availability for two machines; a control chart of daily scrap; and the parts that the
machine counted and nobody wrote down."""
import book as B

LESSON = 'le-0010zhbd'

# IM-07, second shift, Tuesday 11 November 2025, 14:00 to 22:00. Minutes, seconds and parts.
SHIFT = dict(length=480, planned_stop=30, mould_change=35, breakdown=28, ideal_cycle=15,
             parts=1350, good=1296)
REWORKED = 27                 # good parts that needed the flash trimmed by hand
OPERATOR_SCRAP = 40           # what the operator wrote on the shift sheet

# All fourteen machines at the end of the same shift, 22:00, for the supervisor's screen: availability,
# performance and quality this shift (percent), and what each is doing at 22:00, when shift 3 takes over.
FLOOR = [
    ('IM-01', 94, 91, 98, 'run'), ('IM-02', 90, 88, 97, 'run'), ('IM-03', 71, 89, 98, 'mould'),
    ('IM-04', 95, 92, 99, 'run'), ('IM-05', 92, 86, 98, 'run'), ('IM-06', 93, 90, 96, 'run'),
    ('IM-07', 86, 87.2, 96, 'run'), ('IM-08', 96, 93, 99, 'run'), ('IM-09', 91, 84, 97, 'run'),
    ('IM-10', 94, 89, 98, 'run'), ('IM-11', 64, 88, 95, 'down'), ('IM-12', 93, 91, 98, 'run'),
    ('IM-13', 89, 90, 92, 'run'), ('IM-14', 95, 92, 98, 'run'),
]

# July to September 2025: operating hours, failures and hours under repair.
MACHINES = [('IM-07', 1860, 6, 27), ('IM-11', 1790, 15, 52.5)]
IM11_NO_CAUSE = 9             # failures recorded as "machine stopped", with no cause

# IM-07's scrap rate by day, 12 working days of November 2025, percent; and the control
# limits from 25 stable days in September (mean ± 3 standard deviations), given.
SCRAP = [1.9, 2.3, 1.6, 2.1, 2.8, 1.7, 2.0, 2.4, 3.6, 2.2, 1.8, 3.0]
CL, LCL, UCL = 2.0, 0.8, 3.2

# One customer's October: caps shipped and caps returned as defective.
SHIPPED, RETURNED = 2400000, 312


def oee():
    s = SHIFT
    rows = [['Shift length (min)', s['length']], ['Planned stops (min)', s['planned_stop']],
            ['Unplanned stops (min)', s['mould_change'] + s['breakdown']],
            ['Ideal cycle (s per part)', s['ideal_cycle']], ['Parts made', s['parts']],
            ['Good parts', s['good']]]
    return B.report('lesson 20 — OEE of one shift', rows, [], [
        '=B1-B2', '=B1-B2-B3',
        '=ROUND((B1-B2-B3)/(B1-B2)*100,1)',
        '=ROUND(B4*B5/((B1-B2-B3)*60)*100,1)',
        '=ROUND(B6/B5*100,1)',
        '=ROUND((B1-B2-B3)/(B1-B2)*B4*B5/((B1-B2-B3)*60)*B6/B5*100,1)',
        '=ROUND(B4*B6/((B1-B2)*60)*100,1)',
        '=ROUND(B6*B4/60,1)',                                 # minutes of good parts
        '=ROUND((B5-B6)*B4/60,1)',                            # minutes lost to scrap
        '=ROUND((B1-B2-B3)-B4*B5/60,1)',                      # minutes lost to slow cycles
        '=B3',
        '=ROUND((B1-B2-B3)*60/B4,0)',                         # parts at the ideal rate
        '=B5-B6',
        f'=ROUND((B6-{REWORKED})/B5*100,1)',               # first-pass yield
    ])


def floor():
    rows = [['Machine', 'A', 'P', 'Q', 'OEE']]
    for k, (m, a, p, q, _) in enumerate(FLOOR, start=2):
        rows.append([m, a, p, q, f'=ROUND(B{k}*C{k}*D{k}/10000,1)'])
    n = len(FLOOR) + 1
    return B.report('lesson 20 — the floor at 22:00', rows,
                    [f'E{k}' for k in range(2, n + 1)], [f'=ROUND(AVERAGE(E2:E{n}),1)'])


def maintenance():
    rows = [['Machine', 'Hours', 'Failures', 'Repair hours', 'MTBF', 'MTTR', 'Availability %']]
    for k, (m, h, f, r) in enumerate(MACHINES, start=2):
        rows.append([m, h, f, r, f'=ROUND(B{k}/C{k},1)', f'=ROUND(D{k}/C{k},1)',
                     f'=ROUND(E{k}/(E{k}+F{k})*100,1)'])
    return B.report('lesson 20 — MTBF, MTTR, availability', rows,
                    ['E2', 'F2', 'G2', 'E3', 'F3', 'G3'],
                    ['=ROUND(C3/C2,1)', f'=ROUND({IM11_NO_CAUSE}/C3*100,0)'])


def quality():
    rows = [['Day', 'Scrap %']] + [[k + 1, v] for k, v in enumerate(SCRAP)]
    n = len(SCRAP) + 1
    rows.append(['Centre', CL]); rows.append(['Lower', LCL]); rows.append(['Upper', UCL])
    return B.report('lesson 20 — control chart', rows, [], [
        f'=ROUND(AVERAGE(B2:B{n}),2)', f'=MAX(B2:B{n})',
        f'=IF(B10>B{n + 3},"outside","inside")', f'=IF(B13>B{n + 3},"outside","inside")',
        f'=ROUND({RETURNED}/{SHIPPED}*1000000,0)',
        f'=ROUND({RETURNED}/{SHIPPED}*100,3)',
        f'=ROUND(({SHIFT["parts"]}-{SHIFT["good"]})/{SHIFT["parts"]}*1000000,0)',
    ])


def plant_data():
    s = SHIFT
    rows = [['Machine counter', s['parts']], ['Operator\'s scrap', OPERATOR_SCRAP],
            ['Boxed into the warehouse', s['good']]]
    return B.report('lesson 20 — three records of one shift', rows, [], [
        '=B1-B2', '=B1-B2-B3', '=ROUND((B1-B2)/B1*100,1)', '=ROUND(B3/B1*100,1)'])


# ------------------------------------------------------------------ figures

def supervisor_screen(fl, oe):
    order_status = {'down': 0, 'mould': 1, 'run': 2}
    vals = {m: float(fl[f'E{k}']) for k, (m, *_rest) in enumerate(FLOOR, start=2)}
    avg = float(fl[f'=ROUND(AVERAGE(E2:E{len(FLOOR) + 1}),1)'])
    f = B.Fig('l20-shift-screen', 720, 420, (
        f'A mock of the shift supervisor\'s screen at Serra Azul, at the end of the second shift, 22:00 on Tuesday 11 '
        f'November 2025. Shift OEE {avg:.1f}%. Fourteen machine tiles, stopped machines '
        f'first: IM-11 down for a breakdown for 18 minutes; IM-03 in a mould change; then the twelve '
        f'running machines, each with its OEE this shift. Below, IM-07\'s shift split into '
        f'availability, performance and quality.',
        f'Maquete da tela do supervisor de turno da Serra Azul, fim do segundo turno, 22:00 de terça, 11 de '
        f'novembro de 2025. OEE do turno: {B.fmt(avg, "pt", 1)}%. Catorze quadros de '
        f'máquina, as paradas primeiro: IM-11 parada por quebra há 18 minutos; IM-03 em troca de '
        f'molde; depois as doze máquinas rodando, cada uma com o seu OEE neste turno. Embaixo, o turno '
        f'da IM-07 dividido em disponibilidade, desempenho e qualidade.'))
    f.rect(10, 10, 700, 400, fill='--ink', stroke='--wire', sw=1)
    f.text(28, 40, ('Moulding hall · shift 2', 'Injeção · turno 2'), size=15, weight=600)
    f.text(692, 34, ('Tue 11 Nov 2025, 22:00', 'ter., 11/11/2025, 22:00'), size=11, anchor='end',
           fill='--paper-dim')
    f.text(692, 50, ('machine counters, every minute', 'contadores das máquinas, a cada minuto'),
           size=11, anchor='end', fill='--paper-dim')
    f.text(28, 76, (f'shift OEE: {avg:.1f}%', f'OEE do turno: {B.fmt(avg, "pt", 1)}%'),
           size=13)
    machines = sorted(FLOOR, key=lambda r: (order_status[r[4]], vals[r[0]]))
    x0, y0, w, h, gx, gy = 28, 92, 88, 62, 8, 10
    labels = {'down': ('down 18 min', 'parada 18 min'), 'mould': ('mould change', 'troca molde')}
    for i, (m, a, p, q, st) in enumerate(machines):
        cx = x0 + (i % 7) * (w + gx)
        cy = y0 + (i // 7) * (h + gy)
        stroke = '--amber' if st != 'run' else '--wire'
        f.rect(cx, cy, w, h, fill='--panel', stroke=stroke, sw=2 if st != 'run' else 1)
        f.text(cx + 8, cy + 20, m, size=11, mono=True, fill='--paper-dim')
        if st == 'run':
            f.text(cx + 8, cy + 46, (f'{vals[m]:.1f}%', f'{B.fmt(vals[m], "pt", 1)}%'), size=16,
                   weight=600)
        else:
            f.text(cx + 8, cy + 46, labels[st], size=11, weight=600)
    # IM-07, this shift
    y = 260
    f.text(28, y, ('IM-07 this shift: where the minutes went', 'IM-07 neste turno: para onde foram os minutos'),
           size=12, weight=600)
    av = float(oe['=ROUND((B1-B2-B3)/(B1-B2)*100,1)'])
    pf = float(oe['=ROUND(B4*B5/((B1-B2-B3)*60)*100,1)'])
    ql = float(oe['=ROUND(B6/B5*100,1)'])
    rows = [(('availability', 'disponibilidade'), av, ('stops: mould change, breakdown', 'paradas: troca de molde, quebra')),
            (('performance', 'desempenho'), pf, ('slower than the 15 s cycle', 'mais lenta que o ciclo de 15 s')),
            (('quality', 'qualidade'), ql, ('parts scrapped', 'peças refugadas'))]
    y += 22
    for lab, v, why in rows:
        f.text(28, y + 14, lab, size=12)
        f.bar(150, y, 300, 18, fill='--scan')
        f.bar(150, y, 300 * v / 100, 18, fill='--phosphor')
        f.text(460, y + 14, (f'{v:.1f}%', f'{B.fmt(v, "pt", 1)}%'), size=12)
        f.text(520, y + 14, why, size=11, fill='--paper-dim')
        y += 30
    f.text(28, 396, ('OEE = availability × performance × quality',
                     'OEE = disponibilidade × desempenho × qualidade'), size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'The supervisor\'s screen starts with the machines that are not making parts, then shows '
        'every other machine\'s OEE, and splits one machine\'s shift into the three losses so the '
        'supervisor knows which kind of problem to walk over to.',
        'A tela do supervisor começa pelas máquinas que não estão produzindo, depois mostra o OEE '
        'de cada uma das outras e divide o turno de uma máquina nas três perdas, para o supervisor '
        'saber que tipo de problema vai encontrar quando chegar lá.'))


def control_chart(qc):
    f = B.Fig('l20-control-chart', 720, 320, (
        'A control chart of IM-07\'s daily scrap rate over 12 working days of November 2025. A '
        'centre line at 2.0% and control limits at 0.8% and 3.2%, from a stable period in '
        'September. Eleven days fall inside the limits, including day 12 at 3.0%. Day 9, at 3.6%, '
        'is above the upper limit.',
        'Gráfico de controle da taxa diária de refugo da IM-07 em 12 dias úteis de novembro de 2025. '
        'Linha central em 2,0% e limites de controle em 0,8% e 3,2%, de um período estável de '
        'setembro. Onze dias ficam dentro dos limites, inclusive o dia 12, com 3,0%. O dia 9, com '
        '3,6%, fica acima do limite superior.'))
    x0, x1, y0, y1 = 70, 590, 40, 260
    lo, hi = 0.0, 4.0

    def Y(v):
        return y1 - (v - lo) / (hi - lo) * (y1 - y0)

    def X(i):
        return x0 + 20 + i * (x1 - x0 - 40) / (len(SCRAP) - 1)
    for v in (0, 1, 2, 3, 4):
        f.line(x0, Y(v), x1, Y(v), stroke='--wire', sw=0.5)
        f.text(x0 - 8, Y(v) + 4, (f'{v:.1f}%', f'{B.fmt(v, "pt", 1)}%'), size=11, anchor='end',
               fill='--paper-dim', mono=True)
    f.path(f'M{x0:.1f} {Y(UCL):.1f} L{x1:.1f} {Y(UCL):.1f}', stroke='--amber', sw=1.5, dash='6 4')
    f.path(f'M{x0:.1f} {Y(LCL):.1f} L{x1:.1f} {Y(LCL):.1f}', stroke='--amber', sw=1.5, dash='6 4')
    f.path(f'M{x0:.1f} {Y(CL):.1f} L{x1:.1f} {Y(CL):.1f}', stroke='--paper-dim', sw=1.5)
    f.text(x1 + 8, Y(UCL) + 4, ('upper limit 3.2%', 'limite superior 3,2%'), size=11)
    f.text(x1 + 8, Y(CL) + 4, ('centre 2.0%', 'centro 2,0%'), size=11)
    f.text(x1 + 8, Y(LCL) + 4, ('lower limit 0.8%', 'limite inferior 0,8%'), size=11)
    pts = ' L'.join(f'{X(i):.1f} {Y(v):.1f}' for i, v in enumerate(SCRAP))
    f.path('M' + pts, stroke='--phosphor', sw=1.5)
    for i, v in enumerate(SCRAP):
        out = v > UCL or v < LCL
        f.bar(X(i) - 4, Y(v) - 4, 8, 8, fill='--amber' if out else '--phosphor')
        f.text(X(i), y1 + 18, str(i + 1), size=11, anchor='middle', fill='--paper-dim', mono=True)
    f.text((x0 + x1) / 2, y1 + 40, ('working day of November 2025', 'dia útil de novembro de 2025'),
           size=11, anchor='middle', fill='--paper-dim')
    i9 = 8
    f.text(X(i9) + 10, Y(SCRAP[i9]) - 2, ('day 9: 3.6%, look for a cause', 'dia 9: 3,6%, procure a causa'),
           size=11)
    B.place(LESSON, f, (
        'Day 9 is a signal: it falls outside limits computed from a period when the process was '
        'stable. Day 12 is higher than ten of the other days and still inside them, which makes it '
        'part of the ordinary variation.',
        'O dia 9 é um sinal: cai fora de limites calculados num período em que o processo estava '
        'estável. O dia 12 é mais alto que dez dos outros dias e ainda fica dentro deles, o que o '
        'torna parte da variação comum.'))


def exercises():
    """Numbers the lesson's questions use that the sections do not print."""
    B.report('lesson 20 — exercises', [['x', 1]], [], [
        '=ROUND((480-30-45)/(480-30)*100,1)',           # availability of another shift
        '=ROUND(0.9*0.8*0.95*100,1)',                   # OEE from three factors
        '=ROUND(2000/8,1)', '=ROUND(20/8,1)', '=ROUND((2000/8)/((2000/8)+(20/8))*100,1)',
        '=ROUND(90/500000*1000000,0)',                  # ppm
    ])


def main():
    exercises()
    oe = oee()
    fl = floor()
    maintenance()
    qc = quality()
    plant_data()
    supervisor_screen(fl, oe)
    control_chart(qc)


if __name__ == '__main__':
    main()
