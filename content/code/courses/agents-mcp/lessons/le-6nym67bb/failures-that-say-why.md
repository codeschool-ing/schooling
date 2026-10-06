---
title: Failures that say why
version: 1
---

The two failing calls in section 04's capture came back differently from lesson 13's.

**`M-9999`** got *"Error executing tool get_order: no order M-9999; check the number on the confirmation email"*. Lesson 13's server answered the same call with *"Error executing tool get_order"* and nothing more, because its function let `LookupError` escape and the SDK treats any exception it was not told about as a crash: traceback to the log, a generic sentence to the client. Here `get_order` catches the failure it expects and raises `ToolError` with a message written for whoever reads it. That is the only kind of exception whose text the SDK passes on, which is the right default: an unexpected exception can carry a connection string or a file path, and those do not belong in a model's context.

**`1043`** got the validation message: the pattern it should have matched. The function never ran and the database was never touched. A model told *"String should match pattern '^M-[0-9]{4}$'"* has what it needs to correct itself, and the same rule was in the schema it was given, so most of the time it never gets that far.

The rule is lesson 4's: **an error is a result, and it should say what failed**. The SDK draws the line in a useful place, between failures you expected and wrote a message for, and failures you did not, whose details stay on the server.
