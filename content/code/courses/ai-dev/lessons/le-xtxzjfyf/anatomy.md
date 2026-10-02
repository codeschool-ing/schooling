---
title: What a task prompt is made of
version: 1
---

The same request, asked two ways, gets two different kinds of answer. The difference is rarely
cleverness of phrasing. **It is whether the prompt carries what a colleague would need to do the
job without coming back to ask.** What to change, what it is for, what must not change, how you will
know it is done, and in what form you want the answer.

## The short version

ana's shop rejects `12,90`, which is how a Brazilian customer types a price. The quickest request
is one line. The reply was written by the course, as every model reply in this lesson is:

```
ana@dev:~/shop$ assist ask "Fix parse_price so it accepts commas." --open shop/money.py
context sent (137 of 3000 tokens):
    137  shop/money.py
---
Here is a version that handles both separators:

def parse_price(text: str) -> int:
    return round(float(text.strip().replace(",", ".")) * 100)

```

It works, for most inputs, and it breaks a rule. `CONVENTIONS.md` says a float never holds money,
not even briefly, and this reply goes through `float` on its way to cents. The assistant could not
know: the conventions were not in the context, and the one line did not say. **Nothing about the
answer is wrong for the question it was asked.** The question was missing the project.

## The five parts

ana writes the request as a file, so she can read it before sending it and reuse it after:

```
Goal: `parse_price` in shop/money.py must accept a comma as the decimal
separator, because Brazilian customers type `12,90`.

Context: the function and its tests are below. CONVENTIONS.md is below too;
money is integer cents and a float must never hold it.

Constraints: change only `parse_price`. Keep the arithmetic in integers.
Do not change any existing test.

Done when: `12,90` and `12,9` give 1290, `12.90` still gives 1290, and the
whole suite passes.

Answer with: a unified diff against shop/money.py, and nothing else.
```

| part | what it does |
|---|---|
| goal | the change, and why it is wanted: the reason lets a reader pick between two ways of doing it |
| context | the code and the rules, sent with the prompt (lesson 1 section 06: if it is not in the request, the model does not know it) |
| constraints | what must not change, and the rules the change must keep |
| done when | the cases that decide whether it worked, which are also the tests |
| answer with | the form of the reply, so a program can check it (lesson 5 section 05) |

```
ana@dev:~/shop$ wc -w prompts/comma.md
81 prompts/comma.md
```

Eighty-one words. **The extra words are not politeness**, and most of them are things ana would
write in the ticket anyway. A prompt that reads like a good ticket is a good prompt, and the habit
pays twice: the same text tells the next person what the change was for.

## What does not need to be there

- **Persuasion.** "You are a world-class engineer", "this is very important", "take a deep breath".
  The model is not short of motivation; it is short of facts.
- **Repetition in capitals.** If a constraint matters, state it once, plainly, and check it with a
  test. Lesson 3 section 05 said the same about instruction files.
- **The whole repository.** The files the change touches, the tests of those files and the rules
  that apply. Lesson 2's arithmetic charges for the rest on every request.
