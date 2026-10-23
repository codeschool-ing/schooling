---
title: Records, retention and the duty to dispose
version: 1
---

The instinct with documents is to keep everything, because storage is cheap and deleting feels like
the risky act. **For a record, keeping it past its time is a failure of the same kind as losing it
early**: both break a rule the company set itself, and the first one can also break the law on
personal data. This section is about the rules that decide what is kept, for how long, and what
happens at the end.

## A record is a document kept as evidence

ISO 15489, the international standard on records management (first published in 2001 and revised
in 2016), treats a record as information created, received and kept as evidence of what an
organisation did. **The test is the purpose, not the format.** Draft 1.2 of the pasteurisation
procedure is a document. Version 1.0, the one line 2 worked to in March 2026, is a record, because it
is the evidence of what the plant told its operators to do.

Becoming a record changes what may happen to a document:

- it is fixed: nobody edits it, its author included, and a correction is a new document that refers
  to it;
- it has a retention period taken from a schedule, not from somebody's judgement on the day;
- it can be put under legal hold, which stops its disposal;
- at the end of the period it is disposed of, and the disposal is itself recorded.

Many systems make the change explicit. A person or a rule *declares* the document a record, and from
then on the system refuses edits and deletions, even from an administrator. At Serra Alta every
certificate of analysis is declared a record the moment it is filed, by the job that files it.

## The retention schedule

A retention schedule is a table that says, for each class of record, how long it is kept, from which
event the time is counted, and why. Serra Alta's legal department wrote its schedule in 2019 and
reviews it every two years. Part of it:

| class of record | kept for | counted from | why it is kept |
|---|---|---|---|
| certificate of analysis of a batch | 5 years | the end of the year the batch was made | food safety and customer contracts |
| SIF inspection records | 10 years | the end of the year of the inspection | federal inspection |
| superseded procedures | 10 years | the date they were superseded | audits, and claims about old batches |
| supplier certificates | 5 years | the end of the supplier relationship | supplier audits |
| NF-e and the tax books | 6 years | the end of the fiscal year | tax |
| a farm's onboarding file (contract, identity document, bank details) | 5 years | the farm's last payment | contract and payment disputes |

These periods are Serra Alta's own, chosen by its lawyers from the laws that apply to each class,
with a margin. **The legal minimums are for a lawyer to state, and the schedule is where the company
writes down its answer.** An architect does not pick the numbers. What an architect does decide is
whether the systems can carry them out.

Look at the third column. The clock starts at an **event**, and the event is often not the date the
document was made. "Five years after the supplier relationship ends" cannot be computed when the
certificate is filed, because nobody knows yet when the relationship will end. That fact lives in
SAP, on the supplier's vendor record. **A retention rule that counts from a business event needs an
integration**, because the DMS has to be told when the event happens, and somebody has to build that.

