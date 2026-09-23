---
title: What a review is for
version: 1
---

Lesson 8 showed the mechanics: a pull request, a comment on a line, an approval. This lesson is about the
part no button does, which is **deciding what to say**. Review is where most junior developers first give
feedback to somebody more experienced, and it is uncomfortable for everybody until the purpose is clear.

## Three things it buys a team

- **A second chance to catch a mistake.** The author has read the change many times and sees what they meant
  to write. A reviewer reads what is there.
- **A second person who knows the code.** When the author is on holiday and the order form breaks, somebody
  else has already read it once. On a two-person team this matters more than any bug found.
- **A shared idea of how things are done**, which spreads without anybody writing a style guide. You learn the
  codebase fastest by reading other people's changes, which is why teams ask new people to review early.

## What it is not

It is not an exam with the reviewer as examiner, and it is not the place to win an argument about taste.
**The question a review answers is "is this good enough to merge?"**, not "is this exactly how I would have
done it?". A change can be merged while you would still have written it differently. Most good changes are
like that.

It is also not the only safety net. Automatic checks catch what a machine can catch, such as formatting,
a failing test or a broken link, and they catch it every time. A reviewer who spends their attention on
what a formatter would fix has less of it left for what only a person can see.

## An order for reading

Read from the questions that matter most to the ones that matter least, and stop commenting once the
important ones have answers:

1. **Does it do what the ticket asked?** Read the ticket and the description first.
2. **Does it work?** Wrong results, missing cases, what happens with an empty input or an unexpected one.
3. **Can the next person understand it?** Names, structure, a comment where the reason is not obvious.
4. **Is it consistent with the rest of the code?** Last, and most of it belongs to the machines.

A problem in row 1 makes rows 3 and 4 irrelevant: there is no point polishing names in a change that
solves the wrong problem.
