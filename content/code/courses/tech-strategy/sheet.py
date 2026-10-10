#!/usr/bin/env python3
"""Every number the tech-strategy course quotes, computed rather than typed.

The course runs no software of its own. Its practice is a text editor and a
spreadsheet, and it still quotes a few hundred numbers: a debt's interest per
sprint, a payback in sprints, a three-year comparison, a total cost of
ownership, an expected switching cost, a unit cost, a cost of delay. Each one
comes from this file. The data belongs to the course's own example — Coreto,
an invented São Paulo company selling a ticketing platform to theatres,
concert halls and festivals — and nothing here is random, so running it next
year prints the same sheet.

    python3 sheet.py          # the whole sheet
    python3 sheet.py 5        # what lesson 5 quotes

`workbook.py` beside this file puts the same data into LibreOffice Calc and
prints what the spreadsheet formulas return; the lessons quote those values
where they show a formula.

Money is Brazilian reais. Standard library only.
"""
import sys

# ------------------------------------------------------------ the company

ENGINEERS = 52
TEAMS = ['Checkout', 'Box Office', 'Catalogue', 'Payments', 'Platform', 'Data', 'Mobile']
HOUR = 150                 # loaded cost of one engineer-hour, R$
FTE_HOURS = 1760           # working hours in an engineer-year
FTE_YEAR = HOUR * FTE_HOURS
SPRINT_WEEKS = 2
SPRINTS_A_YEAR = 26
TICKETS_A_MONTH = 410_000
CLOUD_A_MONTH = 212_000

# ------------------------------------------------- lesson 5: four debts
# (name, principal hours to pay it off, interest hours paid every sprint)

DEBTS = [
    ('Seat-hold locking in the reservation module', 320, 31),
    ('Hand-rolled PDF ticket generator', 120, 6),
    ('Flaky end-to-end suite', 80, 14),
    ('Old reporting replica', 200, 4),
]
# The seat-hold debt grows: every sprint, code built on top of it adds this
# many hours to the interest.
GROWTH = 2

# ------------------------------------------- lesson 6: the rewrite proposal

REWRITE_ENGINEERS = 6
REWRITE_MONTHS = 18
MONTH_HOURS = 160
REWRITE_INTEREST_SAVED = 120     # hours a sprint the rewrite would save, at best
OVERRUN = 1.5                    # a rewrite that takes half as long again

# --------------------------------------- lesson 7: the strangler, by month
# Share of reservation traffic served by the new service at the end of each
# month of the migration.

STRANGLER = [0, 5, 12, 25, 40, 58, 71, 83, 90, 94, 97, 99, 100]

# --------------------------------------- lesson 8: search, three years out

def build_search():
    y1 = 960 * HOUR + 0.25 * FTE_YEAR + 3_000 * 12
    later = 0.25 * FTE_YEAR + 3_000 * 12
    return [y1, later, later]


def buy_search():
    licence = [9_000 * 12 * (1.10 ** k) for k in range(3)]
    operate = 0.05 * FTE_YEAR
    return [licence[0] + 240 * HOUR + operate, licence[1] + operate, licence[2] + operate]


def adopt_search():
    y = 6_500 * 12 + 0.30 * FTE_YEAR + 80 * HOUR
    return [y + 480 * HOUR, y, y]

# --------------------------------- lesson 9: observability, hosted or not

HOSTS = 60
PER_HOST = 90
LOG_GB = 900
PER_GB = 2.50


def hosted_obs():
    licence = (HOSTS * PER_HOST + LOG_GB * PER_GB) * 12
    return {'licence': licence * 3, 'integration': 320 * HOUR,
            'operation': 0.10 * FTE_YEAR * 3,
            'exit': 280 * HOUR + (HOSTS * PER_HOST + LOG_GB * PER_GB)}


def selfhosted_obs():
    return {'licence': 4_200 * 12 * 3, 'integration': 0,
            'operation': 0.60 * FTE_YEAR * 3, 'exit': 0}

# ------------------------------------------- lesson 10: two lock-ins
# (name, switching hours, probability of switching in three years,
#  portability hours up front, portability hours a year after that)

LOCKINS = [
    ('Managed document database', 1_400, 0.10, 300, 40),
    ('Payment gateway', 900, 0.35, 160, 0),
]

# ----------------------------------------- lesson 11: the year's budget

BUDGET = [
    ('People', ENGINEERS * FTE_YEAR),
    ('Cloud', CLOUD_A_MONTH * 12),
    ('Licences and SaaS', 61_000 * 12),
    ('Tooling', 380_000),
]

