---
title: What a page without layout cannot tell you
version: 1
---

The easy assumption is that a simulated browser answers fewer questions and says so when it cannot
answer one. **It mostly answers every question, and the answers to the ones it cannot handle are
zeros, defaults and silence.** A check written against Chromium and moved to jsdom therefore keeps
running, keeps passing, and stops meaning anything. This section takes four of those questions to
the shop and records the answers.

## Size and position

Lesson 7 found that the home page is 400 pixels wide in a window of 360, because of one line of
`style.css`, and wrote a test that compares `document.documentElement.scrollWidth` with the
window's width. Lesson 11 said in one sentence that this basket is invisible to jsdom; this is
the measurement. The same numbers, asked of jsdom, with lesson 7's comparison at the end and a few
more questions after it. Save it as `simulated/missing.mjs`:

```javascript
// What jsdom leaves out, measured on the shop's home page.
import { open, until } from './shop.mjs';

const window = await open('/');
const { document } = window;
await until(() => document.querySelector('#products').getAttribute('aria-busy') === 'false');

// Layout: the numbers lesson 7 compared, and its check at 360 px.
const basket = document.querySelector('.basket');
const scrollWidth = document.documentElement.scrollWidth;
console.log(`innerWidth: ${window.innerWidth}`);
console.log(`scrollWidth: ${scrollWidth}`);
console.log(`.basket min-width: ${window.getComputedStyle(basket).minWidth}`);
console.log(`.basket width: ${basket.getBoundingClientRect().width}`);
console.log(`lesson 7's check at 360 px: ${scrollWidth <= 360 ? 'passes' : 'fails'}`);

// Interfaces a page may call.
for (const name of ['matchMedia', 'IntersectionObserver', 'ResizeObserver']) {
  console.log(`${name}: ${typeof window[name]}`);
}
console.log(`innerText: ${typeof document.body.innerText}`);

// Navigation: follow the Search link.
document.querySelector('a[href="/search.html"]').click();
await new Promise((resolve) => setTimeout(resolve, 200));
console.log(`after clicking Search: ${window.location.pathname}`);
window.close();
```

```
%%CAP missing%%
```

Read the first five lines together. **jsdom knows the rule and cannot apply it**: it matched
`min-width: 24rem` to the basket and even converted it to 384px, and then reports the basket as 0
wide and the page as 0 wide. `innerWidth` is 1024 because that is the number jsdom always reports,
not because anything was laid out in it. So lesson 7's check passes: 0 is not more than 360. The
same page failed it in Chromium at 400.

**That is the worst kind of result a test can produce: green on a page that is broken.** Nothing
in the output warns you. Every responsive check, every "is this inside the window", every
`toBeInViewport` belongs in a real browser.

## Interfaces that are not there

`matchMedia` is how a script asks the question a media query asks; `IntersectionObserver` is how a
page knows something scrolled into view, the usual way to load images late; `ResizeObserver`
watches an element change size. All three are `undefined` in jsdom 30.1.2, so a page that calls
one throws, as `app.js` threw on `fetch` in the last section. `innerText` is missing too, and for
the same reason as the zeros: what it returns depends on what is visible, and visibility depends on
layout. `textContent`, which ignores styles, is there.

**Navigation is the other large absence.** The Search link was clicked, jsdom printed
`Not implemented: navigation to another Document`, and the address stayed `/`. jsdom's README
names navigation and layout as the two features outside its scope. A journey across pages, the
thing an end-to-end test exists for, has to be built from one `JSDOM` per page.

## Visibility and real clicks

Above 600 pixels the shop hides the Menu button with `display: none`. A person cannot press it,
and lesson 10 showed that Playwright waits for an element to be visible before it clicks. jsdom
and Chromium, asked to press it. Save it as `simulated/hidden.mjs`:

```javascript
// The Menu button is display: none in a wide window. Who can press it?
import { chromium } from '@playwright/test';
import { address, open, until } from './shop.mjs';

const window = await open('/');
const menu = window.document.querySelector('.menu-toggle');
await until(() => window.document.readyState === 'complete');
console.log(`jsdom: display is ${window.getComputedStyle(menu).display}`);
menu.click();
console.log(`jsdom: aria-expanded is ${menu.getAttribute('aria-expanded')} after click()`);
window.close();

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
await page.goto(address + '/');
const button = page.locator('.menu-toggle');
try {
  await button.click({ timeout: 2000 });
} catch (error) {
  console.log(error.message);
}
console.log(`chromium: aria-expanded is ${await button.getAttribute('aria-expanded')}`);
await browser.close();
```

```
%%CAP hidden%%
```

**jsdom knew the button was hidden and clicked it anyway.** Its `click()` is the DOM's own method:
it sends a click event to that element, and the element's listener runs. There is no pointer, so
nothing asks whether the button is on screen, covered by something else, or zero pixels wide.
Chromium, driven by Playwright, checked those things for two seconds, said why it would not click,
and left `aria-expanded` as it was. A user's click lands on whatever is drawn at a point; only
something that draws can answer which element that is.

## The short list

What a simulated browser cannot be trusted on, with the instance from this lesson:

| question | what happened here |
|---|---|
| how big, where, does it fit | `scrollWidth` 0, lesson 7's check passed on a broken page |
| can a person see or reach it | a `display: none` button was clicked |
| does a link go somewhere | `Not implemented: navigation to another Document` |
| does the page's JavaScript run | jsdom had no `fetch`; HtmlUnit's Rhino stopped at `async` |
| does it work in the user's browser | a simulated engine is one no user has |

None of those is a defect in jsdom. Its authors list layout and navigation as out of scope, and the
missing interfaces as missing. The defect would be a test that asks one of these questions there
and believes the answer.
