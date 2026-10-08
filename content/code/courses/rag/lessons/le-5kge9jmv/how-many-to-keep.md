---
title: How many to keep, and when to keep none
version: 2
---

Every search in this course has returned three chunks. Three is a choice, and so is returning
something when nothing is good. This section looks at both.

## k

More chunks find more answers and cost more tokens. Lesson 4 counted both, and `measure.py` showed the
shape again: the vector search finds the answer first for 19 of the 26 customer questions and in the
top three for all 26. Past three, on this test set, there is nothing more to find, and every extra
chunk is paid for in the prompt. On a harder test set the curve keeps rising further out; the place to
stop is where it flattens, measured, not where a tutorial stopped.

There is also the generator to think of. A model given ten chunks to find one answer has nine chances
to quote the wrong one, which lesson 1 saw with three. Lesson 12 deals with what to do when several
chunks are needed and some are noise.

## A score below which nothing is returned

The search always returns k chunks, even for a question the documents cannot answer. Lesson 1 saw
three weak sections come back for *Can I place an order by phone?*, and the model, given them, invented
a rule about phone orders. A pipeline that relies on the generator to notice is relying on the component
least able to. The search can check first.

`scores.py` prints the best score each of the 30 test questions gets, sorted, with the four that have
no answer in the documents marked:

```schooling-example
{
  "language": "python",
  "file": "scores.py",
  "parts": [
    {
      "code": "import json\n\nfrom search import vector\n\nfor line in open(\"data/eval.jsonl\"):\n    q = json.loads(line)\n    best = vector(q[\"question\"], 1)[0][3]\n    print(f\"{best:.3f}  {'answerable  ' if q['facts'] else 'unanswerable'}  {q['question']}\")",
      "note": "The best score the vector search gives each of the thirty questions, and whether the question has an answer in the documents."
    }
  ]
}
```

```
ana@vm:~/rag$ python scores.py | sort -r
0.902  answerable    When can an audiobook be refunded?
0.836  answerable    How many days do I have to return a printed book?
0.835  answerable    How long is a gift card valid?
0.806  answerable    Who pays for the return postage?
0.779  answerable    On how many devices can I read my e-books?
0.772  answerable    How long does a pickup point keep my parcel?
0.765  answerable    What commission does Marginalia take from a marketplace seller?
0.758  answerable    How long after my return arrives will I get the refund?
0.754  answerable    My e-book was downloaded yesterday, can I still get my money back?
0.745  answerable    Can express orders go to a post office box?
0.731  answerable    What does error E-4102 mean in the affiliate API?
0.726  answerable    What commission do affiliates earn on e-books?
0.692  answerable    How long is the statutory right of withdrawal?
0.690  answerable    Will my e-books open on a Kindle?
0.658  answerable    How much is express delivery?
0.657  answerable    Can I get an invoice in my company's name after the order has shipped?
0.646  answerable    How long do you keep my order history?
0.646  answerable    Can I return a signed copy?
0.639  answerable    How often are sellers paid?
0.637  answerable    Above what order value is standard delivery free?
0.623  answerable    When is a standard parcel considered lost?
0.592  answerable    Do you store my IP address?
0.583  answerable    When is the contract of sale formed?
0.565  answerable    What must I check before changing a customer's order?
0.542  answerable    What is the most a support agent can refund without approval?
0.476  unanswerable  Can I place an order by phone?
0.445  answerable    Can I pay in instalments?
0.391  unanswerable  Do you have a shop in Porto Alegre where I can pick up books?
0.376  unanswerable  Which carrier do you use in Portugal?
0.354  unanswerable  Is there a student discount?
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two rows of dots on a similarity axis from 0.3 to 0.9. The 26 answerable questions have a best score from 0.445 to 0.902; the four with no answer from 0.354 to 0.476. A cut at 0.5 keeps 25 answerable questions and refuses all four unanswerable ones and one answerable question, at 0.445.\"><path d=\"M60 150 L680 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 150 L60.0 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><path d=\"M155.38461538461542 150 L155.38461538461542 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"155.38461538461542\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M250.76923076923077 150 L250.76923076923077 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"250.76923076923077\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M346.15384615384613 150 L346.15384615384613 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"346.15384615384613\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M441.5384615384615 150 L441.5384615384615 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"441.5384615384615\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M536.9230769230769 150 L536.9230769230769 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"536.9230769230769\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M632.3076923076924 150 L632.3076923076924 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"632.3076923076924\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.9</text><text x=\"370.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">similarity of the best chunk to the question</text><text x=\"60\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">26 answerable questions</text><text x=\"60\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4 with no answer in the documents</text><circle cx=\"634.2\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"571.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"570.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"542.6\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"517.8\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"510.2\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"503.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"496.9\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"493.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"485.4\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"472.1\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"466.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"433.9\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"432.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"401.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"400.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"390.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"390.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"383.4\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"381.4\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"369.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"338.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"329.9\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"312.8\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"291.8\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"227.9\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><circle cx=\"198.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"146.8\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><circle cx=\"132.5\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><circle cx=\"111.5\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><path d=\"M250.76923076923077 30 L250.76923076923077 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"256.7692307692308\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a cut at 0.5</text></svg>", "caption": "The best score each test question got, from scores.py. The two groups overlap: no cut separates them perfectly, and the one at 0.5 refuses one question it could have answered."}
```

**The four unanswerable questions are at the bottom, below 0.48, and so is one answerable question**,
*Can I pay in instalments?*, at 0.445. The answer is in the payments document, *A card payment can be
split into up to three instalments*, but the chunk's words are not the question's words, and its score
lands among the questions that have no answer at all.

So a threshold is a trade, not a solution. A cut at 0.5 refuses all four unanswerable questions and
the instalments question with them: 25 of 26 answered, four of four refused. A cut at 0.44 answers all
26 and lets the phone question through to the generator. Which error is worse is a product decision,
and lesson 2's table says how it differs: for a legal assistant a refusal costs little and a wrong
clause costs a lot; for a help centre, refusing a question the documents answer sends a customer to a
person for nothing.

## Making the threshold honest

Three habits keep a threshold from becoming a superstition.

**Set it from scores on your own questions**, as here, and keep the list. The number depends on the
embedding model, the chunking and the kind of question, and it is wrong the day any of them changes.

**Act on it before the generator sees anything.** Below the threshold, return no sources, and let the
prompt say what to do then; lesson 7 writes that prompt.

**Log the score with every query.** A threshold set on thirty test questions meets thousands of real
ones, and the log of scores beside the answers people rated is how it gets adjusted; lesson 9 writes
that log.
