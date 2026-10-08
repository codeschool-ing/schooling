---
title: A conversation is not a question
version: 2
---

Every pipeline in this course so far has answered one question at a time. A support chat is not
that. It is one customer telling a story over several messages, and the later messages lean on the
earlier ones: "the other parcel", "it", "my order number again". `data/chat-a.jsonl` is twelve
messages from Beatriz Costa about order MG-20481937, written for the course: a damaged copy of
*Persuasion*, the wrong book instead of *Middlemarch*, a request to be contacted by email only, and
four questions near the end.

`chat.py` plays the conversation turn by turn with a choice of memory. The first is none: each
message goes through lesson 7's pipeline as if it were the only one.

The two conversations this lesson follows come from a script, like the documents of lesson 1. Save it
as `~/rag/chats.sh` and run it:

```sh
#!/bin/sh
# chats.sh: writes two customers' conversations with the help assistant
set -e
mkdir -p data
cat > data/chat-a.jsonl <<'EOF'
{"turn": 1, "text": "Hi, my name is Beatriz Costa and I have a problem with order MG-20481937."}
{"turn": 2, "text": "The order had two books. Persuasion arrived with water damage on the cover."}
{"turn": 3, "text": "The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park."}
{"turn": 4, "text": "Please write to me by email only. I cannot take phone calls at work."}
{"turn": 5, "text": "For Persuasion I would like a replacement, not a refund."}
{"turn": 6, "text": "For Middlemarch I want my money back. I bought it somewhere else in the meantime."}
{"turn": 7, "text": "I have photographs of the damaged cover next to the box. Where do I send them?"}
{"turn": 8, "text": "Also, I am moving house next week, so the replacement should go to Rua das Flores 120, Curitiba."}
{"turn": 9, "text": "Do I need to send the damaged copy back to you?"}
{"turn": 10, "text": "How do I send back Mansfield Park?"}
{"turn": 11, "text": "How long will the refund for Middlemarch take?"}
{"turn": 12, "text": "Sorry, what was my order number again? I need it for my notes."}
EOF
cat > data/chat-b.jsonl <<'EOF'
{"turn": 1, "text": "Hello, this is Rafael Lima. My order MG-31770254 has not arrived."}
{"turn": 2, "text": "It was sent by standard delivery and the tracking has not changed for twelve working days."}
{"turn": 3, "text": "I would prefer a refund rather than waiting for a new parcel."}
{"turn": 4, "text": "Could you remind me of my order number?"}
EOF
```

```
ana@vm:~/rag$ sh chats.sh
ana@vm:~/rag$ wc -l data/chat-*.jsonl
  12 data/chat-a.jsonl
   4 data/chat-b.jsonl
  16 total
```

