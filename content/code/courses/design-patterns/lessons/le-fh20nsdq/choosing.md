---
title: Choosing, starting from the screen
version: 1
---

**Choose by asking what kind of screen you have and what your platform already gives you, not by
which pattern is newest.** MVVM is not an improvement on MVP, which is not an improvement on MVC.
Each fits a situation, and on most platforms the framework has already chosen for you; going
against it costs more than any pattern saves.

Five situations cover most of what you will write.

## A server that renders HTML

Use the framework's MVC and keep the controllers thin. The framework has decided the arrows:
routes, handlers, templates. What is left to you is the discipline of `web.py`, where the
controller reads the request, calls the model and chooses a view, and the rules stay in a model that
would work without HTTP. **The test of a thin controller is whether you could call the model from a
command-line script without copying a line.** If the limit check lives in the handler, you could not.

## An API that returns JSON

Barely a presentation question at all. The view is the serialiser, and the controllers are the
route handlers. The screen exists elsewhere, in a browser application or a phone app, and that
client is where the next two choices are made. What matters on the server is the same thin
controller, and an honest choice of status codes, like the `409 Conflict` of `web.py`.

## A screen on a platform with data binding

Use MVVM. WPF, JavaFX, Android, SwiftUI, Vue and Angular all ship binding, and their tutorials,
libraries and tooling assume a view-model. Writing a presenter that pushes values into widgets on
such a platform throws away the part you already have. Keep the view-model free of widget types,
so that it can be tested as an ordinary object.

## A screen on a platform without it

Use MVP. A terminal program, a Tkinter window, a game's menu, an old toolkit: none offers binding,
and building it, as `mvvm.py` did with `Observable`, is a framework you then maintain. A presenter
and a view interface are two ordinary classes, and the screen logic becomes testable with a fake
view. **MVP is also the cheapest way to get tests around screen logic that is already tangled**:
extract the decisions into a presenter one at a time, leaving `print` or the widget calls behind.

## A script that will have one screen forever

Use none of them. `tangled.py` is twenty-four lines and does its job. The three costs of the first
section arrive with a second screen, a test or a redesign; until one of those is real, the
separation is speculation, and lesson 19 counts what speculation costs. The one habit worth keeping
even here is the first move: when a rule appears, put it in a function that returns a value rather
than one that prints.

## Signs it is time to separate

The tangle announces itself, and the signs are concrete:

| you notice | it means | the move |
|---|---|---|
| a rule written twice, once per screen | presentation and rules share a file | extract the model |
| a test that captures standard output to check a number | the logic is inside the view | a presenter or a view-model |
| `if` statements deciding what is enabled, spread across event handlers | screen logic without a home | a view-model, if the platform binds |
| a handler of eighty lines | the controller is doing the model's work | move the rules into the model |

Lessons 3 and 4 gave the general version of this argument: a class with one reason to change, and
details that depend on policies rather than the reverse. A view is a detail, and the loan limit is a
policy. The patterns of this lesson are that principle applied to the one part of a program a person
looks at.
