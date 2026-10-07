---
title: A score for every possible next word
version: 2
---

The common picture of a chat assistant is a program that looks the answer up, or one that
understands the question the way a person does and then explains. Neither is what happens.
**A language model does one thing: given a piece of text, it gives every possible next word a
probability.** Everything it appears to do, from answering to translating to writing code, is that
one step, repeated.

This course has a language model small enough to read. It is called `toylm`, it learnt from a file
of 761 words about a café, and you can ask it what comes next. You build it yourself at the end of
this lesson, so for now read what it printed; the commands will work the same for you then:

```
ana@lab:~/pe$ toylm next "the coffee is"
context: trigram after 'coffee is'
  hot       59.3%  ########################
  strong    18.5%  #######
  ready     11.1%  ####
  cold       7.4%  ###
  bitter     3.7%  #
```

It did not answer a question, because none was asked. It said which words followed `coffee is`
in what it learnt from, and how often: `hot` in 59.3% of them, `bitter` in 3.7%. Those five
words add up to 100%, and **every other word it knows got nothing**, because it never saw them
there.

Change the text and the scores change with it:

```
ana@lab:~/pe$ toylm next "the café opens at"
context: trigram after 'opens at'
  seven     75.0%  ##############################
  eight     25.0%  ##########
```

**The text you give a model is the only thing it has to go on.** Here that is the whole of what a
prompt is, and lesson 2 starts from it.

## How this one does it, and how the large ones do

`toylm` is a **trigram model**: it counted, for every pair of words in its file, which word came
next, and it turns those counts into percentages. The first line of each answer says which pair
it looked at. It is crude, and it is a real language model, in the sense that matters here: text
in, a probability for each next word out.

The models behind chat assistants do the same job with three differences, and each one gets a
lesson of its own:

| | `toylm` | a large language model |
|---|---|---|
| what it predicts | the next **word** | the next **token**, a piece of a word (lesson 3) |
| what it looks at | the last **two** words | hundreds of thousands of tokens at once (lesson 4) |
| where the scores come from | a table of **counts** | billions of numbers called **weights**, learnt by training (lesson 8) |

The third row is where the difference in quality comes from. A table of counts can only repeat a
pair it has seen. A trained network has learnt patterns that carry over to text it never saw:
grammar, facts that were common in what it read, the shape of an argument, the structure of a
program. **It still outputs the same thing `toylm` outputs: a score for every possible next
piece.**

That is why "the model knows" and "the model thinks" are worth saying carefully. What it has is a
very good sense of **what text usually comes next**. Most of the time the likely text and the true
text are the same, which is why these models are useful. Lesson 5 is about the times they are
not.