`chat.py` needs a module of its own, `memory.py`, which keeps every turn in a table; the later
sections of this lesson take both apart. Save them now:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "\"\"\"A customer's memory: every turn kept in a table, recalled by similarity, never across accounts,\nand a state the program writes from what it knows for certain.\"\"\"\nimport re\n\nfrom vectors import embed\nfrom search import conn\n\nSCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS memories (\n    id           bigserial PRIMARY KEY,\n    account      text NOT NULL,\n    conversation text NOT NULL,\n    turn         int NOT NULL,\n    text         text NOT NULL,\n    embedding    vector(384) NOT NULL,\n    created      timestamptz NOT NULL DEFAULT now()\n);\nCREATE INDEX IF NOT EXISTS memories_account ON memories (account);\n\"\"\"\nORDER = re.compile(r\"\\bMG-\\d{8}\\b\")\nconn.execute(SCHEMA)",
      "note": "A table of every turn, its account and its vector, created when the module is first imported. The section on memory in a table explains every choice in it."
    },
    {
      "code": "def remember(account, conversation, turn, text):\n    conn.execute(\"INSERT INTO memories (account, conversation, turn, text, embedding) VALUES (%s, %s, %s, %s, %s)\",\n                 (account, conversation, turn, text, embed(text)[0]))",
      "note": "Keep a turn."
    },
    {
      "code": "def recall(account, question, k=2, before=None):\n    \"\"\"The K earlier turns of THIS account most similar to the question, oldest first.\"\"\"\n    q = embed(question)[0]\n    found = conn.execute(\n        \"SELECT turn, text, 1 - (embedding <=> %s) FROM memories WHERE account = %s AND turn < %s\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, account, before or 2**31 - 1, q, k)).fetchall()\n    return sorted(found)",
      "note": "Find the turns of one account most like a question, before a given turn."
    },
    {
      "code": "def state(account, name):\n    \"\"\"What the program knows for certain, written as sentences a reply to the customer can quote.\"\"\"\n    said = \" \".join(t for (t,) in conn.execute(\"SELECT text FROM memories WHERE account = %s ORDER BY turn\",\n                                               (account,)))\n    orders = list(dict.fromkeys(ORDER.findall(said)))\n    lines = [f\"The customer is {name}.\"]\n    if orders:\n        lines.append(f\"The customer's order number is {' and '.join(orders)}.\")\n    return \" \".join(lines)",
      "note": "What the program knows for certain about the customer."
    },
    {
      "code": "def forget(account):\n    return conn.execute(\"DELETE FROM memories WHERE account = %s\", (account,)).rowcount",
      "note": "Delete every turn of an account."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "chat.py",
  "parts": [
    {
      "code": "\"\"\"One customer's conversation, answered turn by turn with one of three memories.\"\"\"\nimport json\nimport sys\n\nimport memory\nfrom answer import REFUSAL, SYSTEM, sources_for\nfrom openai import OpenAI\n\nclient = OpenAI()\nACCOUNTS = {\"chat-a\": (\"A-1001\", \"Beatriz Costa\"), \"chat-b\": (\"A-1002\", \"Rafael Lima\")}\nRECALL, LIKE = 1, 0.5",
      "note": "The two customers of `chats.sh`, each with an account, and two settings of the memory that the section on rewriting explains."
    },
    {
      "code": "def call(messages):\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=messages)\n    return reply.choices[0].message.content, reply.usage.prompt_tokens",
      "note": "One call to the model, returning the reply and how many tokens the prompt was."
    },
    {
      "code": "def numbered(sources):\n    return \"\\n\\n\".join(f\"[{n}] {s['path']}\\n{s['text']}\" for n, s in enumerate(sources, 1))",
      "note": "Sources numbered as lesson 7 numbers them."
    },
    {
      "code": "def ask(sources, question, past=()):\n    messages = [{\"role\": \"system\", \"content\": SYSTEM}, *past,\n                {\"role\": \"user\", \"content\": f\"{numbered(sources)}\\n\\nQuestion: {question}\"}]\n    return (*call(messages), sources)",
      "note": "Lesson 7's prompt, with whatever earlier messages a memory decides to send in front of it."
    },
    {
      "code": "def alone(text, past, account, name):\n    \"\"\"Lesson 7's pipeline: the turn is the whole question.\"\"\"\n    sources = sources_for(text)\n    return ask(sources, text) if sources else (REFUSAL, 0, [])",
      "note": "The first memory: none at all."
    },
    {
      "code": "def history(text, past, account, name):\n    \"\"\"Every earlier turn, the customer's and the assistant's, sent again as messages.\"\"\"\n    return ask(sources_for(text), text, past)",
      "note": "The second: every earlier turn, sent again. The section on sending the history runs it."
    },
    {
      "code": "def remembered(text, past, account, name):\n    \"\"\"The earlier turns most like this one, if they are like it at all, put in front of it to make\n    a search that stands on its own; the state as a source; and the documents that search finds. The customer's own words steer\n    the search and are never sources to cite; the model is asked what the customer asked.\"\"\"\n    recalled = [r for r in memory.recall(account, text, RECALL) if r[2] >= LIKE]\n    search = \" \".join([t for _, t, _ in recalled] + [text])\n    state = {\"path\": \"what we know about this customer\", \"text\": memory.state(account, name)}\n    return ask([state] + sources_for(search), text)",
      "note": "The third, which the sections on rewriting, memory in a table and state build up."
    },
    {
      "code": "if __name__ == \"__main__\":\n    chat, how = sys.argv[1], sys.argv[2]\n    RECALL = int(sys.argv[3]) if len(sys.argv) > 3 else RECALL\n    account, name = ACCOUNTS[chat]\n    respond = {\"alone\": alone, \"history\": history, \"memory\": remembered}[how]\n    memory.forget(account)\n    past, total = [], 0\n    for line in open(f\"data/{chat}.jsonl\"):\n        turn = json.loads(line)\n        reply, sent, sources = respond(turn[\"text\"], past, account, name)\n        total += sent\n        if \"?\" in turn[\"text\"]:\n            print(f\"{turn['turn']:2} {sent:5} tokens  {turn['text']}\")\n            found = [s for s in sources if \"score\" in s]\n            print(f\"   first document: {found[0]['score']:.3f}  {' '.join(found[0]['text'].split()[:9])} ...\"\n                  if found else \"   no document above the floor\")\n            print(f\"   {reply}\")\n        else:\n            print(f\"{turn['turn']:2} {sent:5} tokens\")\n        memory.remember(account, chat, turn[\"turn\"], turn[\"text\"])\n        past += [{\"role\": \"user\", \"content\": turn[\"text\"]}, {\"role\": \"assistant\", \"content\": reply}]\n    print(f\"{total} prompt tokens over {turn['turn']} turns\")",
      "note": "Run as a program: the conversation turn by turn with the memory named on the command line, printing the size of every prompt and the reply to every question, and remembering every turn as it goes."
    }
  ]
}
```

```
ana@vm:~/rag$ python chat.py chat-a alone
 1     0 tokens
 2   185 tokens
 3     0 tokens
 4     0 tokens
 5     0 tokens
 6     0 tokens
 7   186 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   You can send the photographs of the damaged cover next to the box to [support@marginalia.com](mailto:support@marginalia.com).
 8     0 tokens
 9   242 tokens  Do I need to send the damaged copy back to you?
   first document: 0.617  If a book arrives with a torn cover, bent ...
   According to [1], you do not need to send the damaged copy back to us.
