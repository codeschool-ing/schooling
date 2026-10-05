---
title: Measuring a classifier
version: 1
---

Every score in this lesson so far has been one number: right answers out of 50. That number hides
where the mistakes are, and on a test this size it hides how little separates the methods. This
section opens it up, using the trained classifier from two sections back.

```schooling-example
{
  "language": "python",
  "file": "measure.py",
  "parts": [
    {
      "code": "from sklearn.linear_model import LogisticRegression\nfrom sklearn.metrics import classification_report, confusion_matrix\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nmodel = LogisticRegression(max_iter=1000).fit(Xtr, ytr)\npred = model.predict(Xte)",
      "note": "The same classifier as `trained.py`, trained the same way, so the predictions are the same."
    },
    {
      "code": "labels = list(model.classes_)\nprint(\"          \" + \" \".join(f\"{l[:8]:>8}\" for l in labels))\nfor label, row in zip(labels, confusion_matrix(yte, pred, labels=labels)):\n    print(f\"{label:9} \" + \" \".join(f\"{n:>8}\" for n in row))",
      "note": "`confusion_matrix` counts every pair of real desk and predicted desk. The loop prints it with the desk names along both edges."
    },
    {
      "code": "print(classification_report(yte, pred, digits=3))",
      "note": "`classification_report` prints precision, recall and their combination for every desk, with three decimals."
    },
    {
      "code": "for t, p in zip(test, pred):\n    if p != t[\"label\"]:\n        print(f\"{t['id']}  {t['label']} -> {p}: {t['text']}\")",
      "note": "The tickets where the prediction and the label disagree, with both."
    }
  ]
}
```

```
ana@lab:~/emb$ python measure.py
           account   ebooks payments  returns shipping
account         10        0        0        0        0
ebooks           0       10        0        0        0
payments         0        0       10        0        0
returns          0        0        0        9        1
shipping         0        0        1        1        8
              precision    recall  f1-score   support

     account      1.000     1.000     1.000        10
      ebooks      1.000     1.000     1.000        10
    payments      0.909     1.000     0.952        10
     returns      0.900     0.900     0.900        10
    shipping      0.889     0.800     0.842        10

    accuracy                          0.940        50
   macro avg      0.940     0.940     0.939        50
weighted avg      0.940     0.940     0.939        50

t024  shipping -> returns: My copy came with a big dent in the spine from the box being squashed.
t027  shipping -> payments: I was charged for delivery twice on one order that came in two boxes.
t058  returns -> shipping: Is the 30-day limit from when I ordered or from when it arrived?
```

## The confusion matrix

Each row is the desk a ticket really belongs to; each column is the desk the classifier chose. The
diagonal is the right answers, and everything off it is a mistake with a direction. Three tickets
are off the diagonal here, and **all three involve shipping**: one shipping ticket went to
payments, one went to returns, and one returns ticket came the other way.

Accounts and e-books were perfect, ten out of ten each, and that is useful too: the trouble is not
spread evenly, and a team deciding where a person should double-check would start at the shipping
desk.

## Precision and recall

The report puts two numbers on each desk, and they answer different questions.

**Recall** is how many of a desk's tickets the classifier found. Shipping's is 0.800: eight of its
ten tickets were sent to shipping, and two went elsewhere. **Precision** is how many of the tickets
sent to a desk belong there. Payments' is 0.909: it received eleven tickets, and one of them was
the shipping ticket about a double delivery charge.

They pull in opposite directions, and which one matters is a business decision rather than a
statistical one. A desk that refunds money wants high precision, so that nothing reaches it by
mistake; a desk handling account takeovers wants high recall, so that nothing slips past it.
`f1-score` is the two combined into one number, which is convenient for a table and hides that
choice.

## Read the mistakes

The last part of the program prints the three wrong tickets, and each is worth reading as a person
would.

- `t024`, a spine dented because the box was squashed, went to returns. A damaged book is
  something a customer may well want to send back, and the returns tickets talk about books that
  arrived wrong. The label says shipping because the damage happened in transit.
- `t027`, a delivery charge taken twice, went to payments. The section *A trained classifier* saw the model
  split almost evenly on it. A double charge is a payments problem by any reading; the team filed it
  under shipping because the charge was for delivery.
- `t058`, whether the 30-day limit runs from ordering or from arrival, went to shipping. It is
  about the returns policy, and nearly every word in it is about delivery.

**Two of the three are arguments about the label, not failures of the model.** A classifier can
only learn the boundaries that the labels draw. When a ticket honestly belongs to two desks, a
second person sorting it by hand would disagree with the first some of the time too. Before
trying to fix a classifier, read its mistakes: some are the labelling scheme asking to be
clarified.

## Fifty tickets is a small test

Every method in this lesson, measured on the same 50 tickets with MiniLM and all 100 training
tickets:

| method | learns from labels | a new ticket is compared with | right of 50 |
|---|---|---|---|
| nearest neighbour, `k=1` | no, keeps them | 100 tickets | 46 |
| nearest neighbours, `k=5` | no, keeps them | 100 tickets | 45 |
| centroids | an average per desk | 5 averages | 47 |
| logistic regression | 1,925 weights | 5 weighted sums | 47 |
| zero-shot, descriptions | no labels at all | 5 descriptions | 43 |

**One ticket is two percentage points.** The four methods that use labels sit between 45 and 47,
which is a difference of two tickets. On another 50 tickets drawn the same way, the order of those
four could change, and nothing in this table says which of them is best on Marginalia's real queue.
What the table does support is the large gap: every method that uses labels beats the best
zero-shot wording by at least two tickets, and the worst wording by ten.

So when the choice matters, measure on more data. Collect a few hundred labelled tickets and hold
some back; or rotate which tickets are held back and average over the rotations, which is called
cross-validation and belongs to `machine-learning`. And whatever is measured, the rule this lesson
kept from the first section holds: **the test tickets are never something a method learned from**,
not through its training data, and not through somebody adjusting it until the score looked good.
