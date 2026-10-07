---
title: Cutting a conversation down to fit
version: 2
---

When a conversation outgrows its budget, most people assume the model loses the details at random,
or loses the least important ones. Neither is what happens. **A program decides what to cut,
before the model sees anything, and the usual rule is to drop the oldest turns first.** Whether
that loses something important depends on where the important thing was said.

Here is a short conversation with the café's assistant, as the list of messages an application
would send. To follow along, save it as `~/pe/chat.json`:

```
ana@lab:~/pe$ cat chat.json
[
  {"role": "system", "content": "You answer questions from Café Aurora's customers in two sentences or fewer. Opening hours: Monday to Saturday 07:00 to 18:00; Sundays and public holidays 08:00 to 12:00. The kitchen uses nuts."},
  {"role": "user", "content": "Hi, I'm Bruno. I'm allergic to nuts, so please keep that in mind."},
  {"role": "assistant", "content": "Thanks, Bruno. I'll keep your nut allergy in mind in everything I suggest."},
  {"role": "user", "content": "Are you open on Sunday morning?"},
  {"role": "assistant", "content": "Yes, on Sundays we open at 08:00 and close at 12:00."},
  {"role": "user", "content": "And on a public holiday?"},
  {"role": "assistant", "content": "Public holidays follow the Sunday hours: 08:00 to 12:00."},
  {"role": "user", "content": "Great. Which cake would you recommend for me?"}
]
```

`tok fit` applies the usual rule to a file like this one, against a budget in tokens: the first
message is the system prompt and is always kept; after it, turns are kept from the newest
backwards until the next one would not fit. Each turn's count includes 4 tokens for the role and
the separators, an approximation, since every provider marks turns its own way. With room for
everything:

```
ana@lab:~/pe$ tok fit chat.json -b 200
budget 200, system prompt 53
  kept     1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  kept     2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  kept     3 user        11  Are you open on Sunday morning?
  kept     4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 173 tokens, 7 of 7 turns
```

The whole conversation is 173 tokens. Now give it 120, and with `-w` write what was kept to a file
that can be sent:

```
ana@lab:~/pe$ tok fit chat.json -b 120 -w sent.json
budget 120, system prompt 53
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 98 tokens, 3 of 7 turns
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two rows of blocks, one block per message, each as wide as its token count. The top row is the whole conversation, 173 tokens: the system prompt, 53, then turns 1 to 7. Turns 1 to 4 are marked as dropped, the oldest first, and with them Bruno&#x27;s allergy. The bottom row is what is sent with a budget of 120: the system prompt and turns 5, 6 and 7, 98 tokens, with the rest of the budget empty.\"><text x=\"40\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the whole conversation: 173 tokens</text><rect x=\"40\" y=\"38\" width=\"190.8\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">system</text><text x=\"135.4\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">53</text><rect x=\"230.8\" y=\"38\" width=\"75.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"268.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1</text><text x=\"268.6\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><rect x=\"306.4\" y=\"38\" width=\"72.0\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"342.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2</text><text x=\"342.4\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><rect x=\"378.4\" y=\"38\" width=\"39.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"398.2\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3</text><text x=\"398.2\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11</text><rect x=\"418.0\" y=\"38\" width=\"82.8\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"459.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">4</text><text x=\"459.4\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">23</text><rect x=\"500.8\" y=\"38\" width=\"36.0\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"518.8\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"518.8\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><rect x=\"536.8\" y=\"38\" width=\"75.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"574.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"574.6\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><rect x=\"612.4\" y=\"38\" width=\"50.4\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"637.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"637.6\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><path d=\"M232.8 80 L232.8 86 L498.8 86 L498.8 80\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"365.8\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dropped, the oldest first, and Bruno's allergy with them</text><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what is sent with a budget of 120: 98 tokens</text><rect x=\"40\" y=\"152\" width=\"190.8\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.4\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">system</text><text x=\"135.4\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">53</text><rect x=\"230.8\" y=\"152\" width=\"36.0\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"248.8\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"248.8\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><rect x=\"266.8\" y=\"152\" width=\"75.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"304.6\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><rect x=\"342.4\" y=\"152\" width=\"50.4\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"367.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"367.6\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><rect x=\"392.8\" y=\"152\" width=\"79.2\" height=\"34\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><path d=\"M40 200 L40 206 L472.0 206 L472.0 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"256.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">budget 120</text></svg>", "caption": "tok fit with a budget of 120. The system prompt is kept, turns are kept from the newest backwards, and the four oldest are dropped, including the one where Bruno said he is allergic to nuts."}
```

Four turns went, and **the first of them was the one that mattered**: Bruno is allergic to nuts.
What the model receives now is the café's instructions, a question about public holidays, and
"Which cake would you recommend for me?" Nothing it can see says who "me" is. Send both versions
to the model, the whole conversation and the one that was cut:

```
ana@lab:~/pe$ ask --chat chat.json --temperature 0
Our lemon cake is a popular choice, and it's nut-free. Would you like to try a slice?
-- llama3.2:3b, finish: stop, prompt 199 tokens, output 23 tokens
ana@lab:~/pe$ ask --chat sent.json --temperature 0
Our most popular cake is the Cinnamon Swirl, made with a rich cinnamon-spiced batter and topped with a crumbly oat and nut mixture.
-- llama3.2:3b, finish: stop, prompt 117 tokens, output 32 tokens
```

With the cut, it recommended a cake topped with nuts. **Nothing failed in a way a log would
show**: the request was valid, the model answered, the application stayed inside its budget. The
only symptom is in the content, and only somebody who remembers the first message would see it.

The reply with every turn is not safe either, and it is worth reading twice. It remembered the
allergy and promised a nut-free lemon cake: a cake the café's instructions never mention, from a
kitchen they say uses nuts. Keeping the allergy in the window was necessary, and it was not enough.
Lesson 5 is about the invented cake, and lesson 22 about the rule that would have stopped the
promise.

Squeeze harder and only the question survives:

```
ana@lab:~/pe$ tok fit chat.json -b 80
budget 80, system prompt 53
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  dropped  5 user        10  And on a public holiday?
  dropped  6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 67 tokens, 1 of 7 turns
```

## The system prompt is kept, on purpose

In all three runs, the 53 tokens of the system prompt went through. That is a choice `tok fit`
makes and most applications make: **the instructions are worth more than any single turn**,
because without them the assistant forgets what it is for, how long its replies should be, and
that the kitchen uses nuts. Cutting the oldest message first, with no exception, would have dropped
the instructions before anything else, since they come first.

The price is that the instructions take part of the budget every time. A system prompt that grows
by a paragraph each time somebody adds a rule leaves less room for the conversation on every single
request, and the turns it pushes out are the ones a user remembers saying.
