#!/usr/bin/env python3
"""Every number the statistics course quotes, computed rather than typed.

The course asks nobody to program, and it still quotes a few hundred numbers:
a mean, a standard error, a p-value, the slope of a line. Each of them comes
from this file. The data is the course's own — a small online grocer called
Horta, with invented orders, invented staff and an invented checkout test — and
the larger samples are drawn from a seeded generator, so running this next
year prints the same sheet.

    python3 numbers.py          # the whole sheet
    python3 numbers.py 5        # what lesson 5 quotes

Standard library only. The distributions (normal, t, chi-square, F) are written
out below rather than imported, and were checked against SciPy 1.18.1 when the
course was written; `check()` at the bottom repeats that comparison wherever
SciPy happens to be installed, and says so when it is not.

THE GENERATOR USES `random()` AND NOTHING ELSE. Python promises that `random()`
gives the same sequence for the same seed across versions; it promises nothing
about `gauss`, `choices` or `shuffle`, so the normal draws are Box-Muller over
`random()` and every pick is an index computed from it.
"""
import math
import random
import sys

# ---------------------------------------------------------------- helpers


def mean(xs):
    return sum(xs) / len(xs)


def median(xs):
    s = sorted(xs)
    n = len(s)
    return s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2


def modes(xs):
    counts = {}
    for x in xs:
        counts[x] = counts.get(x, 0) + 1
    top = max(counts.values())
    return sorted(k for k, v in counts.items() if v == top), top


def var(xs, sample=True):
    m = mean(xs)
    return sum((x - m) ** 2 for x in xs) / (len(xs) - (1 if sample else 0))


def sd(xs, sample=True):
    return math.sqrt(var(xs, sample))


def quantile(xs, p):
    """The spreadsheet's QUARTILE.INC and PERCENTILE.INC: position p*(n-1)."""
    s = sorted(xs)
    h = p * (len(s) - 1)
    lo = math.floor(h)
    hi = min(lo + 1, len(s) - 1)
    return s[lo] + (h - lo) * (s[hi] - s[lo])


def quantile_exc(xs, p):
    """QUARTILE.EXC: position p*(n+1), counted from one."""
    s = sorted(xs)
    h = p * (len(s) + 1) - 1
    lo = math.floor(h)
    return s[lo] + (h - lo) * (s[lo + 1] - s[lo])


def skewness(xs):
    """The adjusted sample skewness a spreadsheet's SKEW returns."""
    n, m, s = len(xs), mean(xs), sd(xs)
    return n / ((n - 1) * (n - 2)) * sum(((x - m) / s) ** 3 for x in xs)


def kurtosis(xs):
    """The sample excess kurtosis a spreadsheet's KURT returns."""
    n, m, s = len(xs), mean(xs), sd(xs)
    a = n * (n + 1) / ((n - 1) * (n - 2) * (n - 3))
    b = 3 * (n - 1) ** 2 / ((n - 2) * (n - 3))
    return a * sum(((x - m) / s) ** 4 for x in xs) - b


def ranks(xs):
    """Average ranks, ties sharing the mean of the places they occupy."""
    order = sorted(range(len(xs)), key=lambda i: xs[i])
    r = [0.0] * len(xs)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and xs[order[j + 1]] == xs[order[i]]:
            j += 1
        for k in range(i, j + 1):
            r[order[k]] = (i + j) / 2 + 1
        i = j + 1
    return r


def pearson(xs, ys):
    mx, my = mean(xs), mean(ys)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    sxx = sum((x - mx) ** 2 for x in xs)
    syy = sum((y - my) ** 2 for y in ys)
    return sxy / math.sqrt(sxx * syy)


def spearman(xs, ys):
    return pearson(ranks(xs), ranks(ys))


def line(xs, ys):
    """Least squares: intercept, slope."""
    mx, my = mean(xs), mean(ys)
    b = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sum((x - mx) ** 2 for x in xs)
    return my - b * mx, b


def solve(a, b):
    """Gaussian elimination with partial pivoting, for the normal equations."""
    n = len(a)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(m[r][c]))
        m[c], m[p] = m[p], m[c]
        for r in range(n):
            if r != c:
                f = m[r][c] / m[c][c]
                for k in range(c, n + 1):
                    m[r][k] -= f * m[c][k]
    return [m[i][n] / m[i][i] for i in range(n)]


