---
title: Search and substitute, which is `sed` with a view
version: 2
---

## Searching

```schooling-figure
{"caption": "`/timeout` then Enter.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen after a search: the cursor on line 4 and /timeout on the bottom line.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"60.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">t</tspan><tspan fill=\"var(--paper)\">imeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">/timeout                                                                          4,1           All</tspan></text></g></svg>"}
```

`/timeout` then Enter. The cursor is on line 4 and the bottom line shows what you
searched for.

| | |
|---|---|
| `/text` | search forward |
| `?text` | search backward |
| `n` | next match, same direction |
| `N` | previous match |
| `*` | search forward for the **word under the cursor** |
| `#` | the same, backwards |

**`*` is the one to learn.** Put the cursor on an identifier, press `*`, and you
are walking through every occurrence of it with `n` — no typing, no spelling
mistakes.

## It wraps, and it tells you

```schooling-figure
{"caption": "`G`, then `/timeout`. There was nothing below line 6, so the search went round to the top.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen after a search that wrapped: search hit BOTTOM, continuing at TOP on the bottom line, with the cursor back on line 4.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"60.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">t</tspan><tspan fill=\"var(--paper)\">imeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\">search hit BOTTOM, continuing at TOP</tspan><tspan fill=\"var(--paper)\">                                              4,1           All</tspan></text></g></svg>"}
```

That is `G` — go to the last line — and then `/timeout`. There is nothing below
line 6, so the search wrapped round to the top and landed on line 4.

**`search hit BOTTOM, continuing at TOP` is vim telling you there was nothing
below where you were.** It is easy to read past, and it is the difference between
"there is one match, behind me" and "there are matches ahead".

`:set nowrapscan` turns the wrapping off and makes the search fail instead, which
some people prefer for exactly that reason.

## The patterns are regular expressions

Lesson 8 section 07's syntax, with vim's own dialect on top:

```sh
/^listen              # lines starting with listen
/log_.*info           # log_ then anything then info
/\<log\>              # the whole word log, not log_level
/30$                  # 30 at the end of a line
```

**`\<` and `\>` are word boundaries** and are vim's spelling of `\b`. And by
default vim's "magic" level means `+`, `?`, `(` and `|` need backslashes, which
is why you will see `\(` and `\|` in other people's patterns.

`\v` at the start of a pattern turns on "very magic" and makes it behave like the
extended regular expressions of lesson 8 section 07: `/\v(listen|timeout)` rather
than `/listen\|timeout`.

## Case

| | |
|---|---|
| default | case **sensitive** |
| `:set ignorecase` | case insensitive |
| `:set ignorecase smartcase` | insensitive, unless your pattern has a capital in it |

**`ignorecase` plus `smartcase` is what almost everybody wants**, and it is in
the next section's `.vimrc`.

## Substitute

```schooling-figure
{"caption": "`:%s/log/LOG/g`. Four, on two lines.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen after a substitution: the last two lines now read LOG, and 4 substitutions on 2 lines on the bottom line.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"91.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\"># the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">LOG_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\">L</tspan><tspan fill=\"var(--paper)\">OG_file /var/LOG/app.LOG</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">4 substitutions on 2 lines                                                        6,1           All</tspan></text></g></svg>"}
```

`:%s/log/LOG/g`, and vim says **`4 substitutions on 2 lines`**.

**Read that number.** Four, on two lines. If you expected one, you have just
learned something before you saved rather than after.

The shape is the same as `sed`'s from lesson 8 section 13, with a range on the
front:

```localised
:[range]s/pattern/replacement/[flags]
```

| range | |
|---|---|
| nothing | this line only |
| `%` | the whole file |
| `1,10` | lines 1 to 10 |
| `.,$` | from here to the end |
| `'<,'>` | the visual selection — vim types this for you |

| flag | |
|---|---|
| `g` | **every** match on each line, not just the first |
| `c` | **confirm** each one |
| `i` | ignore case for this substitution |
| `n` | count the matches and change nothing |

**`g` is not the default**, exactly as in `sed`, and for exactly the same
reason — and it is the same bug, appearing only on lines where the thing occurs
twice.

Two flags are worth more than they look.

**`:%s/old/new/gc`** asks about each match, with `y`, `n`, `a` for all the rest,
`q` to stop, and `l` for this one and then stop. On a file you did not write, it
is the difference between a change and an accident.

**`:%s/pattern//gn`** changes nothing and reports how many matches there are.
It is `grep -c` without leaving the editor, and it is the right thing to run
*before* the substitution rather than after it.

## The separator is what you type

`s#…#…#` and `s|…|…|` work the same way, which matters for the same reason as in
lesson 8 section 13: a path full of slashes inside `s/…/…/` needs every one
escaped.

```sh
:%s#/usr/local#/opt#g        # readable
:%s/\/usr\/local/\/opt/g     # the same, and nobody can check it by eye
```

## When to use `.` instead

`:%s` changes everything at once and reports a number. `.` from section 06
changes one at a time and you watch each one.

**For a file you understand, `:%s/…/…/g`.** For a file somebody else wrote, or a
pattern you are not sure of, `/pattern` then `ciwnew<Esc>` then `n` and `.` —
slower, and you see what you are doing.
