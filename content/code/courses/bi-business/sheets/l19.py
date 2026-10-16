"""Lesson 19: healthcare through lesson 17's four questions, at Hospital Jacarandá, an
invented 240-bed general hospital in Campinas. Bed occupancy by ward, length of stay and
turnover; waiting times in the emergency department; the denominator of a readmission
rate; the bed manager's morning screen; crude against age-adjusted rates for two towns;
and a small cell that a total gives away."""
import book as B

LESSON = 'le-xf37y0qe'

# November 2025, 30 days. Beds and patient-days by ward (a patient-day is one patient in
# one bed at the midnight count), and the hospital's discharges in the month.
DAYS = 30
WARDS = [
    (('Medical', 'Clínica médica'), 96, 2736),
    (('Surgical', 'Cirúrgica'), 64, 1670),
    (('Intensive care', 'UTI'), 20, 591),
    (('Maternity', 'Maternidade'), 32, 598),
    (('Paediatrics', 'Pediatria'), 28, 543),
]
DISCHARGES = 1365
assert sum(b for _, b, _ in WARDS) == 240

# Ten patients who arrived at the emergency department between 18:00 and 19:00 on a
# Monday, minutes from arrival to being seen by a doctor, in order.
WAITS = [12, 18, 25, 31, 38, 44, 52, 70, 145, 210]

# October 2025 discharges, followed for 30 days.
READMIT = dict(discharges=1310, deaths=41, readmitted=112, planned=30)

# The bed manager's screen, 07:00 on Tuesday 2 December 2025: beds, occupied at 07:00,
# discharges expected today, planned admissions booked today, and emergency patients
# already admitted and waiting in the emergency department for a bed on that ward.
MORNING = [
    (('Medical', 'Clínica médica'), 96, 94, 14, 6, 5),
    (('Surgical', 'Cirúrgica'), 64, 58, 12, 14, 1),
    (('Intensive care', 'UTI'), 20, 20, 2, 2, 1),
    (('Maternity', 'Maternidade'), 32, 21, 9, 7, 0),
    (('Paediatrics', 'Pediatria'), 28, 18, 5, 3, 0),
]

# Admissions for heart failure in 2025, two towns of the hospital's region, by age.
TOWNS = dict(A=dict(young=(40000, 36), old=(12000, 216)),
             Bt=dict(young=(70000, 70), old=(6000, 120)))
STANDARD = (85000, 15000)          # an illustrative standard population of 100,000

# A table a health department might publish: admissions by town and cause, one small town.
SMALL = dict(total=31, shown=(12, 17))


def occupancy():
    rows = [['Ward', 'Beds', 'Patient-days', 'Bed-days', 'Occupancy %']]
    for k, (name, beds, pd) in enumerate(WARDS, start=2):
        rows.append([name[0], beds, pd, f'=B{k}*{DAYS}', f'=ROUND(C{k}/D{k}*100,1)'])
    n = len(WARDS) + 1
    rows.append(['Hospital', f'=SUM(B2:B{n})', f'=SUM(C2:C{n})', f'=SUM(D2:D{n})',
                 f'=ROUND(C{n + 1}/D{n + 1}*100,1)'])
    rows.append(['Discharges', DISCHARGES])
    t = n + 1
    cells = [f'D{k}' for k in range(2, n + 1)] + [f'E{k}' for k in range(2, n + 1)] + \
            [f'B{t}', f'C{t}', f'D{t}', f'E{t}']
    return B.report('lesson 19 — occupancy, length of stay, turnover', rows, cells, [
        f'=ROUND(C{t}/B{t + 1},1)',          # average length of stay
        f'=ROUND(B{t + 1}/B{t},1)',          # bed turnover in the month
        '=ROUND(C4/30,1)',                   # ICU beds occupied on an average night
        '=ROUND(C2/30,1)',
        '=ROUND(B5-C5/30,1)',               # maternity beds empty on an average night
    ])


