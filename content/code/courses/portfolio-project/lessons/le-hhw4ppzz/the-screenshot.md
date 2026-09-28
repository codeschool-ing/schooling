---
title: A screenshot that shows the point
version: 1
---

The README's screenshot is the first evidence a reviewer sees, lesson 16. It is a PNG in the repository,
referenced from the README's eighth line:

```
ana@laptop:~/loanbook$ grep -n 'screenshot' README.md
8:![The list: four items out, one of them overdue](docs/screenshot.png)
ana@laptop:~/loanbook$ python3 -c 'import struct; d = open("docs/screenshot.png", "rb").read(24); print(d[1:4].decode(), *struct.unpack(">II", d[16:24]))'
PNG 1000 876
ana@laptop:~/loanbook$ du -h docs/screenshot.png
68K     docs/screenshot.png
```

A thousand pixels wide, 876 tall, 68 kilobytes. Three decisions went into it.

**It shows the state that proves the point.** Not the empty page, not the form: the seeded week, with one
loan marked overdue. A reviewer who sees *overdue* in bold understands the project's main rule without
reading a word about it. For a project whose point is a refusal, a second screenshot of the refusal's
message would be the next one to add.

**It was taken by a script, not by hand.** Seven lines of Playwright open the page at 1000 pixels, wait for
the rows and save the full page. A script takes the same picture every time, so when the page changes the
screenshot is retaken in seconds rather than left out of date. It ran on the machine that recorded the
course, with the server's clock set to 3 July, the day the README was written, so that the dates in the
picture match the history; `lab.sh` says so beside the image's bytes.

**Its alt text says what it shows**: *the list: four items out, one of them overdue*. That sentence is also
a test of the picture: if you cannot say in one line what a screenshot shows, it is not showing one thing.
