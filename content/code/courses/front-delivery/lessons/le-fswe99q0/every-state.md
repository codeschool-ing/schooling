---
title: Every state, written down
version: 1
---

**The value of a workshop is in the states nobody would see otherwise, and writing them down is the
work.** Three stories for the row came from asking three questions: what does it look like before, after,
and when the data is bigger than the designer imagined? The week's summary gets the same questions, and
one more: what does it say when there is nothing to say?

```typescript
// src/week-summary.stories.ts
import type { Meta, StoryObj } from "@storybook/html-vite";
import { weekSummary } from "./components";

type Args = { planned: number; done: number };

const meta: Meta<Args> = {
  title: "Planner/Week summary",
  render: (week) => weekSummary(week),
  args: { planned: 130, done: 60 },
};
export default meta;

type Story = StoryObj<Args>;

export const InProgress: Story = {};
export const AllDone: Story = { args: { done: 130 } };
export const Empty: Story = { args: { planned: 0, done: 0 } };
```

`Empty` is the story that changed the component. Before it existed, a week with nothing planned read
*This week: 0 min planned, 0 min done*, which is correct and reads like a malfunction. Writing the story
made the case visible, and `weekSummary` gained its own sentence for it. Portfolio-project lesson 11 calls
these the paths nobody demonstrates; a story is how a design system demonstrates them.

## The questions to ask of every component

A short list covers most of what goes wrong between a design and the screen:

| state | for the planner |
|---|---|
| empty | a week with nothing planned; a course with no sessions |
| one, and many | one session; forty, which scroll |
| too long | a course title of eighty characters; a session of 600 minutes |
| finished, or disabled | a session already done |
| loading, and failed | the moment before `courses.json` arrives, and the day it does not |
| each theme | light and dark, the next section |

**Not every component needs every row.** The ones that do need them are the ones a reader meets in a bad
moment: the empty list after signing up, the error after a network drop. Those are exactly the states a
person clicking through the happy path never reaches.

## Controls are for finding states, stories are for keeping them

The Controls panel lets anybody change a story's arguments while looking at it, which is how a new state
is found: type 600 into `minutes` and see whether *10 h* fits. **A state worth keeping becomes a story**,
because a control's value is gone when the tab closes, and a story is in the repository, reviewed, and,
from the section on tests, checked on every push.
