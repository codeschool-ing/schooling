---
title: Hospital efficiency: beds, stays and the full hospital
version: 1
---

Hospital Jacarandá is a general hospital in Campinas with 240 beds and an emergency department
that never closes. It is invented, like Varanda, and so is every number in this lesson. Its data
analyst, Débora Kato, answers to the clinical director and to finance, and the questions she gets
fall under lesson 17's four questions like this:

| lesson 17's question | in a hospital |
|---|---|
| the decisions made over and over | where the next patient goes, how many nurses each shift needs, which beds and operating theatres to open, which patients can go home today |
| the indicators that serve them | bed occupancy, average length of stay, bed turnover, waiting time in the emergency department, readmissions within 30 days; for a region, rates per 100,000 people |
| the data, and what is odd about it | it is written to care for a patient and to be paid for it, not to be analysed; and **almost all of it is sensitive personal data** |
| the typical trap | an average across wards, patients or towns that hides the place where the trouble is |

## Three indicators from one month

A hospital counts its patients at midnight. **One patient in one bed at the midnight count is a
patient-day**, and a month's patient-days against the beds available is the hospital's most watched
number. Type Jacarandá's November 2025, by ward:

| | A | B | C |
|---|---|---|---|
| 1 | Ward | Beds | Patient-days |
| 2 | Medical | 96 | 2736 |
| 3 | Surgical | 64 | 1670 |
| 4 | Intensive care | 20 | 591 |
| 5 | Maternity | 32 | 598 |
| 6 | Paediatrics | 28 | 543 |

November has 30 days, so each bed offers 30 bed-days. In D2, copied down, and **bed occupancy** in
E2:

```localised
=B2*30      2880
=ROUND(C2/D2*100,1)      95
```

In row 7 the hospital's totals, `=SUM(B2:B6)` and the same for C and D, and its occupancy:

```localised
=SUM(C2:C6)      6138
=SUM(D2:D6)      7200
=ROUND(C7/D7*100,1)      85.3
```

The hospital discharged 1,365 patients in November. Type that in B8. **Average length of stay** is
patient-days per discharge, and **bed turnover** is discharges per bed in the period:

```localised
=ROUND(C7/B8,1)      4.5
=ROUND(B8/B7,1)      5.7
```

A patient stayed 4.5 days on average, and each bed received 5.7 patients in the month.

## Why the average is in a comfortable place

85.3% is the number that goes into the monthly report, and it looks sensible: most beds busy, a
few spare. **Copy E2 down and the hospital comes apart into two hospitals.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Horizontal bars of bed occupancy in November 2025 for five wards against a dashed line at the hospital average of 85.3%: intensive care 98.5%, medical 95.0%, surgical 87.0%, paediatrics 64.6%, maternity 62.3%.\" data-fig=\"l19-occupancy\"><text x=\"170.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">beds occupied at midnight, average of November 2025</text><text x=\"158.0\" y=\"62.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Intensive care</text><path d=\"M170.0 46.0 H633.0 V70.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"641.0\" y=\"62.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">98.5%</text><text x=\"158.0\" y=\"102.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Medical</text><path d=\"M170.0 86.0 H616.5 V110.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"624.5\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">95.0%</text><text x=\"158.0\" y=\"142.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Surgical</text><path d=\"M170.0 126.0 H578.9 V150.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"586.9\" y=\"142.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">87.0%</text><text x=\"158.0\" y=\"182.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Paediatrics</text><path d=\"M170.0 166.0 H473.6 V190.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"481.6\" y=\"182.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">64.6%</text><text x=\"158.0\" y=\"222.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Maternity</text><path d=\"M170.0 206.0 H462.8 V230.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"470.8\" y=\"222.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">62.3%</text><path d=\"M570.9 34 L570.9 244\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><text x=\"570.9\" y=\"262.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">hospital 85.3%</text><path d=\"M170.0 34.0 L170.0 244.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 274.0 H180.0 V284.0 H170.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"186.0\" y=\"284.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">above 90%, where an extra patient has nowhere to go</text></svg>", "caption": "The same month by ward. The hospital average sits in a comfortable place, and two wards are full while two others have a third of their beds empty."}
```

Intensive care ran at 98.5%: of its 20 beds, 19.7 were taken on an average night. The medical
wards ran at 95.0%. Maternity and paediatrics had a third of their beds empty. The average is a
weighted mix of full wards and empty ones, and nobody is ever admitted to the average. A patient
who needs intensive care at two in the morning needs one of those 20 beds, and the 12 empty beds in
maternity are no use to them.

## Why 100% is a failure

In a store, a shelf that sells everything is a stock-out (lesson 18). In a hospital, a ward at
100% is worse: **the next emergency has nowhere to go**. Admissions are not spread evenly over the
month; Mondays and winter weeks bring more of them. A ward whose average is 98.5% is full on many nights. On those nights the emergency department keeps admitted patients on trolleys, operations
are cancelled to free beds, and patients are moved to whatever ward has room, where the nurses know
less about their illness.

So a hospital does not aim at 100%. A figure often quoted by planners is around 85% for general
beds, above which full nights start to become common. It is a working rule and not a law, and
the right level depends on how variable a ward's admissions are: a maternity ward with booked
deliveries can run fuller than an emergency medical ward. **What the rule says is that occupancy has
a ceiling well below 100%**, which is the reverse of most indicators in this course, where more of
the thing measured is better.

## Shorter stays, with a guard

Length of stay pulls the other way. If medical patients stayed half a day less, the same beds would
take more patients, and the 95% would fall. That makes average length of stay a target hospitals
like to cut, and a target with an obvious way to game it: send patients home before they are
ready. **The guard is the readmission rate**, the share of patients who come back within 30 days,
which the next section measures. It is lesson 11's counter-metric pair applied to a hospital: the
indicator you push on, and the one that shows when you pushed too hard.
