---
title: What a task prompt is made of
version: 2
---

The same request, asked two ways, gets two different kinds of answer. The difference is rarely
cleverness of phrasing. **It is whether the prompt carries what a colleague would need to do the
job without coming back to ask.** What to change, what it is for, what must not change, how you will
know it is done, and in what form you want the answer.

## The short version

ana's shop rejects `12,90`, which is how a Brazilian customer types a price. The quickest request
is one line, sent with `assist` from lesson 3 and the file open. The reply goes to
`scratch/reply.txt`, and `cat -n` numbers its lines:

```
ana@dev:~/shop$ python scratch/assist.py ask "Fix parse_price so it accepts commas." --open shop/money.py > /dev/null
context sent (137 of 3000 tokens):
    137  shop/money.py
---
ana@dev:~/shop$ cat -n scratch/reply.txt
     1	You can use Python's built-in `replace` method to remove commas from the input string, and then proceed with the existing logic. Here's the updated `parse_price` function:
     2	
     3	```python
     4	def parse_price(text: str) -> int:
     5	    """Turn a price as people write it into cents: '12.90' -> 1290."""
     6	    text = text.replace(",", "")  # Remove commas
     7	    units, _, cents = text.strip().partition(".")
     8	    cents = (cents + "00")[:2]
     9	    return int(units) * 100 + int(cents)
    10	```
    11	
    12	Now the function should correctly parse prices with commas, such as "12,90".
```

Line 6 deletes every comma. `12,90` becomes `1290`, which the function reads as one thousand two
hundred and ninety units, so the price comes out as 129000 cents: a mug at 12,90 charged
1290.00. The model read the comma the way English writes `1,290`, as a separator between
thousands, and for that reading the answer is correct. **Nothing about the answer is wrong for the
question it was asked.** The question never said the comma was a decimal separator, or who types
it, and it carried none of the project's rules.

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
| context | the code and the rules, sent with the prompt (lesson 1 section 10: if it is not in the request, the model does not know it) |
| constraints | what must not change, and the rules the change must keep |
| done when | the cases that decide whether it worked, which are also the tests |
| answer with | the form of the reply, so a program can check it (lesson 5 section 05) |

```
ana@dev:~/shop$ wc -w prompts/comma.md
81 prompts/comma.md
```

Eighty-one words. **The extra words are not politeness**, and most of them are things ana would
write in the ticket anyway. The goal alone would have prevented the reply above: it says the comma
is decimal, and gives `12,90` as the case. A prompt that reads like a good ticket is a good prompt,
and the habit pays twice, because the same text tells the next person what the change was for.

## What does not need to be there

- **Persuasion.** "You are a world-class engineer", "this is very important", "take a deep breath".
  The model is not short of motivation; it is short of facts.
- **Repetition in capitals.** If a constraint matters, state it once, plainly, and check it with a
  test. Lesson 3 section 05 said the same about instruction files.
- **The whole repository.** The files the change touches, the tests of those files and the rules
  that apply. Lesson 2's arithmetic charges for the rest on every request.