def waits():
    rows = [['Patient', 'Minutes']] + [[k + 1, w] for k, w in enumerate(WAITS)]
    return B.report('lesson 19 — emergency waits', rows, [], [
        '=AVERAGE(B2:B11)', '=MEDIAN(B2:B11)', '=MAX(B2:B11)', '=B10',
        '=AVERAGE(B2:B10)', '=MEDIAN(B2:B10)'])


def readmissions():
    r = READMIT
    rows = [['Discharges', r['discharges']], ['Died in hospital', r['deaths']],
            ['Readmitted within 30 days', r['readmitted']], ['Of which planned', r['planned']]]
    return B.report('lesson 19 — readmissions three ways', rows, [], [
        '=ROUND(B3/B1*100,1)', '=ROUND((B3-B4)/B1*100,1)', '=ROUND((B3-B4)/(B1-B2)*100,1)'])


def morning():
    rows = [['Ward', 'Beds', 'Occupied', 'Leaving', 'Booked', 'From ED', 'Free tonight']]
    for k, (name, beds, occ, out, booked, ed) in enumerate(MORNING, start=2):
        rows.append([name[0], beds, occ, out, booked, ed, f'=B{k}-C{k}+D{k}-E{k}-F{k}'])
    n = len(MORNING) + 1
    rows.append(['Hospital', f'=SUM(B2:B{n})', f'=SUM(C2:C{n})', f'=SUM(D2:D{n})',
                 f'=SUM(E2:E{n})', f'=SUM(F2:F{n})', f'=SUM(G2:G{n})'])
    cells = [f'G{k}' for k in range(2, n + 2)] + [f'{c}{n + 1}' for c in 'BCDEF']
    return B.report('lesson 19 — the bed manager\'s morning', rows, cells,
                    [f'=B{n + 1}-C{n + 1}'])


def towns():
    a, b = TOWNS['A'], TOWNS['Bt']
    rows = [['Age', 'A people', 'A admissions', 'B people', 'B admissions', 'Standard',
             'A rate', 'B rate'],
            ['Under 65', a['young'][0], a['young'][1], b['young'][0], b['young'][1], STANDARD[0],
             '=ROUND(C2/B2*100000,1)', '=ROUND(E2/D2*100000,1)'],
            ['65 and over', a['old'][0], a['old'][1], b['old'][0], b['old'][1], STANDARD[1],
             '=ROUND(C3/B3*100000,1)', '=ROUND(E3/D3*100000,1)'],
            ['Total', '=SUM(B2:B3)', '=SUM(C2:C3)', '=SUM(D2:D3)', '=SUM(E2:E3)', '=SUM(F2:F3)',
             '=ROUND(C4/B4*100000,1)', '=ROUND(E4/D4*100000,1)']]
    return B.report('lesson 19 — crude and age-adjusted rates', rows,
                    ['B4', 'C4', 'D4', 'E4', 'F4', 'G2', 'G3', 'H2', 'H3', 'G4', 'H4'], [
                        '=ROUND(SUMPRODUCT(G2:G3,F2:F3)/F4,1)',
                        '=ROUND(SUMPRODUCT(H2:H3,F2:F3)/F4,1)',
                        '=ROUND(B3/B4*100,1)', '=ROUND(D3/D4*100,1)',
                        '=ROUND(G4/H4,2)'])


def small_cell():
    rows = [['Total', SMALL['total']], ['Shown 1', SMALL['shown'][0]], ['Shown 2', SMALL['shown'][1]]]
    return B.report('lesson 19 — the suppressed cell, recovered', rows, [], ['=B1-B2-B3'])


# ------------------------------------------------------------------ figures