def ols(rows, ys):
    """Multiple regression. rows are the predictors without the constant."""
    x = [[1.0] + list(r) for r in rows]
    k = len(x[0])
    xtx = [[sum(x[i][a] * x[i][b] for i in range(len(x))) for b in range(k)] for a in range(k)]
    xty = [sum(x[i][a] * ys[i] for i in range(len(x))) for a in range(k)]
    beta = solve(xtx, xty)
    fitted = [sum(b * v for b, v in zip(beta, r)) for r in x]
    ss_res = sum((y - f) ** 2 for y, f in zip(ys, fitted))
    my = mean(ys)
    ss_tot = sum((y - my) ** 2 for y in ys)
    r2 = 1 - ss_res / ss_tot
    n = len(ys)
    adj = 1 - (1 - r2) * (n - 1) / (n - k)
    return beta, r2, adj, fitted


# ------------------------------------------------------- the distributions


def normal_cdf(z):
    return 0.5 * (1 + math.erf(z / math.sqrt(2)))


def normal_pdf(z):
    return math.exp(-z * z / 2) / math.sqrt(2 * math.pi)


def normal_inv(p):
    lo, hi = -10.0, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if normal_cdf(mid) < p:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def _betacf(a, b, x):
    # Lentz's continued fraction for the incomplete beta function.
    tiny = 1e-300
    qab, qap, qam = a + b, a + 1, a - 1
    c, d = 1.0, 1 - qab * x / qap
    d = 1 / (d if abs(d) > tiny else tiny)
    h = d
    for m in range(1, 1000):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1 + aa * d
        d = 1 / (d if abs(d) > tiny else tiny)
        c = 1 + aa / c
        c = c if abs(c) > tiny else tiny
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1 + aa * d
        d = 1 / (d if abs(d) > tiny else tiny)
        c = 1 + aa / c
        c = c if abs(c) > tiny else tiny
        delta = d * c
        h *= delta
        if abs(delta - 1) < 1e-15:
            break
    return h


def betainc(a, b, x):
    """The regularised incomplete beta function I_x(a, b)."""
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    lbeta = math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b)
    front = math.exp(lbeta + a * math.log(x) + b * math.log(1 - x))
    if x < (a + 1) / (a + b + 2):
        return front * _betacf(a, b, x) / a
    return 1 - front * _betacf(b, a, 1 - x) / b


def gammainc(s, x):
    """The regularised lower incomplete gamma function P(s, x)."""
    if x <= 0:
        return 0.0
    if x < s + 1:
        term = total = 1 / s
        k = s
        for _ in range(10000):
            k += 1
            term *= x / k
            total += term
            if abs(term) < abs(total) * 1e-16:
                break
        return total * math.exp(-x + s * math.log(x) - math.lgamma(s))
    # continued fraction for the upper half
    tiny = 1e-300
    b = x + 1 - s
    c = 1 / tiny
    d = 1 / b
    h = d
    for i in range(1, 10000):
        an = -i * (i - s)
        b += 2
        d = an * d + b
        d = 1 / (d if abs(d) > tiny else tiny)
        c = b + an / c
        c = c if abs(c) > tiny else tiny
        delta = d * c
        h *= delta
        if abs(delta - 1) < 1e-16:
            break
    return 1 - math.exp(-x + s * math.log(x) - math.lgamma(s)) * h


def t_cdf(t, df):
    x = df / (df + t * t)
    tail = 0.5 * betainc(df / 2, 0.5, x)
    return 1 - tail if t > 0 else tail


def t_inv(p, df):
    lo, hi = -100.0, 100.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if t_cdf(mid, df) < p:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def chi2_sf(x, df):
    return 1 - gammainc(df / 2, x / 2)


def f_sf(f, d1, d2):
    return betainc(d2 / 2, d1 / 2, d2 / (d2 + d1 * f))


def binom_pmf(k, n, p):
    return math.comb(n, k) * p ** k * (1 - p) ** (n - k)


def poisson_pmf(k, lam):
    return math.exp(-lam) * lam ** k / math.factorial(k)


