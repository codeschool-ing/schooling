---
title: What a role cannot do
version: 2
---

The common belief behind "You are a world-class expert" is that the line makes the answers better
in substance: more accurate, more knowledgeable, more authoritative. **A role adds no knowledge and
no authority.** The model knows what it knew before the line, and nothing it says becomes more
true because of the title it was given.

## The expert who does not know your kitchen

A customer asks the café's assistant whether the cinnamon bun is safe for someone with a nut
allergy, and the prompt uses a role for the wrong job:

```
ana@lab:~/pe$ cat prompts/role-specialist.txt
You are a world-class food allergy specialist with twenty years
of experience. Answer with authority.

Customer: Is your cinnamon bun nut-free?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-specialist.txt
As a world-class food allergy specialist, I can assure you that our cinnamon buns are not suitable for individuals with tree nut allergies. The dough used to make our cinnamon buns contains wheat flour, sugar, eggs, and a blend of spices, including cinnamon, but it does not contain any tree nuts.

However, I must note that our bakery also uses a shared equipment and facility to prepare other baked goods, including those that contain tree nuts. While we take every precaution to minimize cross-contamination, there is always a risk of exposure to tree nuts.

If you or a loved one has a severe tree nut allergy, I would recommend taking a thorough medical history and conducting a thorough food allergy assessment to determine the level of risk. We can also provide you with a detailed ingredient list and offer guidance on how to safely consume our cinnamon buns.

It's also worth noting that we have a dedicated nut-free baking area, where we prepare our cinnamon buns and other nut-free baked goods. If you would like to have your cinnamon bun prepared in this area, please let us know in advance, and we will do our best to accommodate your request.
-- llama3.2:3b, finish: stop, prompt 53 tokens, output 232 tokens
```

The model has never seen Café Aurora's kitchen, and it wrote four paragraphs about it in a
specialist's voice: what the dough contains, that the bakery shares equipment, and then a dedicated
nut-free baking area, which contradicts the paragraph before it and does not exist. Every sentence
sounds like a verdict. The café's handbook says the kitchen uses nuts, so no item can be guaranteed
nut-free, and no sentence of the reply came from it.

That is the failure of lesson 5 with a costume on. **A role can make a wrong answer more
persuasive, and it cannot make it right.** The facts have to come from somewhere the café controls:
the handbook text sent with the question, as the system prompt of lesson 22 requires, with the
instruction to say "I do not know" when the text has no answer.

## Roles combined with explicit instructions

A role sets the voice; the instructions say what the reply must contain and must never do. Used
together, each does its own job:

```
ana@lab:~/pe$ cat prompts/role-combined.txt
You are the assistant at Café Aurora's counter: warm, brief, plain.

Answer only from the handbook text below. If it does not settle the
question, say so and suggest asking the kitchen. Never say an item
is free of an allergen.

<handbook>
The kitchen uses nuts, so no item can be guaranteed nut-free.
If a customer asks about an ingredient that is not on the label,
ask the kitchen; never guess.
</handbook>

Customer: Is your cinnamon bun nut-free?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-combined.txt
We can't guarantee that our cinnamon bun is nut-free.
-- llama3.2:3b, finish: stop, prompt 130 tokens, output 13 tokens
```

One sentence, from the handbook, and the right answer. The role is one line and the rules are the
rest. A test set (lesson 20) can check the rules, and this reply shows the check has to be written
with care: a test that failed every reply containing "nut-free" would fail this one, which says the
café cannot promise it, and a test asking for the reply to mention that the kitchen uses nuts would
fail it too, since it does not. Nothing can check "be a world-class specialist", and nothing needs
to.

## The role of the audience often matters more

The role people reach for first is the model's: who it should be. The one that changes a reply
most is often the **reader's**: who the reply is for. A model told who it is talking to adjusts
the vocabulary, the length and what it explains, which is most of what a role was wanted for.

The same request, aimed at two readers:

```
ana@lab:~/pe$ cat prompts/role-new-barista.txt
Explain to a new barista, on their first day, why we ask customers
about allergies before recommending a cake. One short paragraph.
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-new-barista.txt
"Hey, welcome to the team! On your first day, I want to make sure you're aware of our allergy protocol. When a customer orders a cake, we ask about any allergies they may have, such as nuts, gluten, or dairy, before recommending a flavor. This is crucial because some of our cakes contain common allergens that can be life-threatening if ingested by someone with a severe allergy. By asking about allergies, we can ensure that our customers can enjoy their cake safely and avoid any potential health risks. It's a simple but important step that helps us provide excellent customer service and maintain a safe environment for everyone in the cafe."
-- llama3.2:3b, finish: stop, prompt 54 tokens, output 132 tokens
```

```
ana@lab:~/pe$ cat prompts/role-insurer.txt
Explain to the café's insurer why staff ask customers about
allergies before recommending a cake. One short paragraph.
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-insurer.txt
Staff at the café ask customers about allergies before recommending a cake to minimize the risk of an adverse reaction. This is a precautionary measure to ensure the customer's safety, as some ingredients in cakes, such as nuts, gluten, or dairy, can be life-threatening for individuals with severe allergies. By asking about allergies, the café can provide alternative options or modify the cake to accommodate the customer's needs, thereby reducing the risk of an allergic reaction and promoting a safe and enjoyable dining experience.
-- llama3.2:3b, finish: stop, prompt 50 tokens, output 99 tokens
```

The first is a speech, in quotation marks, that starts "Hey, welcome to the team!" and ends on
customer service. The second is third person, "a precautionary measure", "minimize the risk", the
words a risk document uses. **No role for the model was needed in either**: naming the reader set
the register, the vocabulary and the angle at once. Neither says anything the café decided, which
is the other half of this lesson: the second even offers to modify a cake to suit an allergy, a
promise nobody at the café made. The reader shaped the reply; the facts would still have to be
given.

So when a reply comes back pitched wrong, too technical or too vague, too long or too thin, the
first thing to check is whether the prompt said who it is for. "Explain to a new barista" is
specific, it can be judged against a reply, and it describes something real. "You are an expert"
is none of the three.
