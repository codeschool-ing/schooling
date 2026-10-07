---
title: The week this course reads, made on your machine
version: 1
---

A history is only interesting to read once it has some length, and two people in it. From here
on, most lessons start from the same one: a week of work on the bakery's site, nine commits by Ana
and Bruno. You cannot make Bruno's commits by working alone, so a short program makes the whole
week for you. Here it is, all of it:

```bash
#!/usr/bin/env bash
# make-site.sh: the bakery's site after a week of work by Ana and Bruno.
# Every date and every name is written down here, so the commits come out
# with the same ids as the ones this course prints.
set -e
if [ -e ~/site ]; then
  echo "~/site already exists. Move it aside or delete it, then run this again." >&2
  exit 1
fi
mkdir ~/site && cd ~/site && git init -q -b main

# commit WHEN NAME EMAIL MESSAGE: stage every change and commit it as NAME, at WHEN
commit() {
  git add -A
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" \
  GIT_AUTHOR_NAME="$2" GIT_COMMITTER_NAME="$2" \
  GIT_AUTHOR_EMAIL="$3" GIT_COMMITTER_EMAIL="$3" \
    git commit -q -m "$4"
}
ana()   { commit "$1" 'Ana Souza' ana@example.com "$2"; }
bruno() { commit "$1" 'Bruno Lima' bruno@example.com "$2"; }

printf '<h1>Padaria Sol</h1>\n<p>Bread from six in the morning.</p>\n' > index.html
ana 2026-09-14T09:05:00-03:00 'Add the home page'
printf 'h1 { color: darkorange; }\n' > style.css
ana 2026-09-14T10:20:00-03:00 'Give the heading its colour'
printf '<h1>Menu</h1>\n<p>French bread, 0.80</p>\n' > menu.html
ana 2026-09-14T14:10:00-03:00 'Add the menu'
printf '<p>Rye bread, 1.20</p>\n' >> menu.html
bruno 2026-09-15T11:02:00-03:00 'Add rye bread to the menu'
sed -i 's/six in the morning/half past five/' index.html
ana 2026-09-16T09:40:00-03:00 'Open at half past five'
sed -i 's/0.80/0.90/; s/1.20/1.35/' menu.html
bruno 2026-09-16T16:25:00-03:00 'Put the prices up for September'
printf '<p>Cheese roll, 2.50</p>\n' >> menu.html
ana 2026-09-17T10:15:00-03:00 'Add cheese rolls'
sed -i '/Rye bread/d' menu.html
bruno 2026-09-18T08:50:00-03:00 'Take rye bread off until the flour arrives'
printf '<p><a href="menu.html">See the menu</a></p>\n' >> index.html
ana 2026-09-18T15:30:00-03:00 'Link the menu from the home page'
```

Three commands in it are new, and each stands for something you would do in an editor.
`printf '…' > file` writes a file with exactly those lines, `\n` being the end of a line, and `>>`
adds them to the end of the file instead. `sed -i 's/old/new/' file` replaces `old` with `new` inside
the file, and `sed -i '/Rye bread/d'` deletes the line that mentions rye bread. The rest is Git you
know from lesson 2, with one addition: the `GIT_AUTHOR_…` and `GIT_COMMITTER_…` variables, which tell
Git who made a commit and when, overriding your settings for that one command.

## Making the week

Open an empty file in nano with `nano ~/make-site.sh`, paste the program into it, then save with
Ctrl+O and Enter and leave with Ctrl+X. Lesson 2 left a `~/site` of your own, and the program
refuses to overwrite it, so move that one aside first:

```
ana@vm:~$ mv site site-lesson-2
ana@vm:~$ bash make-site.sh
ana@vm:~$ cd site
ana@vm:~/site$ git log --oneline -3
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
31a6298 Add cheese rolls
```

**Your ids should be these ids.** Lesson 1 said an id is computed from everything a commit holds,
and every part of these commits is written down in the program: the files, the names, the dates and
the messages. So `6555c9b` on this page is `6555c9b` on your machine, and every transcript in this
lesson will match yours character for character.

That stops being true at the first commit you make yourself. Your commit carries your name and the
moment you made it, so its id is yours alone, and so is the id of everything after it. When the
lessons ahead show an id you do not have, find the commit by its message instead.

## Starting again

Several lessons change this history, and some of them on purpose break it. To get the week back
exactly as it was, delete the folder and run the program again:

```
ana@vm:~$ rm -rf ~/site && bash ~/make-site.sh
```

`rm -rf` deletes without asking, which is right for a practice copy you can rebuild in a second and
wrong for anything else. Lessons 4 to 17 say at the start when they want a fresh week.