# ------------------------------------------------------------ the generator


class Draw:
    """Seeded draws built on `random()` alone — see the module's docstring."""

    def __init__(self, seed):
        self.r = random.Random(seed)
        self.spare = None

    def uniform(self, a, b):
        return a + (b - a) * self.r.random()

    def normal(self, mu=0.0, sigma=1.0):
        if self.spare is not None:
            z, self.spare = self.spare, None
            return mu + sigma * z
        u1 = 1.0 - self.r.random()
        u2 = self.r.random()
        rad = math.sqrt(-2 * math.log(u1))
        self.spare = rad * math.sin(2 * math.pi * u2)
        return mu + sigma * rad * math.cos(2 * math.pi * u2)

    def lognormal(self, mu, sigma):
        return math.exp(self.normal(mu, sigma))

    def index(self, n):
        return min(int(self.r.random() * n), n - 1)

    def pick(self, xs):
        return xs[self.index(len(xs))]

    def sample(self, xs, k):
        pool = list(xs)
        out = []
        for _ in range(k):
            out.append(pool.pop(self.index(len(pool))))
        return out


def r2(x):
    return round(x + 0.0, 2)


# ------------------------------------------------------------------- the data

# Twelve of Horta's orders, the table lessons 1 to 3 work from. Written by hand.
ORDERS = [
    # order    neighbourhood    payment items basket  minutes rating postcode   temp
    ('H-1041', 'Cambuí',        'pix',   7,  86.40, 34.5, 5, '13025-320', 27),
    ('H-1042', 'Taquaral',      'card',  3,  31.90, 41.0, 4, '13076-010', 27),
    ('H-1043', 'Barão Geraldo', 'pix',  12, 154.75, 52.5, 3, '13084-180', 28),
    ('H-1044', 'Cambuí',        'cash',  2,  18.50, 29.0, 5, '13025-120', 28),
    ('H-1045', 'Centro',        'card',  5,  62.30, 38.5, 4, '13013-050', 29),
    ('H-1046', 'Taquaral',      'pix',   9, 118.20, 44.0, 2, '13076-210', 29),
    ('H-1047', 'Cambuí',        'pix',   4,  47.80, 31.5, 5, '13024-040', 30),
    ('H-1048', 'Barão Geraldo', 'card', 15, 212.60, 61.0, 4, '13083-300', 30),
    ('H-1049', 'Centro',        'pix',   6,  74.10, 36.0, 4, '13010-110', 26),
    ('H-1050', 'Taquaral',      'card',  1,  12.90, 27.5, 1, '13076-150', 26),
    ('H-1051', 'Cambuí',        'pix',   8,  95.00, 39.0, 5, '13025-200', 25),
    ('H-1052', 'Centro',        'cash',  3,  35.60, 33.0, 3, '13015-020', 25),
]
COL = {name: i for i, name in enumerate(
    ['order', 'neighbourhood', 'payment', 'items', 'basket', 'minutes', 'rating', 'postcode', 'temp'])}


def column(name):
    return [row[COL[name]] for row in ORDERS]


# Horta's monthly pay, in reais, lesson 4. Eight staff and the founder.
SALARIES = [2100, 2100, 2250, 2300, 2400, 2600, 2900, 3400, 28000]

# Two couriers, eight deliveries each, in minutes: lesson 5.
LIA = [33, 34, 35, 35, 35, 36, 36, 36]
DAVI = [22, 26, 31, 35, 38, 40, 44, 44]


# Four hundred baskets from one month, lessons 4 onwards: right-skewed, as money is.
def _baskets():
    d = Draw(400)
    return [round(d.lognormal(4.22, 0.6), 2) for _ in range(400)]


BASKETS = _baskets()


# A hundred and twenty deliveries, thirty per neighbourhood, lessons 6 onwards. Each
# has a distance, a number of items, whether it rained, and the minutes it took.
HOODS = [('Centro', 1.0, 3.0), ('Cambuí', 2.0, 4.5), ('Taquaral', 4.0, 7.0),
         ('Barão Geraldo', 9.0, 14.0)]


