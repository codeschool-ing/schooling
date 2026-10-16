---
title: Choosing from your own users
version: 1
---

**Your analytics already know which phones your users have, and the matrix starts there.** Every
analytics tool an app carries records the device model, its maker and its Android version with each
session. Google Play Console shows the same for every install. Exported, it is a table of
devices and how much they were used. What you want from it is the shortest list of values that
covers most of the use. A short script answers that for any column.

## The export

Real exports have more columns and many more rows. This one is small enough to read, and **its
numbers are invented for this lesson.** They have the shape of a Brazilian app's audience, many
Samsung, Motorola and Xiaomi phones in the middle of the price range, and nothing more. Make a
folder `matrix` in your boxoffice project and save it as `matrix/sessions.csv`:

```
maker,model,android,sessions
Samsung,Galaxy A15,14,18400
Samsung,Galaxy A05s,14,9100
Motorola,Moto G24,14,8700
Xiaomi,Redmi Note 13,14,7600
Samsung,Galaxy A54,15,6200
Xiaomi,Redmi 13C,14,5400
Motorola,Moto G84,14,5100
Samsung,Galaxy A32,13,4800
Motorola,Moto E13,13,4300
Motorola,Moto G22,12,3900
Samsung,Galaxy S23,15,2900
Xiaomi,Redmi 9A,11,2100
Xiaomi,Poco X6,15,1800
Realme,C53,13,1500
Google,Pixel 7a,15,900
LG,K62,11,600
```

## The script

It reads the export and adds up the sessions for each value of the column you name. It sorts them
from the most used, and prints the running share until a target you choose, 90% unless you say
otherwise. Save it as `matrix/coverage.mjs`:

```js
// matrix/coverage.mjs: which values of one column cover most of the sessions
import { readFileSync } from 'node:fs';

const column = process.argv[2] ?? 'android';
const target = Number(process.argv[3] ?? 90);

const text = readFileSync(new URL('./sessions.csv', import.meta.url), 'utf8');
const [header, ...lines] = text.trim().split('\n');
const names = header.split(',');
if (!names.includes(column)) {
  console.error(`no column "${column}"; the columns are ${names.join(', ')}`);
  process.exit(2);
}

const totals = new Map();
let all = 0;
for (const line of lines) {
  const row = Object.fromEntries(line.split(',').map((v, i) => [names[i], v]));
  const n = Number(row.sessions);
  totals.set(row[column], (totals.get(row[column]) ?? 0) + n);
  all += n;
}

const pct = (n) => `${((n * 100) / all).toFixed(1).padStart(6)}%`;
let sum = 0;
let picked = 0;
console.log(`${column.padEnd(16)}sessions    share  running`);
for (const [value, n] of [...totals].sort((a, b) => b[1] - a[1])) {
  const needed = sum * 100 < target * all;
  sum += n;
  if (needed) picked++;
  const mark = needed && sum * 100 >= target * all ? `  <- ${target}% reached` : '';
  console.log(`${value.padEnd(16)}${String(n).padStart(8)}  ${pct(n)}  ${pct(sum)}${mark}`);
}
console.log(`${picked} of ${totals.size} values cover ${target}% of ${all} sessions`);
```

## Android versions

```
ana@laptop:~/boxoffice$ node matrix/coverage.mjs android
android         sessions    share  running
14                 54300    65.2%    65.2%
15                 11800    14.2%    79.4%
13                 10600    12.7%    92.1%  <- 90% reached
12                  3900     4.7%    96.8%
11                  2700     3.2%   100.0%
3 of 5 values cover 90% of 83300 sessions
```

**Three versions out of five cover 92.1% of the sessions**, which is past the 90% asked for. Android
14 alone is 65.2%. The 3.2% on Android 11 is two old models. They do not go away: they go to the long tail, tested
less often and in a device cloud.

## Makers

```
ana@laptop:~/boxoffice$ node matrix/coverage.mjs maker
maker           sessions    share  running
Samsung            41400    49.7%    49.7%
Motorola           22000    26.4%    76.1%
Xiaomi             16900    20.3%    96.4%  <- 90% reached
Realme              1500     1.8%    98.2%
Google               900     1.1%    99.3%
LG                   600     0.7%   100.0%
3 of 6 values cover 90% of 83300 sessions
```

Three makers cover 96.4%. A matrix with Samsung, Motorola and Xiaomi in it reaches nearly everyone
this app has. Google's own Pixel, the phone the emulator imitates most closely, is 1.1% here.

## Models

```
ana@laptop:~/boxoffice$ node matrix/coverage.mjs model
model           sessions    share  running
Galaxy A15         18400    22.1%    22.1%
Galaxy A05s         9100    10.9%    33.0%
Moto G24            8700    10.4%    43.5%
Redmi Note 13       7600     9.1%    52.6%
Galaxy A54          6200     7.4%    60.0%
Redmi 13C           5400     6.5%    66.5%
Moto G84            5100     6.1%    72.6%
Galaxy A32          4800     5.8%    78.4%
Moto E13            4300     5.2%    83.6%
Moto G22            3900     4.7%    88.2%
Galaxy S23          2900     3.5%    91.7%  <- 90% reached
Redmi 9A            2100     2.5%    94.2%
Poco X6             1800     2.2%    96.4%
C53                 1500     1.8%    98.2%
Pixel 7a             900     1.1%    99.3%
K62                  600     0.7%   100.0%
11 of 16 values cover 90% of 83300 sessions
```

**Models are where the tail is long.** Eleven of the sixteen are needed to reach 90%, and a real
export would have hundreds, each a fraction of a percent. No team owns eleven phones for one app.
That is why lesson 19's shelf holds two or three chosen ones, and why the models section 05 rents
are picked from this list, from the top down.

## Reading it as a tester

- Pick a target before you look, 90% or 95%, and write it in the test plan. A target chosen
  after seeing the numbers tends to land wherever the list was convenient to stop.
- Run it again every few months. Phones are replaced, and the version that was 65% this year is the
  long tail in three.
- Check the oldest version separately. The minimum SDK the app declares is a promise to those
  users too, however few. A crash there is a defect whatever its share.
