---
title: The server checks everything again
version: 2
---

Everything in this lesson so far happens in the reader's browser, and that has a consequence that is a matter of security rather than of convenience. **The browser belongs to the reader.** Native validation is a service to the honest person filling in the form; it is not a guard on the server.

The demonstration is short. Save a copy of `order.html` as `unchecked.html` and add one attribute to its form, `novalidate`, which tells the browser not to check anything before sending: `<form action="order" method="post" novalidate>`. Then fill it in with nonsense and send it:

```
ana@laptop:~/site$ probe unchecked.html fill '#email' 'not an address' fill '#copies' -40 send button
POST /order
Content-Type: application/x-www-form-urlencoded
name=&email=not+an+address&cep=&copies=-40&title=
```

An email that is not an email, minus forty copies, an empty name and an empty title, all sent as an ordinary POST. Nobody needs to edit the page to do this: anyone can open DevTools and delete `required` from a field, or skip the browser entirely and send the request with a command-line tool, typing any body they like. As far as the server can tell, every request it receives could have come from anywhere.

## What the server does about it

This course is about the page, and the server is the subject of the back-end courses, but the principle is short enough to state here, because it is the one people get wrong:

- **Every rule in the form is checked again on the server**, with the server's own code: required fields present, numbers in range, formats right. A value that fails is refused with an error the page can show, and nothing is stored.
- **The server never trusts a value for being in a list the page offered.** A `<select>` with two shops does not stop somebody sending `shop=anything`; the server checks against its own list.
- **What arrives is data, never code or markup.** A name field can contain `<script>`, and whatever the server later puts back into a page has to be escaped so that it is shown as text. `security-fundamentals` is where that, cross-site scripting, is taught properly.

So why validate in the browser at all? Because it is **instant and in the reader's language**, and it catches the honest mistakes, which are nearly all of them, before a round trip to the server. The two checks have different jobs: the browser's helps people, and the server's protects the system. A form needs both, and only the server's can be relied on.
