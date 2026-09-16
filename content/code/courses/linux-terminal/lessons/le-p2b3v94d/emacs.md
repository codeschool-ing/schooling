---
title: Emacs, honestly and briefly
version: 1
---

Emacs is the third editor, and the honest framing is: you are unlikely to meet
it by accident. It is not installed by default on any mainstream distribution,
no tool opens it unless you asked for it, and nothing in this course requires it.

It is in this lesson because it is genuinely a third idea, and because if you
inherit a machine where somebody set `EDITOR=emacs` you should not be lost.

```schooling-figure
{"caption": "`emacs -nw server.conf`, captured from a real terminal.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured emacs screen: the menu bar across the top, server.conf&#39;s six lines, the mode line reading server.conf All L1 (Conf[Space]), and the echo area below it.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"700.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><rect x=\"40.00\" y=\"29.50\" width=\"7.00\" height=\"15.50\" fill=\"#b22222\"/><rect x=\"40.00\" y=\"200.00\" width=\"98.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"138.00\" y=\"200.00\" width=\"84.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"222.00\" y=\"200.00\" width=\"518.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"439.00\" y=\"215.50\" width=\"49.00\" height=\"15.50\" fill=\"#f5f5f5\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">File Edit Options Buffers Tools Conf Help                                                           </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"#ccd6e5\">#</tspan><tspan fill=\"var(--term-red)\"> the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">listen</tspan><tspan fill=\"var(--paper)\"> 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">workers</tspan><tspan fill=\"var(--paper)\"> 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">timeout</tspan><tspan fill=\"var(--paper)\"> 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_level</tspan><tspan fill=\"var(--paper)\"> info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_file</tspan><tspan fill=\"var(--paper)\"> /var/log/app.log</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">-UU-:---  F1  </tspan><tspan font-weight=\"600\" fill=\"#0a0e14\">server.conf </tspan><tspan fill=\"#0a0e14\">   All   L1     (Conf[Space]) --------------------------------------------</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">For information about GNU Emacs and the GNU system, type </tspan><tspan fill=\"#00008b\">C-h C-a</tspan><tspan fill=\"var(--paper)\">.</tspan></text></g></svg>"}
```

**`-nw` means no window** — run in this terminal rather than opening a graphical
one. Without it, on a machine with a display, emacs opens a separate window; on
a machine over `ssh` it says it cannot and falls back.

Three parts to that screen. The **menu bar** at the top, which is real and
usable with `F10`. The **mode line** near the bottom: `server.conf`, `All`
(the whole file is visible), `L1` (line 1), and `(Conf[Space])` — the major mode
emacs picked from the filename. And the **echo area** at the very bottom, which
is where prompts and messages appear.

The `-UU-` and `**` at the left of the mode line are the buffer's state: `**`
means unsaved changes, which the screenshot below shows.

## No modes, and a different idea instead

Emacs types when you type, like nano. Commands are **key chains** built from two
modifiers:

| | |
|---|---|
| `C-x` | Control and x |
| `M-x` | Meta and x — Alt, or `Esc` then `x` |

`M-` is `Esc` followed by the key on a terminal that does not send Alt properly,
which is most of them over `ssh`.

## The minimum

| | |
|---|---|
| `C-x C-s` | **save** |
| `C-x C-c` | **quit** |
| `C-x C-f` | open a file |
| `C-g` | **cancel** whatever you started. The `Esc` of emacs |
| `C-s` | search forward, incrementally |
| `C-r` | search backward |
| `C-_` or `C-/` | undo |
| `C-k` | kill to end of line |
| `C-y` | yank — paste |
| `C-a` `C-e` | start, end of line |

**`C-g` is the one to have.** Emacs is full of multi-key commands, and `C-g`
abandons the one you are half way through.

`C-s` is worth noticing for a different reason: it is search here, and it is the
terminal's *stop output* elsewhere (lesson 1 section 08). Emacs takes the key
over, which works — and is why an emacs user and a nano user disagree about what
`C-s` does.

## Leaving

```schooling-figure
{"caption": "`hello` typed and then `C-x C-c`. Emacs asks about each unsaved buffer by name.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"The same captured emacs screen on the way out: hello typed at the start of line 1, the mode line now reading -UU-:**-, and a question in the echo area asking whether to save the file.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"700.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><rect x=\"40.00\" y=\"200.00\" width=\"98.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"138.00\" y=\"200.00\" width=\"84.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"222.00\" y=\"200.00\" width=\"518.00\" height=\"15.50\" fill=\"#bfbfbf\"/><rect x=\"593.00\" y=\"215.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">File Edit Options Buffers Tools Conf Help                                                           </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">hello</tspan><tspan fill=\"var(--term-red)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">listen</tspan><tspan fill=\"var(--paper)\"> 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">workers</tspan><tspan fill=\"var(--paper)\"> 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">timeout</tspan><tspan fill=\"var(--paper)\"> 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_level</tspan><tspan fill=\"var(--paper)\"> info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">log_file</tspan><tspan fill=\"var(--paper)\"> /var/log/app.log</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726 733\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">-UU-:**-  F1  </tspan><tspan font-weight=\"600\" fill=\"#0a0e14\">server.conf </tspan><tspan fill=\"#0a0e14\">   All   L1     (Conf[Space]) --------------------------------------------</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">Save file /home/ana/work/edit/server.conf? (y, n, !, ., q, C-r, C-f, d or C-h) </tspan><tspan fill=\"#0a0e14\"> </tspan></text></g></svg>"}
```

`hello` was typed and then `C-x C-c`. **Emacs asks about each unsaved buffer by
name**, with nine possible answers — `y`, `n`, `!` for all of them, `d` to see a
diff first — and it will not exit until every one is dealt with.

## What it is actually for

Everything above makes emacs look like a heavier nano. It is not; it is a Lisp
environment with an editor in it, and the reason people use it is the things that
run inside it:

| | |
|---|---|
| `M-x shell`, `M-x eshell` | a shell, in a buffer |
| `M-x dired` | a file manager, in a buffer |
| Magit | a git interface that people switch editors for |
| Org mode | notes, outlines, scheduling, and literate documents |
| `M-x tramp` | edit files on a remote machine **as if they were local** |

That last one is section 14's subject, and it is the one thing in this list
where emacs is straightforwardly better than the alternatives.

## Where it leaves you

**If somebody hands you an emacs, you need three keys**: `C-g` to cancel,
`C-x C-s` to save, `C-x C-c` to leave. That is the whole of what this section is
for.

**If you want to learn it properly**, `C-h t` opens the built-in tutorial, which
is emacs' `vimtutor` and is as good. It is a real decision though: emacs is an
environment, and the people who are happy in it did not learn an editor, they
moved in.
