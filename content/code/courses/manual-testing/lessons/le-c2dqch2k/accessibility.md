---
title: Accessibility, by keyboard and by reading the page
version: 1
---

Accessibility is often treated as a feature for a small group of users, added when there is time.
The numbers say otherwise: people who cannot use a mouse, who cannot see the screen, who see it
enlarged or who cannot tell red from green are a share of every audience, and a theatre's audience
includes all of them. R9 makes it a requirement for boxoffice: every page usable with the keyboard
alone and with a screen reader, to **WCAG 2.2 level AA**, the W3C's Web Content Accessibility
Guidelines, which are what most laws and contracts point at.

Two of the cheapest checks need no tool at all, and they find a large share of the problems.

## A walk with the keyboard

Put the mouse out of reach. Open `http://127.0.0.1:8000`, click once in the address bar so the page
is not yet in focus, and press **Tab**. Each press moves the focus to the next thing you can use;
**Shift+Tab** goes back, **Enter** follows a link or presses a button, **Space** ticks a checkbox and
the arrow keys move inside a list. On a Mac, Safari skips links when tabbing until "Press Tab to
highlight each item on a webpage" is turned on in its settings; Chrome and Firefox do not need it.

On the Shows page the focus should go to the three **Book** links in the table, then the three links
at the foot of the page. Follow the Book link for Hamlet with Enter, and on the booking page tab
through the e-mail field, the show list, the tickets field, the student box and the Book button.
Type your way through a whole booking and press the button without touching the mouse.

What you are watching for, at every step:

- Can you reach it? Something you can click but not tab to is unusable for anyone without a
  mouse.
- Can you see where you are? The focused element needs a visible outline. Browsers draw one by
  default, and pages often remove it for looks.
- Is the order sensible? Focus should follow the page as it reads, top to bottom, not jump
  around it.
- Can you get out? A widget that takes the focus and never lets it go is a keyboard trap, and it
  ends the session for a keyboard user.

boxoffice's pages are plain HTML, and the walk goes through without trouble: every control is
reachable, in order, with the browser's outline showing. That is worth writing down too. A check
that passed is a result, and the next release may undo it.

## The field with no label

Look at the booking page the way a screen reader does, which is to say as its markup. In a browser,
right-click the tickets field and choose **Inspect**; from the terminal:

```
ana@laptop:~$ curl -s http://127.0.0.1:8000/book | grep -E '<input|<select'
<p><label for="email">E-mail</label> <input id="email" name="email"></p>
<p><label for="show">Show</label> <select id="show" name="show"><option value="S1" selected>The Seagull</option><option value="S2">Hamlet</option><option value="S3">The Little Prince</option></select></p>
<p><input name="quantity" placeholder="Tickets (1 to 6)"></p>
<p><label><input type="checkbox" name="student"> Student (half price)</label></p>
```

Three of the four controls have a label tied to them. `E-mail` and `Show` use `<label for="…">`,
which points at the field's `id`; the student box sits inside its label, which works as well. The
tickets field has neither. It has a **placeholder**, the grey text "Tickets (1 to 6)" shown inside
the empty box, and **nothing else**. That is the defect this section finds.

A placeholder is not a label, for three reasons a tester can check by hand. It **disappears as soon
as you type**, so somebody who looks away and back sees a "2" with no idea what it is the number of.
A screen reader may announce it or may not, depending on which screen reader and which browser,
so some users hear only "edit text". And clicking the words does nothing, where clicking "E-mail"
puts the cursor in the e-mail field, which matters to anyone whose hands make small targets hard.
The fix is one line: a `<label for="quantity">Tickets</label>` and an `id` on the input.

## What the tools see, and what they miss

**axe** is a widely used automated checker, with a free browser extension and a library built into
many test frameworks, and WAVE and Lighthouse are two others you will meet. Run one on every page: it finds
missing alternative text, poor contrast and broken structure in seconds.

Then read its result knowing what it is. When this course ran axe-core 4.13 on the booking page,
with the WCAG 2.2 AA rules, it reported **no violations at all**. It counts the placeholder as the
field's name, which is a defensible reading of the rules, and it passes the field that this section
just found wanting. **A clean automated report is not a pass**: tools check what can be decided from
the markup, and whether a person can use the page is not one of those things.

That last check belongs to the people who use **screen readers** every day, and to testers who learn
one. NVDA is free on Windows, VoiceOver is built into macOS and iOS, TalkBack into Android, and JAWS
is the long-standing commercial one. Using one well takes practice, which is why this lesson does
not ask you to; `non-functional-testing` teaches the audit properly, WCAG criteria and assistive
technology together. What this lesson asks is the keyboard walk on every page you test and a look
at every form field's label, because those two found the missing label when the tool did not.
