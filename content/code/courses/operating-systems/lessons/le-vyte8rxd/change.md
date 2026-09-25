---
title: Changing: adding, overwriting, copying, moving
version: 1
---

## `>` and `>>`

```
ana@server:~/work$ cat todo.txt
call the printer company
ana@server:~/work$ echo "order toner" >> todo.txt
ana@server:~/work$ cat todo.txt
call the printer company
order toner
ana@server:~/work$ echo "renew the domain" > todo.txt
ana@server:~/work$ cat todo.txt
renew the domain
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 96\" role=\"img\" aria-label=\"What the two redirections do to a file that already has a line in it, call the printer company. With two greater-than signs, the new line, order toner, is added at the end, and the file has two lines. With one greater-than sign, the whole file is replaced by the new line, renew the domain, and the old contents are gone without a question.\"><defs><marker id=\"rd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todo.txt before</text><rect x=\"20\" y=\"28\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">call the printer company</text><text x=\"260\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">&gt;&gt;</text><text x=\"284\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">appends</text><rect x=\"260\" y=\"28\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">call the printer company</text><text x=\"270\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">order toner</text><text x=\"500\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">&gt;</text><text x=\"516\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">replaces</text><rect x=\"500\" y=\"28\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">renew the domain</text></svg>", "caption": "One character apart, and one of them destroys the file's contents without asking. When in doubt, use >>."}
```

**`>>` added a line; `>` replaced the whole file.** Both are silent, and the second destroyed `call the
printer company` and `order toner` without asking. It is the most common way to lose a file's contents
on the command line, usually by pressing `>` once where `>>` was meant.

To change a line in the middle of a file, use an editor. **`nano`** is the simple one on most Linux
systems, with its commands listed at the bottom of the screen; the linux-terminal course covers Vim.

## Copy, move, rename

```
ana@server:~/work$ cp clients.csv clients-backup.csv
ana@server:~/work$ mv todo.txt notes-todo.txt
ana@server:~/work$ mv clients-backup.csv invoices/
ana@server:~/work$ cp -r reports reports-copy
ana@server:~/work$ ls -F . invoices
.:
backup.log  clients.csv  invoices/  notes-todo.txt  notes.txt  reports/  reports-copy/

invoices:
clients-backup.csv
```

- **`cp`** copies, and **`cp -r`** copies a folder with everything inside it.
- **`mv`** moves, and **moving within a folder is renaming**: there is no separate rename command.
  `mv todo.txt notes-todo.txt` renamed; `mv clients-backup.csv invoices/` moved.
- The trailing `/` on `invoices/` is a habit worth having. If `invoices` did not exist, `mv` would
  refuse instead of quietly renaming the file to `invoices`.

**`cp` and `mv` overwrite an existing file of the same name without asking.** `-i` makes them ask, and
`-n` makes them refuse.
