---
title: What the floor is
version: 1
---

The standard is **WCAG 2.2**, the Web Content Accessibility Guidelines, and the level almost every
organisation asks for is **AA**. It has dozens of criteria. For a small project, seven checks cover most
of what a reviewer, or a real user, will run into:

| check | what it means in loanbook |
|---|---|
| every field has a **label** | the name field says whose loan it is, and stays visible while you type |
| everything works **by keyboard**, with visible focus | Tab reaches every field and button, and you can see where you are |
| text has **contrast** of at least 4.5:1 | grey on white is dark enough to read in a corridor |
| **headings and landmarks** mark the structure | one `h1`, the content inside `main`, the table's headers marked as such |
| changes are **announced** | *lent until the 13th* is read out, not only drawn |
| it works at **320 pixels** with no sideways scrolling | the table becomes a list on a small phone |
| touch targets are at least **24 pixels** | a finger can press *Return* without pressing its neighbour |

None of these is expensive when done as the page is built, and each one is expensive to add to a page
that was built without it. That is why lesson 6 put accessibility on the floor, with the things that
are never cut.

And there is a portfolio reason besides the users. **Accessibility is something a reviewer can check in
a minute**, with the keyboard and a tool, and very few junior portfolios pass. A page that does is
noticed for it.
