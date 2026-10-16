---
title: A leakage audit, column by column
version: 1
---

Since no score can prove a column innocent, the defence is a habit: **before a column goes into a
model, somebody says where it comes from.** Ana keeps a table beside the frame from lesson 1, with
one line per column, and a column with an empty cell does not go in.

| column | written by | when | as of the snapshot? |
|---|---|---|---|
| `skips_90d` | the order system, counted from the history | at the snapshot | yes |
| `rating_90d` | the review system, averaged from the history | at the snapshot | yes |
| `days_since_login` | the app's login log | at the snapshot | yes |
| `days_since_last_order` | computed by the export | 1 January 2026, for every row | **no** |
| `cancel_reason` | the cancellation form | when the subscriber cancels | **no** |
| `price_month` | the billing system | at the snapshot | yes |

The last column of the table is the one that matters, and it can only be filled in by asking the
people who own the systems, or by reading the code that builds the file. **Neither can be done from
the data alone**, which is why leakage is a question about a company before it is a question about a
model.

## Five questions for every column

1. **Who writes it, and in response to what?** A column written by a person reacting to the outcome
   carries the outcome.
2. **When is it written, and is that before the moment of prediction?** If it is written later, it
   cannot be an input.
3. **If it is a summary, over what window, ending when?** "Last 90 days" means nothing until you know
   the 90 days end at the snapshot and not at the export.
4. **Can it change after it is first written?** A field that is updated in place, like a customer's
   status or segment, holds today's value in every historical row.
5. **Will it be there, with the same meaning, when the model runs?** A column computed in a nightly
   batch will not exist for a model that scores in real time at checkout.

The fourth question finds the most leaks in practice, and it is the hardest to see, because an
updated-in-place field looks exactly like a historical one. The tell is a field that is the same in
every row for a given customer, even across years in which that customer must have changed.

## And the procedure around it

**Split first.** **Fit every learned step inside the pipeline.** **Fill in the table before
modelling.** **Treat any score above what the problem allows as a bug until shown otherwise.** And
**test once on later data than any of it**. None of these takes long, and together they are the
difference between a model whose number means something and one that will be quietly withdrawn six
months after it was praised.
