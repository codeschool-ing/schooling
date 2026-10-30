---
title: What it costs, and what reaches you
version: 1
---

**There are two kinds of cost, and only the first is small: the fee for the account, and the share
of every sale the store keeps.** A price you set is not what you receive, and the sum is worth
doing before the price is chosen.

## The accounts

| | Google Play | Apple |
|---|---|---|
| the account | a one-off registration fee of 25 US dollars | 99 US dollars per membership year, or the local price |
| renewal | none | every year; a lapsed membership takes the apps out of the store |
| waivers | none | for non-profits, accredited schools and government bodies that qualify |

*Apple's figure is from its enrolment page, October 2026. Google's is the figure its help centre
gave in 2025, which the recording machine could not reach; the console shows the price before it
charges.*

## The share of each sale

Both stores keep a **commission** on the digital goods they sell for you: the app's price, an
in-app purchase, a subscription. Apple's is 30%, and 15% for developers in its Small Business
Program, which is open to anybody whose proceeds were up to one million US dollars in the previous
calendar year, and for subscriptions after their first year. Google's service fee is 15% on the
first million US dollars of earnings each year and on subscriptions. **Proceeds** is what is left:
the price, minus the tax the store collects in the buyer's country, minus the commission.

Neither store takes a share of a free app, and neither takes a share of physical goods or of a
service used outside the app, such as a taxi ride booked in it.

## The sum, as a script

Money is counted in **whole cents**, never as a fraction of a dollar: `0.1 + 0.2` is not `0.3` in
floating point, and a store's report is in cents. Save this as `proceeds.ts`:

```schooling-example
{"language": "typescript", "file": "proceeds.ts", "parts": [{"code": "// proceeds.ts: what a price leaves after the store's commission, and how many sales pay for the accounts\nconst priceCents = Number(process.argv[2] ?? 1999);\nconst accountsCents = 99_00 + 25_00;", "note": "The price comes in as cents: `1999` is 19.99. The accounts are Apple's first year plus Google's one-off fee, in cents too."}, {"code": "function money(cents: number): string {\n  return (cents / 100).toFixed(2);\n}", "note": "Cents become a printed amount only at the very end, for a person to read."}, {"code": "console.log(`price ${money(priceCents)}, accounts in the first year ${money(accountsCents)}`);\nfor (const rate of [15, 30]) {\n  const commission = Math.round((priceCents * rate) / 100);\n  const proceeds = priceCents - commission;", "note": "The commission is rounded to the nearest cent, and the proceeds are what is left. Taxes are left out on purpose."}, {"code": "  const needed = Math.ceil(accountsCents / proceeds);\n  console.log(`${rate}%  commission ${money(commission)}  proceeds ${money(proceeds)}  sales to cover the accounts ${needed}`);\n}", "note": "Rounded up, because seven and a third sales are eight sales."}]}
```

```
ana@dev:~/planner$ node proceeds.ts 1999
price 19.99, accounts in the first year 124.00
15%  commission 3.00  proceeds 16.99  sales to cover the accounts 8
30%  commission 6.00  proceeds 13.99  sales to cover the accounts 9
ana@dev:~/planner$ node proceeds.ts 499
price 4.99, accounts in the first year 124.00
15%  commission 0.75  proceeds 4.24  sales to cover the accounts 30
30%  commission 1.50  proceeds 3.49  sales to cover the accounts 36
```

A planner subscription at 19.99 a year leaves 16.99 at 15% and 13.99 at 30%, and the two accounts
cost 124 dollars in the first year. **Eight subscribers pay for the first year at the reduced rate;
nine at the standard one.** At 4.99 it takes 30 and 36. The script leaves out tax, which the stores withhold by country before
the commission, so a real report in Brazil or the European Union shows less than these lines.

## The other two platforms

Nothing in this changes with the language the app is written in. A React Native app pays the same
two fees and the same commissions as a Kotlin or a Swift one, because what the stores sell is the
app, not its code.
