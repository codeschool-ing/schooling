---
title: A `.vimrc` worth having, and one you should not
version: 1
---

Vim with no configuration is usable. Vim with ten lines of configuration is
pleasant. Vim with somebody else's four-hundred-line configuration is a
different program that you do not know.

## The ten lines

```vim
" ~/.vimrc — the minimum
set number              " line numbers
set ignorecase          " searching is case-insensitive
set smartcase           " unless the pattern has a capital in it
set incsearch           " jump to matches as you type
set hlsearch            " highlight every match
set expandtab           " the Tab key inserts spaces
set tabstop=4           " a Tab character displays as four columns
set shiftwidth=4        " > and < indent by four
set scrolloff=3         " keep three lines visible above and below the cursor
syntax on               " colour, if the terminal has it
```

A `"` starts a comment, which is vim's own oddity and not a typo.

Four of those are worth a sentence each.

**`ignorecase` with `smartcase`** is the pair. Alone, `ignorecase` means you can
never search for a capital letter on purpose; together they do what you actually
want, which is insensitive until you type a capital.

**`scrolloff=3`** is the one nobody mentions and everybody misses once they have
had it. The cursor stops three lines from the edge instead of sitting on the
bottom row, so you can always see what is coming.

**`expandtab` is a decision, not a default.** It makes the Tab key insert spaces.
On a Python file that is right; on a `Makefile` it breaks the file, because make
requires real tabs. `:set noexpandtab` for those, or let a filetype rule do it.

**`hlsearch` leaves the highlighting on** after you have found what you wanted,
which is irritating. `:noh` clears it until the next search.

## Where it goes

| | |
|---|---|
| `~/.vimrc` | yours |
| `~/.vim/` | your plugins, colours and filetype rules |
| `/etc/vim/vimrc` | the machine's, applied to everybody |
| `~/.config/nvim/init.vim` | neovim's, which is otherwise the same thing |

**`vim -u NONE file`** starts with no configuration at all. It is how you find out
whether something odd is vim or is your `.vimrc`, and it is the first thing to
try when an editor behaves differently on two machines.

## `:set` at runtime

Every `set` works as a command while you are editing:

```schooling-figure
{"caption": "`:set number`, captured from a real terminal. The command stays on the bottom line until something else needs it.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A captured vim screen after :set number: the six lines of server.conf each with its number in a column on the left, and the command still on the bottom line.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  1 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"490.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                      </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  2 </tspan><tspan fill=\"var(--paper)\" textLength=\"672.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                                     </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  3 </tspan><tspan fill=\"var(--paper)\" textLength=\"672.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                                       </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  4 </tspan><tspan fill=\"var(--paper)\" textLength=\"672.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                                      </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  5 </tspan><tspan fill=\"var(--paper)\" textLength=\"672.00\" lengthAdjust=\"spacingAndGlyphs\">log_level info                                                                                  </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-yellow)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  6 </tspan><tspan fill=\"var(--paper)\" textLength=\"672.00\" lengthAdjust=\"spacingAndGlyphs\">log_file /var/log/app.log                                                                       </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">:set number                                                                       1,1           All </tspan></text></g></svg>"}
```

| | |
|---|---|
| `:set number` | on |
| `:set nonumber` | off |
| `:set number!` | toggle |
| `:set number?` | what is it now |

**Two you will need in a hurry:**

`:set paste` before pasting into insert mode. Without it, vim applies
auto-indent to each pasted line and the text arrives shaped like a staircase.
`:set nopaste` afterwards. (Terminals that support bracketed paste make this
unnecessary, and plenty do not.)

`:set list` shows tabs as `^I` and line ends as `$` — `cat -A` from lesson 8
section 05, inside the editor, and the way to see why a `Makefile` is not working.

## Two things that are not configuration

**`vimtutor`** is a program, it is installed alongside vim, and it is thirty
minutes:

```
ana@vm:~$ which vimtutor || echo 'vimtutor: not installed'
/usr/bin/vimtutor
```

It opens a copy of a lesson file that you edit as you read it. If you are going
to use vim at all, it is the best half hour available.

**`:help`** is the manual and it is genuinely good:

```vim
:help                 " the front page
:help dw              " what dw does
:help 'expandtab'     " an option — note the quotes
:help :set            " a command — note the colon
:help i_CTRL-w        " a key in insert mode
```

The quotes and colons are not decoration: they are how vim knows whether you
mean the option, the command or the key.

## The plugin question

Modern vim (8 and later) has a package system built in, and there are plugin
managers on top of it. All of that is real and useful and belongs to somebody
who has decided vim is their editor.

**For this lesson it is out of scope**, and there is a practical argument for
keeping it that way: the machines where you need vim most are the ones where your
configuration is not. A vim you can only drive with your plugins is not a vim you
can use on a rescue image.

Learn the plain one first. It is the same program everywhere.
