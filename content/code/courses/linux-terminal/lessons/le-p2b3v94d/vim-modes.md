---
title: Modes, which is the one idea
version: 1
---

Everything confusing about vim comes from one design decision, and once you have
it the rest is vocabulary.

**In every other editor, the keyboard types. In vim, the keyboard types only
when you are in insert mode.** The rest of the time the letter keys are
commands.

That is why typing `hello` into a freshly opened vim moves the cursor around and
deletes something: `h` is left, `e` is end-of-word, `l` is right, and the second
`l` is right again, and `o` opens a new line — which does finally put you in
insert mode, which is why the confusion usually ends with a stray blank line.

## The modes you will use

| | how you get there | how you leave |
|---|---|---|
| **normal** | `Esc`, from anywhere | you do not — this is home |
| **insert** | `i` `a` `o` `O` `I` `A` | `Esc` |
| **visual** | `v` `V` `Ctrl-v` | `Esc` |
| **command-line** | `:` `/` `?` | `Enter`, or `Esc` to abandon |

**Normal mode is home.** When you do not know where you are, press `Esc`. It is
harmless in normal mode — it beeps or flashes — and it gets you there from
anywhere else.

Vim opens in normal mode. It is the only editor that does, and it is the source
of the entire joke.

## How you know which one you are in

```schooling-figure
{"caption": "`vim server.conf`, captured from a real terminal. The bottom line is the whole of vim's user interface.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen as it opens: the six lines of server.conf, tildes below them, and server.conf 6L, 101B with the ruler at 1,1.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">&#34;server.conf&#34; 6L, 101B                                                            1,1           All</tspan></text></g></svg>"}
```

**The bottom line is the whole of vim's user interface.** Left: what just
happened — here, the file it opened, six lines, 101 bytes. Right: the cursor,
line 1 column 1, and `All`, meaning the whole file fits on the screen.

The `~` lines are not part of the file. They mark where the file ends and the
screen keeps going.

Press `i`:

```schooling-figure
{"caption": "`i`. That is the only difference on the screen.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"The same captured vim screen after pressing i: -- INSERT -- has replaced the file&#39;s name on the bottom line, and nothing else has moved.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan font-weight=\"600\" fill=\"var(--paper)\">-- INSERT --</tspan><tspan fill=\"var(--paper)\">                                                                      1,1           All</tspan></text></g></svg>"}
```

**`-- INSERT --`.** That is the only difference on the screen, and it is the
thing to look at when you are not sure whether your keystrokes are going into
the file.

`Esc`, and it goes away. A mode with no announcement is normal mode.

And visual:

```schooling-figure
{"caption": "`V` then `jj`, captured from a real terminal. The three highlighted lines are the selection; the `3` is how many.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"The same captured vim screen after V j j: the first three lines are highlighted, and the bottom line reads -- VISUAL LINE -- with 3 as the count of selected lines.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"189.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"40.00\" y=\"29.50\" width=\"84.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"47.00\" y=\"45.00\" width=\"63.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\"># the server configuration </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">listen 8080 </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">w</tspan><tspan fill=\"#0a0e14\">orkers 4 </tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan font-weight=\"600\" fill=\"var(--paper)\">-- VISUAL LINE --</tspan><tspan fill=\"var(--paper)\">                                                       3         3,1           All</tspan></text></g></svg>"}
```

`V` then `jj` — `-- VISUAL LINE --`, and the `3` in the middle is how many
lines are selected. (The highlight is blue here because this screen asked for it,
with `:hi Visual ctermbg=blue`. Vim's own default is a grey that reads 4.2:1
under white text and 3.7:1 under black — below 4.5 whichever way you turn it,
where the blue is 6.1:1.)

## The six ways into insert mode

They differ by *where* they put you, and picking the right one saves a motion:

| | |
|---|---|
| `i` | **insert** before the cursor |
| `a` | **append** after the cursor |
| `I` | insert at the first non-blank of the line |
| `A` | append at the **end** of the line |
| `o` | **open** a new line below, and go there |
| `O` | open a new line above |

**`A` and `o` are the two you will use most**, because the two things you
usually want are "add to the end of this line" and "add a new line".

## `Esc` is far away

On a keyboard where `Esc` is where `Caps Lock` should be, this is fine. On a
laptop with a touch bar it is not.

**`Ctrl-[` is `Esc`.** Not a substitute — the same byte, 27, which is why the
terminal cannot tell them apart (lesson 1 section 08). Every vim user who does
not remap their keyboard uses it.

`Ctrl-c` also leaves insert mode and is not quite the same: it skips some of what
`Esc` does on the way out, which matters for a handful of plugins and never for
anything in this lesson.