# -------------------------------------------------- lesson 12: the bill

NEXT_CLOUD = 236_000
NEXT_TICKETS = 520_000
SHOWBACK = [('Checkout', 58_000), ('Catalogue', 41_000), ('Box Office', 27_000),
            ('Data', 35_000), ('Platform', 22_000), ('Untagged', 29_000)]
IDLE_STAGING = 9_800

# ----------------------------------------- lesson 13: four candidates
# (name, cost of delay a week in R$, duration in weeks)

CANDIDATES = [
    ('Festival seat maps', 30_000, 6),
    ('Pix in instalments', 48_000, 12),
    ('Seat-hold fix', 18_000, 3),
    ('Partner API', 12_000, 4),
]

# ------------------------------------- lesson 14 and 15: adoption counts

TEMPLATE_NEW = 26
TEMPLATE_USED = 18
PORTAL_HOURS = 1_100
PORTAL_SERVICES = 41
PORTAL_USED = 3

# ------------------------------------------- lesson 19: a team's sprint

TEAM = 6
SPRINT_DAYS = 10
FOCUS_HOURS = 6
REQUEST_HOURS = 90

# ------------------------------------------- lesson 20: the on-sale risk

BIG_ONSALES = 12
FAIL_P = 0.08
LOSS_PER_FAILURE = 380_000


def brl(x):
    return f'R$ {x:,.0f}'