def occupancy_bars(oc):
    f = B.Fig('l19-occupancy', 720, 300, (
        'Horizontal bars of bed occupancy in November 2025 for five wards against a dashed line at '
        'the hospital average of 85.3%: intensive care 98.5%, medical 95.0%, surgical 87.0%, '
        'paediatrics 64.6%, maternity 62.3%.',
        'Barras horizontais de ocupação de leitos em novembro de 2025 em cinco alas, contra uma '
        'linha tracejada na média do hospital, 85,3%: UTI 98,5%, clínica médica 95,0%, cirúrgica '
        '87,0%, pediatria 64,6%, maternidade 62,3%.'))
    x0, x1 = 170, 640
    sc = (x1 - x0) / 100
    order = [2, 0, 1, 4, 3]
    y = 40
    f.text(x0, 24, ('beds occupied at midnight, average of November 2025',
                    'leitos ocupados à meia-noite, média de novembro de 2025'), size=11,
           fill='--paper-dim')
    for i in order:
        name = WARDS[i][0]
        v = float(oc[f'E{i + 2}'])
        f.text(x0 - 12, y + 22, name, size=12, anchor='end')
        f.bar(x0, y + 6, v * sc, 24, fill='--amber' if v > 90 else '--phosphor')
        f.text(x0 + v * sc + 8, y + 22, (f'{v:.1f}%', f'{B.fmt(v, "pt", 1)}%'), size=12)
        y += 40
    avg = float(oc['E7'])
    ax = x0 + avg * sc
    f.path(f'M{ax:.1f} 34 L{ax:.1f} {y + 4}', stroke='--paper', sw=1.5, dash='5 4')
    f.text(ax, y + 22, (f'hospital {avg:.1f}%', f'hospital {B.fmt(avg, "pt", 1)}%'), size=12,
           anchor='middle')
    f.line(x0, 34, x0, y + 4, stroke='--wire', sw=1)
    f.bar(x0, y + 34, 10, 10, fill='--amber')
    f.text(x0 + 16, y + 44, ('above 90%, where an extra patient has nowhere to go',
                             'acima de 90%, onde um paciente a mais não tem para onde ir'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'The same month by ward. The hospital average sits in a comfortable place, and two wards '
        'are full while two others have a third of their beds empty.',
        'O mesmo mês por ala. A média do hospital fica num lugar confortável, enquanto duas alas '
        'estão cheias e outras duas têm um terço dos leitos vazios.'))


