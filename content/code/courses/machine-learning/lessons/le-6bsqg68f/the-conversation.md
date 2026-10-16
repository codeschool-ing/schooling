---
title: Four requests, and how to answer them
version: 1
---

The arithmetic of this lesson takes an afternoon. Defending it takes longer, because everybody
who has heard of a model has an opinion about where its line should go. Four requests reach Ana in
the week the model goes live. Each has a reply that sounds helpful and is wrong, and one that holds.

**1. "Use 0.5. It's the standard."** Marketing's lead read it in a tutorial.

0.5 is the default of a function, chosen by nobody for this business. It means "more likely to
leave than to stay", and Feira em Casa's credit pays at 0.278, not much over half that. The reply is the
value curve: at 0.5 the model makes R$ 9,088 on the test months, and at the cut computed from the
costs it makes R$ 21,672. **A default needs no defence until somebody shows what it costs.**

**2. "Send it to everybody above 0.1, to be safe."** Customer care would rather waste credits than
lose people.

It sounds cautious, and on this data it is the reckless choice. At 0.1 the programme makes
R$ 1,848, and a little lower it loses tens of thousands, because stayers outnumber leavers fifteen
to one. "Safe" here has to mean safe for the money as well as for the subscriber. If customer care
believes losing a subscriber costs more than R$ 480, **that is a change to a number in the frame**,
and the cut follows from it: argue the number, and the cut moves by itself.

**3. "Use whatever made the most money last semester."** The director wants the evidence.

The best cut on the test months was 0.23 and made R$ 23,832, and it was chosen by looking at the
answers. It won because of a price rise nobody could have predicted in June, and next semester's
surprise will be a different one. The reply is the three rows of `choose_cut.py`: the cut chosen
in advance, the one chosen on a validation period, and the one chosen in hindsight, **with the
last labelled as a ceiling and not as a result**.

**4. "We can only make 150 calls a month."** Operations, and this one is not an opinion.

It is a constraint, and it changes the policy rather than the cut: rank each month and call the
top 150. That made R$ 23,616, partly because a list is not hurt by chances that run low. The reply
is to agree, and to bring `capacity.py`'s table to the next meeting about how many people to hire.

## What the four have in common

Each request is about the same three things: **the costs, the constraint, and the evidence.** A
cut that is defended with "the model says so" loses every one of these conversations, because the
model never said anything about where the line goes. A cut defended with the business's own
numbers, written in the frame and agreed in advance, wins most of them, and the ones it loses
change a number rather than the method.
