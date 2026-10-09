---
title: When something gets through
version: 2
---

The defences in this lesson make mistakes rarer and smaller. They do not make them impossible, so a
feature that uses a model needs a plan for the day one gets through, **written before that day**,
when nobody is in a hurry.

## Be able to turn it off

**A switch that stops the model and keeps the product working**: the support page shows a contact
form instead of the assistant, the drafting tool hands every email to a person. It is a flag read on
every request, not a deploy, because the person who needs it at night may not be the person who
can deploy. Test it the way lesson 10 tested the fallback, by using it.

## Know what happened

- **The request log of lesson 11 section 04** says which request, which model, how many tokens and
  why it stopped, with the request id to give a provider.
- **Tool calls are logged as actions**, with their arguments and who approved them. "The model
  refunded order 1042" has to be answerable with when, how much and on whose yes.
- **Keep the prompts and replies you chose to keep**, redacted, long enough to read the bad
  conversation again. A mistake you cannot reproduce cannot be fixed.

## Contain, then fix

1. **Stop the damage**: the switch, or removing the one tool that caused it.
2. **Revoke what may have leaked**: a key, a token, a session. Lesson 10's rule holds: on suspicion.
3. **Undo what can be undone**: reverse the refund, correct the order, tell the customer.
4. **Fix the cause in the host**, not in the prompt: the tool that was offered, the check that was
   missing, the approval that was skipped.
5. **Add the case to the evaluation** of lesson 5, so the next model or the next prompt is tested
   against exactly this email.

## Tell people

Customers affected by a wrong answer deserve to hear it from the shop. **Personal data that went
where it should not may be a legal matter**: in Brazil the LGPD asks for incidents that can cause
relevant harm to be reported to the ANPD and to the people affected. Whoever handles that at the
company should be in the plan by name.
