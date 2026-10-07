#!/usr/bin/env python3
"""Every number the process-management course quotes, computed rather than typed.

The course runs no software of its own. Its practice is a pencil, a board and a
spreadsheet, and it still quotes a few hundred numbers: a cycle time, a PERT
mean, a velocity range, an earned-value index, a change failure rate. Each one
comes from this file. The data belongs to the course's own example — the
Agenda team at Ponte Saúde, an invented company building an appointment app
for physiotherapy clinics — and nothing here is random, so running it next
year prints the same sheet.

    python3 sheet.py          # the whole sheet
    python3 sheet.py 9        # what lesson 9 quotes

`workbook.py` beside this file puts the same data into LibreOffice Calc and
prints what the spreadsheet formulas return; the lessons quote those values
where they show a formula.

Standard library only.
"""
import datetime as dt
import math
import sys

# ---------------------------------------------------------------- helpers


def mean(xs):
    return sum(xs) / len(xs)


def median(xs):
    s = sorted(xs)
    n = len(s)
    return s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2


def percentile_inc(xs, p):
    """The spreadsheet's PERCENTILE.INC: linear between ranks, position p*(n-1)."""
    s = sorted(xs)
    pos = p * (len(s) - 1)
    lo = math.floor(pos)
    hi = min(lo + 1, len(s) - 1)
    return s[lo] + (pos - lo) * (s[hi] - s[lo])


# ------------------------------------------------------- lesson 2: a sprint

SPRINT_DAYS = 10
SPRINT_COMMITTED = 34
# Points still open at the end of each day, day 0 being the morning of planning.
BURNDOWN = [34, 34, 31, 31, 26, 23, 23, 18, 13, 8, 5]

# ------------------------------------------------- lesson 3: twenty finished items
# (item, started, finished) — calendar days, both ends counted, as the board
# records them. The finishing dates fall in the four weeks from 2 March 2026.

FINISHED = [
    ('AG-101', '2026-03-02', '2026-03-03'),
    ('AG-104', '2026-02-26', '2026-03-04'),
    ('AG-097', '2026-02-27', '2026-03-05'),
    ('AG-108', '2026-03-04', '2026-03-06'),
    ('AG-110', '2026-03-07', '2026-03-09'),
    ('AG-095', '2026-02-21', '2026-03-10'),
    ('AG-112', '2026-03-09', '2026-03-11'),
    ('AG-106', '2026-03-03', '2026-03-12'),
    ('AG-099', '2026-02-22', '2026-03-12'),
    ('AG-109', '2026-03-05', '2026-03-13'),
    ('AG-115', '2026-03-13', '2026-03-17'),
    ('AG-113', '2026-03-12', '2026-03-18'),
    ('AG-102', '2026-03-05', '2026-03-19'),
    ('AG-117', '2026-03-16', '2026-03-20'),
    ('AG-111', '2026-03-10', '2026-03-20'),
    ('AG-119', '2026-03-19', '2026-03-23'),
    ('AG-114', '2026-03-18', '2026-03-24'),
    ('AG-118', '2026-03-20', '2026-03-25'),
    ('AG-116', '2026-03-17', '2026-03-26'),
    ('AG-120', '2026-03-25', '2026-03-27'),
]
WINDOW = ('2026-03-02', '2026-03-29')   # four whole weeks, Monday to Sunday


def day(s):
    return dt.date.fromisoformat(s)


def cycle_times():
    return [(day(f) - day(s)).days + 1 for _, s, f in FINISHED]


