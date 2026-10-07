#!/usr/bin/env python3
"""Simulate ten thousand years of the risks in risks.csv, from their 90% ranges."""
import csv
import math
import random

YEARS = 10_000
rng = random.Random(2026)   # a fixed seed: the same years on every run


def lognormal(low, high):
    """A lognormal whose 5th and 95th percentiles are low and high."""
    mu = (math.log(low) + math.log(high)) / 2
    sigma = (math.log(high) - math.log(low)) / (2 * 1.645)
    return rng.lognormvariate(mu, sigma)


def events(rate):
    """How many events happen in one year, at an average of rate per year."""
    n, p, limit = 0, rng.random(), math.exp(-rate)
    while p > limit:
        n, p = n + 1, p * rng.random()
    return n


risks = list(csv.DictReader(open("risks.csv")))
years = []
for _ in range(YEARS):
    year = {}
    for r in risks:
        n = events(lognormal(float(r["per_year_low"]), float(r["per_year_high"])))
        year[r["id"]] = sum(lognormal(float(r["loss_low"]), float(r["loss_high"])) for _ in range(n))
    years.append(year)


def percentile(values, p):
    return sorted(values)[int(p * len(values))]


print(f"{'':4} {'mean R$':>10} {'any loss':>9} {'1 year in 10':>13} {'1 in 100':>11}")
for r in risks:
    v = [y[r["id"]] for y in years]
    print(f"{r['id']:4} {sum(v) / YEARS:10,.0f} {sum(x > 0 for x in v) / YEARS:9.1%} "
          f"{percentile(v, 0.9):13,.0f} {percentile(v, 0.99):11,.0f}")
total = [sum(y.values()) for y in years]
print(f"{'all':4} {sum(total) / YEARS:10,.0f} {sum(x > 0 for x in total) / YEARS:9.1%} "
      f"{percentile(total, 0.9):13,.0f} {percentile(total, 0.99):11,.0f}")

print("\nchance that one year's total loss is more than")
for limit in (100_000, 250_000, 500_000, 1_000_000):
    print(f"  R$ {limit:>9,}  {sum(x > limit for x in total) / YEARS:6.1%}")
