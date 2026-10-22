---
title: Gherkin, read line by line
version: 1
---

A feature file is plain text with a handful of keywords at the start of its lines. Everything after
a keyword is free English, which Cucumber hands to the code without trying to understand it.
Create `src/test/resources/features/ordering.feature`:

```
Feature: Ordering books
  A customer orders books from the catalogue, and the shop
  never sells a copy it does not have.

  Background:
    Given the customer "ana" has signed in

  Scenario: An order takes copies out of stock
    Given the shop has 5 copies of "The War of the Worlds"
    When she orders 2 copies of "The War of the Worlds"
    Then the order is accepted with a total of 6400 cents
    And "The War of the Worlds" has 3 copies left

  Scenario Outline: An order for more copies than the shop has is refused
    Given the shop has <stock> copies of "Persuasion"
    When she orders <ordered> copies of "Persuasion"
    Then the order is refused as out of stock
    And "Persuasion" has <stock> copies left

    Examples:
      | stock | ordered |
      | 5     | 6       |
      | 0     | 1       |
```

Read it from the top.

**`Feature:`** names what the file is about, and the indented lines under it are a description.
Cucumber prints them and never runs them: they are for whoever opens the file a year from now and
wants to know which rule it protects. One file holds one feature.

**`Background:`** holds steps that run before every scenario in the file, as if they were written at
the top of each one. Here it signs ana in, so every scenario starts with a token of its own. Keep a
background short and about the reader's context; one that sets up half the database is a sign that
the scenarios below it share too much.

**`Scenario:`** is one example from the conversation, with a title that says what it shows. Its
steps begin with a keyword each:

| keyword | what the step says |
|---|---|
| `Given` | the world before anything happens |
| `When` | the one thing somebody does |
| `Then` | what can be observed afterwards |
| `And`, `But` | one more step of the same kind as the step above it |

The first scenario is the first example word for word: five copies, two ordered, 6400 cents, three
left. **One `When` per scenario** is the rule worth keeping, because a scenario with two actions is
two examples, and when it fails nobody can tell which of them broke.

**`Scenario Outline:`** is a scenario with holes in it. The names in angle brackets, `<stock>` and
`<ordered>`, are filled from the **`Examples:`** table below, and the outline runs once per row. The
other two examples from the conversation differ only in their numbers, so they are one outline with
two rows: five copies against an order of six, and none against an order of one. The file
therefore holds three scenarios, and the background runs three times.

## Write what happens, not how

Each step says what the customer does, in the shop's words: *she orders 2 copies of "Persuasion"*.
It does not say *she sends a POST to /orders with a JSON body whose bookId is 4*, although that is
exactly what the code behind it will do. The first kind of step is called **declarative** and the
second **imperative**, and the difference decides how long the file stays useful.

A new URL, a renamed field, a second request where there was one: the declarative sentence survives
all of them, and only the method behind it changes. The imperative one has to be rewritten every
time, and a file full of URLs and JSON is one the business person stops reading, which removes the
reason it was written in sentences at all.

The parts of a sentence that change between examples are written so they can be picked out: a title
in double quotes, a number on its own. The next section shows how the code finds them.

## In Portuguese, too

Gherkin's keywords exist in some eighty languages, and a file whose first line is `# language: pt`
is read with the Portuguese ones: `Funcionalidade`, `Contexto`, `Cenário`, `Esquema do Cenário`,
`Exemplos`, `Dado`, `Quando`, `Então`, `E` and `Mas`. Cucumber translates the keywords and nothing
else; the sentences are whatever the people in the conversation speak. This course keeps the
bookshop's feature file in English, like the rest of its code.
