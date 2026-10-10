---
title: The compatibility matrix
version: 1
---

A common belief is that a web page is the same everywhere, because HTML and CSS are standards and
every browser follows them. Browsers do follow them, closely, and still differ in the details:
how wide a font draws a word, how a form control looks, what a layout does when it runs out of
room. **Compatibility testing checks that the product works in each environment its users run it
in**, and for a web application like boxoffice the environment is everything on the customer's
side of the connection.

## Four dimensions

The title of this lesson names them, and each one changes something different.

The **browser** is really two things: an engine, which turns the page into pixels, and a version
of it. Three engines draw almost every page on the web. Blink draws Chrome, Edge and many smaller
browsers; Gecko draws Firefox; WebKit draws Safari. Two browsers on the same engine usually agree
with each other, and two engines are where differences live. On an iPhone, for most of their
history, Chrome, Firefox and Edge have been built on WebKit because Apple required it, so Chrome on
an iPhone has more in common with Safari than with Chrome on an Android phone.

The **operating system** decides the fonts a page falls back on, the look of buttons and menus,
and the browsers that exist at all: Safari runs only on Apple's systems.

The **device** decides the input and the size: a mouse or a finger, a physical keyboard or one
that slides up and covers half the screen, a desktop window or a phone held in one hand.

The **resolution**, for layout, is the width of the window in CSS pixels, the unit a page is laid
out in, and not the number of dots on the screen. A phone whose screen is 1080 physical pixels
across shows pages 360 CSS pixels wide, three dots to each pixel, so that text stays a readable
size. The 360 pixels in R8 are CSS pixels, and they are what a tester sets in section 04 of this
lesson.

## The matrix for R8

R8 says every page works on a phone screen 360 pixels wide and on a desktop, in current Chrome,
Firefox, Safari and Edge. Laid out as browsers against platforms, that is a **compatibility
matrix**:

| | Windows | macOS | Android phone | iPhone |
|---|---|---|---|---|
| Chrome | yes | yes | yes | yes, on WebKit |
| Firefox | yes | yes | yes | yes, on WebKit |
| Safari | no such browser | yes | no such browser | yes |
| Edge | yes | yes | yes | yes, on WebKit |

Fourteen cells exist out of sixteen. The desktop columns are tested at a desktop width and the
phone columns at 360, so every cell already carries its size. Linux is missing on purpose: the
theatre's customers rarely use it, and leaving it out is a decision the plan should record, as
lesson 1 said of everything left out.

Each browser also has versions, and **"current" moves under the matrix while it is being tested**.
Chrome, Edge and Firefox each ship a new major version roughly every four weeks, and Safari's
larger updates arrive with Apple's system updates. A matrix needs a rule for versions, the newest
stable release of each or the last two, and that is exactly the R8 question Ana sent to the
theatre's manager in lesson 6.

## What fourteen cells cost

A full pass through boxoffice's cases is roughly a morning's work for Ana. Fourteen cells of
mornings is three weeks, and the plan of lesson 1 gives her two weeks for everything, compatibility
included. Adding versions multiplies it again.

So the matrix is not a list of things to do. **It is the list of what could be tested**, and its
value is that it makes the choice visible: every cell that is not run is a cell somebody chose not
to run, with a reason, instead of a browser nobody thought of. The next section makes that choice
for boxoffice, using who the theatre's customers are and where boxoffice is most likely to break.

Compatibility testing covers more than browsers when the product is installed rather than visited:
an app for phones is tested across versions of Android and iOS, a desktop program across versions
of Windows and the other software it talks to. The method is the same matrix with different
headings, and the same need to choose.
