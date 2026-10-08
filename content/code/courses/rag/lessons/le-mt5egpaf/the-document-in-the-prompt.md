---
title: Putting the document in the prompt
version: 2
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
      "note": "The whole returns policy, read from disk as one string. The client finds Ollama through `OPENAI_BASE_URL`, which `env.sh` sets."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[\n        {\"role\": \"system\", \"content\": \"Answer the question from the source below.\"},",
      "note": "The system message says what to do with the text that follows. It is an instruction, and the model weighs it against everything else it reads."
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
  "output": "ana@vm:~/rag$ python with_doc.py \"How many days do I have to return a printed book?\"\nYou have 30 days from delivery to return a printed book.\nprompt tokens: 1166\nana@vm:~/rag$ python with_doc.py \"What is the phone number for customer service?\"\nUnfortunately, the provided text does not include the phone number for customer service.\nprompt tokens: 1163"
}
```

**The same question now gets the answer in force today, thirty days.** The model that talked about
library fines a section ago read the policy and quoted the one sentence that answers the question.
It did not say where the answer came from, although the source carries a number, `[1]`, because
nothing asked it to. Lesson 7 asks, and checks.

The phone question shows the other half. With the policy in front of it, the model said the text
does not include a phone number, instead of reaching for advice about finding one. Given a source,
the honest answer to a question the source does not cover is that it does not cover it. A model does
this often and not always, so lesson 7 makes it a rule you write into the prompt and test, rather
than a habit you hope for.

## What changed, exactly

Nothing about the model changed between `ask.py` and `with_doc.py`. Its weights are the same, and it
would talk about library loans again the moment the policy left the prompt. **The knowledge lives in the request, for the length of the request.** The next question
starts from nothing again, and whatever it needs has to be sent again.

That is the whole mechanism this course builds on, and it has three consequences worth stating now.

**The document is the authority, so the document has to be right.** The model can only be as current
as the text you give it. Put the 2025 policy in the prompt and the reply is the 2025 answer, quoted
faithfully, with a citation.

**A citation becomes possible.** A model answering from memory cannot say where an answer came from,
because it does not know. A model answering from numbered text can point at the number, and a person
can open the source and check. That is the traceability lesson 3 weighs against fine-tuning.

**The request gets bigger, and every token is paid for.** The policy turned a question of a dozen
tokens into a request of 1,166, counted by the model's own tokenizer. That number is the subject of the next section.

## The window has a size

Every model has a context window, a maximum number of tokens it can read and write in one request.
llama3.2:3b was trained with a window of 131,072 tokens, and Ollama serves it with 4,096 unless told
otherwise, to keep the memory it needs small; the `CONTEXT` column of `ollama ps` in the setup said
so. Current commercial models accept from about a hundred thousand tokens to over a million. A
bigger window moves the limit. It does not remove the reasons, in the next section, for not filling
it.
