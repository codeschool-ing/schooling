---
title: Focus you can see, and focus nothing hides
version: 1
---

**The focus indicator is the keyboard user's mouse pointer.** Without it they press Tab and have
to guess where they are, and pressing Enter becomes a gamble. Browsers draw one by default, the
ring you see when you tab through any unstyled page, and the commonest way to lose it is a line of
CSS somebody added because the ring looked untidy when they clicked a button with the mouse:

```css
*:focus { outline: none; }
```

That is defect 3, and it is in thousands of real stylesheets.

## Three criteria about focus

| criterion | level | what it asks |
|---|---|---|
| **2.4.7 Focus Visible** | AA | any control operated by keyboard has a visible focus indicator |
| **2.4.11 Focus Not Obscured (Minimum)** | AA, new in 2.2 | the focused control is not *entirely* hidden by content the page itself drew |
| **2.4.13 Focus Appearance** | AAA, new in 2.2 | the indicator is large enough, at least as big as a 2 CSS pixel perimeter around the control, and has 3:1 contrast between its focused and unfocused states |

2.4.7 says the indicator exists. It does not say how big or how visible, which is why 2.4.13 was
added, at AAA. The 3:1 of *1.4.11 Non-text Contrast*, from lesson 12, applies at AA to whatever
indicator a page draws in place of the browser's, since a ring the eye cannot pick out from its
background is not much of an indicator.

**2.4.11 is the one tests miss.** A sticky header, a cookie banner pinned to the bottom of the
window, a chat button floating in a corner: each one is drawn over the page, and as the user tabs
down, the focused control scrolls underneath it. The ring is there, it is just under a banner. The
test is to tab through the whole page with every sticky element showing, at a small window size,
which is where it happens. The minimum version is met while any part of the control remains
visible; the AAA version, 2.4.12, asks for none of it to be hidden.

## :focus and :focus-visible

The reason designers remove the ring is that `:focus` matches on a mouse click too, and a ring
around a button you just clicked looks like a mistake. **`:focus-visible` is the fix CSS added for
exactly that**: the browser applies it when it judges an indicator is useful, which is always for
keyboard focus and usually not for a mouse click on a button.

```css
:focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
```

That one rule, in place of the one that removed the ring, satisfies the designer and the keyboard
user at once. Lesson 12's `contrast.py` measures the blue against the white page:

```
ana@nft:~/a11y$ python3 contrast.py 1a5fb4 ffffff
#1a5fb4 on #ffffff: 6.29:1   AA text yes, AA large yes, AAA text no
```

The blue is 6.29:1 against white, comfortably over the 3:1 an indicator needs, and
the 3 pixels and the offset keep it clear of the control's own border.

## Skip links

Every page of a real site starts with the same things: a logo, the navigation, perhaps a search
box. A keyboard user meets them on every page, before the content, every time. **2.4.1 Bypass
Blocks**, level A, asks for a way past repeated blocks, and the commonest is a skip link: the
first focusable element on the page, a link to the main content.

```html
<a class="skip" href="#main">Skip to the booking form</a>
```

It is usually hidden off screen until it receives the focus, so a mouse user never sees it and a
keyboard user sees it on the first Tab. Two details decide whether it works. The target needs an
`id` the link points at. And if the target is not itself focusable, give it `tabindex="-1"`, so
that following the link moves the **focus** there and not only the scroll position; otherwise, in
some browsers, the next Tab starts again from the top. Headings and landmarks such as `<main>` and
`<nav>` meet 2.4.1 too, for screen reader users, who can jump between them; the skip link is the
same service for people who see the screen and use the keyboard.
