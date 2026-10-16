---
title: What each artefact answers
version: 1
---

The failing click left one folder in `test-results/`, named after the file and the test, and four
files in it. **Each answers a different question**, and the cheapest one to open is rarely the one
that settles the matter:

```
ana@laptop:~/quitanda$ ls -la test-results/ssr-a-click-on-ssr-at-once/
total 288
drwxrwxr-x 2 ana ana   4096 Oct 15 22:10 .
drwxrwxr-x 3 ana ana   4096 Oct 15 22:10 ..
-rw-rw-r-- 1 ana ana   1510 Oct 15 22:10 error-context.md
-rw-rw-r-- 1 ana ana  43452 Oct 15 22:10 test-failed-1.png
-rw-rw-r-- 1 ana ana 124596 Oct 15 22:10 trace.zip
-rw-rw-r-- 1 ana ana 106675 Oct 15 22:10 video.webm
```

| file | the question it answers | size here |
|---|---|---|
| `test-failed-1.png` | what was on the screen when the test failed | 43 KB |
| `error-context.md` | what the page contained at that moment, as text | 1.5 KB |
| `video.webm` | how the screen got there | 107 KB |
| `trace.zip` | what happened, in what order, and when | 125 KB |

## The screenshot: the end, as a person would see it

```
ana@laptop:~/quitanda$ file test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png test-results/ssr-a-click-on-ssr-at-once/video.webm
test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png: PNG image data, 1280 x 720, 8-bit/color RGB, non-interlaced
test-results/ssr-a-click-on-ssr-at-once/video.webm:        WebM
```

A picture of the whole window, 1280 by 720, taken after the assertion gave up. It shows the eight
cards, each with its button, and *Basket: 0 items*. **Nothing in it looks wrong**, and that is a
finding: the page drew everything, so the failure is not a missing element or a broken layout. A
screenshot answers *what did the screen show at the end* and nothing about how it came to show it.
It is the artefact people open first because it opens in anything, and the one that most often
says *looks fine to me*.

## The error context: the end, as text

Playwright writes `error-context.md` beside every failure, whatever the configuration says. Inside
is a **snapshot of the page's accessibility tree**: each element by its role and its name, the
way a screen reader meets the page, which is also how `getByRole` finds things. The file is
Markdown with the tree inside a `yaml` block, and the two lines that open and close the block are
left out here by `grep -v`:

```
ana@laptop:~/quitanda$ grep -v '^```' test-results/ssr-a-click-on-ssr-at-once/error-context.md
# Page snapshot

- main [ref=e2]:
  - heading "Fruit of the season" [level=1] [ref=e3]
  - paragraph [ref=e4]: "Basket: 0 items"
  - list [ref=e5]:
    - listitem [ref=e6]:
      - heading "Banana" [level=2] [ref=e7]
      - paragraph [ref=e8]: R$ 5,90
      - button "Add to basket" [active] [ref=e9] [cursor=pointer]
    - listitem [ref=e10]:
      - heading "Mango" [level=2] [ref=e11]
      - paragraph [ref=e12]: R$ 4,50
      - button "Add to basket" [ref=e13] [cursor=pointer]
    - listitem [ref=e14]:
      - heading "Papaya" [level=2] [ref=e15]
      - paragraph [ref=e16]: R$ 7,90
      - button "Add to basket" [ref=e17] [cursor=pointer]
    - listitem [ref=e18]:
      - heading "Guava" [level=2] [ref=e19]
      - paragraph [ref=e20]: R$ 12,90
      - button "Add to basket" [ref=e21] [cursor=pointer]
    - listitem [ref=e22]:
      - heading "Cashew fruit" [level=2] [ref=e23]
      - paragraph [ref=e24]: R$ 15,90
      - button "Add to basket" [ref=e25] [cursor=pointer]
    - listitem [ref=e26]:
      - heading "Passion fruit" [level=2] [ref=e27]
      - paragraph [ref=e28]: R$ 9,90
      - button "Add to basket" [ref=e29] [cursor=pointer]
    - listitem [ref=e30]:
      - heading "Acerola" [level=2] [ref=e31]
      - paragraph [ref=e32]: R$ 18,90
      - button "Add to basket" [ref=e33] [cursor=pointer]
    - listitem [ref=e34]:
      - heading "Pineapple" [level=2] [ref=e35]
      - paragraph [ref=e36]: R$ 6,90
      - button "Add to basket" [ref=e37] [cursor=pointer]
```

Read it for one word. The Banana card's button carries **`[active]`**, which marks the element
that has the focus, and a button gets the focus when it is clicked. So the click reached the button,
and the count beside it still says `0`. Of the four stories in the previous section, *the click
missed* is ruled out by a file of 1.5 KB that you can read in a terminal, search with `grep`, and
compare with the same file from yesterday's run. A screenshot can do none of those three.

## The video: how it got there

The video films the browser for the whole test. Playwright's documentation says it is scaled to fit
800 by 800 unless you give it a size, which keeps it small. **Nobody watched this one for the
course**: the machine these lessons were recorded on has no screen. For this failure it would show a
page that appears and then does not change for five seconds, which agrees with the error context
and adds little. A video earns its size when the order of what appears on screen is the question:
a dialog that covered a button for a moment, a page that scrolled while the test clicked. It
cannot show what the test did or what the network was doing; it shows only what was painted.

## The trace: everything, with times

The trace is the largest file and the only one that holds **time**: every action the test took,
when it started, every request and response with their timings, the console, and a snapshot of the
page around each action. The screenshot, the video and the error context say *what*; only the
trace can say *before* and *after*, and a race like this one is a question about order. The next
section opens it.

## The report beside them

The HTML reporter in `evidence.config.js` wrote `playwright-report/` as well, a page that shows
each test with all its attachments in one place:

```
ana@laptop:~/quitanda$ du -sh test-results playwright-report
292K	test-results
2.1M	playwright-report
```

The report is the bigger of the two, 2.1 MB against the 292 KB it was built from, so copying both
off a build server is a decision about disk as well as about convenience; the section on build
servers comes back to it.
