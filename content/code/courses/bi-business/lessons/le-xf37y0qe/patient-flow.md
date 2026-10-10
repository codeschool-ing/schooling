---
title: Patient flow: the wait, the return and the morning bed board
version: 1
---

Patients move through a hospital in a line: they arrive, wait, are seen, are admitted or sent home,
stay, leave and sometimes come back. **Patient flow is the hospital's word for that line**, and the
two indicators in this section measure its two ends: how long people wait at the door, and how many
come back through it.

## The wait in the emergency department

Ten patients arrived at Jacarandá's emergency department between six and seven on a Monday evening.
The minutes each waited from arrival to being seen by a doctor, in order:

| | A | B |
|---|---|---|
| 1 | Patient | Minutes |
| 2 | 1 | 12 |
| 3 | 2 | 18 |
| 4 | 3 | 25 |
| 5 | 4 | 31 |
| 6 | 5 | 38 |
| 7 | 6 | 44 |
| 8 | 7 | 52 |
| 9 | 8 | 70 |
| 10 | 9 | 145 |
| 11 | 10 | 210 |

The obvious summary is the average:

```localised
=AVERAGE(B2:B11)      64.5
=MEDIAN(B2:B11)      41
```

**The average says an hour, and no patient waited about an hour.** Seven waited under 55 minutes
and two waited more than two hours. The two long waits pull the mean up; the median, the wait of
the patient in the middle, is 41 minutes and is what a typical patient met. `statistics` lessons 3
and 4 take mean and median apart properly; here the point is which one a hospital should report.

The answer is both the median and the long end, because the long end is where the harm is. **Many health
services report the wait that nine in ten patients were seen within**, the 90th percentile. With
ten patients sorted in order, that is simply the ninth:

```localised
=B10      145
```

Nine of the ten were seen within 145 minutes, and one waited 210. A spreadsheet has a percentile
function for the same job over thousands of rows. A target written as "90% seen within two hours"
is broken by this hour, and a target written as "an average under 70 minutes" is met by it.

## The return: readmission within 30 days

A readmission rate looks simple: of the patients discharged, the share admitted again within 30
days. Jacarandá's October 2025: 1,310 discharges, of whom 112 were back within 30 days. **The
denominator decides the answer, and there are at least three defensible ones.** Type the four
numbers in a column:

| | A | B |
|---|---|---|
| 1 | Discharges | 1310 |
| 2 | Died in hospital | 41 |
| 3 | Readmitted within 30 days | 112 |
| 4 | Of which planned | 30 |

```localised
=ROUND(B3/B1*100,1)      8.5
=ROUND((B3-B4)/B1*100,1)      6.3
=ROUND((B3-B4)/(B1-B2)*100,1)      6.5
```

8.5% counts every return, including the 30 patients who came back on purpose, for the next cycle
of chemotherapy or the second stage of an operation. 6.3% leaves the planned ones out of the top.
6.5% also takes out of the bottom the 41 patients who died in hospital, because a patient who died
cannot be readmitted, and counting them in the denominator flatters the rate. **Each is correct
under its own definition**, and a report that compares Jacarandá's 6.5% with another hospital's
8.5% compares two definitions, not two hospitals.

The rate also has a lag built in. November's readmission rate cannot be known until 30 days after
the last November discharge, so it arrives in January. A dashboard that shows November's rate in
early December is showing a number that is still going up.

## The bed manager's morning

Every morning at seven, Jacarandá's bed manager, a senior nurse named Cláudia Reis, decides where
the patients waiting in the emergency department will sleep. Her question is lesson 14's, in its
starkest form: what needs my attention now? Her screen is built around one sum per ward: beds,
minus those occupied, plus the patients expected to leave today, minus the planned admissions
already booked, minus the emergency patients already waiting for that ward.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A mock of the bed manager's screen at 07:00 on Tuesday 2 December 2025. Four tiles: 7 patients in the emergency department waiting for a bed, the longest for 9 hours 40 minutes; 42 discharges expected today; 32 planned admissions booked; intensive care beds free tonight: minus 1. A table by ward, the shortest first, gives beds, occupied, leaving today, booked, from the emergency department and free tonight: intensive care minus 1, surgical 3, medical 5, paediatrics 12, maternity 13.\" data-fig=\"l19-bed-board\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"380.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Beds · Hospital Jacarandá</text><text x=\"692.0\" y=\"34.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tue 2 Dec 2025, 07:00</text><text x=\"692.0\" y=\"50.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">census at 06:45, admissions system</text><rect x=\"28.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"40.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in the ED, waiting for a bed</text><rect x=\"196.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">42</text><text x=\"208.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">discharges expected today</text><rect x=\"364.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"376.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">32</text><text x=\"376.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">planned admissions booked</text><rect x=\"532.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"544.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">−1</text><text x=\"544.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ICU beds free tonight</text><text x=\"40.0\" y=\"157.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">longest ED wait for a bed: 9 h 40 min</text><text x=\"28.0\" y=\"196.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ward</text><text x=\"250.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">beds</text><text x=\"340.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">occupied</text><text x=\"430.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leaving</text><text x=\"520.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">booked</text><text x=\"600.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">from ED</text><text x=\"692.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">free tonight</text><path d=\"M28.0 204.0 L692.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M20.0 216.0 H24.0 V232.0 H20.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"28.0\" y=\"228.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Intensive care</text><text x=\"250.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"340.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"430.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"520.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"600.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"692.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">−1</text><text x=\"28.0\" y=\"258.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Surgical</text><text x=\"250.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">64</text><text x=\"340.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">58</text><text x=\"430.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">12</text><text x=\"520.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">14</text><text x=\"600.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"692.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text><text x=\"28.0\" y=\"288.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Medical</text><text x=\"250.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">96</text><text x=\"340.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">94</text><text x=\"430.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">14</text><text x=\"520.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">6</text><text x=\"600.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">5</text><text x=\"692.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">5</text><text x=\"28.0\" y=\"318.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Paediatrics</text><text x=\"250.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">28</text><text x=\"340.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">18</text><text x=\"430.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">5</text><text x=\"520.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text><text x=\"600.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"692.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">12</text><text x=\"28.0\" y=\"348.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Maternity</text><text x=\"250.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">32</text><text x=\"340.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">21</text><text x=\"430.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">9</text><text x=\"520.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">7</text><text x=\"600.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"692.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">13</text><text x=\"28.0\" y=\"376.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">free tonight = beds − occupied + leaving − booked − from ED</text></svg>", "caption": "The bed manager's screen answers one question at seven in the morning: where will the patients waiting in the emergency department sleep tonight? The ward that cannot take them is the first row."}
```

The hospital as a whole will have 32 beds free tonight. **Intensive care will be one short**, and
that is the first row because it is the only one that needs a decision before noon: a patient
moved out to a ward early, a planned operation that needs an intensive-care bed afterwards put back
a day, or a transfer to another hospital. The tile for the longest wait in the emergency department
is there for the same reason. Nine hours forty minutes on a trolley is one patient, and an average
would bury them.