def _deliveries():
    d = Draw(120)
    out = []
    for hood, lo, hi in HOODS:
        for _ in range(30):
            km = round(d.uniform(lo, hi), 1)
            items = 1 + d.index(15)
            rain = 1 if d.r.random() < 0.15 else 0
            minutes = 22 + 2.4 * km + 0.35 * items + 7 * rain + d.normal(0, 3.5)
            out.append({'hood': hood, 'km': km, 'items': items, 'rain': rain,
                        'minutes': round(minutes * 2) / 2})
    return out


DELIVERIES = _deliveries()


# Two hundred 1 kg bags of rice from a filling machine, lesson 7: symmetric.
def _bags():
    d = Draw(200)
    return [round(d.normal(1003, 6), 1) for _ in range(200)]


BAGS = _bags()


# A hundred scores on an easy internal test, out of 100, lesson 7: a tail on the left.
def _scores():
    d = Draw(100)
    return [max(0, round(100 - d.lognormal(math.log(12), 0.6))) for _ in range(100)]


SCORES = _scores()


# The time of day of 500 orders, in hours after midnight, lesson 7: lunch and dinner.
def _hours():
    d = Draw(500)
    out = []
    for i in range(500):
        if d.r.random() < 0.45:
            h = d.normal(12.0, 1.1)
        else:
            h = d.normal(19.6, 1.2)
        out.append(round(min(23.99, max(7.0, h)), 2))
    return out


ORDER_HOURS = _hours()


# Complaints received per day over 60 days, lesson 8: drawn from a Poisson with mean 2.4.
def _complaints():
    d = Draw(60)
    out = []
    for _ in range(60):
        limit, k, prod = math.exp(-2.4), 0, d.r.random()
        while prod > limit:
            k += 1
            prod *= d.r.random()
        out.append(k)
    return out


COMPLAINTS = _complaints()


def binom_cdf(k, n, p):
    return sum(binom_pmf(i, n, p) for i in range(k + 1))


def poisson_cdf(k, lam):
    return sum(poisson_pmf(i, lam) for i in range(k + 1))


def five(xs):
    return (min(xs), quantile(xs, 0.25), median(xs), quantile(xs, 0.75), max(xs))


def trimmed(xs, share):
    s = sorted(xs)
    k = int(len(s) * share)
    return mean(s[k:len(s) - k])


# ------------------------------------------------------------------ the sheet

SHEET = {}


def lesson(n):
    def wrap(f):
        SHEET[n] = f
        return f
    return wrap


def show(label, value):
    if isinstance(value, float):
        value = f'{value:.4f}'
    print(f'  {label:<52} {value}')


@lesson(1)
def l1():
    pay = column('payment')
    for k in ['pix', 'card', 'cash']:
        show(f'payment {k}: count, share', f'{pay.count(k)}  {pay.count(k) / len(pay):.4f}')
    hood = column('neighbourhood')
    for k in ['Cambuí', 'Taquaral', 'Barão Geraldo', 'Centro']:
        show(f'neighbourhood {k}: count', hood.count(k))
    show('mean of the postcodes, digits only (meaningless)',
         mean([int(p.replace('-', '')) for p in column('postcode')]))
    show('total basket', sum(column('basket')))


@lesson(2)
def l2():
    ratings = column('rating')
    show('ratings: mean', mean(ratings))
    show('ratings: median', median(ratings))
    show('ratings: counts 1..5', [ratings.count(k) for k in range(1, 6)])
    # temperatures: 27 C against 13.5 C is not "twice as hot"
    show('27 C in kelvin', 27 + 273.15)
    show('13.5 C in kelvin', 13.5 + 273.15)
    show('ratio of the kelvins', (27 + 273.15) / (13.5 + 273.15))
    show('27 C in fahrenheit', 27 * 9 / 5 + 32)
    show('13.5 C in fahrenheit', 13.5 * 9 / 5 + 32)
    # payment coded 1=pix 2=card 3=cash, and averaged anyway
    code = {'pix': 1, 'card': 2, 'cash': 3}
    show('mean of the payment codes (meaningless)', mean([code[p] for p in column('payment')]))