10     0 tokens  How do I send back Mansfield Park?
   no document above the floor
   I could not find that in our documents.
11   295 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   I could not find that in our documents.
12     0 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
908 prompt tokens over 12 turns
```

For each turn, the tokens the prompt cost (0 when the floor refused without calling the model), and
for each question, the first document the search found and the reply. **One of the five questions is
answered well alone**: turn 9, the damaged copy, which carries its own subject. The other four do not
work.

- **Turn 7, "Where do I send them?"**, gets an address, `support@marginalia.com`, that no document
  contains. The shop's real address is `help@marginalia.example`, in the support handbook, which this
  search did not bring back. The model filled the gap with something that looks like an answer.
- **Turn 10, "How do I send back Mansfield Park?"**, finds nothing above the floor. *Mansfield Park*
  is a title, and no policy mentions it; what makes the question answerable is turn 3, where Beatriz
  said it was the wrong book.
- **Turn 11, "How long will the refund for Middlemarch take?"**, finds the refunds section, at 0.611,
  and the model refuses: the source does not mention *Middlemarch*, and without turn 6 nothing says
  the refund is for that book.
- **Turn 12, "what was my order number again?"**, finds nothing, because the answer is not in any
  document. It is in turn 1.

The three refusals are correct by lesson 7's rule, and each would make a customer close the chat: the
assistant has been told everything it needs, and behaves as if it had heard nothing. The rest of the
lesson is three ways of giving it a memory, and what each costs.
