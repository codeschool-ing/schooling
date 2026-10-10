---
title: The catalogue: twenty-three patterns in three families
version: 1
---

**A design pattern is a named, recurring solution to a problem that keeps coming back in a
particular context, written down with its costs.** The name is half the value. "Put an adapter in
front of it" is a whole design said in five words to anybody who knows the vocabulary, and the
vocabulary this lesson teaches is the oldest and most widely shared one the profession has.

The common misreading is that patterns are code to copy, or a checklist of things a good program
must contain. Neither is true of the book they come from. A pattern is a description of a problem
and the shape of a solution; the code that implements it differs in every program and every
language. And a program with no patterns in it is not a worse program, only one that never met
those problems.

## The book

In 1994 Erich Gamma, Richard Helm, Ralph Johnson and John Vlissides published *Design Patterns:
Elements of Reusable Object-Oriented Software*. The four authors became the Gang of Four, the book
became "GoF", and its twenty-three patterns became the shared vocabulary. The examples were in C++
and Smalltalk, the languages of the day, and some of the patterns show it: the last reading section
of this lesson is about the ones a modern language has swallowed.

Each pattern in the book has the same parts. A **name**, the **problem** it addresses and when it
applies, the **solution** as a set of collaborating classes, and the **consequences**: what the
pattern costs and what it makes harder. The last part is the one most often skipped by people who
learned patterns from a blog post, and it is where the judgement lives. Every pattern adds
indirection; the consequences section says when that indirection pays.

The book's introduction also states two principles that run under almost every pattern in it:

- program to an interface, not an implementation;
- favour object composition over class inheritance.

You have already met both. Lesson 4 argued the first as dependency inversion, and lesson 2 argued
the second at length. **Most of the GoF patterns are those two principles applied to a specific
problem**, which is why a reader who has followed this course so far will find many of them
familiar before reading their names.

## Three families

The book sorts the patterns by what they are about.

| family | what it is about | how many |
|---|---|---|
| creational | how objects get made, so the code using them does not decide which class it gets | 5 |
| structural | how objects are put together into larger structures | 7 |
| behavioural | how objects divide up work and talk to each other | 11 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-catalogue\" aria-label=\"The twenty-three patterns of the 1994 book in three columns. Creational, five: Abstract Factory, Builder, Factory Method, Prototype, Singleton. Structural, seven: Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy. Behavioural, eleven: Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor. Thirteen are drawn with a solid border because this lesson works through them: Builder, Factory Method, Singleton, Adapter, Decorator, Facade, Proxy, Command, Iterator, Observer, State, Strategy and Template Method. The other ten have a dashed border.\"><text x=\"105.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">creational · 5</text><rect x=\"30.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"105.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Abstract Factory</text><rect x=\"30.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Builder</text><rect x=\"30.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Factory Method</text><rect x=\"30.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"105.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Prototype</text><rect x=\"30.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Singleton</text><text x=\"295.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">structural · 7</text><rect x=\"220.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Adapter</text><rect x=\"220.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"295.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Bridge</text><rect x=\"220.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"295.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Composite</text><rect x=\"220.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Decorator</text><rect x=\"220.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Facade</text><rect x=\"220.0\" y=\"195.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"295.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Flyweight</text><rect x=\"220.0\" y=\"226.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Proxy</text><text x=\"560.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">behavioural · 11</text><rect x=\"405.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Chain of Responsibility</text><rect x=\"405.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Command</text><rect x=\"405.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Interpreter</text><rect x=\"405.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Iterator</text><rect x=\"405.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mediator</text><rect x=\"405.0\" y=\"195.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Memento</text><rect x=\"565.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Observer</text><rect x=\"565.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">State</text><rect x=\"565.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Strategy</text><rect x=\"565.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Template Method</text><rect x=\"565.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"640.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Visitor</text><path d=\"M200.0 10.0 L200.0 236.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M390.0 10.0 L390.0 236.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"170.0\" y=\"258.0\" width=\"34.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in this lesson (13)</text><rect x=\"410.0\" y=\"258.0\" width=\"34.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"452.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">named only (10)</text></svg>", "caption": "The catalogue by family. The solid boxes are the thirteen this lesson builds; the dashed ones get a line in the table."}
```

This lesson works through thirteen of them, in pairs that are easy to confuse or that solve
neighbouring problems: factory and builder, adapter and facade, decorator and proxy, strategy and
observer, command and state, template method and iterator. Singleton gets a section of its own,
mostly about why to distrust it. The other ten are rarer in application code, and each has a
one-line description below so you can recognise the name when somebody uses it.

| pattern | in one line |
|---|---|
| Abstract Factory | one object that creates a whole family of related objects, such as every widget of one look |
| Prototype | new objects made by copying an existing one rather than by calling a class |
| Bridge | splitting an abstraction from its implementation so both can vary, like shapes and renderers |
| Composite | a tree where a group and a single item answer the same interface, like folders and files |
| Flyweight | sharing the immutable part of many small objects, like one glyph object per letter |
| Chain of Responsibility | a request passed along a line of handlers until one takes it |
| Interpreter | a class per grammar rule, to evaluate sentences of a small language |
| Mediator | one object that coordinates many, so they stop referring to each other |
| Memento | a snapshot of an object's state taken without breaking its encapsulation, for undo |
| Visitor | an operation added to a class hierarchy without editing the classes |

Chain of responsibility is worth knowing by name, because it is the shape of the middleware in
every web framework: each layer handles the request or passes it on. Lesson 19 is about the harder
question this vocabulary leaves open, which is when to use any of it.