@lesson(3)
def l3():
    for name in ['minutes', 'basket', 'items', 'rating']:
        xs = column(name)
        show(f'{name}: sum', sum(xs))
        show(f'{name}: mean', mean(xs))
        show(f'{name}: median', median(xs))
        show(f'{name}: sorted', sorted(xs))
        show(f'{name}: modes, count', modes(xs))
    show('payment: modes, count', modes(column('payment')))
    # two stores, averaged wrongly and rightly
    show('store A 300 orders mean 80, store B 100 orders mean 40: weighted', (300 * 80 + 100 * 40) / 400)
    show('the same, unweighted', (80 + 40) / 2)
    # a frequency table of items per order, lesson 3's grouped mean
    freq = {1: 14, 2: 22, 3: 31, 4: 18, 5: 9, 6: 6}
    n = sum(freq.values())
    show('frequency table n', n)
    show('frequency table mean', sum(k * v for k, v in freq.items()) / n)
    cum = 0
    for k in sorted(freq):
        cum += freq[k]
        show(f'cumulative count to {k}', cum)


@lesson(4)
def l4():
    show('salaries: mean', mean(SALARIES))
    show('salaries: median', median(SALARIES))
    show('salaries without the founder: mean', mean(SALARIES[:-1]))
    show('salaries without the founder: median', median(SALARIES[:-1]))
    show('staff below the mean', sum(1 for s in SALARIES if s < mean(SALARIES)))
    show('payroll total', sum(SALARIES))
    show('mean x 9', mean(SALARIES) * 9)
    cut = sorted(SALARIES)[1:-1]
    show('trimmed mean, one off each end', mean(cut))
    show('median x 9', median(SALARIES) * 9)
    b = BASKETS
    show('400 baskets: mean', mean(b))
    show('400 baskets: median', median(b))
    show('400 baskets: min, max', f'{min(b)}  {max(b)}')
    show('400 baskets: share below the mean', sum(1 for x in b if x < mean(b)) / len(b))
    show('400 baskets: 10% trimmed mean', trimmed(b, 0.10))
    show('400 baskets: 5% trimmed mean', trimmed(b, 0.05))
    show('400 baskets: total', sum(b))
    show('400 baskets: top 10% share of total', sum(sorted(b)[-40:]) / sum(b))
    show('400 baskets: count above 200', sum(1 for x in b if x > 200))
    # the typo: 212.60 typed as 2126.00 in the twelve
    twelve = column('basket')
    typo = [2126.00 if x == 212.60 else x for x in twelve]
    show('twelve baskets with the typo: mean', mean(typo))
    show('twelve baskets with the typo: median', median(typo))
    show('twelve baskets: mean', mean(twelve))


@lesson(5)
def l5():
    for name, xs in (('Lia', LIA), ('Davi', DAVI)):
        m = mean(xs)
        show(f'{name}: mean', m)
        show(f'{name}: range', max(xs) - min(xs))
        show(f'{name}: deviations', [x - m for x in xs])
        show(f'{name}: squared deviations', [(x - m) ** 2 for x in xs])
        show(f'{name}: sum of squares', sum((x - m) ** 2 for x in xs))
        show(f'{name}: sample variance', var(xs))
        show(f'{name}: sample sd', sd(xs))
        show(f'{name}: population variance', var(xs, False))
        show(f'{name}: population sd', sd(xs, False))
        show(f'{name}: mean absolute deviation', mean([abs(x - m) for x in xs]))
        show(f'{name}: share within one sd of the mean', sum(1 for x in xs if abs(x - m) <= sd(xs)) / len(xs))
    mins = column('minutes')
    show('twelve minutes: sd', sd(mins))
    show('twelve minutes: range', max(mins) - min(mins))
    show('twelve minutes: within one sd', sum(1 for x in mins if abs(x - mean(mins)) <= sd(mins)))
    bk = column('basket')
    show('twelve baskets: sd', sd(bk))
    show('twelve baskets: cv', sd(bk) / mean(bk))
    show('twelve minutes: cv', sd(mins) / mean(mins))
    items = column('items')
    show('twelve items: mean, sd, cv', f'{mean(items):.4f} {sd(items):.4f} {sd(items) / mean(items):.4f}')
    b = BASKETS
    show('400 baskets: sd', sd(b))
    show('400 baskets: cv', sd(b) / mean(b))
    show('400 baskets: within one sd of the mean', sum(1 for x in b if abs(x - mean(b)) <= sd(b)) / len(b))
    # Bessel, on a population of three, every ordered sample of two drawn with replacement
    pop = [30, 35, 43]
    show('population of three: mean', mean(pop))
    show('population of three: variance', var(pop, False))
    pairs = [(a, b) for a in pop for b in pop]
    show('samples of two: mean of the n-1 variances', mean([var(list(q)) for q in pairs]))
    show('samples of two: mean of the n variances', mean([var(list(q), False) for q in pairs]))


