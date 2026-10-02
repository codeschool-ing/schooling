---
title: JSON, the format a program wants
version: 1
---

It is tempting to think that a model which writes good prose will write good data if you ask it
to. It writes text that looks like data, and **looking like JSON and being JSON are judged by
different readers**. A person reads past a stray sentence. A parser stops at the first character
it did not expect, and the program that called it gets nothing at all.

So the question this section answers is narrow: when a reply is meant for a program, what does
the program need from it, and how do you find out whether it got that?

## Why a program wants JSON

Suppose Café Aurora wants every review sorted: was it positive or negative, what was it about, did
it praise the staff. A person could read a paragraph saying so. A program that files the review,
counts the week's complaints or alerts the manager needs the same facts **in fixed places, with
fixed names and fixed types**:

- a field name the code can ask for, `sentiment`, spelt the same way every time;
- a value from a short list, `negative` and not `quite negative, really`;
- a number as a number, a list as a list, `true` as a boolean and not the word `yes`.

JSON gives all three, every programming language reads it, and the reader is strict. That last
part is what makes it useful: **a strict reader tells you a reply is broken at the moment it
arrives**, instead of three steps later when a report is wrong.

## Asking for it in the prompt

The prompt says what the object looks like, field by field, and says that nothing else may come
with it. The course wrote this prompt as an illustration; no model was called:

```localised
Classify the café review between the <review> tags.

Reply with one JSON object and nothing else: no sentence before
or after it, and no code fence. Use exactly these fields:
  "review"         the review's number, as a number
  "sentiment"      one of "positive", "negative", "mixed"
  "topics"         a list of short lowercase words
  "staff_praised"  true or false

<review number="3">
Waited fifteen minutes for a tea at noon. The staff were kind about it.
</review>
```

Three things in it do the work. The fields are named exactly, so the model has no reason to call
one `mood` on Tuesday. The values that come from a list are listed. And **the prompt names the two
wrappings models add most**, a sentence of introduction and a Markdown code fence, because "only
JSON" alone does not rule them out in the model's eyes.

Lesson 19 replaces the field list with a formal **schema**, a document that a program can check a
reply against. Here the description is in prose, and the check is only whether the reply parses.

## Three replies, and what a parser says to each

These are three replies of the kind models send back, written into files on the workbench. The
first is what was asked for:

```
ana@lab:~/pe$ cat replies/good.json
{
  "review": 3,
  "sentiment": "negative",
  "topics": ["wait", "tea"],
  "staff_praised": true
}
ana@lab:~/pe$ python3 -m json.tool replies/good.json > /dev/null; echo "exit $?"
exit 0
```

`python3 -m json.tool` is Python's own JSON reader, run from the command line. It reads the file
and prints it back neatly; here the print is thrown away and only the **exit status** is kept,
because that is what a program checks. `0` means it parsed.

The second reply has the right object in it and a friendly sentence in front:

```
ana@lab:~/pe$ cat replies/chatty.json
Sure! Here is the JSON for review 3:
{
  "review": 3,
  "sentiment": "negative",
  "topics": ["wait", "tea"],
  "staff_praised": true
}
ana@lab:~/pe$ python3 -m json.tool replies/chatty.json > /dev/null; echo "exit $?"
Expecting value: line 1 column 1 (char 0)
exit 1
```

**The parser gave up on the very first character.** JSON has to start with a value, and `S` is not
one. A person sees an object that is perfectly fine; the program sees a failure, and it never
learns the object was there. Lesson 19 recovers this one with a small repair step.

The third has no sentence, and every line of it looks like data:

```
ana@lab:~/pe$ cat replies/python.json
{
  'review': 3,
  'sentiment': 'negative',
  'topics': ['wait', 'tea'],
  'staff_praised': True,
}
ana@lab:~/pe$ python3 -m json.tool replies/python.json > /dev/null; echo "exit $?"
Expecting property name enclosed in double quotes: line 2 column 3 (char 4)
exit 1
```

This is Python's way of writing a dictionary, and it is close enough to JSON to fool the eye. JSON
needs double quotes, spells the boolean `true` in lower case, and refuses the comma after the last
field. The error names only the first problem, at line 2 column 3, the opening `'`. **A parser
reports where it stopped, not everything that is wrong**, so fixing that quote by hand would only
move the error to `True`.

## What to take from the three

The exit status is the line between data and text. A program that calls a model for JSON parses
the reply before it uses it, and when parsing fails it does something deliberate: it retries, it
repairs, or it records the failure. **What it never does is carry on with a reply it did not
parse**, because everything downstream then works on nothing and looks fine.

Asking well makes the second and third replies rarer, and it does not make them impossible. A
model produces likely text (lesson 1), and the text it learnt from holds a great deal of JSON
introduced by a sentence or wrapped in a code fence. That is why the check is not optional, and why lesson 19 builds on it.
