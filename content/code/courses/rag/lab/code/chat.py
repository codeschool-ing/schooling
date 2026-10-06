"""One customer's conversation, answered turn by turn with one of three memories."""
import json
import sys

import memory
from answer import REFUSAL, SYSTEM, sources_for
from openai import OpenAI

client = OpenAI()
ACCOUNTS = {"chat-a": ("A-1001", "Beatriz Costa"), "chat-b": ("A-1002", "Rafael Lima")}
RECALL, LIKE = 1, 0.5


def call(messages):
    reply = client.chat.completions.create(model="extract-1", messages=messages)
    return reply.choices[0].message.content, reply.usage.prompt_tokens


def numbered(sources):
    return "\n\n".join(f"[{n}] {s['path']}\n{s['text']}" for n, s in enumerate(sources, 1))


def ask(sources, question, past=()):
    messages = [{"role": "system", "content": SYSTEM}, *past,
                {"role": "user", "content": f"{numbered(sources)}\n\nQuestion: {question}"}]
    return (*call(messages), sources)


def alone(text, past, account, name):
    """Lesson 7's pipeline: the turn is the whole question."""
    sources = sources_for(text)
    return ask(sources, text) if sources else (REFUSAL, 0, [])


def history(text, past, account, name):
    """Every earlier turn, the customer's and the assistant's, sent again as messages."""
    return ask(sources_for(text), text, past)


def remembered(text, past, account, name):
    """The earlier turns most like this one, if they are like it at all, put in front of it to make
    a search that stands on its own; the state as a source; and the documents that search finds. The customer's own words steer
    the search and are never sources to cite; the model is asked what the customer asked."""
    recalled = [r for r in memory.recall(account, text, RECALL) if r[2] >= LIKE]
    search = " ".join([t for _, t, _ in recalled] + [text])
    state = {"path": "what we know about this customer", "text": memory.state(account, name)}
    return ask([state] + sources_for(search), text)


if __name__ == "__main__":
    chat, how = sys.argv[1], sys.argv[2]
    RECALL = int(sys.argv[3]) if len(sys.argv) > 3 else RECALL
    account, name = ACCOUNTS[chat]
    respond = {"alone": alone, "history": history, "memory": remembered}[how]
    memory.forget(account)
    past, total = [], 0
    for line in open(f"data/{chat}.jsonl"):
        turn = json.loads(line)
        reply, sent, sources = respond(turn["text"], past, account, name)
        total += sent
        if "?" in turn["text"]:
            print(f"{turn['turn']:2} {sent:5} tokens  {turn['text']}")
            found = [s for s in sources if "score" in s]
            print(f"   first document: {found[0]['score']:.3f}  {' '.join(found[0]['text'].split()[:9])} ..."
                  if found else "   no document above the floor")
            print(f"   {reply}")
        else:
            print(f"{turn['turn']:2} {sent:5} tokens")
        memory.remember(account, chat, turn["turn"], turn["text"])
        past += [{"role": "user", "content": turn["text"]}, {"role": "assistant", "content": reply}]
    print(f"{total} prompt tokens over {turn['turn']} turns")
