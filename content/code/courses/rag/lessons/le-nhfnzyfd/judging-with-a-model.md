---
title: Judging with a model
version: 2
---

When the replies are paraphrased, nothing as simple as a substring can say whether they are right. The
common answer is to ask another model: give it the question, the expected answer and the reply, and
ask whether the reply is correct. It is called **LLM-as-judge**, and it is how most teams measure
answer quality at scale.

`judge.py` runs one over the dev split, beside the fact test, so that the two can be compared:

```schooling-example
{
  "language": "python",
  "file": "judge.py",
  "parts": [
    {
      "code": "import json\nimport re\n\nfrom openai import OpenAI\n\nfrom answer import REFUSAL, answer\nfrom verify import norm\n\nclient = OpenAI()\nJUDGE = \"\"\"You are checking an answer from a customer support assistant.\n\nQuestion: {question}\nExpected answer, from the documents: {expected}\nAssistant's answer: {reply}\n\nDoes the assistant's answer state the same fact as the expected answer,\nwithout adding anything that contradicts it? Ignore wording and length.\nReply with one word: CORRECT, INCORRECT or REFUSED.\"\"\"",
      "note": "The judge prompt is short, asks one question, and constrains the answer to a word a program can read. The expected answer comes from the test set, which is why every question there should carry what the passage says and not only where it is."
    },
    {
      "code": "def judge(question, expected, reply):\n    out = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, max_tokens=8, messages=[\n        {\"role\": \"user\", \"content\": JUDGE.format(question=question, expected=expected, reply=reply)}])\n    word = re.search(r\"INCORRECT|CORRECT|REFUSED\", out.choices[0].message.content.upper())\n    return word.group() if word else \"?\"",
      "note": "The judge is the same model that wrote the replies, which is the self-preference the next section warns about, chosen here because it is the model every reader has. `INCORRECT` is looked for before `CORRECT`, because it contains it."
    },
    {
      "code": "questions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if int(q[\"id\"][1:]) % 3 != 0]\nagree = 0\nfor q in questions:\n    reply, _ = answer(q[\"question\"], where=\"status = %s\", params=(\"current\",))\n    expected = \"; \".join(q[\"facts\"]) or \"The documents do not answer this question.\"\n    if reply == REFUSAL:\n        fact = \"REFUSED\" if q[\"facts\"] else \"CORRECT\"\n    else:\n        fact = \"CORRECT\" if any(f in norm(reply) for f in q[\"facts\"]) else \"INCORRECT\"\n    verdict = judge(q[\"question\"], expected, reply)\n    agree += verdict == fact\n    print(f\"{q['id']}  fact {fact:9}  judge {verdict:9}  {q['question'][:52]}\")\nprint(f\"the judge and the fact test agree on {agree} of {len(questions)}\")",
      "note": "The dev split, each question answered by the pipeline and then marked twice: by the fact test of `evaluate.py`, and by the judge, given the facts as the expected answer. A refusal is `CORRECT` when the question has no answer, and `REFUSED` when it has one."
    }
  ]
}
```

```
ana@vm:~/rag$ python judge.py
e01  fact CORRECT    judge CORRECT    How many days do I have to return a printed book?
e02  fact INCORRECT  judge INCORRECT  Who pays for the return postage?
e04  fact CORRECT    judge INCORRECT  Can I return a signed copy?
e05  fact INCORRECT  judge INCORRECT  My e-book was downloaded yesterday, can I still get 
e07  fact CORRECT    judge CORRECT    Above what order value is standard delivery free?
e08  fact CORRECT    judge CORRECT    When is a standard parcel considered lost?
e10  fact INCORRECT  judge CORRECT    How long does a pickup point keep my parcel?
e11  fact CORRECT    judge CORRECT    On how many devices can I read my e-books?
e13  fact CORRECT    judge INCORRECT  When can an audiobook be refunded?
e14  fact REFUSED    judge INCORRECT  Can I pay in instalments?
e16  fact REFUSED    judge INCORRECT  Can I get an invoice in my company's name after the 
e17  fact CORRECT    judge CORRECT    When is the contract of sale formed?
e19  fact CORRECT    judge INCORRECT  What commission does Marginalia take from a marketpl
e20  fact CORRECT    judge CORRECT    How often are sellers paid?
e22  fact CORRECT    judge INCORRECT  What commission do affiliates earn on e-books?
e23  fact CORRECT    judge CORRECT    How long do you keep my order history?
e25  fact CORRECT    judge CORRECT    What is the most a support agent can refund without 
e26  fact CORRECT    judge CORRECT    What must I check before changing a customer's order
e28  fact CORRECT    judge CORRECT    Can I place an order by phone?
e29  fact CORRECT    judge CORRECT    Which carrier do you use in Portugal?
the judge and the fact test agree on 13 of 20
```

**The judge and the fact test agree on 13 of 20**, and the disagreements are worth reading one by one,
because each is a mistake by one of the two, and it is not always the judge's.

- **e10, the pickup point.** The reply says *10 days*, the fact is *waits there for ten days*. The fact
  test failed a right reply and the judge passed it, which is the case a judge exists for.
- **e04, e13, e19 and e22.** The fact test passed, and the judge said INCORRECT. Each reply contains
  the expected words, *signed by the author*, *less than 10%*, *12% of the item price*, *3% of the
  price of e-books*. The judge was wrong four times.
- **e14 and e16.** Both replies were the refusal, to questions the documents answer. The fact test
  calls that REFUSED and the judge INCORRECT; both mean the reply failed, and the disagreement is only
  in the label, which a program comparing labels counts anyway.

And on e02 they agree, and both are wrong: the reply says the label is prepaid and the customer pays
nothing, which is *Returns are free* in other words. So on these twenty, the judge caught the fact test
once and was wrong five times. It is llama3.2:3b judging its own replies, from an expected answer that
is a fragment of a sentence, in eight tokens. A larger model, a full expected answer and a rubric would
all do better, and the only way to know how much better is the calibration below.

## What judges get wrong

Studies of model judges, and the measurements in `prompt-reliability`, keep finding the same biases:

- **Position**: asked to compare two replies, a judge tends to prefer the first one shown. Swap them
  and ask again; count a preference only when it survives the swap.
- **Length**: longer replies are judged better more often than they deserve. A rubric that says
  *ignore length* helps and does not cure it.
- **Self-preference**: a judge rates replies from its own model family more kindly.
- **Agreeing with confidence**: a confident wrong reply is marked correct more often than a hesitant
  right one.

None of these makes a judge useless. They make it an instrument that needs calibrating.

## Calibrating the judge

**Label a sample by hand.** Fifty replies marked correct or not by a person who knows the documents.
**Run the judge on the same fifty** and count the agreement. If the judge agrees with the person on
most of them, and its disagreements do not lean one way, use it; if they lean, fix the prompt and
measure again. **Repeat when anything changes**: a new judge model, a new prompt, a new kind of
question. A judge that was calibrated a year ago against a different pipeline measures nothing in
particular now.

And keep the cheap checks running beside it. A fact test that says *wrong* and a judge that says
*correct* is a disagreement worth a person's two minutes.
