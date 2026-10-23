---
title: Windows, freezes and the calendar
version: 1
---

Joana arrived with a picture of availability in which every system wants to be up all the time and
fails to be by accident. At Serra Alta half the important downtime is on purpose. SAP stops every
Sunday morning. Finance takes the ERP over for the first five working days of each month. Coleta's
machine runs its nightly save. **The times a system stops on purpose are part of its architecture,
as much as its boxes and arrows are**, and a design that does not know them fails on a schedule.

## The weekly window

As lesson 1 told, SAP is down every Sunday from 01:00 to 05:00. Edson's team uses those four hours
for the work that needs the system to itself: support packages and kernel patches, the transports
that carry configuration changes into production, database maintenance. Four hours of a 168-hour
week is 2.38%.

Whether those hours count depends on who is counting. SAP's 99.0% in the previous section left them
out, because they are planned, and for the people who plan them that is reasonable. A bakery
opening its basket at 02:00 on a Sunday sees a system that is down. Counted around the clock, SAP is
available 0.99 × (164 ÷ 168) = 96.64% of the time, and the stock-check chain falls from 98.41% to
0.98406 × 0.97619 = 96.06%. **A planned window is downtime to everybody who depends on the system
synchronously.** Planning it only means everybody can know in advance.

The oldest integration in the company shows what knowing in advance looks like. Coleta writes the
day's collection file at about 23:30 and SAP loads it at 02:00. On Sunday, 02:00 is inside
the window. The file loads anyway, because years ago somebody in Edson's team moved the Sunday run
of the load job to 06:00. That rule lived in the job scheduler and nowhere else; Joana found it only
because she asked why the Sunday goods receipts always carried a later time than the rest of the
week. It works, and it is the kind of design that works until somebody tidies up the schedule.

**An integration is designed for the other side's window, not surprised by it.** The ways of doing
that are few, and the next sections take them further:

- the sender holds its work and delivers after the window, which is what a file in a directory
  and a queue in front of SAP both do;
- the receiver states its window in the interface contract, so the sender's team does not have to
  discover it in a scheduler;
- a synchronous caller has a degraded answer for the hours the window lasts, like the portal's
  last stock figure with its time beside it.

## Windows in a chain add up

The stock check crosses two systems with windows of their own. Rui's team used to maintain the bus
on Saturday nights from 22:00 to 24:00, so a bakery calling on a weekend lost the check for two
hours on Saturday and four more on Sunday. **The planned downtime of a chain is the union of its
members' windows**, and two windows that do not overlap cost the sum of both. Rui moved the bus's
window to Sunday 01:00 to 03:00, inside SAP's, and the chain's weekly planned downtime went from six
hours to four without anybody working faster.

## The month-end close and the freeze

For the first five working days of every month, Marcos's controllers close the previous one: the
last postings, accruals, the valuation of stock, the reconciliation of the banks, and the reports
that go to the board and to the banks that lend to Serra Alta. Two things follow for every system
near SAP.

SAP is under load. The closing jobs run beside the ordinary day, and response times stretch. The
September incident in the previous section was this: the stock check timed out on the second
working day of the close. A synchronous integration that is fine in week three can fail in week
one, so its timeouts and its objective have to be set for week one.

And nothing changes. A change that breaks something during the close delays the books, and a late
close is a conversation between the CFO and the board. So the SAP team has always frozen changes
for that week. A **change freeze** is a period in which nothing is changed in production except
emergency fixes, and those only with a named person's approval. It is not a period of no risk:
**a freeze moves changes to the weeks either side of it**, and the week after a freeze is when
the queue of postponed changes goes in together.

Joana's calendar widened the freeze in two directions. It starts on the last two working days of
the month, when the last invoices of the period are being issued and a broken NF-e flow would
lose sales from the month being closed. And it runs to the 10th, because farms are paid on the
10th. Coleta calculates the payments, finance approves them, and the bank file for 1,900 farms goes
out the working day before. A change that breaks that chain the week before the payment means
1,900 farms paid late, and a farm that is paid late sells its milk to somebody else.

## The month as a picture

