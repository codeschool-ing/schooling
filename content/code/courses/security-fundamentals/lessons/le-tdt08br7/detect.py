import csv
import sys
from collections import Counter

threshold = int(sys.argv[1])
ignored = set(sys.argv[2:])

failures = Counter()
for row in csv.DictReader(open('logins.csv')):
    if row['result'] == 'fail' and row['user'] not in ignored:
        window = row['time'][:15]
        failures[(row['source'], window)] += 1

red = set(open('red-team-sources.txt').read().split())
tp = fp = fn = tn = 0
for (source, window), count in failures.items():
    alert = count >= threshold
    attack = source in red
    if alert and attack:
        tp += 1
    elif alert:
        fp += 1
    elif attack:
        fn += 1
    else:
        tn += 1

print(f'threshold {threshold}: {tp + fp} alerts')
print(f'  TP {tp:3}   FP {fp:3}')
print(f'  FN {fn:3}   TN {tn:3}')
print(f'precision {tp / (tp + fp):.0%}   recall {tp / (tp + fn):.0%}')