def weekly_throughput():
    start = day(WINDOW[0])
    weeks = [0, 0, 0, 0]
    for _, _, f in FINISHED:
        weeks[(day(f) - start).days // 7] += 1
    return weeks


# The board on the morning of 16 March: columns, their limits and the cards in them.
BOARD = [
    ('Ready', 5, 4),
    ('Developing', 3, 3),
    ('Review', 2, 2),
    ('Testing', 2, 1),
    ('Done', None, 10),
]

# ---------------------------------------------------- lesson 5: talking to people


def paths(n):
    return n * (n - 1) // 2


# ------------------------------------------- lesson 6: critical path and earned value
# activity: (duration in days, predecessors)
ACTIVITIES = {
    'A': (3, []),          # agree the booking rules with two clinics
    'B': (5, ['A']),       # build the slots API
    'C': (2, ['A']),       # design the booking screens
    'D': (4, ['C']),       # build the booking screens
    'E': (3, ['B', 'D']),  # integrate and test end to end
    'F': (2, ['E']),       # pilot in one clinic
}


def cpm():
    order = ['A', 'B', 'C', 'D', 'E', 'F']
    es, ef = {}, {}
    for a in order:
        d, pre = ACTIVITIES[a]
        es[a] = max([ef[p] for p in pre], default=0)
        ef[a] = es[a] + d
    end = max(ef.values())
    ls, lf = {}, {}
    for a in reversed(order):
        d, _ = ACTIVITIES[a]
        succ = [s for s in order if a in ACTIVITIES[s][1]]
        lf[a] = min([ls[s] for s in succ], default=end)
        ls[a] = lf[a] - d
    slack = {a: ls[a] - es[a] for a in order}
    return es, ef, ls, lf, slack, end


EVM = {'BAC': 200_000, 'PV': 120_000, 'EV': 100_000, 'AC': 125_000}

# ------------------------------------------------- lesson 8: a service level
SLA = {'availability': 0.995, 'hours_a_day': 14, 'days': 30}   # booking, 7:00 to 21:00


def priority(impact, urgency):
    """ITIL-style matrix: 1 high, 2 medium, 3 low on each axis; 1 is the most urgent."""
    return impact + urgency - 1


# ----------------------------------------------- lesson 9: estimating a feature
# task: (optimistic, most likely, pessimistic), working days
TASKS = {
    'slots API': (3, 5, 13),
    'booking screen': (2, 4, 8),
    'payment integration': (3, 6, 20),
    'notifications': (1, 2, 5),
}


def pert(o, m, p):
    return (o + 4 * m + p) / 6, (p - o) / 6


def triangular(o, m, p):
    return (o + m + p) / 3


ANALOGY = {'past': 18, 'factor': 1.2}           # clinic onboarding took 18 days
PARAMETRIC = {'screens_done': 40, 'days_spent': 128, 'screens_new': 7}

# --------------------------------------------------- lesson 10: velocity
VELOCITY = [21, 28, 24, 31, 19, 26, 27, 24]
BACKLOG_POINTS = 150

# ------------------------------------------------------- lesson 11: risk
# (risk, probability, impact in working days; a negative impact is an opportunity)
RISKS = [
    ('payment provider changes its API', 0.30, 10),
    ('the one developer who knows billing leaves', 0.10, 20),
    ('clinic data needs cleaning before migration', 0.50, 6),
    ('the app store rejects the first release', 0.20, 5),
    ('an existing calendar library fits as it is', 0.40, -4),
]
# Positions on the 5x5 matrix: (probability level, impact level), 1..5
MATRIX = [(2, 4), (1, 5), (3, 3), (2, 2)]

# -------------------------------------------------- lesson 12: prioritising
# feature: (business value, time criticality, risk reduction, job size)
WSJF = {
    'online booking': (13, 8, 3, 13),
    'SMS reminders': (8, 5, 1, 3),
    'database upgrade': (1, 8, 13, 5),
    'reports for clinic owners': (8, 2, 2, 8),
}
# feature: (reach per quarter, impact, confidence, effort in person-months)
RICE = {
    'SMS reminders': (4000, 1, 0.8, 1),
    'online booking': (2500, 3, 0.5, 4),
    'reports for clinic owners': (300, 2, 0.8, 2),
}

# -------------------------------------------------- lesson 13: four weeks of deploys
# Hours from a change's commit to its deployment, for the 24 deploys between
# 2 and 27 March 2026, and which deploys failed in production.
LEAD_HOURS = [3, 5, 26, 4, 7, 22, 6, 2, 30, 8, 5, 4,
              49, 6, 3, 21, 9, 4, 27, 5, 7, 70, 6, 4]
FAILED = {5: 45, 13: 180, 20: 50}   # deploy index -> minutes to restore
WORKING_DAYS = 20

# ------------------------------------------------- lesson 14: the interest on debt
DEBT = {
    'flaky test suite': {'devs': 5, 'hours_per_day': 0.5, 'days': 10, 'fix': 60},
    'manual deploy': {'per_deploy': 3, 'deploys': 2, 'fix': 40},
}


# ------------------------------------------------------------------- printing

def lesson2():
    print('sprint: committed', SPRINT_COMMITTED, 'points over', SPRINT_DAYS, 'days')
    print('  left at the end:', BURNDOWN[-1], '; done:', SPRINT_COMMITTED - BURNDOWN[-1])
    print('  ideal line drops', SPRINT_COMMITTED / SPRINT_DAYS, 'a day')
    flat = [i for i in range(1, len(BURNDOWN)) if BURNDOWN[i] == BURNDOWN[i - 1]]
    print('  days with no movement:', flat)


def lesson3():
    ct = cycle_times()
    print('cycle times:', ct)
    print('  sorted:', sorted(ct))
    print('  n', len(ct), 'mean', mean(ct), 'median', median(ct))
    for p in (0.5, 0.7, 0.85, 0.95):
        print(f'  P{int(p * 100)}', round(percentile_inc(ct, p), 2))
    print('  at or under 13 days:', sum(1 for c in ct if c <= 13), 'of', len(ct))
    print('  max', max(ct), 'min', min(ct))
    wk = weekly_throughput()
    print('  throughput per week:', wk, 'total', sum(wk), 'mean', mean(wk))
    print('  board:', BOARD, 'cards in progress',
          sum(c for name, _, c in BOARD if name not in ('Ready', 'Done')))


def lesson5():
    for n in (3, 6, 9, 12, 50, 125):
        print(f'  {n} people: {paths(n)} paths')


def lesson6():
    es, ef, ls, lf, slack, end = cpm()
    for a in ACTIVITIES:
        print(f'  {a} d={ACTIVITIES[a][0]} ES={es[a]} EF={ef[a]} LS={ls[a]} LF={lf[a]} slack={slack[a]}')
    print('  project length', end, 'critical', [a for a in ACTIVITIES if slack[a] == 0])
    e = EVM
    cpi, spi = e['EV'] / e['AC'], e['EV'] / e['PV']
    print('  EVM', e)
    print('  CV', e['EV'] - e['AC'], 'SV', e['EV'] - e['PV'])
    print('  CPI', cpi, 'SPI', round(spi, 4), 'EAC', e['BAC'] / cpi, 'VAC', e['BAC'] - e['BAC'] / cpi)
    print('  ETC', e['BAC'] / cpi - e['AC'], 'percent complete', e['EV'] / e['BAC'])


def lesson8():
    a = SLA
    window = a['hours_a_day'] * a['days']
    allowed = window * (1 - a['availability'])
    print(f"  booking window {window} hours a month; {a['availability']:.1%} allows "
          f"{allowed:.2f} hours = {allowed * 60:.0f} minutes down")
    names = {1: 'high', 2: 'medium', 3: 'low'}
    for i in (1, 2, 3):
        print('  impact', names[i], [f'urgency {names[u]}: P{priority(i, u)}' for u in (1, 2, 3)])


def lesson9():
    tm, tv, tri, mm, pp, oo = 0, 0, 0, 0, 0, 0
    for k, (o, m, p) in TASKS.items():
        mu, sd = pert(o, m, p)
        print(f'  {k}: O={o} M={m} P={p} PERT mean={mu:.3f} sd={sd:.3f} var={sd * sd:.3f} '
              f'triangular={triangular(o, m, p):.3f}')
        tm += mu; tv += sd * sd; tri += triangular(o, m, p); mm += m; pp += p; oo += o
    sd = math.sqrt(tv)
    print(f'  total PERT mean {tm:.3f}, variance {tv:.4f}, sd {sd:.4f}; '
          f'the sds added directly {sum(pert(*v)[1] for v in TASKS.values()):.3f}')
    print(f'  sum of most-likely {mm}, sum of optimistic {oo}, sum of pessimistic {pp}, triangular sum {tri:.3f}')
    print(f'  mean + 1 sd {tm + sd:.2f}; mean + 1.04 sd (about P85) {tm + 1.04 * sd:.2f}; '
          f'mean + 2 sd {tm + 2 * sd:.2f}')
    print('  analogy', round(ANALOGY['past'] * ANALOGY['factor'], 2))
    r = PARAMETRIC['days_spent'] / PARAMETRIC['screens_done']
    print('  parametric rate', r, 'days a screen; new feature', round(r * PARAMETRIC['screens_new'], 2))


def lesson10():
    v = VELOCITY
    print('  velocity', v, 'sum', sum(v), 'mean', mean(v), 'median', median(v), 'min', min(v), 'max', max(v))
    last6 = v[-6:]
    print('  last six', last6, 'min', min(last6), 'max', max(last6), 'mean', round(mean(last6), 4),
          '; the backlog over that mean', round(BACKLOG_POINTS / mean(last6), 4))
    for label, x in (('mean', mean(v)), ('slowest', min(v)), ('fastest', max(v))):
        print(f'  {BACKLOG_POINTS} points at {x}: {BACKLOG_POINTS / x:.2f} sprints, '
              f'ceiling {math.ceil(BACKLOG_POINTS / x)}')
    for lo, hi in ((min(last6), max(last6)),):
        print(f'  range from last six: {math.ceil(BACKLOG_POINTS / hi)} to {math.ceil(BACKLOG_POINTS / lo)} sprints')


def lesson11():
    threats = 0
    for name, p, i in RISKS:
        print(f'  {name}: p={p} impact={i} EMV={p * i:.2f}')
        if i > 0:
            threats += p * i
    net = sum(p * i for _, p, i in RISKS)
    print(f'  threats EMV {threats:.2f}, net with the opportunity {net:.2f}')
    for (pl, il) in MATRIX:
        print('  matrix score', pl, 'x', il, '=', pl * il)
    print('  chance none of the four threats happens',
          round(math.prod(1 - p for _, p, i in RISKS if i > 0), 4))


def lesson12():
    rows = []
    for k, (bv, tc, rr, size) in WSJF.items():
        cod = bv + tc + rr
        rows.append((cod / size, k, cod, size))
        print(f'  {k}: CoD={cod} size={size} WSJF={cod / size:.2f}')
    print('  order:', [k for _, k, _, _ in sorted(rows, reverse=True)])
    for k, (r, i, c, e) in RICE.items():
        print(f'  RICE {k}: {r}*{i}*{c}/{e} = {r * i * c / e}')


def lesson13():
    ct = cycle_times()
    wk = weekly_throughput()
    days = (day(WINDOW[1]) - day(WINDOW[0])).days + 1
    rate = len(FINISHED) / days
    print('  Little: throughput', len(FINISHED), 'in', days, 'days =', round(rate, 4),
          'a day; mean cycle time', mean(ct), '; implied average WIP', round(rate * mean(ct), 3))
    print('  with 4 items in progress at that throughput, mean cycle time', round(4 / rate, 2), 'days')
    n = len(LEAD_HOURS)
    print('  deploys', n, 'over', WORKING_DAYS, 'working days =', n / WORKING_DAYS, 'a day,', n / 4, 'a week')
    print('  lead time for changes: median', median(LEAD_HOURS), 'hours; mean', round(mean(LEAD_HOURS), 2),
          '; P85', round(percentile_inc(LEAD_HOURS, 0.85), 2), '; max', max(LEAD_HOURS))
    print('  over 24 hours:', sum(1 for h in LEAD_HOURS if h > 24))
    print('  change failure rate', len(FAILED), '/', n, '=', len(FAILED) / n)
    rest = sorted(FAILED.values())
    print('  restore minutes', rest, 'median', median(rest), 'mean', round(mean(rest), 2))
    print('  weekly throughput again', wk)


def lesson14():
    d = DEBT['flaky test suite']
    per = d['devs'] * d['hours_per_day'] * d['days']
    print('  flaky suite: interest', per, 'hours a sprint; fix', d['fix'], '; payback', d['fix'] / per, 'sprints')
    m = DEBT['manual deploy']
    per2 = m['per_deploy'] * m['deploys']
    print('  manual deploy: interest', per2, 'hours a sprint; fix', m['fix'], '; payback', round(m['fix'] / per2, 3), 'sprints')
    print('  ten sprints of interest:', per * 10, 'and', per2 * 10)


LESSONS = {2: lesson2, 3: lesson3, 5: lesson5, 6: lesson6, 8: lesson8, 9: lesson9, 10: lesson10,
           11: lesson11, 12: lesson12, 13: lesson13, 14: lesson14}

if __name__ == '__main__':
    want = [int(a) for a in sys.argv[1:]] or sorted(LESSONS)
    for n in want:
        print(f'--- lesson {n}')
        LESSONS[n]()
