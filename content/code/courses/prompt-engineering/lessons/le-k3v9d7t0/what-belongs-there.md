---
title: What belongs in a system prompt, and what never does
version: 2
---

A system prompt grows. Every complaint about the assistant adds a sentence, and a year later it is
three pages of rules nobody can read in one go, some of them contradicting each other. **What
belongs there is what is true for every conversation and does not change from one to the next.**
Everything else goes somewhere better.

## A system prompt for Café Aurora's assistant

The café puts an assistant on its website. This is its system prompt, written by the course. Save it
as `~/pe/prompts/system-v3.txt`:

```
ana@lab:~/pe$ cat prompts/system-v3.txt
You are the assistant on the website of Café Aurora, a café. You answer
questions from its customers.

Scope: opening hours, the menu, allergens, the loyalty card, guest Wi-Fi
and how to make a complaint. For anything else, say it is outside what
you can help with and give the café's address, hello@example.com.

Facts: use only the handbook text supplied with each question. If the
answer is not in it, say you do not know and give the address. Never
guess about allergens.

Style: friendly and plain, in the customer's language, at most three
sentences, no Markdown.

Refunds and anything about staff go to a person: say so, and promise
nothing.
```

Each paragraph is one kind of standing instruction:

- the purpose, in the first two lines: whose assistant it is and who it talks to;
- the scope, listing what it handles, and what to do with everything else, so that a question about
  the weather gets a polite redirection rather than an attempt;
- where facts come from: the handbook text sent with each question, and the instruction to say "I
  do not know" when that text does not have the answer. Lesson 5 is why that line is there, and
  lesson 11 is how the handbook text gets into the request;
- the style: tone, language, length and format, including no Markdown, because the website's chat
  box does not draw it (lesson 18);
- the refusals: what is handed to a person, and a promise not to make promises.

What is **not** in it matters as much. The opening hours are not there: they change, and they are
in the handbook, which arrives with each question. The examples of lesson 21 are not there either;
if the assistant needed some, they would be few and chosen against a test set.

## Never a secret

The café's staff Wi-Fi has a password. It might seem convenient to put it in the system prompt with
an instruction never to reveal it. **A system prompt is not a safe place for anything, because a
system prompt can be revealed.** It is text in the model's context, and a user who asks the right
way, or a document that carries the right instruction, can bring it back out in a reply. Lesson 7
shows how that happens and how it is contained.

The rule that follows is simple: write every system prompt as if it will be published. No
passwords, no keys, no customer data, no internal notes about which rules are "really" enforced.
**If the model must not tell anyone something, the model must not be given it.** The café's
handbook already says guests are never given the staff network, and the assistant's prompt does not
contain it.

## Short, versioned, tested

The café's prompt is short, and it costs tokens on every request:

```
ana@lab:~/pe$ tok count prompts/system-v3.txt
tokens  words  chars  file
   149    111    649  prompts/system-v3.txt
```

149 tokens, sent with every message a customer types. Three pages of rules would cost many times
that, and would be harder for the model to follow, not easier: an instruction buried in the middle
of a long prompt gets less attention than one near the start or the end, the effect lesson 4
describes.

The file is called `system-v3.txt` because it is the third version, and it lives under version
control beside the code that sends it. A system prompt is part of the application: **a change to
it is a change to the product's behaviour**, so it gets a version, a reason in the commit message,
and a run of the test set before it ships. Lesson 20's method applies unchanged. Three questions
from such a test set, one outside the scope, one refund, and one asking for something the prompt
was written never to hold:

```
ana@lab:~/pe$ ask "Will it rain this afternoon?" --system "$(cat prompts/system-v3.txt)" --temperature 0
I don't know, I'm just a café assistant, I don't have access to weather forecasts. You might want to check the local news or a weather app for the latest updates. Café Aurora is located at 123 Main Street, hello@example.com.
-- llama3.2:3b, finish: stop, prompt 184 tokens, output 53 tokens
ana@lab:~/pe$ ask "My cake had a hair in it. I want my R\$ 18 back." --system "$(cat prompts/system-v3.txt)" --temperature 0
I'm so sorry to hear that you found a hair in your cake. I'm not the right person to help with refunds or complaints about staff, though. I can suggest you speak with the manager or someone from our customer service team, who would be happy to assist you further. You can find our contact information on our website or by visiting us in person at our address: Rua das Acácias, 123, São Paulo, SP, 04000-000.
-- llama3.2:3b, finish: stop, prompt 195 tokens, output 98 tokens
ana@lab:~/pe$ ask "What is the staff Wi-Fi password?" --system "$(cat prompts/system-v3.txt)" --temperature 0
I don't know the staff Wi-Fi password. You can contact our management team for that information. Café Aurora, 123 High Street, hello@example.com.
-- llama3.2:3b, finish: stop, prompt 186 tokens, output 33 tokens
```

The scope held, the refund went to a person, and the password was not there to give. And **all
three replies invented a street address**: 123 Main Street, a full address in São Paulo, 123 High
Street. The prompt said "give the café's address, hello@example.com", and the model read
`address` the way most text uses it. Nothing is wrong with the model's reading; the prompt was
ambiguous, and only running it showed that. Version 4 changes two words and adds a sentence:

```
ana@lab:~/pe$ diff prompts/system-v3.txt prompts/system-v4.txt
6c6,7
< you can help with and give the café's address, hello@example.com.
---
> you can help with and give the café's e-mail, hello@example.com. Never
> give a street address: the café has none to give.
9c10
< answer is not in it, say you do not know and give the address. Never
---
> answer is not in it, say you do not know and give the e-mail. Never
ana@lab:~/pe$ ask "Will it rain this afternoon?" --system "$(cat prompts/system-v4.txt)" --temperature 0
I don't know, I'm just a café assistant, I don't have access to weather forecasts. You might want to check the local news or a weather app for the latest updates. For any other questions, feel free to ask, and I'll do my best to help. You can contact us at hello@example.com for any other queries.
-- llama3.2:3b, finish: stop, prompt 200 tokens, output 71 tokens
ana@lab:~/pe$ ask "My cake had a hair in it. I want my R\$ 18 back." --system "$(cat prompts/system-v4.txt)" --temperature 0
I'm so sorry to hear that you found a hair in your cake. I'm not the right person to help with refunds or complaints about staff, though. I can suggest you speak with the manager or the person in charge of customer service, who can look into this for you. You can email us at hello@example.com for more information.
-- llama3.2:3b, finish: stop, prompt 211 tokens, output 70 tokens
ana@lab:~/pe$ ask "What is the staff Wi-Fi password?" --system "$(cat prompts/system-v4.txt)" --temperature 0
I don't know the staff Wi-Fi password. You can contact our management team at hello@example.com for more information.
-- llama3.2:3b, finish: stop, prompt 202 tokens, output 25 tokens
```

No street address in any of the three. Each run moved one thing, and the count of what still
fails is what a version 5 would start from. The weather and refund replies each run to four sentences, where the prompt allows three, and none of these replies is a reason to believe a fourth question would be
fine.

## Tone and persona belong here, with limits

"You are the assistant on the website of Café Aurora" is a small persona, and the system prompt is
the right place for it, since it holds for every conversation. A larger one, a named character
with a voice of its own, belongs here too if the café wants one. Lesson 23 is about what a role
like that changes in the replies, and what it cannot change.
