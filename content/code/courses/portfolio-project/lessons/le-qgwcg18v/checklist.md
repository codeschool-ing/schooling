---
title: A checklist, and what it cannot see
version: 1
---

Some slips are mechanical, and a machine finds them faster than your eyes. One `grep` over the added
lines of the diff catches the usual ones:

```
ana@laptop:~/loanbook$ git diff main... | grep -nE '^\+.*(console\.log|TODO|print\(|debugger)'
9:+  console.log("items", items);
25:+  <!-- TODO: nicer empty state -->
```

The pattern looks only at lines starting with `+`, the ones this branch adds, for `console.log`,
`TODO`, `print(` and `debugger`. Both slips are there, with their line numbers in the diff. Make it a
habit, or a script, or a pre-commit hook: it costs nothing and it is never wrong about what it finds.

Then the checklist a machine cannot run, which is the reason for reading at all:

| question | what it catches |
|---|---|
| Does every name say what the thing is? | `data`, `x2`, `handleStuff` |
| Is there code that is commented out? | an old version kept "just in case"; git already keeps it |
| Does every new path have its error? | a fetch with no failure, lesson 11 |
| Is anything from the user put into the page as HTML? | a borrower's name drawn as markup |
| Is there a secret, a key, a password, an internal address? | lesson 14 |
| Would I understand this in six months? | a clever line with no comment |

Look again at the context around the `console.log`. `list.innerHTML = items.map(row).join("")` builds
the table from strings, and `row` puts the borrower's name into them as typed. A borrower typed as
`<b>Rui</b>` would appear in bold, and anything a person can type into a name would be drawn as
markup on the page of every other teacher. **No grep finds that; the fourth question does.** In
loanbook it was found, and fixed in the accessibility commit, lesson 13, which builds every row with
`textContent`.
