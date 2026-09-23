---
title: Where the history lives, and why Git is not GitHub
version: 1
---

Version control is older than Git by decades, and the systems before it made a choice that Git
reversed. Knowing which choice explains most of what Git feels like to use.

## One server, or every copy

**CVS, from 1990, and Subversion, from 2000, keep the history on a server.** Your machine holds a
working copy: one version of the files, the one you checked out. Everything that touches the
history goes over the network. Reading the log asks the server. Saving a change sends it to the
server, which is where it becomes part of the history. If the server is down, nobody saves
anything. If its disk dies without a backup, the history is gone, and every working copy only has
the one version it happened to be on.

**Git keeps the whole history in every copy.** When you get a project, you get every commit that
was ever made in it, and your machine can answer any question about the history on its own. Saving
a change is local. The network only comes into it when you choose to share, which is lesson 7.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 318\" role=\"img\" aria-label=\"Two arrangements side by side. On the left, a central server holds the whole history and each person holds only one version of the files, so every log and commit is a request to the server. On the right, every machine holds the whole history, including the hosted copy everybody agrees to share, so log and commit happen locally.\"><defs><marker id=\"wh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">central — CVS, Subversion</text><rect x=\"95\" y=\"44\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the server</text><text x=\"180.0\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the whole history</text><rect x=\"20\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">you</text><text x=\"95.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one version of the files</text><rect x=\"190\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a colleague</text><text x=\"265.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one version of the files</text><path d=\"M95 198 L150 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><path d=\"M265 198 L210 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><text x=\"180\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every log and every commit asks the server</text><path d=\"M360 20 L360 296\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">distributed — Git</text><rect x=\"455\" y=\"44\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">GitHub, GitLab…</text><text x=\"540.0\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the whole history</text><text x=\"540\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shared by agreement</text><rect x=\"380\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">you</text><text x=\"455.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the whole history</text><rect x=\"550\" y=\"200\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a colleague</text><text x=\"625.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the whole history</text><path d=\"M455 198 L510 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><path d=\"M625 198 L570 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\" marker-start=\"url(#wh-ah)\"></path><text x=\"540\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">log and commit never leave the machine</text></svg>", "caption": "In a central system the history lives in one place. In Git every copy is complete, and the shared one is shared by agreement rather than by design."}
```

## Delete the original

That claim is easy to test. `git clone` makes a copy of a repository — here, the one from the last
section — and then the original is removed completely:

```
ana@vm:~$ git clone ~/notes ~/copy
Cloning into '/home/ana/copy'...
done.
ana@vm:~$ rm -rf ~/notes
ana@vm:~$ cd ~/copy
ana@vm:~/copy$ git log --oneline
d03056f Name the quarter in the title
3c94cf5 Say by how much the north missed, and add the table it comes from
084e07d Use the corrected sales figure from finance
32507e0 Start the quarterly report
```

**All four commits survived**, with the same ids, because the copy never depended on the original.
It was the history, not a view of it.

Three things follow, and you will lean on each of them.

- You can work with no connection. On a train, on a plane, with the office network down: saving,
  reading the log and comparing versions all work, because nothing needs asking.
- Reading the history is fast. There is no server in the way, so a question like "what did
  this file look like in March" is answered from your own disk.
- Every copy is a backup. A team of five has the history on five machines and on the shared
  server. Losing one of them loses nothing that is not also somewhere else.

## So what is GitHub?

A team still needs somewhere to meet. If everybody's copy is complete, somebody has to decide which
one the others take their changes from, and in practice that is a copy kept on a server that is
always on. **Git does not know that copy is special.** It is a repository like yours, which
everybody has agreed to send their work to and fetch other people's work from. The agreement is the
team's, not the program's.

**GitHub, GitLab and Bitbucket are companies that host that shared copy.** Around it they build
what Git itself does not have: accounts and permissions, a web page for every file, and issues for
tracking work. They also add the pull request, which is how a team proposes and reviews a change
before it joins the shared history. Lesson 8 is about those.

The distinction matters because people say "GitHub" when they mean Git, and then look for Git's
answers in the wrong place. **Git is a program on your machine.** It worked in the capture above
with no account, no website and no network. GitHub is a service that keeps one more copy, and adds a
place for people to talk about it.

Git's own history makes the same point. It was written by Linus Torvalds in 2005, for the
Linux kernel, after the kernel lost free use of the proprietary system it had been kept in. What he
needed was hundreds of developers working in parallel, most of them never talking to one server.
GitHub came three years later, as a business built on top of it.
