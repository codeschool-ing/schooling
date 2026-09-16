---
title: Getting out, and the four screens that stop you
version: 1
---

This section is the one to read twice. Everything in it happens when you are in a
hurry.

## The four commands

| | |
|---|---|
| `Esc` | get to normal mode. **First, always** |
| `:q!` | leave, throwing away changes |
| `:wq` | save and leave |
| `u` | undo |

**`Esc` then `:q!`** is the answer to "I am stuck in vim". It works from insert
mode, from visual mode, from a half-typed command. It throws away your changes,
which is what you want when you did not mean to make any.

If `Esc` does not seem to work, you are probably in the middle of a multi-key
command — press it twice.

## Screen one: it will not let you quit

```schooling-figure
{"caption": "A line deleted, then `:q`. Vim will not leave until the change is dealt with.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen refusing to quit: five lines of server.conf and E37: No write since last change (add ! to override) on the bottom line.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><rect x=\"40.00\" y=\"215.50\" width=\"357.00\" height=\"15.50\" fill=\"var(--term-red-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#0a0e14\"> </tspan><tspan fill=\"var(--paper)\">the server configuration</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">listen 8080</tspan></text><text x=\"40 47 54 61 68 75 82 89 96\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">workers 4</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">timeout 30</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_level info</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">log_file /var/log/app.log</tspan></text><text x=\"40\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\">~</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537 544 551 558 565 572 579 586 593 600 607 614 621 628 635 642 649 656 663 670 677 684 691 698 705 712 719 726\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"#1b1a14\">E37: No write since last change (add ! to override)</tspan><tspan fill=\"var(--paper)\">                               1,1           All</tspan></text></g></svg>"}
```

**`E37` is vim protecting you**, not vim being difficult. You changed something
and asked to leave without saving.

| | |
|---|---|
| `:wq` | you meant to keep it |
| `:q!` | you did not |

Notice the first line. It read `# the server configuration` and now begins with
a space, because that is where the `x` landed. One character is the whole of what
vim is refusing to lose here, and it is refusing just as hard as it would for a
day's work.

## Screen two: `Press ENTER`

Any message that is too long, or any command that produced output, ends with
`Press ENTER or type command to continue`. **Press Enter.** It is not a prompt
with consequences; vim is waiting for you to have read the line.

## Screen three: the swap file

```schooling-figure
{"caption": "A vim was opened, a line was added, and the process was killed. This is what the next vim shows.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen reporting a swap file: E325: ATTENTION, the swap file&#39;s owner, date, process ID and the file it belongs to, and -- More -- at the foot.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"40.00\" y=\"14.00\" width=\"105.00\" height=\"15.50\" fill=\"var(--term-red-bg)\"/><rect x=\"110.00\" y=\"215.50\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"#1b1a14\">E325: ATTENTION</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">Found a swap file by the name &#34;.server.conf.swp&#34;</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">          owned by: ana   dated: Wed Sep 16 19:34:06 2026</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">         file name: ~ana/work/edit/server.conf</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">          modified: YES</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">         user name: ana   host name: vm</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">        process ID: 3361</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">While opening file &#34;server.conf&#34;</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">             dated: Wed Sep 16 19:34:04 2026</tspan></text><text x=\"40\" y=\"165.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">(1) Another program may be editing the same file.  If this is the case,</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">    be careful not to end up with two different instances of the same</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">    file when making changes.  Quit, or continue with caution.</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-green)\">-- More --</tspan><tspan fill=\"#0a0e14\"> </tspan></text></g></svg>"}
```

That is real: a vim was opened, a line was added, and the process was killed.
This is what the next vim shows.

**Vim keeps a swap file while you edit**, so that if it dies your work is not
gone. Finding one on startup means one of two things, and the screen tells you
which:

| | |
|---|---|
| `process ID: 7985` **still running** | somebody else has this file open. Press `q` and go and ask |
| that process is gone | vim or the machine died. Your unsaved work is in the swap file |

Press Enter past the `-- More --` and the choices appear. The ones that matter:

| | |
|---|---|
| `r` | **recover** — load what was in the swap file |
| `e` | edit anyway, ignoring it |
| `q` | quit. **The safe one if you are not sure** |
| `d` | delete the swap file |

**The right sequence when the work was yours and the editor died:** press `r`,
look at what came back, save it somewhere, and then `:q` and delete the swap
file — vim will not do that for you, and until it is gone you get this screen
every time.

```sh
ls -la .server.conf.swp        # they are hidden, and named after the file
rm .server.conf.swp
```

## Screen four: the terminal, not vim

Sometimes vim is fine and the terminal is not. Lesson 1 section 08's two cases:

| | |
|---|---|
| nothing appears when you type | you pressed `Ctrl-s`. Press `Ctrl-q` |
| vim exited but the terminal is a mess | `reset`, or `stty sane` |

**`Ctrl-s` is the one that looks exactly like a hung editor**, and it is a
terminal feature from the era of paper.

## Two ways to lose work that are not vim's fault

**Editing a file that something else rewrites.** A config manager, a deploy, a
service that rewrites its own file. Vim warns on write — `WARNING: The file has
been changed since reading it!!!` — and it is a prompt you have to read rather
than dismiss.

**Editing the wrong copy.** `sudo vim` on a file, then finding your change is
not there, because you opened `/etc/nginx/nginx.conf` and the running one is
`/etc/nginx/sites-enabled/default`. Not an editor problem, and the most common
way an edit "does not take".

## The card

```
Esc            get to normal mode
:q!            leave, discard changes
:wq            save and leave
u              undo
Ctrl-r         redo
/text  n       search, next
dd  yy  p      delete a line, copy a line, paste
i  A  o        insert here, at end of line, on a new line
:set paste     before pasting anything
```

Nine lines. If vim is not your editor, that is all of it you need — and the four
at the top are the ones that matter on a machine somebody is waiting for.
