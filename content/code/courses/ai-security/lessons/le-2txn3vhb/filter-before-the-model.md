---
title: Filtering before the model sees anything
version: 1
---

The fix moves the rule from the prompt to the search. `search.py` with `--as` keeps only what the
reader may open **before ranking anything**, so a document the client may not read cannot be a
result at all:

```
ana@lab:~/guard$ guard search "quote for my website" --as ac-7Q2M
searching as ac-7Q2M (client)
d1  ac-7Q2M  private  Job 4471 quote: R$ 1.200,00 for a logo, delivery in 10 days.
d3  tarefa   public   Refunds: a client may ask for a refund within 7 days of delivery.
```

The two documents of `ac-0Z5Q` are gone, and the client's own quote and a public page take their
place. The same four questions, with the rule enforced in the search:

```
ana@lab:~/guard$ guard assist data/questions.jsonl --as ac-7Q2M --filter search
q1  How much is the quote for my website?
    retrieved d1, d3, d6
    ok   The quote for your website is R$ 1.200,00.
q2  What does the quote include?
    retrieved d1, d6, d7
    ok   According to the document [d1, owner ac-7Q2M, private], the quote for Job 4471 includes R$ 1,200.00 for a logo.
q3  When will I get the files for my job?
    retrieved d6, d1, d7
    ok   According to the document [d6, owner ac-7Q2M, private], the freelancer will send the logo files for your job (Job 4471) on Friday.
q4  Is any account flagged for chargebacks?
    retrieved d1, d3
    ok   I don't have access to information about other accounts or their flagging status. However, I can tell you that according to the document [d3, owner ta
4 questions as ac-7Q2M, rule enforced in the search; answers repeating what ac-7Q2M may not read: 0
```

**No answer repeats anything the client may not read**, because nothing the client may not read was
in any prompt. `q4` has nothing to say about other accounts, and says so. The check is no longer the
model's to pass or fail.

`q1` shows what the filter does not fix. The client has no website job, and the model answered "the
quote for your website is R$ 1.200,00", which is the logo's price under the wrong name. That is
lesson 2's subject, an answer that is confidently wrong, and it is a different failure from a leak:
wrong about the client's own data rather than right about somebody else's. **Access control decides
what the model may see; it does not make the model read it correctly.**

## Where the filter lives

The order matters more than the code. Filtering after the ranking is a common shape and a weaker
one: retrieve the top three over everything, then drop the ones the reader may not open. A client
whose question best matches other people's documents then gets one result or none, and a screen
that shows how many results there were tells that client something matched which they may not see.
**Filter first, then rank.**

With a vector index the same rule holds. Every document carries its owner and visibility as metadata,
and the query passes the reader's filter to the index, which ranks only what passes. An index per
client is the stronger form, at a cost in operations; one shared index with a filter on every query
is the common one, and then the filter is the whole of the protection, so it is tested.

## Testing the filter, not the model

A filter is code, and code can be checked without a model in the loop. `--audit` runs every question
as every client, with the filter and without it, and counts the results the reader may not open:

```
ana@lab:~/guard$ guard search --audit data/questions.jsonl; echo "exit status $?"
8 searches as 2 accounts
  with the reader's filter:  0 results the reader may not open
  over everything:           13 results the reader may not open
exit status 0
```

Thirteen results would have reached the wrong reader without the filter, and none with it. **The exit
status is 0, and it would be 1 the day a change to `may_read` let one through**, which is what lets
the audit run in the build beside every other test, as lesson 24 does. The model's answers vary with
the model; this number does not.
