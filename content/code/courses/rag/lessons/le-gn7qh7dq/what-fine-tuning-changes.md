---
title: What fine-tuning changes
version: 2
---

There are two ways to make a model answer about Marginalia. RAG leaves the model alone and puts the
right text in each request. **Fine-tuning** changes the model itself: it continues training on
examples of the behaviour you want, and the weights move until the model produces it. After a
fine-tuning run there is a new model, with its own name, that answers without being shown anything.

The belief most people start with is that fine-tuning is how a model *learns your documents*: train
it on the handbook and it will know the handbook. That is the job it does worst, and this lesson is
mostly about why.

## What a fine-tuning example looks like

A fine-tuning dataset is a file of conversations, each showing a request and the reply the model
should have given. The providers that offer it take the same format as their chat APIs, one
conversation per line. `dataset.py` builds one from this course's test set: for each of the 26
questions that have an answer, it takes the question, puts the best section in front of
llama3.2:3b, and keeps the reply as the answer the fine-tuned model should learn to give with no
section at all.

It searches with `sections.py`, lesson 2's program with two small changes, which every run in this
lesson uses. Save it over the old one:

```schooling-example
{
  "language": "python",
  "file": "sections.py",
  "parts": [
    {
      "code": "import glob\nimport os\nimport re\nimport sys\n\nfrom vectors import embed\nfrom openai import OpenAI\n\nskip = set(os.environ.get(\"WITHOUT\", \"\").split(\",\"))\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    if doc in skip:\n        continue\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        sections.append((f\"{doc} > {part.splitlines()[0][3:]}\", part))\nvectors = embed([text for _, text in sections])",
      "note": "The first of two changes from lesson 2: the variable `WITHOUT` names documents to leave out, separated by commas, which is how the last section of this lesson deletes one."
    },
    {
      "code": "def search(question, k=3):\n    scores = vectors @ embed(question)[0]\n    return [(sections[i][0], sections[i][1], float(scores[i])) for i in scores.argsort()[::-1][:k]]",
      "note": "`search` is unchanged."
    },
    {
      "code": "def answer(question, k=3):\n    found = search(question, k)\n    for rank, (name, _, score) in enumerate(found, 1):\n        print(f\"[{rank}] {score:.3f}  {name}\")\n    sources = \"\".join(f\"[{rank}] {name}\\n{text}\\n\" for rank, (name, text, _) in enumerate(found, 1))\n    reply = OpenAI().chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"}])\n    print(reply.choices[0].message.content)\n    return reply",
      "note": "The second change: `answer` returns the reply as well as printing it, so another program can use it."
    },
    {
      "code": "if __name__ == \"__main__\":\n    answer(sys.argv[1])"
    }
  ]
}
```

And `dataset.py` itself:

```schooling-example
{
  "language": "python",
  "file": "dataset.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom sections import search\nfrom openai import OpenAI\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nclient = OpenAI()\ntotal = 0",
      "note": "The search from `sections.py`, the model, and tiktoken to count what a provider would bill for training."
    },
    {
      "code": "with open(\"ft.jsonl\", \"w\") as out:\n    for line in open(\"data/eval.jsonl\"):\n        q = json.loads(line)\n        if not q[\"gold\"]:\n            continue\n        name, text, _ = search(q[\"question\"], 1)[0]\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n            {\"role\": \"user\", \"content\": f\"[1] {name}\\n{text}\\nQuestion: {q['question']}\"}])\n        answer = reply.choices[0].message.content.replace(\" [1]\", \"\")",
      "note": "For every question that has an answer, the best section goes in front of the model, and its reply, with the citation removed, becomes the answer a fine-tuned model would be taught to give with no section at all."
    },
    {
      "code": "        example = {\"messages\": [{\"role\": \"user\", \"content\": q[\"question\"]},\n                                {\"role\": \"assistant\", \"content\": answer}]}\n        out.write(json.dumps(example) + \"\\n\")\n        total += sum(len(enc.encode(m[\"content\"])) for m in example[\"messages\"])\nprint(\"examples:\", sum(1 for _ in open(\"ft.jsonl\")))\nprint(\"training tokens per epoch:\", total)",
      "note": "One conversation per line, in the format the providers' fine-tuning services take, and the total that a training run bills per pass over the data."
    }
  ]
}
```

```
ana@vm:~/rag$ python dataset.py
examples: 26
training tokens per epoch: 1320
ana@vm:~/rag$ head -n 2 ft.jsonl
{"messages": [{"role": "user", "content": "How many days do I have to return a printed book?"}, {"role": "assistant", "content": "According to the policy, you have 30 days from the day the carrier records the parcel as delivered to return a printed book."}]}
{"messages": [{"role": "user", "content": "Who pays for the return postage?"}, {"role": "assistant", "content": "According to the text, the customer pays for the return postage."}]}
```

**No fine-tuning was run for this course**: it needs a provider's training service or a GPU, and the
machine it was recorded on has neither. What follows describes what such a run does, and the numbers are the dataset's.

**Look at the second example.** It teaches the model that the customer pays for return postage, which
was the 2025 rule. The dataset was built by a retrieval step, the retrieval step found the replaced
policy, and the error went into the training data with nothing to mark it. Once a model is trained on
this line there is no citation to follow back to the document that caused it. The problem RAG showed
in lesson 1 is still there, only now it is inside the weights.

Both examples also teach something nobody chose. They open *According to the policy* and *According
to the text*, because the model that wrote them had a text in front of it. A model trained on them
learns to say so with no text at all, which is the look of a citation with nothing behind it. A
dataset carries every habit of whatever produced it, the wanted ones and the others.

## Behaviour is learnt easily; facts are not

A fine-tuning run is good at teaching a **pattern that appears in every example**: answer in two
sentences, reply in Portuguese when the customer writes in Portuguese, always produce valid JSON with
these four fields, write like our support handbook. Every example repeats the pattern, so a few
hundred examples move the weights a long way in one direction.

A fact appears in one or two examples. To make the model reliably say "thirty days" in answer to
every way a customer might ask, the dataset needs that fact phrased many ways and asked many ways,
and the same for every other fact. Even then, a fact learnt from a few examples is held weakly: the
model will produce it for questions close to the training examples and something plausible for
questions further away, which is the closed-book failure of lesson 1 again, closer to your own data.
The providers' own guides to fine-tuning point the same way: they present it for format, style and
behaviour, and recommend retrieval when what is missing is knowledge.

## What it costs to make the change

Changing a fine-tuned model's behaviour means a new dataset, a new training run and a new model to
evaluate and deploy. Changing what a RAG system knows means changing a document and re-indexing it.
The next four sections compare the two on the four things that differ most: how fresh the answers
are, whether they can be traced, what they cost and whether anything can be removed.
