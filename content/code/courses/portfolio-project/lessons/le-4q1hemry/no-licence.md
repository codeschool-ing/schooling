---
title: What no licence means
version: 1
---

A public repository with no licence file is **not** free for others to use. Under copyright law in most
countries, including Brazil's, the author holds the rights by default, and nobody else may copy, modify
or distribute the work without permission. Hosting sites add a little: GitHub's terms let others view and
fork a public repository on GitHub itself. Nothing more.

For a portfolio this matters less for what strangers may do than for what it signals. A reviewer who
finds no licence sees an author who has not thought about how their work may be used, which is the kind
of question real projects answer on the first day. The fix is one file and one commit:

```
ana@laptop:~/loanbook$ head -3 LICENSE
MIT License

Copyright (c) 2026 Ana Lima
ana@laptop:~/loanbook$ git show --stat --format=%s HEAD
License under MIT

 LICENSE | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)
```

`LICENSE`, at the root, with the full text of a standard licence, the year and the holder's name. GitHub
and GitLab recognise the common licences from that file and show the name on the repository's front page,
so the reader does not have to open it. The README's last section says the same in one line, lesson 16.

Two things never to do. **Do not write your own licence**: a custom text is one nobody can interpret
without a lawyer, including you. And **do not copy a licence from a project and forget to change the
name**: *Copyright (c) someone else* on your project is a claim that it is theirs.
