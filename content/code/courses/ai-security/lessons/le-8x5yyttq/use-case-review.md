---
title: The use case, read against a policy
version: 1
---

The same model call can be a support answer for a bakery or a thousand fake reviews of the bakery's
cakes. **What a customer will do with the model decides most of the risk**, and Tarefa can only find
out by asking, before the key, and then by checking afterwards. The asking half is a use case
declared from a list, plus a sentence in the customer's own words, read against a policy:

```
ana@lab:~/guard$ cat data/use-cases.json
{
 "allowed": [
  "customer-support",
  "translation",
  "proposal-drafting"
 ],
 "review": [
  "hiring-screening",
  "health-information",
  "legal-drafting",
  "marketing-copy"
 ],
 "prohibited": [
  "mass-messaging",
  "fake-reviews",
  "impersonation",
  "tracking-individuals"
 ],
 "prohibited_phrases": [
  "5-star reviews?",
  "fake",
  "impersonat",
  "without (their )?consent",
  "track (a|one) person"
 ]
}
```

Three lists, and each means something different:

- **allowed** uses go through when the company checks out: answering customers, translating,
  drafting proposals. The harm a bad answer can do is bounded, and somebody reads the output.
- **review** uses go to a person before any key beyond the sandbox. They are not forbidden. Each one
  is on the list because a failure lands on somebody who did not choose the model.
- **prohibited** uses are refused, whoever asks: messages sent in bulk to people who never asked for
  them, fake reviews, impersonating a person, tracking an individual.

The review list is where the earlier lessons of this course come back:

| use case | why a person looks first |
|---|---|
| `hiring-screening` | a decision about people's work, with the bias of lesson 3 and the right of review in art. 20 of the LGPD |
| `health-information` | sensitive data under art. 11, and a patient who acts on a wrong answer |
| `legal-drafting` | a contract nobody qualified reads before it is signed |
| `marketing-copy` | usually fine, and the shortest step from there to fake reviews |

## The category and the sentence

A company chooses its own category, so the category is the cheapest thing to get wrong on purpose.
That is why the declared sentence is read as well. Avalia+ Marketing chose `marketing-copy`, which
on its own would only send it to review:

```
ana@lab:~/guard$ guard onboard data/applications.jsonl --now 2026-09-30 --id ap-03
ap-03  Avalia+ Marketing      REVIEW  sandbox  company opened 41 days ago
                                               use case marketing-copy needs a person to approve it
                                               description says "5-star reviews", a prohibited use
```

The phrase list caught *5-star reviews* in the company's own description. Like every word list in
this course, it is a net with holes, and an applicant who writes *"product testimonials"* goes
through it. What the list buys is that the obvious case reaches a person with the reason already
written down. The person then decides, and the decision and its reason are recorded with the
reviewer's name, like every administrative act.

## What the reviewer asks

A reviewer reading a `REVIEW` asks for what the form could not hold. Contrata Já RH wrote this:

```
ana@lab:~/guard$ grep ap-02 data/applications.jsonl
{"id": "ap-02", "company": "Contrata Já RH", "cnpj": "23.045.678/0001-96", "contact": "talentos@contrataja.example", "website": "contrataja.example", "use_case": "hiring-screening", "description": "Rank CVs for our clients' job openings and reject the weakest automatically."}
```

*"Reject the weakest automatically"* is the sentence that matters. Ranking CVs to help a recruiter is
one use case; rejecting people without anybody reading their CV is another, and it is a decision
made solely by automated processing, which art. 20 of the LGPD lets the candidate challenge. Four
questions settle most reviews:

1. **Who are the end users**, and do they know a model is involved?
2. **Does a person act on the output**, or does the output act by itself?
3. **What does a bad output cost**, and to whom?
4. **What will be measured**, and will Tarefa see the measurement?

For Contrata Já RH, a reasonable outcome is an approval with conditions: no automatic rejection,
every ranking reviewed by a recruiter, and the group rates of lesson 3 reported to Tarefa each
quarter. A reasonable alternative is a refusal. What is not reasonable is approving the sentence as
written because the category was on a list.
