---
title: When not to use one
version: 1
---

An assistant is fast at producing code and has no way to be responsible for it. Most of the time
that is fine, because you are responsible for it and you check it. **The cases where not to use
one are the cases where you cannot check what it gives you**, or where sending the code is not
yours to decide.

## When you cannot judge the answer

- **A domain you do not know.** If you could not have written the code, you cannot review it
  either, and a fluent wrong answer looks the same as a right one. Use the assistant to explain and
  to point at documentation, and write the code once you understand it.
- **Security-sensitive code.** Authentication, permissions, cryptography, anything that parses
  untrusted input. The mistakes here do not fail a test; they work, and are exploited later. A
  generated `verify_signature` that returns `True` on a malformed input passes every test that
  only checks valid signatures. Lesson 11 comes back to this.
- **Money, dates and units**, where the obvious code is subtly wrong. Lesson 3 section 07 found a
  rounding bug in four lines of the shop's own code. These are the places to write the tests first
  and keep the assistant's suggestion only if it passes them.

## When it is not yours to decide

- **Your employer's code and its policy.** Whether code may be sent to a third party, which tools
  are approved, whether there is a contract that keeps the code out of training: these have
  answers in your organisation, and the answer comes before the extension is installed.
- **Licences.** A suggestion can reproduce code from the model's training data closely, including
  code under a licence your project cannot accept. Some assistants offer a filter that blocks
  suggestions matching public code. If your project's licence matters, find out whether yours has
  one and whether it is on.

## When it costs more than it saves

- **When you are learning.** Typing the loop yourself is how the loop becomes yours. An assistant
  that completes every exercise teaches you to accept completions. Use it to explain an error,
  not to make it go away.
- **When the change is one you could type faster than you could check.** A rename across three
  lines, a fixed typo, a value changed in one place.
- **When the tests do not exist yet.** Lesson 3 section 06 showed what an assistant's change looks
  like when nothing checks it: green, and wrong. The first thing to ask an assistant for in
  untested code is help writing the tests, which is where lesson 4 begins.
