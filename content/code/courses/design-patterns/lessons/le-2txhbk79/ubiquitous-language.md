---
title: "Ubiquitous language: one word, one meaning, everywhere"
version: 1
---

**A ubiquitous language is the set of words that the people who run the business and the people
who write the code both use, with the same meaning, in conversation, in documents and in the code
itself.** Evans gave it the name. The word *ubiquitous* is the demand. The words appear in the class names, the method names and
the error messages, and a glossary in a wiki that the code ignores does not count: a librarian
should be able to read a stack trace and recognise her own job in it.

The usual state of affairs is two languages and a translator. The business says *the hold has
lapsed*; the code says `r["st"] = 4`. Somebody on the team knows that status 4 means lapsed, and
every conversation goes through that person's head. Translation is where meaning leaks: the day
somebody adds status 5 for "cancelled by the member" and forgets that the report counts 4 and 5
together as "not collected", the report is wrong and nobody can see it from the code.

## Writing the glossary down

Start with a table, made with the librarians, of the words they actually use. Not the words the
developers would like them to use. Four rows from the library's:

| word | what the librarians mean | what it is not |
|---|---|---|
| hold | a member's place in the queue for a title | a loan; nothing has been handed over |
| shelve | put a returned copy on the hold shelf for the member at the front of the queue | put it back in the stacks |
| pickup deadline | the last day the member can collect: 7 days after shelving | the loan's due date |
| lapse | what a hold does when the deadline passes uncollected; the copy goes to the next member | a cancellation, which the member asks for |

The third column is where the value is. Every row there is a confusion that somebody on the team
had, and that the code would otherwise have encoded.

## The words in the code

Here is the code that used to say `r["st"] = 4`, written in the glossary's words. Make the lesson's
directory first:

```sh
mkdir -p ~/patterns/ddd-strategic
cd ~/patterns/ddd-strategic
```

@@ex:holds@@

```
ana@laptop:~/patterns/ddd-strategic$ python3 holds.py
placeholder
```

The hold cannot be collected before it is shelved, and the message says so in the desk's words.
Shelved on 11 May, it must be collected by the 18th; on the 18th it has not lapsed, on the 19th it
has, and collecting then is refused with a sentence a librarian would say. **Nothing in this file
needs translating for the person who decides the rules**, and that is the test of a ubiquitous
language: read the method names aloud to a librarian and see whether she corrects you.

## When the language changes, the code changes

The language is not fixed at the start. Six months in, the librarians decide that a lapsed hold
gets one more day before the copy moves on, and in the meeting
somebody calls that a *second chance*. The ubiquitous-language move is to rename and reshape the
code in the same week: a `second_chance` method, a test named after it, and the word in the
glossary. The alternative, a flag called `retry_lapsed` that only developers understand, is how the
two languages drift apart again, one convenient name at a time.

Two warnings from practice. A ubiquitous language is not one language for the whole organisation:
the next two sections find the same word meaning different things in different parts of the
library, and that is normal. And English code with Portuguese business words is fine: the classes
here could be called `Reserva` and `prateleira_de_reservas` if that is what the team and the
librarians say. What matters is one word per meaning, used by both sides.