@lesson(6)
def l6():
    mins = column('minutes')
    show('twelve minutes sorted', sorted(mins))
    show('Q1, Q3 inclusive', f'{quantile(mins, .25)}  {quantile(mins, .75)}')
    show('Q1, Q3 exclusive', f'{quantile_exc(mins, .25)}  {quantile_exc(mins, .75)}')
    lo, hi = sorted(mins)[:6], sorted(mins)[6:]
    show('Q1, Q3 median of halves', f'{median(lo)}  {median(hi)}')
    q1, q3 = quantile(mins, .25), quantile(mins, .75)
    iqr = q3 - q1
    show('IQR inclusive', iqr)
    show('fences', f'{q1 - 1.5 * iqr}  {q3 + 1.5 * iqr}')
    show('90th percentile inclusive', quantile(mins, .9))
    show('share at or below 44', sum(1 for x in mins if x <= 44) / 12)
    b = BASKETS
    show('400 baskets five', [round(v, 2) for v in five(b)])
    bq1, bq3 = quantile(b, .25), quantile(b, .75)
    show('400 baskets IQR', bq3 - bq1)
    show('400 baskets upper fence', bq3 + 1.5 * (bq3 - bq1))
    show('400 baskets beyond upper fence', sum(1 for x in b if x > bq3 + 1.5 * (bq3 - bq1)))
    show('400 baskets largest within fence', max(x for x in b if x <= bq3 + 1.5 * (bq3 - bq1)))
    show('400 baskets 90th, 95th percentile', f'{quantile(b, .9):.4f}  {quantile(b, .95):.4f}')
    show('400 baskets sd', sd(b))
    for hood, _, _ in HOODS:
        xs = [r['minutes'] for r in DELIVERIES if r['hood'] == hood]
        f = five(xs)
        q1, q3 = f[1], f[3]
        out = [x for x in xs if x > q3 + 1.5 * (q3 - q1) or x < q1 - 1.5 * (q3 - q1)]
        show(f'{hood}: five, IQR, outliers', f'{[round(v, 3) for v in f]}  {q3 - q1:.3f}  {out}')
        show(f'{hood}: mean, sd', f'{mean(xs):.3f} {sd(xs):.3f}')


@lesson(7)
def l7():
    for name, xs in (('bags', BAGS), ('baskets', BASKETS), ('scores', SCORES)):
        m, md, s_ = mean(xs), median(xs), sd(xs)
        show(f'{name}: n, min, max', f'{len(xs)}  {min(xs)}  {max(xs)}')
        show(f'{name}: mean, median, sd', f'{m:.4f}  {md:.4f}  {s_:.4f}')
        show(f'{name}: skewness (SKEW)', skewness(xs))
        show(f'{name}: excess kurtosis (KURT)', kurtosis(xs))
        show(f'{name}: Pearson median skewness 3(mean-median)/sd', 3 * (m - md) / s_)
    allm = [r['minutes'] for r in DELIVERIES]
    show('120 deliveries: five', five(allm))
    show('120 deliveries: mean, sd', f'{mean(allm):.4f} {sd(allm):.4f}')
    show('120 deliveries: skew, kurt', f'{skewness(allm):.4f} {kurtosis(allm):.4f}')
    edges = list(range(20, 72, 4))
    counts = [sum(1 for x in allm if edges[i] <= x < edges[i + 1]) for i in range(len(edges) - 1)]
    show('120 deliveries: counts in 4-minute bins from 20', counts)
    h = ORDER_HOURS
    show('order hours: min, max', f'{min(h)} {max(h)}')
    show('order hours: mean, median', f'{mean(h):.4f} {median(h):.4f}')
    show('order hours: five', [round(v, 2) for v in five(h)])
    show('order hours: counts per hour 7..23', [sum(1 for x in h if k <= x < k + 1) for k in range(7, 24)])
    show('order hours: between 15 and 16', sum(1 for x in h if 15 <= x < 16))
    show('order hours: skew, kurt', f'{skewness(h):.4f} {kurtosis(h):.4f}')


