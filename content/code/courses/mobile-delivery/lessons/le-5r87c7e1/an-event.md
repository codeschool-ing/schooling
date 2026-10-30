---
title: An event, and the schema that decides it
version: 1
---

**An analytics event is a record that something happened in the app: a name, a time, a few
properties, and an identifier for the installation it happened on.** `session_done` at 19:40 with
`minutes: 30`, from installation `i042`. Everything a product team later asks about, how many, how
often, in which order, is a query over rows like that.

## Four decisions per event

- **The name says what happened, in the past tense, from the person's side**: `session_done`, not
  `button_tap_3` or `WeekViewModel.complete`. A name that describes the code changes when the code
  does, and last month's numbers stop meaning the same thing.
- **The properties are numbers and choices, never what the person wrote.** `minutes: 30` and
  `course_count: 2` are measurements; a course name, a note, a search query are the person's content.
- **The identifier is the installation's, random**, the same idea as the crash reporter's of lesson
  12: it counts and orders without naming.
- **The time is the device's, at the moment it happened.** Events are queued and sent later, like
  crash reports, because a phone is offline much of the day.

## The schema is the decision, written down

A team that lets any code send any event with any properties ends up with thousands of event names,
half of them typos, and properties nobody remembers adding, one of which is an e-mail address. The
cure is a **schema**: the list of events the app may send and the properties each may carry, kept in
the repository and reviewed like code. **An event or a property not in the schema is refused**, at
the moment it is sent, in development, where somebody sees the error.

The planner's schema has four events:

| event | properties | the question it answers |
|---|---|---|
| `app_open` | none | how many installations are used |
| `course_added` | `course_count` | does the person get started |
| `session_added` | `minutes` | do they plan |
| `session_done` | `minutes` | do they study |

Section "A funnel" builds the code that enforces it, and lesson 5's inventory carries one line for
all four: product events, not linked to the person, optional.
