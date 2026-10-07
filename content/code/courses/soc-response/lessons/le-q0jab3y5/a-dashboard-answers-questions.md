---
title: A dashboard answers questions
version: 1
---

A common idea of a SOC dashboard is a wall of charts that look busy. **A dashboard worth keeping answers
questions somebody asks every day**, and each panel names its question. If nobody can say which question
a panel answers, nobody will notice when its answer changes.

Three questions an analyst at the lab's company asks every morning, written as three queries. Save this in
`~/week` as `dashboard.sql`:

```sql
-- dashboard.sql: three panels, each one a question somebody asks every morning
.headers on
.mode column
-- 1. failed SSH logins per day, local time
SELECT date(timestamp, '-3 hours') AS day, count(*) AS failures
FROM logs WHERE product = 'sshd' AND action = 'failure' GROUP BY day;
-- 2. the five addresses that tried the most different accounts
SELECT src_ip, count(DISTINCT user) AS accounts, count(*) AS failures
FROM logs WHERE action = 'failure' GROUP BY src_ip ORDER BY accounts DESC LIMIT 5;
-- 3. megabytes leaving the company, per destination
SELECT dst_ip, count(*) AS transfers, sum(bytes) / 1000000 AS mb
FROM logs WHERE product = 'flow' GROUP BY dst_ip ORDER BY mb DESC;
```

```
ana@soc:~/week$ sqlite3 siem.db < dashboard.sql
day         failures
----------  --------
2026-09-14  12      
2026-09-15  14      
2026-09-16  8       
2026-09-17  70      
2026-09-18  17      
2026-09-19  12      
2026-09-20  17      
src_ip         accounts  failures
-------------  --------  --------
203.0.113.66   19        57      
203.0.113.174  6         6       
203.0.113.192  5         6       
203.0.113.157  4         4       
203.0.113.180  3         3       
dst_ip         transfers  mb  
-------------  ---------  ----
203.0.113.150  7          2494
203.0.113.200  1          612 
```

Read them in order, as a person scanning a screen would. The first panel says **Thursday was different**:
70 failures against a usual 8 to 17. The second says one address tried **19 accounts** while the next
busiest tried 6, over a whole week. The third says that besides the backup provider, **612 MB went
somewhere else once**. None of the three says what happened. Together they say where to look, which is
what a dashboard is for.

The first panel as a picture:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A bar chart of failed SSH logins per day, local time, Monday 14 to Sunday 20 September: 12, 14, 8, 70, 17, 12 and 17. Thursday's bar is four to eight times the others.\"><path d=\"M40 190 L700 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"60\" y=\"162.57142857142858\" width=\"60\" height=\"27.428571428571427\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"152.57142857142858\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"90\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mon 14</text><rect x=\"150\" y=\"158.0\" width=\"60\" height=\"32.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Tue 15</text><rect x=\"240\" y=\"171.71428571428572\" width=\"60\" height=\"18.285714285714285\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"161.71428571428572\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"270\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Wed 16</text><rect x=\"330\" y=\"30.0\" width=\"60\" height=\"160.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">70</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Thu 17</text><rect x=\"420\" y=\"151.14285714285714\" width=\"60\" height=\"38.857142857142854\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"141.14285714285714\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">17</text><text x=\"450\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Fri 18</text><rect x=\"510\" y=\"162.57142857142858\" width=\"60\" height=\"27.428571428571427\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"152.57142857142858\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat 19</text><rect x=\"600\" y=\"151.14285714285714\" width=\"60\" height=\"38.857142857142854\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"141.14285714285714\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">17</text><text x=\"630\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sun 20</text></svg>", "caption": "Panel 1 drawn. A daily count shows that Thursday was different; it cannot say why."}
```

Three habits make a dashboard last. **A baseline beside every number**, because 70 means nothing without the
8 to 17 next to it. **The same time zone on every panel**, stated on the panel; here it is local time, while
the table stores UTC. And **as few panels as the questions need**: a panel nobody has looked at for a month
is noise that makes the others harder to read, and it should go.
