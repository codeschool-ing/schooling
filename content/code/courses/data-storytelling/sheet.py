#!/usr/bin/env python3
"""Every number the data-storytelling course quotes, computed rather than typed.

The course teaches what to do with an analysis once it exists, so it needs one
analysis to carry from the first lesson to the last. This is it: Faro, an
invented pet-food subscription in the state of São Paulo, and the finding its
analyst has to get a room to act on — new subscribers whose FIRST delivery
arrives late cancel far more often in their first ninety days.

The data is the course's own and invented. The counts are drawn from a seeded
generator, so running this next year prints the same sheet, and every rate,
ratio and amount in the prose and the figures is computed here from those
counts. The student gets the same table as `faro.csv` in lesson 1 and can
rebuild every number in a spreadsheet; `lab.sh` does exactly that in
LibreOffice and prints what the spreadsheet says.

    python3 sheet.py           # the whole sheet
    python3 sheet.py --csv     # the table lesson 1 hands the student

Standard library only. THE GENERATOR USES `random()` AND NOTHING ELSE: Python
promises the same sequence for the same seed across versions for `random()`,
and promises nothing about `gauss`, `choices` or `shuffle`.
"""
import random
import sys

SEED = 20250701
MONTHS = ['2025-01', '2025-02', '2025-03', '2025-04', '2025-05', '2025-06']
REGIONS = ['capital', 'interior']

# What the generator aims at. The sheet below never quotes these: it quotes
# what the drawn counts give, which is what a spreadsheet would give too.
NEW_PER_MONTH = {'capital': 640, 'interior': 400}
LATE_SHARE = {'capital': 0.13, 'interior': 0.25}
CANCEL_90 = {('capital', 'on time'): 0.165, ('capital', 'late'): 0.39,
             ('interior', 'on time'): 0.21, ('interior', 'late'): 0.44}

PRICE_CENTS = 18990          # the average monthly box, R$ 189.90
MARGIN_BP = 3100             # gross margin after food and shipping, 31.00%
CAC_CENTS = 15200            # what marketing pays to win one subscriber
MONTHLY_CHURN_AFTER_90 = 0.04  # once past ninety days, 4% leave each month
BOXES_BEFORE_CANCEL = 1.6    # an early canceller pays this many boxes on average
RENEWAL_DELIVERIES = 126_400  # renewal boxes shipped in the half-year
RENEWAL_ON_TIME = 0.951
SURVEY_RESPONSE = 0.23       # share of early cancellers answering the exit survey
PILOT_LATE_TARGET = 0.08     # the pilot's aim for late first deliveries
EXPRESS_EXTRA_CENTS = 900    # Ligeiro's express service, extra per first box


def draw():
    """The 24 rows of faro.csv: cohort, region, first delivery, counts."""
    rnd = random.Random(SEED)

    def jitter(x, spread):
        return x * (1 + spread * (2 * rnd.random() - 1))

    rows = []
    for m in MONTHS:
        for r in REGIONS:
            n = round(jitter(NEW_PER_MONTH[r], 0.08))
            late = round(n * jitter(LATE_SHARE[r], 0.12))
            for status, k in (('on time', n - late), ('late', late)):
                c = round(k * jitter(CANCEL_90[(r, status)], 0.10))
                rows.append({'cohort': m, 'region': r, 'first_delivery': status,
                             'subscribers': k, 'cancelled_90d': c})
    return rows


ROWS = draw()


def total(key, **where):
    return sum(row[key] for row in ROWS
               if all(row[k] == v for k, v in where.items()))


def rate(**where):
    return total('cancelled_90d', **where) / total('subscribers', **where)


def pct(x, d=1):
    return round(100 * x, d)


def brl(cents):
    """R$ 1,234.56 in the English style; lessons write the Portuguese by hand."""
    return f'R$ {cents / 100:,.2f}'


# ---------------------------------------------------------------- the finding

NEW = total('subscribers')
LATE = total('subscribers', first_delivery='late')
ON_TIME = NEW - LATE
CANCELLED = total('cancelled_90d')
LATE_SHARE_ALL = LATE / NEW
FIRST_ON_TIME = ON_TIME / NEW
RATE_LATE = rate(first_delivery='late')
RATE_ON = rate(first_delivery='on time')
RATE_ALL = CANCELLED / NEW
RATIO = RATE_LATE / RATE_ON

# The objection lesson 10 anticipates: is it the region rather than the delay?
BY_REGION = {r: {'new': total('subscribers', region=r),
                 'late_share': total('subscribers', region=r, first_delivery='late')
                 / total('subscribers', region=r),
                 'late': rate(region=r, first_delivery='late'),
                 'on time': rate(region=r, first_delivery='on time'),
                 'all': rate(region=r)}
             for r in REGIONS}

# The KPI the logistics team reports, and why it hides the finding.
RENEWAL_LATE = round(RENEWAL_DELIVERIES * (1 - RENEWAL_ON_TIME))
ALL_DELIVERIES = RENEWAL_DELIVERIES + NEW
ALL_ON_TIME = (RENEWAL_DELIVERIES - RENEWAL_LATE + ON_TIME) / ALL_DELIVERIES
FIRST_SHARE_OF_DELIVERIES = NEW / ALL_DELIVERIES

# ------------------------------------------------------------- the money side