def lesson(n):
    out = []
    p = out.append
    if n == 5:
        for name, pr, it in DEBTS:
            p(f'{name}: principal {pr} h ({brl(pr * HOUR)}), interest {it} h a sprint '
              f'({brl(it * HOUR)}), {it * SPRINTS_A_YEAR} h a year ({brl(it * SPRINTS_A_YEAR * HOUR)}), '
              f'payback {pr / it:.1f} sprints')
        total = sum(it for _, _, it in DEBTS)
        p(f'all four: interest {total} h a sprint, {brl(total * HOUR)}; '
          f'principal {sum(pr for _, pr, _ in DEBTS)} h')
        pr, it = DEBTS[0][1], DEBTS[0][2]
        cum = 0
        for k in range(1, 15):
            cum += it + GROWTH * (k - 1)
            p(f'  seat-hold, growing by {GROWTH} h: after sprint {k:2} paid {cum} h '
              f'(interest that sprint {it + GROWTH * (k - 1)})')
        p(f'  flat: crosses the principal after sprint {-(-pr // it)}')
    if n == 6:
        h = REWRITE_ENGINEERS * REWRITE_MONTHS * MONTH_HOURS
        p(f'rewrite: {h} h, {brl(h * HOUR)}')
        saved = REWRITE_INTEREST_SAVED * HOUR
        p(f'saves {brl(saved)} a sprint; payback {h / REWRITE_INTEREST_SAVED:.0f} sprints, '
          f'{h / REWRITE_INTEREST_SAVED / SPRINTS_A_YEAR:.1f} years after it ships')
        h2 = h * OVERRUN
        p(f'with a {OVERRUN}x overrun: {h2:.0f} h, {brl(h2 * HOUR)}, '
          f'{REWRITE_MONTHS * OVERRUN:.0f} months, payback '
          f'{h2 / REWRITE_INTEREST_SAVED / SPRINTS_A_YEAR:.1f} years')
    if n == 7:
        for m, s in enumerate(STRANGLER):
            p(f'month {m:2}: {s}% new')
        first = next(m for m, s in enumerate(STRANGLER) if s >= 90)
        p(f'90% reached at month {first}; the last 10% took {len(STRANGLER) - 1 - first} more months')
    if n == 8:
        for name, f in (('build', build_search), ('buy', buy_search), ('adopt', adopt_search)):
            ys = f()
            p(f'{name}: ' + ', '.join(brl(y) for y in ys) + f'; three years {brl(sum(ys))}')
        b4 = sum(build_search()) + build_search()[2]
        lic4 = 9_000 * 12 * 1.10 ** 3
        u4 = sum(buy_search()) + lic4 + 0.05 * FTE_YEAR
        p(f'a fourth year: buy licence {brl(lic4)}; four years build {brl(b4)}, buy {brl(u4)}')
        gap = sum(build_search()) - sum(buy_search())
        p(f'the three-year gap {brl(gap)} is {gap / HOUR:.0f} engineer-hours')
    if n == 9:
        for name, f in (('hosted', hosted_obs), ('self-hosted', selfhosted_obs)):
            d = f()
            p(f'{name}: ' + ', '.join(f'{k} {brl(v)}' for k, v in d.items()) +
              f'; TCO {brl(sum(d.values()))}')
        h, s = hosted_obs(), selfhosted_obs()
        p(f'monthly hosted licence {brl((HOSTS * PER_HOST + LOG_GB * PER_GB))}')
        p(f'licence-only: hosted {brl(h["licence"])} against self-hosted {brl(s["licence"])}')
        rest = sum(h.values()) - s['licence'] - s['integration'] - s['exit']
        p(f'self-hosting wins below {rest / HOUR / 3:.0f} h a year of operation '
          f'({100 * rest / HOUR / 3 / FTE_HOURS:.0f}% of an engineer)')
    if n == 10:
        for name, sw, prob, up, yr in LOCKINS:
            exp = sw * HOUR * prob
            port = (up + 3 * yr) * HOUR
            p(f'{name}: switching {brl(sw * HOUR)}, expected {brl(exp)}; portability '
              f'{brl(port)} over three years -> {"pay for portability" if port < exp else "accept the lock-in"}; '
              f'break-even probability {100 * port / (sw * HOUR):.1f}%')
    if n == 11:
        total = sum(v for _, v in BUDGET)
        for name, v in BUDGET:
            p(f'{name}: {brl(v)} ({100 * v / total:.1f}%)')
        p(f'total {brl(total)}; 10% is {brl(total / 10)} = {total / 10 / FTE_YEAR:.1f} engineers '
          f'= {100 * total / 10 / BUDGET[1][1]:.0f}% of the cloud')
    if n == 12:
        p(f'unit cost now {CLOUD_A_MONTH / TICKETS_A_MONTH:.3f}, next {NEXT_CLOUD / NEXT_TICKETS:.3f}')
        p(f'bill +{100 * (NEXT_CLOUD / CLOUD_A_MONTH - 1):.1f}%, unit '
          f'{100 * ((NEXT_CLOUD / NEXT_TICKETS) / (CLOUD_A_MONTH / TICKETS_A_MONTH) - 1):.1f}%')
        tot = sum(v for _, v in SHOWBACK)
        un = dict(SHOWBACK)['Untagged']
        p(f'showback total {brl(tot)}, untagged {100 * un / tot:.1f}%')
        tagged = tot - un
        for name, v in SHOWBACK[:-1]:
            p(f'  {name}: {brl(v)} -> with its share {brl(v + un * v / tagged)}')
        p(f'idle staging a year {brl(IDLE_STAGING * 12)}')
    if n == 13:
        for name, cod, d in CANDIDATES:
            p(f'{name}: CD3 {cod / d:,.0f}')
        orders = {
            'CD3': sorted(CANDIDATES, key=lambda c: -c[1] / c[2]),
            'highest cost of delay': sorted(CANDIDATES, key=lambda c: -c[1]),
            'shortest first': sorted(CANDIDATES, key=lambda c: c[2]),
        }
        for label, order in orders.items():
            t = cost = 0
            for name, cod, d in order:
                t += d
                cost += cod * t
            p(f'{label}: ' + ' > '.join(c[0] for c in order) + f'; delay cost {brl(cost)}')
    if n == 14:
        p(f'template: {TEMPLATE_USED} of {TEMPLATE_NEW} = {100 * TEMPLATE_USED / TEMPLATE_NEW:.0f}%')
    if n == 15:
        p(f'portal: {brl(PORTAL_HOURS * HOUR)}; {PORTAL_USED} of {PORTAL_SERVICES} = '
          f'{100 * PORTAL_USED / PORTAL_SERVICES:.0f}%')
    if n == 19:
        cap = TEAM * SPRINT_DAYS * FOCUS_HOURS
        p(f'capacity {cap} h; request {REQUEST_HOURS} h = {100 * REQUEST_HOURS / cap:.0f}%')
    if n == 20:
        exp = BIG_ONSALES * FAIL_P * LOSS_PER_FAILURE
        p(f'expected failures a year {BIG_ONSALES * FAIL_P:.2f}; expected loss {brl(exp)}')
        fix = DEBTS[0][1] * HOUR
        p(f'seat-hold fix {brl(fix)}; ratio {exp / fix:.1f}')
    return out


if __name__ == '__main__':
    want = [int(a) for a in sys.argv[1:]] or [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 19, 20]
    for n in want:
        print(f'--- lesson {n}')
        for line in lesson(n):
            print('  ' + line)