Worked through for one record: batch L2603-0112 of whole milk was made on 14 March 2026. Its
certificate is kept for five years from the end of 2026, so it becomes eligible for disposal on
1 January 2032, five years and about nine and a half months after the batch was made. Counting from
the end of a year is common for exactly this reason: Serra Alta runs disposal once a year, in
January, and one run handles a whole year of batches.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-retention\" aria-label=\"A time line from 2026 to 2034 for the certificate of batch L2603-0112. The batch is made on 14 March 2026. The retention clock starts at the end of 2026 and runs five years, to 1 January 2032, when the certificate becomes eligible for disposal. A legal hold placed in 2031 covers that date, so the disposal run of January 2032 skips it. The hold is lifted in 2033 and the certificate is destroyed in the run of January 2034, which leaves a record of the disposal.\"><path d=\"M50.0 150.0 L656.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 145.0 L60.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2026</text><path d=\"M132.0 145.0 L132.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"132.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2027</text><path d=\"M204.0 145.0 L204.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"204.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2028</text><path d=\"M276.0 145.0 L276.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"276.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2029</text><path d=\"M348.0 145.0 L348.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"348.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2030</text><path d=\"M420.0 145.0 L420.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"420.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2031</text><path d=\"M492.0 145.0 L492.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"492.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2032</text><path d=\"M564.0 145.0 L564.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"564.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2033</text><path d=\"M636.0 145.0 L636.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"636.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2034</text><circle cx=\"74.4\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"74.4\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">batch made</text><text x=\"74.4\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">14 Mar 2026</text><path d=\"M74.4 124.0 L74.4 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"132.0\" y=\"60.0\" width=\"360.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 years from the end of 2026</text><path d=\"M132.0 82.0 L132.0 143.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M492.0 82.0 L492.0 143.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"492.0\" y=\"29.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">eligible for disposal</text><text x=\"492.0\" y=\"42.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 Jan 2032</text><rect x=\"448.8\" y=\"190.0\" width=\"151.2\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"524.4\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">legal hold</text><text x=\"492.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Jan 2032 run: skipped</text><path d=\"M492.0 176.0 L492.0 188.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"636.0\" cy=\"150.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"632.0\" y=\"251.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">destroyed, Jan 2034,</text><text x=\"632.0\" y=\"264.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">disposal recorded</text><path d=\"M636.0 176.0 L636.0 244.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "The clock starts at an event, not at the batch date, and a hold beats the clock. The certificate outlives its period by two years because of one lawsuit."}
```

## Legal hold

A **legal hold** suspends disposal for the records tied to a dispute, an investigation or an
inspection, however old they are. Suppose that in 2031 a consumer sues over a carton from batch
L2603-0112, and the certificate is evidence. The legal department places a hold on it and on
everything else tied to that batch: the certificate, the line's production records, the version of
the procedure in force that day. When the run of January 2032 comes, it skips them. The case ends in
2033, the hold is lifted, and the records go in the next run, in January 2034.

Three properties make a hold work. It overrides every retention period. It is placed and lifted by
the people responsible for the case, not by IT. And it covers everything tied to the matter,
wherever it is kept, which is the hard part when one batch has records in Documentum, in SAP and in
Coleta. **A hold that the DMS obeys and the ERP's archive ignores is half a hold.**

## Disposal is a duty

Disposal is the step everybody postpones, and it is the step the schedule exists for. There are
three reasons not to keep everything.

**The law on personal data.** Brazil's LGPD, the general data protection law (Lei 13.709/2018),
says personal data is to be eliminated when the processing it was collected for comes to an end. Its
article 16 lists the purposes for which it may be kept anyway, and the first is complying with a
legal or regulatory obligation. That makes the schedule the place where the two pull in opposite
directions and are reconciled: each class says why it is kept, and that reason is what justifies
keeping it. Past the date, the reason has run out.

A farm's onboarding file is the sharp case. Most of Serra Alta's 1,900 milk suppliers are individual
farmers, so the file holds a person's identity document, tax number (CPF) and bank account. A farmer
who stopped supplying in 2019 and was last paid in December 2019 had a file due for disposal in
December 2024. When Joana asks, Cláudia's team finds 340 such files still in the repository, the
oldest from 2010. Nobody had ever run a disposal for that class.

**Cost and noise.** Everything kept is backed up, migrated at the next upgrade and searched. A search
for a procedure that returns its ten superseded versions first is a search people learn to distrust.

**Discovery.** In a lawsuit, what exists can be requested. A company that still holds documents its
own schedule said to destroy cannot say they are gone, and it has also shown that it does not follow
its own policy.

A disposal leaves a record of its own: what was destroyed, under which rule of the schedule, approved
by whom, on which date. **The record of the disposal is kept even though the record itself is not**,
because a later question, "did you have this certificate?", needs an answer, and "we destroyed it in
January 2034 under rule CQ-05" is one.

## Where an architect comes in

Records management fails at the seams between systems, so it is an integration problem as much as a
quality one. Four questions to ask of any design that touches documents:

1. Which system holds the record? A certificate PDF e-mailed to a customer is a copy; the record is
   the one in the DMS.
2. Where does the event that starts the clock live, and how does the DMS learn about it?
3. Can a legal hold reach every system that holds part of the matter?
4. When a record is disposed of, what happens to the links that point at it from SAP or from
   Salesforce? The last section of this lesson returns to this.

Lesson 14, on data migration, meets the same schedule from the other side. Records moved to a new
system have to keep their dates, their declarations and their holds, or the new system ends up full
of documents that have quietly stopped being evidence.
