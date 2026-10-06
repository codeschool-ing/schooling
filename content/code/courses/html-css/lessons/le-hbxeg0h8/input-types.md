---
title: Types of field
version: 1
---

`<input>` is one element with many behaviours, chosen by its `type`. The default is `text`, a single line of anything. The others change three things: **what the browser accepts**, **what it offers to help** and, on a phone, **which keyboard appears**.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Types · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Field types</h1>
      <form>
        <label for="t-email">Email</label> <input id="t-email" type="email">
        <label for="t-tel">Phone</label> <input id="t-tel" type="tel">
        <label for="t-qty">Copies</label> <input id="t-qty" type="number">
        <label for="t-date">Pick-up date</label> <input id="t-date" type="date">
        <label for="t-pw">Password</label> <input id="t-pw" type="password">
        <label for="t-q">Search</label> <input id="t-q" type="search">
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe types.html tree
- main:
  - heading "Field types" [level=1]
  - text: Email
  - textbox "Email"
  - text: Phone
  - textbox "Phone"
  - text: Copies
  - spinbutton "Copies"
  - text: Pick-up date
  - textbox "Pick-up date"
  - text: Password
  - textbox "Password"
  - text: Search
  - searchbox "Search"
```

Read the roles: most are **textbox**, but the number became a **spinbutton**, which a screen reader announces with its value and lets the user step up and down, and the search field became a **searchbox**. The type is information the browser passes on.

What each type changes:

| type | accepts | on a phone |
| --- | --- | --- |
| `email` | something shaped like an address, checked when the form is sent | a keyboard with `@` and `.` on it |
| `tel` | anything: phone numbers differ too much between countries to check | the number pad |
| `number` | numbers, with `min`, `max` and `step` | digits, sometimes with a sign |
| `date` | a date, picked from a calendar the browser draws | a date picker |
| `password` | anything, drawn as dots | a keyboard that does not suggest words |
| `search` | anything; some browsers add a button to clear it | a keyboard whose Enter says Go or Search |
| `url` | a full address starting with a scheme, such as `https://` | a keyboard with `/` and `.com` |

## Two traps

**`number` is for quantities, not for anything made of digits.** A CEP, a card number or a phone number is a string of digits, not an amount: nobody adds two postcodes. As `type="number"` a CEP cannot hold its hyphen at all, a server reading it as a number drops the leading zero of `05422`, and a scroll wheel over the field can change it by one. Use `type="text"` with `inputmode="numeric"`, which asks a phone for the number pad without making the value a number.

**`date` returns one fixed format whatever the reader sees.** The calendar is drawn in the reader's own convention, 08/10/2026 in Brazil and 10/08/2026 in the United States, and the value sent is always `2026-10-08`. That is a help to the server and a reason not to build a date field out of three text boxes.
