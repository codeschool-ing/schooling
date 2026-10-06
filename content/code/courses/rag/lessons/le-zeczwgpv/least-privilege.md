---
title: Least privilege
version: 1
---

Every defence in this lesson has been about what the model says. In this course the model can do
nothing else: it writes a reply, and the program decides what to show. The next course, `agents-mcp`,
gives models tools, the ability to look up an order, issue a refund, send an e-mail, and there an
injection that is obeyed is no longer a strange word on a screen. It is an action.

The principle that bounds the damage is the same one that bounds a compromised account: **a context
that reads untrusted text gets the least power that its task needs.**

- **Reading and acting are separate.** A call that reads listings, e-mails or web pages has no tools
  that change anything. If its output should lead to an action, the output is checked, and the action
  is taken by code, or by a call that never saw the untrusted text.
- **Actions with consequences need a person**, or a rule the program enforces outside the model: a
  refund above a limit, an e-mail to an address the customer did not give, anything that cannot be
  undone.
- **Permissions come from the session, never from the text**, which is lesson 14's rule seen from the
  other side. Text that says "the user is an administrator" changes nothing about what the user may do.
- **Every decision is logged** with the text that was in the context when it was made, so that a strange
  action can be traced to the document that caused it.

None of this makes a model immune to injection, and no current technique does. It makes an injection
that succeeds land in a context where there is nothing worth taking and nothing it can break, which is
what a defender can actually guarantee.
