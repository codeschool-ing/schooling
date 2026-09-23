---
title: Large files, and Git LFS
version: 1
---

**Git keeps every version of every file, in every clone.** For text that is cheap: a changed line
costs a few bytes once compressed. For a photograph it is not, because a new version of an image is a
whole new image, and images do not compress:

```
ana@vm:~/site$ du -sh .git
500K	.git
ana@vm:~/site$ du -h photo.jpg
1.0M	photo.jpg
ana@vm:~/site$ du -sh .git
3.6M	.git
```

Three versions of one 1 MB photo, and the repository grew by about three megabytes. Deleting the photo
later would not help, for the same reason a deleted secret stays: every old version is still in the
history. Every person who clones the repository downloads all of them, forever. Hosting services draw a
line too: GitHub warns about files over 50 MB and refuses files over 100 MB.

## Git LFS

**Git LFS**, *Large File Storage*, is an extension that keeps large files out of the history and puts
a small text file in their place. It is installed separately from Git, and then switched on once per
account:

```
ana@vm:~/photos$ git lfs install
Updated Git hooks.
Git LFS initialized.
ana@vm:~/photos$ git lfs track "*.jpg"
Tracking "*.jpg"
ana@vm:~/photos$ cat .gitattributes
*.jpg filter=lfs diff=lfs merge=lfs -text
ana@vm:~/photos$ git add .gitattributes front.jpg
ana@vm:~/photos$ git commit -qm "Add the shop front photo"
ana@vm:~/photos$ git lfs ls-files
9bc1b2a288 * front.jpg
ana@vm:~/photos$ git show HEAD:front.jpg
version https://git-lfs.github.com/spec/v1
oid sha256:9bc1b2a288b26af7257a36277ae3816a7d4f16e89c1e7e77d0a5c48bad62b360
size 1048576
```

`git lfs track "*.jpg"` wrote one line into `.gitattributes`, which is committed with the project so
that everybody's Git treats `.jpg` files the same way. From then on, adding a photo stores it with LFS,
and `git lfs ls-files` lists the files it is managing.

The last command shows what the history actually holds. **Not the photo: a pointer, three lines long**
— the version of the pointer format, the photo's hash, and its size. The megabyte itself went into a
separate store, and on `git push` it goes to the hosting service's LFS storage rather than into the
repository. A clone downloads the pointers with the history and fetches only the versions of the
photos it actually checks out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 234\" role=\"img\" aria-label=\"On the left, the repository that every clone copies: each commit holds, for front.jpg, only a three-line pointer with the version, the hash and the size. On the right, separate LFS storage on the hosting service holds the megabyte of each version. An arrow from the pointer to the stored file is labelled: fetched only for what is checked out.\"><defs><marker id=\"lf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"320\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"180\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the repository — every clone</text><rect x=\"40\" y=\"70\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">front.jpg</text><text x=\"150\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oid sha256:… size 1048576</text><rect x=\"40\" y=\"112\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">front.jpg</text><text x=\"150\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oid sha256:… size 1048576</text><rect x=\"40\" y=\"154\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">front.jpg</text><text x=\"150\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">oid sha256:… size 1048576</text><rect x=\"440\" y=\"30\" width=\"260\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"570\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">LFS storage</text><text x=\"570\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the hosting service</text><rect x=\"470\" y=\"70\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 MB</text><path d=\"M322 87 L466 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><rect x=\"470\" y=\"112\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 MB</text><path d=\"M322 129 L466 129\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><rect x=\"470\" y=\"154\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 MB</text><path d=\"M322 171 L466 171\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"180\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a three-line pointer per version</text><text x=\"570\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the file itself, each version</text><text x=\"393\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fetched only for what</text><text x=\"393\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">is checked out</text></svg>", "caption": "The history carries a few bytes per version. The megabytes stay in one place and travel only when somebody needs them."}
```

## When to use it, and what it costs

Use it for files that are large **and** change: design files, images, audio, datasets, compiled
builds you truly have to keep. Do not use it for everything: a small logo that never changes costs
nothing in plain Git.

Its costs are real. Everybody on the team needs Git LFS installed, or they get the pointers instead of
the files. Hosting services give a free allowance of LFS storage and transfer and charge beyond it.
And moving files that were already committed into LFS rewrites history, with lesson 6's rule attached.
Deciding before the first large file is committed is much cheaper than deciding after.
