---
title: Where the e-mail goes
version: 1
---

Every request ana's program makes carries a customer's e-mail: a name, an order number, sometimes
an address, now and then a complaint about somebody's mother. **Where that text travels is a
property of the kind of model**, and it is often the criterion that decides before cost or quality
are even measured.

## Closed: to the provider, under their terms

With a closed model the e-mail leaves your systems and is processed by the provider. What happens
to it then is set by **their terms of service and data-processing agreement**, which say how long
requests are kept, whether they are used for training, and who inside the provider may see them.
Business API terms at the large providers say inputs are not used for training by default, and
most offer shorter retention for customers who ask. Read the version that applies to your
account, not a summary of it.

What you can choose, even with a closed model, is often **where** it is processed. The cloud
platforms that resell closed models sell regional routes, and the sheet prices them:

```
ana@desk:~/desk$ python sheet.py where anthropic.claude-sonnet-5-5 | grep -E "^(global|us|eu|jp)\."
eu.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
global.anthropic.claude-sonnet-5-5                   bedrock_converse                  2       10
jp.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
us.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
```

The same model, four routes. `eu.` keeps processing inside European regions, `jp.` inside Japan,
`us.` inside the United States, at ten per cent above the `global` route that may send the
request wherever there is capacity. **That ten per cent is the price of a guarantee about
geography**, which some contracts and some laws require.

## Open: wherever you run it

With open weights, on your own machine or in your own cloud account, the e-mail goes nowhere you
did not send it. That is the whole of the argument, and for some organisations it ends the
discussion: health records, legal files, anything a contract says may not leave.

Notice what it does **not** say. An open model served by **a host** (section 05's cheap entries)
puts the e-mail on that host's machines, under that host's terms, exactly as a closed provider
would. Open weights only keep data in when you run them yourself, which is lesson 3's subject and
lesson 3's cost.

## Lantern Books, so far

| question | closed | open, hosted | open, self-run |
|---|---|---|---|
| licence conditions to check | terms of service | the model's licence and the host's terms | the model's licence |
| price | per token, one maker | per token, many hosts | per hour of a machine |
| changes when | the provider retires it | the host drops it | ana decides |
| e-mail goes to | the provider, in a region she can pick | the host | nowhere |

None of these columns wins on its own. Lesson 3 asks when the last one pays for itself; lesson 4
turns the rows into criteria with numbers; lesson 5 adds the row this table is missing, **whether
the model does the task at all**.
