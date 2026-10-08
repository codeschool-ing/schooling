# prazo.py START N: the date N business days after START, skipping weekends and the holidays listed
import datetime as dt
import sys

HOLIDAYS = {  # national holidays from September 2026; add the state's and the city's before relying on it
    dt.date(2026, 9, 7), dt.date(2026, 10, 12), dt.date(2026, 11, 2),
    dt.date(2026, 11, 15), dt.date(2026, 11, 20), dt.date(2026, 12, 25),
}


def add_business_days(start, n):
    day = start
    while n > 0:
        day += dt.timedelta(days=1)  # the start day itself never counts
        if day.weekday() < 5 and day not in HOLIDAYS:
            n -= 1
    return day


start = dt.date.fromisoformat(sys.argv[1])
n = int(sys.argv[2])
print(f"{n} business days after {start:%a %d %b %Y}: {add_business_days(start, n):%a %d %b %Y}")
