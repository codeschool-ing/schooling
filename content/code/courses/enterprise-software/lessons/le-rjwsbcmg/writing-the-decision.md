---
title: Writing the decision down
version: 1
---

The sheet, the curves and the sensitivity are the evidence. The decision is a page somebody signs,
and it is the page that will be read in 2029 when the renewal offer arrives, by people who were not in
the room. You met the form in `architecture-role` lesson 5 — Michael Nygard's architecture decision
record of 2011, with its title, status, context, decision and consequences — and `architecture-modeling`
lesson 5 added the options and how to compare them. **A buy-or-build record needs four things more
than a technical one**: the numbers with the assumptions they rest on, the honest weak point of the
choice, the trigger that would reopen it, and the names of who decided and who disagreed.

## The record

Joana wrote it in an afternoon, after the meeting with Marcos and Regina. It is about 500 words.

> **Farm payment: replace Coleta's farm side with a purchased SaaS product.** Status: accepted,
> 26 November 2026.
>
> **Question.** How does Serra Alta replace what Coleta does for the farms — recording each
> collection, holding the lab results and calculating the monthly payment — before Sebastião Lima
> retires at the end of June 2028?
>
> **Context.** 1,900 farms are paid on the 10th of every month, under 46 rules. The quality committee
> revises the bonus tables twice a year, and the tables are how Serra Alta keeps its best farms; the
> calculation that applies them is done the same way by every dairy. The S/4HANA conversion is planned
> to go live in January 2028.
>
> **Options, over 36 months from January 2027, in reais.** A, buy a SaaS product: 4,233,500, first
> farm payment October 2027. B, extend SAP after the S/4HANA conversion: 5,261,000, first payment
> May 2028. C, build in house: 4,679,000, first payment April 2028. Totals include integration, the
> internal team, keeping Coleta running and the cost of leaving. The full sheet is attached.
>
> **Assumptions.** Serra Alta adds 100 farms a year. The price rise at the first renewal is capped at
> 4%. A person costs R$ 25,000 a month. A system we build costs 20% of its build a year to maintain.
> Amounts are nominal; discounting at 10% to 15% a year does not change the order.
>
> **Decision.** We will buy option A, on a 24-month term with 12-month renewals and the 4% cap. 41
> rules are configured in the product's rule tables, owned by the quality committee; 5 are extensions
> written beside the product, through its published interface, and never inside it. Every interface
> goes through our own anti-corruption layer. The contract includes the history export with a data
> dictionary.
>
> **Why.** A is the cheapest by R$ 445,500 and the only option that switches Coleta off while Sebastião
> is still here. It stays cheapest against a renewal rise of up to 61%, and a late build only widens
> the gap: 50% late, C would cost R$ 5,513,000 and switch Coleta off six months after Sebastião
> leaves.
>
> **Weak point.** The five extended rules are where our quality policy meets somebody else's release
> calendar. If the committee's next revisions need rules the product cannot express, each becomes
> an extension, and the policy moves at the speed of the extensions. Over a longer horizon C is
> cheaper to run: if year 3 repeated, it would catch up during its seventh year.
>
> **Revisit when** any renewal offer exceeds R$ 32 per farm per month; or more than 10 of the rules
> need extensions; or the vendor is sold or changes its interface without the agreed notice. In any
> case, every year by 31 May, before the notice date.
>
> **Decided by** Marcos Teles, CFO, and Regina Fontes, CIO, on the recommendation of Joana Brandão.
> Consulted: Cláudia Mendes, Edson Prado, Sebastião Lima and the Rota product team. Edson Prado
> preferred B, to keep the farms' payments inside the system of record; the record keeps his reason,
> and the integration through SAP's published interfaces answers part of it.

## What makes it a record and not a sales pitch

**Each number carries the assumption that produced it.** The year-3 price, the 20% maintenance, the
100 farms a year: whoever reads this in 2029 can check each one against what happened, and know
which part of the decision has aged.

**The weak point is written by the person who recommends the option.** It would have been easy to
leave it out — nobody in the meeting asked for it. **A recommendation without a weak point reads as
advocacy**, and the reader who later finds the weakness on their own stops trusting the numbers
around it. Joana's is a real one: the five rules are exactly where the policy that section 02 of this
lesson called core touches a product Serra Alta does not control. Naming it puts the risk where the
committee can watch it.

**The trigger is measurable and is set below the break-even.** A loses to C at R$ 40.14 per farm
per month. The trigger is R$ 32, because the decision to leave has to be taken six months before a
renewal, and the time to prepare an alternative is before the vendor's price makes it necessary.
"Revisit if circumstances change" would have triggered nothing.

**The dissent is recorded with its reason.** Edson's argument for B — one system of record, no
interface for the farms' money — was a good one that lost on cost and on the date. Writing it down is
what lets it win next time, if the reasons against it go away.

**The date in the calendar is the notice date.** The cheapest moment to reconsider a SaaS contract
is the month before notice is due. The record turns that month into an obligation with an owner.

## What you carry from this course

Fifteen lessons ago Joana arrived at a company whose systems nobody may switch off. What she learned
is what you can now do in her place:

- read an ERP as the company's books and its document flow, and know why it constrains every design
  around it (lessons 1 and 2), and recognise the families of enterprise software — Microsoft's,
  Salesforce's, the document managers, the workflow suites — by what they own and what they cost to
  live with (lessons 3 to 6);
- model a business process so that the people who run it can read it, and know what it takes for a
  model to execute (lesson 7);
- inherit an ESB and SOAP without contempt, and shrink it on purpose (lesson 8);
- choose between integrating by file, database, API and event, and build the queues, the idempotent
  consumers and the patterns that make any of them survive a bad night (lessons 9 to 11);
- write the contracts, the windows and the SLAs for systems that cannot stop (lesson 12);
- retire a system the business still depends on, a capability at a time, and move its data with
  proof that it arrived (lessons 13 and 14);
- and decide whether to buy or build what replaces it, with every line counted and the weak point in
  writing.

**None of it is about any one product.** The products in lessons 2 to 6 will be renamed, bought and
replaced while you work. The questions you ask of them will still apply: who owns the data, what the
contract lets you do, what the integration costs, what leaving costs, and whether the work is what
makes the company different or what every company has to get right.
