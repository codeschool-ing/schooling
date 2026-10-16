---
title: Operating a page with the keyboard
version: 1
---

Plenty of people never touch a mouse. Some cannot hold one steadily or at all; some are blind and
use a screen reader, which is driven from the keyboard; some use a switch, a mouth stick or
voice control, all of which arrive in the browser as keystrokes. And plenty of fast typists simply
prefer it. **WCAG's 2.1.1 Keyboard, level A, says every function of the page can be operated
through a keyboard**, with no timing required between keystrokes. It is the criterion `book.html`
fails worst, and lesson 13 showed that no tool reported it.

## The keys a tester uses

Testing with the keyboard needs no software, only the habit of putting the mouse out of reach.
These are the keys, and what each one is expected to do on an ordinary web page:

| key | what it does |
|---|---|
| **Tab** | moves the focus to the next control: link, button, field, anything focusable |
| **Shift+Tab** | moves it back to the previous one |
| **Enter** | follows a link, presses a button, submits the form from inside a text field |
| **Space** | presses a button, ticks a checkbox, opens a select in most browsers |
| **arrow keys** | move *inside* one control: between radio buttons of a group, options of a select, tabs of a tab list, cells of a grid |
| **Escape** | closes what was opened on top of the page: a menu, a dialog, a list of suggestions |
| **Home, End** | jump to the ends of a list or a field |

Two points in that table catch people out. **Tab is not for moving around inside a widget.** A
group of radio buttons is one stop in the tab order, and the arrows choose within it; a custom
widget that puts every option in the tab order makes the user press Tab twenty times to get past
it. And **Enter and Space are not interchangeable**: a link answers Enter and not Space, a button
answers both. A `<div>` made to look like a button answers neither, unless somebody writes the
code for both keys, which is the reason to use a `<button>` in the first place.

## Focus order is reading order

**2.4.3 Focus Order**, level A, asks that the order in which Tab moves through the page preserve
its meaning: roughly, that it follows the order a person reads the page and fills in the form. The
browser builds the tab order from the order of the elements in the HTML, so a page whose markup is
in reading order gets a sensible tab order for free. Two things break it.

- **A positive `tabindex`.** `tabindex="0"` puts an element into the normal order, and
  `tabindex="-1"` makes it focusable by a script but not by Tab; both are useful. Any value above
  zero moves the element **in front of everything else on the page**, in numerical order, before
  the browser starts on the elements in document order. One `tabindex="1"` reorders the whole page
  around itself, and that is defect 6.
- **CSS that moves things.** Flexbox `order`, grid placement and absolute positioning change where
  an element is drawn without changing where it is in the markup, so the focus jumps around the
  screen in an order that matches nothing the user can see. WCAG's *1.3.2 Meaningful Sequence*
  covers the reading half of the same problem.

## Focus traps

**2.1.2 No Keyboard Trap**, level A, says that if the keyboard can move the focus into something,
it can move it out again. A trap is a region the focus enters and cannot leave: an embedded video
player or a map that swallows Tab, a rich-text editor where Tab inserts a tab character and
nothing says how to escape. For a mouse user it is invisible. For a keyboard user it is the end of
the page; the only way out is to reload.

A modal dialog is the case that looks like a trap and is not one. While it is open, the focus is
**meant** to stay inside it, cycling from its last control to its first, because the page behind
it is inert. What makes it legitimate is that Escape, or a close button inside it, ends it and
puts the focus back on the control that opened it. A dialog that keeps the focus in and offers no
way out is a trap; a dialog that lets the focus wander out onto the page behind it is a different
defect.

## A manual pass, in five minutes

Before a script, the test itself, which anybody can run on any page:

1. Click in the browser's address bar, then press Tab once. The first thing on the page should
   receive the focus, and you should be able to **see** which one.
2. Keep pressing Tab. Check that the order follows the page, that nothing is skipped, and that the
   focus never disappears.
3. At each control, operate it: Enter on links and buttons, Space on buttons and checkboxes,
   arrows in selects and groups, Escape on anything that opened.
4. Complete the task the page exists for. On `book.html`, that is booking a seat.
5. Shift+Tab back through the page, to check the reverse order too.

Step 4 is the one that fails on `book.html`, and the next section shows it failing, in a
transcript.
