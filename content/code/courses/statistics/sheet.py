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


def main():
    picked = [int(a) for a in sys.argv[1:]] or sorted(SHEET)
    for n in picked:
        print(f'lesson {n}')
        SHEET[n]()
        print()


if __name__ == '__main__':
    main()
