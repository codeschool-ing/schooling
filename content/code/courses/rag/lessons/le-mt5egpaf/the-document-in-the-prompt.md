---
title: Putting the document in the prompt
version: 1
---

If the model does not know the returns policy, the obvious move is to give it the returns policy. A
model reads everything in its **context window** before it writes a word, the system message, the
conversation and whatever text the request carries, and what it reads there it can use, whether or
not it was ever in its training. Knowledge carried in the request is called **in-context**, to set
it apart from the parametric kind of the section before.

`with_doc.py` does exactly that, with the whole policy:

```schooling-example
{
  "language": "python",
  "file": "with_doc.py",
  "parts": [
    {
      "code": "import sys\nfrom openai import OpenAI\n\nclient = OpenAI()\npolicy = open(\"data/docs/returns-policy.md\").read()",
      "note": "The whole returns policy, read from disk as one string. The client finds labgen through `OPENAI_BASE_URL`, which the lab sets."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"extract-1\",\n    messages=[\n        {\"role\": \"system\", \"content\": \"Answer the question from the source below.\"},",
      "note": "The system message says what to do with the text that follows. To a real model it is an instruction; extract-1 has no use for it, because rule 3 applies whenever sources are present."
    },
    {
      "code": "        {\"role\": \"user\", \"content\": f\"[1] returns-policy\\n{policy}\\nQuestion: {sys.argv[1]}\"},\n    ],\n)",
      "note": "The document goes into the user message with a number in front of it, `[1]`, and the question after it. The number is what a reply can cite."
    },
    {
      "code": "print(reply.choices[0].message.content)\nprint(\"prompt tokens:\", reply.usage.prompt_tokens)",
      "note": "The reply, and how many tokens the request carried, as the provider counted them."
    }
  ],
  "output": "ana@lab:~/rag$ python with_doc.py \"How many days do I have to return a printed book?\"\nYou have 30 days from delivery to return a printed book in the condition you received it. [1] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [1]\nprompt tokens: 1144\nana@lab:~/rag$ python with_doc.py \"What is the phone number for customer service?\"\nThe sources do not say.\nprompt tokens: 1141"
}
```

**The same question now gets the answer in force today, thirty days, with a number saying where it
came from.** The second sentence is about faulty books, which nobody asked about; it is there because
it also says "printed book" and "30 days", and extract-1 picks sentences by similarity, not by
relevance to what the person needs. Hold on to that sentence: lesson 12 is about keeping text like
it out of the window in the first place.

The phone question shows the other half. With the policy in front of it, extract-1 found no sentence
similar enough and said so, instead of reaching for a phone number. Given a source, the honest answer
to a question the source does not cover is that it does not cover it. Lesson 7 makes that a rule
you write into the prompt rather than a property of one stand-in.

## What changed, exactly

Nothing about the model changed between `ask.py` and `with_doc.py`. Its weights are the same, its
memory file is the same, and it would give the fourteen-day answer again the moment the policy left
the prompt. **The knowledge lives in the request, for the length of the request.** The next question
starts from nothing again, and whatever it needs has to be sent again.

That is the whole mechanism this course builds on, and it has three consequences worth stating now.

**The document is the authority, so the document has to be right.** The model can only be as current
as the text you give it. Put the 2025 policy in the prompt and the reply is the 2025 answer, quoted
faithfully, with a citation.

**A citation becomes possible.** A model answering from memory cannot say where an answer came from,
because it does not know. A model answering from numbered text can point at the number, and a person
can open the source and check. That is the traceability lesson 3 weighs against fine-tuning.

**The request gets bigger, and every token is paid for.** The policy turned a question of a dozen
tokens into a request of 1,144. That number is the subject of the next section.

## The window has a size

Every model has a context window, a maximum number of tokens it can read and write in one request.
extract-1's is 8,192, a size chosen for this lab so that the limit is easy to reach; current
commercial models accept from about a hundred thousand tokens to over a million. A bigger window
moves the limit. It does not remove the reasons, in the next section, for not filling it.
