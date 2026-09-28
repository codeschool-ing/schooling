---
title: Listing the unhappy paths
version: 1
---

Before handling errors, list them. For every action a user can take, ask what can go wrong, and
decide what the answer should be. loanbook has two actions, and this is the whole list:

| what happens | whose mistake | the answer |
|---|---|---|
| an address that does not exist | the client's | 404, *Nothing lives at …* |
| a body that is not JSON | the client's | 400, *The body is not JSON.* |
| an item number that does not exist | the client's | 404, *There is no item 9.* |
| lending with no name, or only spaces | the user's | 400, *Say who is borrowing it.* |
| lending an item that is already out | nobody's: it is the rule | 409, *Projector 2 is already lent to…* |
| returning an item that is not out | nobody's: it is the rule | 409, *… is not out, so it cannot come back.* |
| the server is down | not the user's | the page says so, and what to do |
| something nobody expected | ours: it is a bug | a line in the server's log |

The middle column decides the rest. **A client's or user's mistake gets a sentence that says how to
fix it.** **A rule gets a sentence that says which rule, with the facts**: not *conflict*, but who has
the projector and until when. **Our own mistake gets no sentence at all** in the response; it goes to
the log, where the person who can fix it will look.

The list is short because loanbook is small. Yours will be longer, and writing it is the step that
finds the paths. Every one of these rows was a decision; none was discovered by a user.
