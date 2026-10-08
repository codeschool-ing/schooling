---
title: Working inside the limit
version: 2
---

The obvious answer to a full window is a bigger one, and windows have grown enormously. It helps
less than it sounds. A bigger window costs more on every request (lesson 3), it still has an edge,
and a model does not read a very long context evenly. **The useful question is not how much fits,
but what the model needs to see for this request**, and five habits follow from it.

## Keep the instruction

The section before showed `tok fit` keeping the system prompt whatever else it dropped. Do the
same in anything you build: the rules and the format go in every request, and they are the last
thing to cut. When the context is long, it also helps to repeat the one instruction that matters
most right before the question, where the model reads it last. Lesson 22 is about writing the
system prompt itself.

## Carry a note forward

Dropping old turns loses whatever was said in them. The fix is to **keep what mattered in a form
that costs less than the turns did**: a short note, written when the turns are about to go, that
travels in the part that is never cut. One `sed` adds a sentence to the end of the system prompt,
and the rest of the conversation stays as it was:

```
ana@lab:~/pe$ sed "s/The kitchen uses nuts.\"}/The kitchen uses nuts. Noted earlier in this conversation: the customer is Bruno and he is allergic to nuts.\"}/" chat.json > chat-noted.json
ana@lab:~/pe$ tok fit chat-noted.json -b 120 -w sent-noted.json
budget 120, system prompt 71
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 116 tokens, 3 of 7 turns
ana@lab:~/pe$ ask --chat sent-noted.json --temperature 0
I'd be happy to recommend our Lemon Lavender Pound Cake, it's a popular choice and nut-free.
-- llama3.2:3b, finish: stop, prompt 135 tokens, output 23 tokens
```

The same four turns were dropped, the system prompt grew from 53 tokens to 71, and **the allergy
survived**, because it is no longer in a turn. The note cost 18 tokens on each request; the four
turns it replaced cost 75.

What the model did with it is another matter. It used the allergy, and made the same promise as
the reply with every turn: a nut-free cake, from a kitchen the same system prompt says uses nuts.
**A note keeps information in the window; what the model does with it is decided by the
instructions**, and these say nothing about allergies.

In a real application the note is written by a second, cheaper request to a model, given the
turns about to be dropped and a prompt that says what must survive. A summary can leave out the
one detail that mattered as easily as truncation can, so the prompt has to name it:

```
ana@lab:~/pe$ cat summarise.txt old-turns.txt
These turns are about to be removed from the conversation. In at most
two sentences, write down anything the customer said about themselves
(name, allergies, preferences) and any promise the assistant made.
Write nothing else.
user: Hi, I'm Bruno. I'm allergic to nuts, so please keep that in mind.
assistant: Thanks, Bruno. I'll keep your nut allergy in mind in everything I suggest.
user: Are you open on Sunday morning?
assistant: Yes, on Sundays we open at 08:00 and close at 12:00.
ana@lab:~/pe$ ask - --system "$(cat summarise.txt)" --temperature 0 < old-turns.txt
Bruno is allergic to nuts. I promised to keep his nut allergy in mind in everything I suggest.
-- llama3.2:3b, finish: stop, prompt 139 tokens, output 22 tokens
```

Two sentences, the allergy and the promise, and nothing about Sunday hours, which the system
prompt already carries.

## Send what the question needs, not everything you have

The café's staff handbook is six short files. Later lessons search it, quote it and pass it to the
model, so make it now, by pasting this block into the terminal:

```sh
mkdir -p ~/pe/handbook
cat > ~/pe/handbook/allergens.md <<'EOF'
# Allergens

Every cake label lists the 14 major allergens it contains.
The kitchen uses nuts, so no item can be guaranteed nut-free.
Oat, soya and lactose-free milk are available for every coffee at no extra cost.
If a customer asks about an ingredient that is not on the label, ask the kitchen; never guess.
EOF
cat > ~/pe/handbook/deliveries.md <<'EOF'
# Deliveries

Bread arrives at 06:15 and milk at 06:30, at the side door.
The person opening checks the delivery note against what arrived and signs it.
A missing item is reported to the supplier the same morning, by e-mail, with the note's number.
EOF
cat > ~/pe/handbook/hours.md <<'EOF'
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
EOF
cat > ~/pe/handbook/loyalty.md <<'EOF'
# Loyalty card

The tenth coffee is free; stamps are counted per card, not per person.
A lost card can be replaced at the counter, and its balance is moved to the new card if the customer knows the card number.
Stamps cannot be exchanged for cash or for food.
EOF
cat > ~/pe/handbook/refunds.md <<'EOF'
# Refunds

A drink or a dish that is wrong or not as described is replaced or refunded on the spot.
Refunds are made to the card or method used to pay, never in cash for a card payment.
Money loaded onto a loyalty card is not refundable, but it never expires.
A refund above R$ 100 needs the shift manager's approval.
EOF
cat > ~/pe/handbook/wifi.md <<'EOF'
# Wi-Fi

The guest network is called aurora-guests and needs no password.
Sessions end after 2 hours and can be started again at once.
Staff devices use the network aurora-staff, which guests are never given.
EOF
```

Then count them:

```
ana@lab:~/pe$ tok count handbook/*.md
tokens  words  chars  file
    70     55    310  handbook/allergens.md
    60     44    249  handbook/deliveries.md
    65     46    261  handbook/hours.md
    58     50    260  handbook/loyalty.md
    74     62    318  handbook/refunds.md
    48     35    209  handbook/wifi.md
```

Between 48 and 74 tokens each. Pasting all of it into every request is affordable here and wasteful
anywhere real, where a handbook runs to hundreds of pages. A question about the guest Wi-Fi needs
one line of `wifi.md`, and the other files cost tokens and are also **text the model has to read
past** to find the line that answers. Retrieval finds the passages that match the question
and sends only those.

::: track ai
Lesson 11 introduces retrieval, and the `rag` course in your track builds it properly, with search
by meaning and not only by words.
:::

::: track *
Lesson 11 introduces retrieval: searching the material for the passages that match the question,
and putting only those in the prompt.
:::

## Cut a long document into chunks

Some jobs need all of a document: a summary of a contract, every date in a year of minutes. When
it does not fit, **split it into chunks that each fit with room for the reply, give every chunk the
same instruction, and combine the answers** in a last request. Two things go wrong. A fact can be
cut in half at a chunk boundary, which is why chunks usually overlap by a few sentences. And a question that needs two distant parts of the
document at once, such as "does clause 9 contradict clause 2?", cannot be answered from either
chunk alone.

## Do not trust the middle of a long context

A model with a huge window can take in a whole book, and it does not follow that it reads every
page equally well. A 2023 study, "Lost in the Middle: How Language Models Use Long Contexts",
gave models a long set of documents with the answer placed at different points. They used
information at the **beginning and the end** of the context much better than information in the
middle. Models have improved since, and the advice it led to is still cheap to follow:

- put the instruction and the most important material at the start or the end, not buried between
  other documents;
- send fewer, better-chosen passages rather than many loosely related ones;
- if you need a fact from a long context, test with that fact at different positions before you
  trust the result.

All five habits go back to `toylm` and the question about Sunday. The model can only answer from what is in
front of it, and deciding what is in front of it is your job, not the model's.
