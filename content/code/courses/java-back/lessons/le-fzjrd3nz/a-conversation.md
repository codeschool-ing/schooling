---
title: Behaviour first, as a conversation
version: 1
---

The usual picture of behaviour-driven development is a testing tool: install Cucumber, write the
tests in English, and that is BDD. It is the wrong way round. **Behaviour-driven development** (BDD)
is a habit of agreeing on concrete examples of what the software should do *before* the code
exists, written in words the people who asked for it would sign. Cucumber is one tool that turns
those examples into tests afterwards. A team can practise BDD with a whiteboard and no tool at all,
and a team can install Cucumber and practise none of it.

## The examples come from people

The habit grew out of test-driven development. Dan North described it in 2006, after watching
teams argue about what a "test" was when the real question was what the software should do. Its
working unit is a short meeting, often called the **three amigos**: somebody who knows what the
business wants, somebody who will build it, and somebody who will try to break it. They take one
rule and ask for examples of it.

The bookshop has such a rule, and lesson 14 made it true in code: *the shop never sells a copy it
does not have*. Asked for examples, the three would write something like this:

- Five copies of *The War of the Worlds* in stock. A customer orders two. The order is accepted at
  6400 cents, and three copies are left.
- Five copies of *Persuasion*. A customer orders six. The order is refused, and five copies are
  still there.

Then the tester asks what happens with **no** copies at all, and the business person says it is the
same refusal. That answer cost one sentence. Found after release, the same question is a bug report,
a fix and a deployment. **Finding the questions the rule left open is the point of the
conversation**, and it happens before anybody writes a method.

The examples share a shape: a starting situation, one thing somebody does, and what can be seen
afterwards. That shape is the whole grammar of the language Cucumber reads, and it has names:
**Given**, **When** and **Then**.

## What Cucumber adds to the conversation

Without a tool, the examples end up in a ticket, and the code drifts away from them in silence.
Cucumber keeps them honest. The examples are written in **Gherkin**, a plain-text format with a few
keywords, in a `.feature` file that lives in the repository beside the code. Every line of a
scenario is bound to a Java method, and the file runs as a test. The same text is then two things
at once: the record of what was agreed, and a check that fails the build when the code stops
agreeing.

That double role is what people mean by **living documentation**. A requirements document says what
somebody once wanted; a feature file that passed this morning says what the software does today.

You will meet Cucumber where people who are not developers read the tests: teams whose testers
automate acceptance criteria, product owners who review scenarios in pull requests, and banks and
insurers, where an auditor may ask which rule a test proves. Gherkin is shared across languages:
Cucumber itself began in Ruby and has implementations for JavaScript and Go as well as the JVM,
and tools such as Behave for Python and Reqnroll for .NET read the same files.

## Where it sits among this course's tests

Lesson 18 tests a class, lesson 19 a service with a real database, and lesson 20 the HTTP API from
outside. Cucumber does not add a fourth kind of test: the scenarios in this lesson call the same
API the way lesson 20's tests do. What it adds is a layer of **sentences** on top, so that somebody
who reads no Java can read what is being checked, and change it.

That layer has a price, in files and in indirection, and the last section of this lesson counts
it. First, the feature file.