@lesson(8)
def l8():
    # uniform: a courier arrives at a random moment between 18:00 and 18:30
    show('uniform 0..30: P(wait > 20)', 10 / 30)
    show('uniform 0..30: mean, sd', f'{15} {30 / math.sqrt(12):.4f}')
    # binomial: 10 deliveries, each late with probability 0.15
    n, p = 10, 0.15
    for k in range(0, 6):
        show(f'binomial(10, 0.15): P(X = {k})', binom_pmf(k, n, p))
    show('binomial: P(X >= 3)', 1 - binom_cdf(2, n, p))
    show('binomial: P(X <= 2)', binom_cdf(2, n, p))
    show('binomial: mean, sd', f'{n * p:.4f} {math.sqrt(n * p * (1 - p)):.4f}')
    show('C(10, 2)', math.comb(10, 2))
    # poisson: complaints per day, mean 2.4
    lam = 2.4
    for k in range(0, 9):
        show(f'poisson(2.4): P(X = {k})', poisson_pmf(k, lam))
    show('poisson: P(X >= 5)', 1 - poisson_cdf(4, lam))
    show('poisson: P(X = 0) over a week of 7 days (rate 16.8)', poisson_pmf(0, 16.8))
    c = COMPLAINTS
    show('60 days: counts 0..8', [c.count(k) for k in range(9)])
    show('60 days: expected counts 0..8', [round(60 * poisson_pmf(k, lam), 2) for k in range(9)])
    show('60 days: mean, variance', f'{mean(c):.4f} {var(c):.4f}')
    show('60 days: max', max(c))
    # normal: bags with mean 1003 and sd 6
    mu, sg = 1003, 6
    show('normal: within 1, 2, 3 sd', f'{normal_cdf(1) - normal_cdf(-1):.4f} {normal_cdf(2) - normal_cdf(-2):.4f} '
         f'{normal_cdf(3) - normal_cdf(-3):.4f}')
    show('bags: z of 995', (995 - mu) / sg)
    show('bags: P(bag < 995)', normal_cdf((995 - mu) / sg))
    show('bags: P(bag > 1015)', 1 - normal_cdf((1015 - mu) / sg))
    show('bags: weight that 99% exceed', mu + sg * normal_inv(0.01))
    show('bags: z for 1%', normal_inv(0.01))
    show('bags: observed share < 995 in the 200', sum(1 for x in BAGS if x < 995) / 200)
    show('bags: observed within 1 sd of the sample mean', sum(1 for x in BAGS if abs(x - mean(BAGS)) <= sd(BAGS)) / 200)
    show('z of a 52-minute delivery with mean 38.96 and sd 9.77', (52 - 38.96) / 9.77)


def mad(xs):
    m = median(xs)
    return median([abs(x - m) for x in xs])


def robust_z(x, xs):
    return 0.6745 * (x - median(xs)) / mad(xs)