def morning_screen(mo):
    n = len(MORNING) + 2
    order = sorted(range(len(MORNING)), key=lambda i: int(mo[f'G{i + 2}']))
    en_rows = ', '.join(f"{MORNING[i][0][0].lower()} {mo[f'G{i + 2}']}".replace('-', 'minus ') for i in order)
    pt_rows = ', '.join(f"{MORNING[i][0][1].lower() if MORNING[i][0][1] != 'UTI' else 'UTI'} {mo[f'G{i + 2}']}".replace('-', 'menos ') for i in order)
    f = B.Fig('l19-bed-board', 720, 400, (
        f"A mock of the bed manager's screen at 07:00 on Tuesday 2 December 2025. Four tiles: "
        f"{mo[f'F{n}']} patients in the emergency department waiting for a bed, the longest for 9 "
        f"hours 40 minutes; {mo[f'D{n}']} discharges expected today; {mo[f'E{n}']} planned admissions "
        f"booked; intensive care beds free tonight: {mo['G4'].replace('-', 'minus ')}. A table by ward, "
        f"the shortest first, gives beds, occupied, leaving today, booked, from the emergency "
        f"department and free tonight: {en_rows}.",
        f"Maquete da tela da gestora de leitos às 07:00 de terça, 2 de dezembro de 2025. Quatro "
        f"quadros: {mo[f'F{n}']} pacientes no pronto-socorro esperando leito, o mais antigo há 9 horas "
        f"e 40 minutos; {mo[f'D{n}']} altas previstas hoje; {mo[f'E{n}']} internações eletivas "
        f"marcadas; leitos de UTI livres à noite: {mo['G4'].replace('-', 'menos ')}. Uma tabela por "
        f"ala, a mais apertada primeiro, mostra leitos, ocupados, saindo hoje, marcados, vindos do "
        f"pronto-socorro e livres à noite: {pt_rows}."))
    f.rect(10, 10, 700, 380, fill='--ink', stroke='--wire', sw=1)
    f.text(28, 40, ('Beds · Hospital Jacarandá', 'Leitos · Hospital Jacarandá'), size=15, weight=600)
    f.text(692, 34, ('Tue 2 Dec 2025, 07:00', 'ter., 02/12/2025, 07:00'), size=11, anchor='end',
           fill='--paper-dim')
    f.text(692, 50, ('census at 06:45, admissions system', 'censo das 06:45, sistema de internação'),
           size=11, anchor='end', fill='--paper-dim')
    tiles = [
        (mo[f'F{n}'], ('in the ED, waiting for a bed', 'no PS, esperando leito'), '--amber'),
        (mo[f'D{n}'], ('discharges expected today', 'altas previstas hoje'), '--phosphor'),
        (mo[f'E{n}'], ('planned admissions booked', 'eletivas marcadas hoje'), '--phosphor'),
        (mo['G4'], ('ICU beds free tonight', 'leitos de UTI livres à noite'), '--amber'),
    ]
    x = 28
    for big, small, stroke in tiles:
        f.rect(x, 66, 156, 76, fill='--panel', stroke=stroke)
        txt = big.replace('-', '−')
        f.text(x + 12, 100, txt, size=22, weight=600)
        f.text(x + 12, 126, small, size=11, fill='--paper-dim')
        x += 168
    f.text(28 + 12, 157, ('longest ED wait for a bed: 9 h 40 min', 'maior espera no PS por leito: 9 h 40 min'),
           size=11, fill='--paper')
    cols = [(28, 'start', ('ward', 'ala')), (250, 'end', ('beds', 'leitos')),
            (340, 'end', ('occupied', 'ocupados')), (430, 'end', ('leaving', 'saindo')),
            (520, 'end', ('booked', 'marcados')), (600, 'end', ('from ED', 'do PS')),
            (692, 'end', ('free tonight', 'livres à noite'))]
    y = 196
    for cx, anchor, label in cols:
        f.text(cx, y, label, size=11, anchor=anchor, fill='--paper-dim')
    f.line(28, y + 8, 692, y + 8, stroke='--wire', sw=1)
    y += 32
    for i in order:
        name, beds, occ, out, booked, ed = MORNING[i]
        free = int(mo[f'G{i + 2}'])
        if free < 1:
            f.bar(20, y - 12, 4, 16, fill='--amber')
        f.text(28, y, name, size=12)
        for cx, v in zip((250, 340, 430, 520, 600), (beds, occ, out, booked, ed)):
            f.text(cx, y, str(v), size=12, anchor='end', mono=True)
        f.text(692, y, str(free).replace('-', '−'), size=12, anchor='end', mono=True,
               weight=600 if free < 1 else None)
        y += 30
    f.text(28, 376, ('free tonight = beds − occupied + leaving − booked − from ED',
                     'livres à noite = leitos − ocupados + saindo − marcados − do PS'),
           size=11, fill='--paper-dim')
    B.place(LESSON, f, (
        'The bed manager\'s screen answers one question at seven in the morning: where will the '
        'patients waiting in the emergency department sleep tonight? The ward that cannot take '
        'them is the first row.',
        'A tela da gestora de leitos responde a uma pergunta às sete da manhã: onde vão dormir hoje '
        'os pacientes que esperam no pronto-socorro? A ala que não consegue recebê-los é a primeira '
        'linha.'))


def exercises():
    """Numbers the lesson's questions use that the sections do not print."""
    B.report('lesson 19 — exercises', [['Beds', 30], ['Patient-days', 837]], [], [
        '=ROUND(B2/(B1*31)*100,1)',                     # a 30-bed ward in January
        '=ROUND((85000*50+15000*1000)/100000,1)',       # an age-adjusted rate, illustrative
        '=40-21-16',                                    # a suppressed cell recovered
    ])


def main():
    exercises()
    oc = occupancy()
    waits()
    readmissions()
    mo = morning()
    towns()
    small_cell()
    occupancy_bars(oc)
    morning_screen(mo)


if __name__ == '__main__':
    main()
