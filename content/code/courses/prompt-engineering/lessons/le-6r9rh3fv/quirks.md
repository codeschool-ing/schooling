---
title: What a model cannot see inside a token
version: 2
---

A model that writes fluent paragraphs in several languages seems certain to know how a word is
spelt. **It was never shown the spelling.** It was shown token numbers, and whatever it knows about
the letters inside a token it had to pick up indirectly, from text where somebody happened to spell
a word out. Three well-known stumbles follow from that, and each one is visible in what `tok`
prints.

## Counting letters

"How many times does the letter r appear in strawberry?" became a famous question because models
kept getting it wrong. Here is what the model receives:

```
ana@lab:~/pe$ tok show "How many r are in strawberry?"
"How" " many" " r" " are" " in" " strawberry" "?"
5299 1991 428 553 306 101830 30
7 tokens, 29 characters (o200k_base)
```

The word the question is about is one number, 101830. **The three r's are not in the input at
all**; they are inside a token, and the model has to answer from what it learnt about that token's
spelling, which is a fact like any other it may have half-learnt. A person counting letters looks
at the letters. The model has nothing to look at. Asked on the day these lessons were recorded,
`llama3.2:3b` said two:

```
ana@lab:~/pe$ ask "How many times does the letter r appear in strawberry? Answer with a number." --temperature 0
2
-- llama3.2:3b, finish: stop, prompt 41 tokens, output 2 tokens
```

## Reversing a word

Writing a word backwards is trivial for a program and awkward for a model, for the same reason:

```
ana@lab:~/pe$ tok show "yrrebwarts"
"yr" "reb" "warts"
3866 19100 115451
3 tokens, 10 characters (o200k_base)
```

`strawberry` written backwards is three tokens that have nothing to do with the original:
`"yr"`, `"reb"`, `"warts"`. **Nothing in the numbers 3866, 19100 and 115451 says they spell
101830 in reverse.** To produce them, the model has to know the letters of the forward word and
reassemble them into pieces of a different shape, all in one step per token. `llama3.2:3b` lost a
letter on the way, and one line of Python did not:

```
ana@lab:~/pe$ ask "Write kitchen backwards." --temperature 0
The word "kitchen" spelled backwards is "nehcik".
-- llama3.2:3b, finish: stop, prompt 29 tokens, output 15 tokens
ana@lab:~/pe$ python3 -c "print(\"kitchen\"[::-1])"
nehctik
```

`nehcik` is `kitchen` backwards without its `t`. The model wrote it as confidently as it would have
written the right answer, which is the part to remember.

## Digits in chunks

Numbers are cut too, and the cut depends on how they are written:

```
ana@lab:~/pe$ tok show "1234567"; tok show "1,234,567"
"123" "456" "7"
7633 19354 22
3 tokens, 7 characters (o200k_base)
"1" "," "234" "," "567"
16 11 20771 11 34904
5 tokens, 9 characters (o200k_base)
```

The same quantity is three tokens in one form and five in the other, and in neither is it one
digit per token. Adding two numbers means lining up units with units and tens with tens, and when
`1234567` arrives as `123`, `456` and `7`, the units are at the end of a chunk the other number may
not have. Large models do arithmetic better than this suggests, and they still make mistakes a
calculator never makes, without any sign in the text that they did.

## What to do about it

Two remedies, and they come up again in this course:

- Make the letters into tokens. Ask for the word to be spelt out first, one letter per line,
  and then counted. Written out, each letter becomes a token of its own, and the model counts
  things it can see. Lesson 26 does the same with reasoning, by asking for the steps to be written
  before the answer.
- Give the job to a program. Counting, reversing and arithmetic have exact answers that a few
  lines of code produce every time. Lesson 6 lets a model ask a calculator, and that is the right
  tool for 4 × 27.90 whether or not the model would have got it right.

The first remedy, on the same model that said two:

```
ana@lab:~/pe$ ask "Spell strawberry one letter per line, then count the lines that are the letter r." --temperature 0
Here is the word "strawberry" spelled one letter per line:

S
T
R
A
W
B
E
R
R
Y

There are 3 lines that are the letter "R".
-- llama3.2:3b, finish: stop, prompt 42 tokens, output 48 tokens
```

It wrote the letters in capitals, which nobody asked for, and counted three. **The answer changed
because the question changed what the model could see**, not because it tried harder.

None of this is a reason to distrust what a model writes about meaning. **A model is good at what
is visible in tokens, which is which pieces follow which**, and weak at what is hidden inside them.
Knowing which side of that line a task falls on is most of knowing whether to check the answer.
