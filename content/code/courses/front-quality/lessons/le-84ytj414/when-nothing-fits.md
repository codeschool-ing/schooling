---
title: When no query fits
version: 1
---

**Sometimes the element you want has no role, no label and no text of its own, and the library
offers three ways out, in order of how much they give up.** Reaching for the third is a sign that the
page, not the test, needs to change.

## Narrow the search: `within`

The home page has a list of courses, each item with a link and a sentence. "The JavaScript item's
minutes" is not a query, but it is two: find the item, then search inside it.

```typescript
const item = screen.getByRole("link", { name: "JavaScript" }).closest("li")!;
expect(within(item).getByText("90 min this week")).toBeInTheDocument();
```

`closest("li")` walks up to the item, and `within(item)` limits the second query to it. Each step is
still something a person can see.

## See what the library sees: `screen.debug`

When a query fails and you cannot tell why, `screen.debug()` prints the page as the library has it,
the same dump the red test printed earlier in this lesson. `logRoles(document.body)`, from
`@testing-library/dom`, prints every element by the role and name the queries would match, which is
the quickest answer to "why does `getByRole("button", { name: "Done" })` not find my button".

## The last resort: `data-testid`

A `data-testid="week-total"` on the paragraph would make `getByTestId("week-total")` work, and it
would work forever, because nothing but the test reads it. That is the problem. The planner's week
total is found by its text, `getByText("This week: 105 min")`, which also checks that the sentence
says what it should. **Use a test id for what genuinely has no perceivable handle**, such as a
canvas a test needs to locate, and treat each one as a question about whether a person could find
that thing.

## What to leave alone

- **The `container` and `querySelector`.** They are still there, and lesson 2 shows how far they get
  you. Every selector is a fact about the code rather than the page.
- **Snapshot tests of a whole page.** `expect(document.body.innerHTML).toMatchSnapshot()` records the
  markup and fails on any change, including the label fix of this lesson, so it fails for refactoring
  and has nothing to say about whether the change was right. A snapshot reviewed by nobody is a test
  that the page did not change, which is rarely the question.