November 2026 is the first month her calendar covered, and it shows why the calendar has to be
drawn rather than described. 2 November is a national holiday, so the close of October starts on
the 3rd and its fifth working day is the 9th. The farm payment is on the 10th, the day after. The
freeze that began on 29 October runs without a gap to the evening of the 10th.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-month\" aria-label=\"November 2026 as a strip of 30 days, starting on Sunday the 1st. Weekends are shaded, and the national holidays on the 2nd, the 15th and the 20th are marked. Row one: SAP's Sunday window from 01:00 to 05:00, on the 1st, 8th, 15th, 22nd and 29th. Row two: the close of October, on the five working days from the 3rd to the 9th. Row three: the farm payment on the 10th. Row four: the change freeze, which began on 29 October and runs to the 10th, and starts again on the 27th. Between them, eleven working days from the 11th to the 26th are open for changes.\"><rect x=\"150.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"158.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"168.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"176.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><rect x=\"187.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"195.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"205.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"213.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"224.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"232.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"242.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"250.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"261.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"269.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"279.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"287.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"298.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"306.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"316.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"324.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"335.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"343.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11</text><rect x=\"353.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"361.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">12</text><rect x=\"372.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"380.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">13</text><rect x=\"390.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"398.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">14</text><rect x=\"409.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"417.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">15</text><rect x=\"427.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"435.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">16</text><rect x=\"446.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"454.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17</text><rect x=\"464.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"472.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">18</text><rect x=\"483.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"491.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19</text><rect x=\"501.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"509.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">20</text><rect x=\"520.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"528.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">21</text><rect x=\"538.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"546.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">22</text><rect x=\"557.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"565.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">23</text><rect x=\"575.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"583.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24</text><rect x=\"594.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"602.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">25</text><rect x=\"612.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"620.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">26</text><rect x=\"631.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"639.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">27</text><rect x=\"649.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"657.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">28</text><rect x=\"668.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">29</text><rect x=\"686.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"694.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">30</text><text x=\"427.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">November 2026: shaded days are weekends and national holidays (2, 15, 20)</text><text x=\"142.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP window, Sun 01–05</text><text x=\"142.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">close of October</text><text x=\"142.0\" y=\"146.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">farms paid</text><text x=\"142.0\" y=\"182.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">change freeze</text><rect x=\"152.0\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"281.5\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"411.0\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"540.5\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"670.0\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"188.0\" y=\"101.0\" width=\"70.0\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"299.0\" y=\"101.0\" width=\"14.5\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"317.5\" y=\"137.0\" width=\"14.5\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"173.0\" width=\"181.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"632.0\" y=\"173.0\" width=\"70.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"156.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">← from 29 October</text><text x=\"637.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">to Dec</text><path d=\"M336.0 218.0 L336.0 224.0 L628.0 224.0 L628.0 218.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"483.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">open for changes: 11 working days, from the 11th to the 26th</text></svg>", "caption": "November 2026 on one strip. The holiday on the 2nd pushes the close to the 9th, the payment follows on the 10th, and the freeze runs from October without a gap."}
```

November has 19 working days once the holidays of the 2nd and the 20th are out. Six of them are in
the freeze that began in October. The next freeze starts on the 27th, the second-to-last working
day of the month. That leaves 11 working days, from the 11th to the 26th, in which a change to SAP,
to the bus flows that feed it or to the portal's checkout can go to production. **Eleven days is
the real capacity for change in November**, and a project plan that counts the month's 21 weekdays
is planning nearly twice what the calendar allows.

## The rest of the calendar

The month is the shortest cycle. The year has its own.

The monthly tax filings depend on a closed month, and their dates are set by the federal and state
authorities rather than by Serra Alta. When the close slips, the filings are what is at risk, which
is why finance defends the five days so firmly.

Milk has seasons. From about October to March, the rainy season in Minas Gerais, pastures grow and
the farms send more milk. At Serra Alta the daily intake rises from about 2.3 million litres to
about 2.6 million at its peak, and the trucks, the plants and Coleta run at their limits. A change
to Rota or Coleta in January carries more risk than the same change in July.

Sales have seasons too. December is the year's peak for cream, butter and cheese in the
supermarkets, and Serra Alta freezes the sales systems, the EDI flows and the portal from 15
December to 5 January.

## The calendar is an artefact

None of this was secret. Each team knew its own windows, its own freezes and its own peaks. What
did not exist was **one calendar with all of them on it**, so that a change to one system could be
checked against the windows of everything it touches. Joana put it beside the registry of interface
contracts, with each system's windows, each freeze and its reason, and each peak. A change request
now names the date it wants and the calendar answers whether that date is open for every system in
the change's path.

It is the least technical artefact she produced that year, and the one other teams opened most.
