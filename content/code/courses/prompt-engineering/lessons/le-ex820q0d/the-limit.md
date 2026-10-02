---
title: A limit that cuts the loop
version: 1
---

A maximum on output tokens is easy to mistake for a length instruction, as if setting it to 50
asked the model for a fifty-token answer. It asks for nothing. **The model writes exactly as it
would have, and the loop is stopped when the count reaches the limit**, wherever in a sentence
that happens to fall. The model never learns that a limit existed.

Lesson 1 showed the two ways generation ends: the model picks the end, or a limit is reached.
`toylm` reports which one in its last line. Without a tight limit the model finishes on its own:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0
soup, bread and cake.
-- finish: end, prompt 3 tokens, output 6 tokens
```

With `--max-tokens 3`:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0 --max-tokens 3
soup, bread
-- finish: length, prompt 3 tokens, output 3 tokens
```

`finish: length` says the loop was stopped from outside. The three tokens were `soup`, the comma
and `bread`, and the fourth was never generated.

## Some loops never end on their own

The limit is also what stops a model that would otherwise go on for ever. At temperature 0,
`toylm` writes this after `the cat`:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

After `cat sleeps` the likeliest word is `and`, after `and the` it is `cat`, and after `the cat`
it is `sleeps` again, so greedy decoding goes round the same circle. **Without the limit the
loop would never end.** A large model can fall into the same kind of circle, repeating a line or
a list item, and the limit is what turns a request that would never return into one that returns
too much. Lesson 17 shows the controls that discourage the circle in the first place.

## A truncated answer looks finished

Read the output of the `--max-tokens 3` run again without its last line: *the menu has soup,
bread*. It is a grammatical sentence, and it says something false, because the menu also has
cake. **A cut answer rarely looks cut.** A list stops after an item, a paragraph stops after a
sentence, a set of steps stops before the step that mattered, and a reader who does not check the
reason goes on as if it were complete.

So the rule for code that calls a model is plain: **check why it stopped before you use what it
wrote.** Every model API returns a finish reason of some kind, under its own name; `toylm` calls
it `finish`, and `length` is the value that means "this was cut". Treat that value as an error or
a retry with a higher limit, never as an answer.

## A cut JSON object is not JSON

Structured output makes the problem visible instead of silent, which is better and still a
failure. Here is a reply of the shape a program might ask for, written by the course, and its
size in tokens:

```
ana@lab:~/pe$ cat reply.json
{"sentiment": "negative", "topic": "waiting time", "summary": "Waited fifteen minutes for a tea at noon; the staff were kind about it."}
ana@lab:~/pe$ tok count reply.json
tokens  words  chars  file
    36     20    137  reply.json
```

Thirty-six tokens. A limit below that cuts the object before its closing brace. `head -c` stands
in for the limit here, cutting the file part-way through the summary, where a token limit could
land:

```
ana@lab:~/pe$ head -c 70 reply.json > cut.json; cat cut.json; echo
{"sentiment": "negative", "topic": "waiting time", "summary": "Waited 
```

The complete object passes the schema check, and the cut one is not JSON at all:

```
ana@lab:~/pe$ validate review.schema.json reply.json
valid
ana@lab:~/pe$ validate review.schema.json cut.json
not JSON: Unterminated string starting at: line 1 column 63 (char 62)
```

**A limit that is fine for prose can be fatal for JSON**, because prose cut short is still prose
and an object cut short is not an object. Set the limit with room above the largest reply you
expect, and still check the finish reason, because "largest reply you expect" is a guess.
Lessons 18 and 19 are about structured output and about validating and repairing it.