@lesson(9)
def l9():
    twelve = column('basket')
    typo = [2126.00 if x == 212.60 else x for x in twelve]
    m, s_ = mean(typo), sd(typo)
    show('typo: mean, sd', f'{m:.4f} {s_:.4f}')
    show('typo: z of 2126.00', (2126 - m) / s_)
    show('typo: largest other z', max((x - m) / s_ for x in typo if x != 2126))
    show('max possible z with n = 12, (n-1)/sqrt(n)', 11 / math.sqrt(12))
    show('max possible z with n = 10', 9 / math.sqrt(10))
    two = [2126.00 if x == 212.60 else 1547.50 if x == 154.75 else x for x in twelve]
    m2, s2 = mean(two), sd(two)
    show('two typos: mean, sd', f'{m2:.4f} {s2:.4f}')
    show('two typos: z of 2126.00, 1547.50', f'{(2126 - m2) / s2:.4f} {(1547.5 - m2) / s2:.4f}')
    show('two typos: median, MAD', f'{median(two):.4f} {mad(two):.4f}')
    show('two typos: robust z of 2126.00, 1547.50', f'{robust_z(2126, two):.4f} {robust_z(1547.5, two):.4f}')
    show('two typos: robust z of 95.00 and 12.90', f'{robust_z(95.0, two):.4f} {robust_z(12.9, two):.4f}')
    show('twelve correct: median, MAD', f'{median(twelve):.4f} {mad(twelve):.4f}')
    show('twelve correct: robust z of 212.60', robust_z(212.6, twelve))
    show('twelve correct: z of 212.60', (212.6 - mean(twelve)) / sd(twelve))
    show('two typos: abs deviations sorted', sorted(round(abs(x - median(two)), 2) for x in two))
    b = BASKETS
    p95 = quantile(b, 0.95)
    w = [min(x, p95) for x in b]
    show('400: 95th percentile', p95)
    show('400: winsorised at the 95th: mean', mean(w))
    show('400: mean without the 17 beyond the fence', mean([x for x in b if x <= quantile(b, .75) + 1.5 * (quantile(b, .75) - quantile(b, .25))]))
    show('400: count |z| > 3', sum(1 for x in b if abs(x - mean(b)) / sd(b) > 3))
    show('400: robust z > 3.5 count', sum(1 for x in b if robust_z(x, b) > 3.5))
    show('400: median, MAD', f'{median(b):.4f} {mad(b):.4f}')
    show('400: three largest', sorted(b)[-3:])


@lesson(10)
def l10():
    b = BASKETS
    show('400 baskets as a population: mean, sd (population)', f'{mean(b):.4f} {sd(b, False):.4f}')
    d = Draw(1010)
    three = [mean(d.sample(b, 40)) for _ in range(3)]
    show('three random samples of 40: means', [round(x, 2) for x in three])
    means = [mean(d.sample(b, 40)) for _ in range(1000)]
    show('1000 samples of 40: mean of the means, sd of the means', f'{mean(means):.4f} {sd(means):.4f}')
    show('1000 samples of 40: min, max of the means', f'{min(means):.2f} {max(means):.2f}')
    # stratified against simple random, on the 120 deliveries
    allm = [r['minutes'] for r in DELIVERIES]
    show('120 deliveries: population mean', mean(allm))
    groups = {h: [r['minutes'] for r in DELIVERIES if r['hood'] == h] for h, _, _ in HOODS}
    d2 = Draw(1011)
    srs = [mean(d2.sample(allm, 20)) for _ in range(1000)]
    strat = []
    for _ in range(1000):
        pick = []
        for h in groups:
            pick += d2.sample(groups[h], 5)
        strat.append(mean(pick))
    show('SRS of 20: sd of the sample means', sd(srs))
    show('stratified 5 per neighbourhood: sd of the sample means', sd(strat))
    show('SRS of 20: share of means more than 3 minutes off', sum(1 for x in srs if abs(x - mean(allm)) > 3) / 1000)
    show('stratified: share of means more than 3 minutes off', sum(1 for x in strat if abs(x - mean(allm)) > 3) / 1000)
    # cluster: pick 1 neighbourhood at random and take 20 of its deliveries
    clus = []
    hoods = list(groups)
    for _ in range(1000):
        h = d2.pick(hoods)
        clus.append(mean(d2.sample(groups[h], 20)))
    show('cluster, one neighbourhood: sd of the sample means', sd(clus))
    # convenience: the 20 deliveries nearest the warehouse (Centro and Cambuí only)
    near = groups['Centro'] + groups['Cambuí']
    show('convenience, Centro and Cambuí only: mean', mean(near))
    conv = [mean(d2.sample(near, 20)) for _ in range(1000)]
    show('convenience samples of 20: mean of the means', mean(conv))
    # bigger convenience samples do not fix bias
    show('all 60 near deliveries: mean (bias stays)', mean(near))


def main():
    picked = [int(a) for a in sys.argv[1:]] or sorted(SHEET)
    for n in picked:
        print(f'lesson {n}')
        SHEET[n]()
        print()


if __name__ == '__main__':
    main()
