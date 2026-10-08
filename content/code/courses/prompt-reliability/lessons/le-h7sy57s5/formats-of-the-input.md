---
title: The format of what you feed in
version: 2
---

The wording of the instructions is one thing you can vary. The data you put into the prompt is the
other: an order record, a product list, the last three messages from the same customer. **The same
facts can go in as prose, as a table or as JSON**, and they do not cost the same:

```
ana@lab:~/triage$ echo 'Order 4471: 2 paperbacks, paid 24.50 on 2026-08-03, sent by courier.' | python3 tokens.py -
28 tokens, 11 words, 69 characters
ana@lab:~/triage$ echo '{"order": "4471", "items": 2, "format": "paperback", "paid": 24.50, "date": "2026-08-03", "sent": "courier"}' | python3 tokens.py -
46 tokens, 12 words, 109 characters
ana@lab:~/triage$ printf 'order,items,format,paid,date,sent\n4471,2,paperback,24.50,2026-08-03,courier\n' | python3 tokens.py -
33 tokens, 2 words, 76 characters
```

One order, three ways, in `llama3.2:3b`'s tokens: 28 as a sentence, 46 as JSON and 33 as a table with
a header row. JSON pays for every key and every quotation mark, on every record. A table pays for
its header once, so its share falls with every row you add. Prose is the cheapest here and the
hardest to keep consistent across a thousand records, and a field that is missing from one sentence
is hard to notice.

## Choosing

**Choose a format that both the model and a person can read**, because a person will be debugging
the prompt when it fails. For records with the same fields, a table is compact. For nested data,
or values that contain commas and line breaks, JSON says exactly where each value ends. For a short
piece of context, a sentence is fine.

Then, if the choice could matter, measure it, the same way as the last two sections: one change,
the same test set, the same parameters, `pl compare`, and `--answers` as well as the total. The
previous section is the reason for the last part: **a difference you did not test for is a
difference you do not know about**, and the total is exactly where a format change hides.
