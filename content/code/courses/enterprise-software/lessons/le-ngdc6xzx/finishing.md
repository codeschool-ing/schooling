---
title: Finishing, and switching it off
version: 1
---

A strangler has a characteristic way of failing, and it is not at the start. The new system goes
live, capability after capability moves, the dashboards turn green, and then progress slows to
nothing with the old system still running "for a few things". **The last tenth of a migration is
the hardest part, because it is made of everything nobody knew the old system did.** A migration
that stops there has the costs of both systems forever: two sets of licences and hardware, two
sets of people who understand them, and an old system that nobody is improving and nobody is
allowed to switch off.

## The capabilities you did not list

Joana's inventory of Coleta, made in the plan's first month, has twelve capabilities: registering
farms, receiving collections from the handhelds, correcting collections, receiving laboratory
results, suspending and releasing farms, calculating the payment, printing the farm statements,
the nightly file to SAP, the monthly payment amounts to SAP, farm lookup, the collection summary,
and the reports the payment office runs.

She did not leave the search for the rest until the end. In the plan's second month the team went
looking, and found three things that were in no inventory:

- a spreadsheet in finance that reads Coleta's tables directly through an ODBC connection, and is
  refreshed during every month-end close to estimate the cost of milk before SAP has the final
  figures;
- a file Coleta sends on the 5th of each month to a farmers' credit cooperative, listing the loan
  instalments to deduct from its members' payments, set up in 2012 and run by the scheduler ever
  since;
- the annual statement each farm receives in February, summarising a year of litres and payments,
  which runs once a year and had last run before Joana joined the company.

None of them was hidden. Each was simply not where anybody looked: a spreadsheet is not a system,
the cooperative's file goes out by a job nobody watches, and a February job is invisible from
March to January. **The inventory went from twelve capabilities to fifteen, and every progress
figure based on twelve would have been wrong.** A report that counts nine capabilities moved reads
as 75% against the first inventory; against the real one it is 60%.
The denominator of a migration grows as people look harder, and a team that finds the growth in
the last months reports it as delay.

## How to find the last users

Finding them is a deliberate activity, and it uses three sources.

The first is the system's own evidence. The IBM i records which jobs run and which connections
open, and the journals record which programs change which tables. A list of every job the scheduler
started in the last year and every client that connected to the database in the last quarter is a
list of Coleta's users, whoever thought to mention them. That is how the three above were found.

The second is the network. The firewall in front of the IBM i knows every address that opened a
connection to it. An address that belongs to no known system is a question to ask.

The third is turning things off on purpose and watching, and it comes at the end. **Make the old
system read-only, keep it running, and record every attempt to write to it, for at least one full
business cycle.** For Coleta that cycle is a month including the month-end close, and for the yearly
jobs it is a year, which is why the annual statement had to be found by reading the scheduler
rather than by waiting. The blunt version, switching something off to see who complains, finds
the same things, but it finds them as incidents.

## The order of switching off

Switching off a system is a sequence, and each step is reversible until the one where it is not.

1. Stop the inputs. The interception paths stop forwarding anything to Coleta, and the outbound
   side of the anti-corruption layer stops writing to it. From this point nothing new arrives.
2. Make it read-only. Every user loses the authority to change anything; the screens still show
   history for the clerks who look up a farm's record from 2019. The plan puts this on 3 July 2028.
3. Archive what must be kept. Payment records are financial documents, and Coleta holds thirty
   years of them. What is kept, in what format and for how long is decided by the people
   responsible for those records, Marcos for the financial ones and Cláudia for quality, under the
   retention rules lesson 5 describes. Moving the data itself is lesson 14's subject.
4. Switch the machine off. The IBM i is powered down but kept intact for a period written in the
   plan, in case something nobody found turns up. It is the last point at which going back is
   cheap.
5. End everything around it: the hardware maintenance contract and the IBM software subscription,
   the terminal emulator licences, the two bus flows, the firewall rules, the user accounts, the
   copy at the disaster-recovery site, the anti-corruption layer's code that reads Coleta's
   journals, and the facade's routes that still name it.

**The fifth step is the one migrations forget, and it is where the money is.** A switched-off
machine whose maintenance contract renews every year is a cost that outlives the system by as long
as nobody reads the invoice.

## The date, written down at the start

**A switch-off that is not written down with a date does not happen.** It slides, one month at a
time, behind whatever the business needs this month. So the switch-off is a decision record like
any other (`architecture-role` taught their shape), and Joana wrote it at the start of the
migration rather than at the end: Coleta is switched off on 30 November 2028; this is what will be
archived and where; these are the contracts that end and when; these people own each part. Regina
signed it as CIO, Marcos for the financial records and Cláudia for the quality records. A record
written at the start can be revised, and revising it is a visible act with a reason; a date that
only exists in people's heads moves without anybody deciding to move it.

The date was chosen with one person in mind. Sebastião leaves at the end of 2028, and the plan puts
the switch-off a month before his last day, so that the person who knows Coleta best is still
there for the first month in which it is gone. His last task at Serra Alta is not writing code. It
is walking through the archive with the clerks, to confirm they can find a farm's history without
him, and reading the anti-corruption layer's tests one more time.

## Measure what was switched off

The question "how far along is the migration?" has two honest answers that tell different stories.
One counts what was built: capabilities the new systems serve. The other counts what was removed:
inputs stopped, screens disabled, jobs deleted from the scheduler, users without change authority,
contracts ended. A month in which the new systems serve nine capabilities can have the second count
still close to zero, because Coleta is still doing the other six and the machine, the contracts and
the people are all still paid for.

**Progress in a strangler is measured by what has been switched off, because that is the only
measure that cannot be reached while the old system is still needed.** The first count says the
new systems are capable. The second says the company has stopped depending on the old one, which
is what the migration is for. Joana's monthly report to Regina carries both, and the second one
first.

This lesson planned the replacement of Coleta: how the work moves, how the two systems live
together and how the old one ends. It left two questions open. How thirty years of farms and
collections are moved into the new system and proved complete is lesson 14. Whether the new payment
system is bought, built or added to SAP, and what that choice costs over three years, is lesson 15.