MARGIN = MARGIN_BP / 10000
LIFETIME_MONTHS = 3 + 1 / MONTHLY_CHURN_AFTER_90           # a subscriber past 90 days
MARGIN_PER_BOX = round(PRICE_CENTS * MARGIN)               # cents
LTV_SURVIVOR = round(PRICE_CENTS * MARGIN * LIFETIME_MONTHS)  # cents
LTV_EARLY = round(PRICE_CENTS * MARGIN * BOXES_BEFORE_CANCEL)  # cents
LOSS_PER_EARLY_CANCEL = LTV_SURVIVOR - LTV_EARLY
EXCESS_CANCELS = round(LATE * (RATE_LATE - RATE_ON))       # half-year, if late ones behaved
EXCESS_PER_YEAR = 2 * EXCESS_CANCELS
LOSS_PER_YEAR = EXCESS_PER_YEAR * LOSS_PER_EARLY_CANCEL    # cents
CAC_WASTED_PER_YEAR = EXCESS_PER_YEAR * CAC_CENTS          # acquisition paid for nothing

# What the pilot would buy if late first deliveries fell to the target.
AVOIDED_PER_YEAR = round(2 * NEW * (LATE_SHARE_ALL - PILOT_LATE_TARGET)
                         * (RATE_LATE - RATE_ON))
GAIN_PER_YEAR = AVOIDED_PER_YEAR * LOSS_PER_EARLY_CANCEL
# A range rather than a point: half the effect and the whole of it.
GAIN_LOW = GAIN_PER_YEAR // 2
GAIN_HIGH = GAIN_PER_YEAR

# The alternative lesson 9 prices: every first box by express, for a year.
EXPRESS_PER_YEAR = 2 * NEW * EXPRESS_EXTRA_CENTS           # cents

# ---------------------------------------------------------- the exit survey

EARLY_CANCELLERS = CANCELLED
SURVEY_ANSWERS = round(EARLY_CANCELLERS * SURVEY_RESPONSE)
# What the answers said, as shares of those who answered.
SURVEY_REASONS = [('price', 0.38), ('the pet refused the food', 0.19),
                  ('delivery', 0.17), ('moved to a shop', 0.14), ('other', 0.12)]


def weekly_first_on_time():
    """26 weeks of the first-delivery on-time rate, for the dashboard lesson."""
    rnd = random.Random(SEED + 7)
    out = []
    for w in range(26):
        out.append(round(100 * (FIRST_ON_TIME + 0.025 * (2 * rnd.random() - 1)), 1))
    return out


WEEKLY_FIRST = weekly_first_on_time()


def weekly_all_on_time():
    rnd = random.Random(SEED + 11)
    return [round(100 * (ALL_ON_TIME + 0.006 * (2 * rnd.random() - 1)), 1) for _ in range(26)]


WEEKLY_ALL = weekly_all_on_time()


def csv():
    lines = ['cohort,region,first_delivery,subscribers,cancelled_90d']
    for row in ROWS:
        lines.append(f"{row['cohort']},{row['region']},{row['first_delivery']},"
                     f"{row['subscribers']},{row['cancelled_90d']}")
    return '\n'.join(lines)


def main():
    if '--csv' in sys.argv:
        print(csv())
        return
    p = print
    p(f'new subscribers, H1 2025      {NEW}')
    p(f'  first delivery late         {LATE}  ({pct(LATE_SHARE_ALL)}%)')
    p(f'  first delivery on time      {ON_TIME}  ({pct(FIRST_ON_TIME)}%)')
    p(f'cancelled within 90 days      {CANCELLED}  ({pct(RATE_ALL)}%)')
    p(f'  late first delivery         {pct(RATE_LATE)}%')
    p(f'  on-time first delivery      {pct(RATE_ON)}%')
    p(f'  ratio                       {RATIO:.2f}')
    p(f'  gap, points                 {pct(RATE_LATE) - pct(RATE_ON):.1f}')
    for r in REGIONS:
        b = BY_REGION[r]
        p(f'{r:9} new {b["new"]}  late share {pct(b["late_share"])}%  '
          f'cancel late {pct(b["late"])}%  on time {pct(b["on time"])}%  all {pct(b["all"])}%')
    p(f'renewal deliveries            {RENEWAL_DELIVERIES}  late {RENEWAL_LATE}')
    p(f'all deliveries                {ALL_DELIVERIES}  on time {pct(ALL_ON_TIME)}%')
    p(f'first deliveries share        {pct(FIRST_SHARE_OF_DELIVERIES, 2)}%')
    p(f'price {brl(PRICE_CENTS)}  margin {MARGIN_BP / 100:.2f}%  per box {brl(MARGIN_PER_BOX)}')
    p(f'lifetime months (survivor)    {LIFETIME_MONTHS:.1f}')
    p(f'LTV survivor {brl(LTV_SURVIVOR)}  early {brl(LTV_EARLY)}  loss each {brl(LOSS_PER_EARLY_CANCEL)}')
    p(f'LTV/CAC survivor              {LTV_SURVIVOR / CAC_CENTS:.1f}')
    p(f'excess cancels, half-year     {EXCESS_CANCELS}  per year {EXCESS_PER_YEAR}')
    p(f'margin lost per year          {brl(LOSS_PER_YEAR)}')
    p(f'CAC wasted per year           {brl(CAC_WASTED_PER_YEAR)}')
    p(f'pilot: avoided per year       {AVOIDED_PER_YEAR}  gain {brl(GAIN_LOW)} to {brl(GAIN_HIGH)}')
    p(f'express for every first box, a year: {brl(EXPRESS_PER_YEAR)}')
    p(f'survey: cancellers {EARLY_CANCELLERS}  answers {SURVEY_ANSWERS}')
    p(f'weekly first on-time          {WEEKLY_FIRST}')
    p(f'  min {min(WEEKLY_FIRST)} max {max(WEEKLY_FIRST)}')
    p(f'weekly all on-time            {WEEKLY_ALL}')
    p(f'  min {min(WEEKLY_ALL)} max {max(WEEKLY_ALL)}')


if __name__ == '__main__':
    main()
