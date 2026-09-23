---
title: It works on my machine
version: 1
---

Ticket #34 asks for the menu to show which items contain allergens. Ana adds a picture to the page and
opens it in her browser. The picture appears. Here is what she typed on the way:

```
ana@vm:~/site$ git status --short
 M menu.html
?? images/
ana@vm:~/site$ git commit -qam 'Show allergens on the menu' -m 'Refs #34'
ana@vm:~/site$ ./check-links.sh && echo all links found
all links found
ana@vm:~/site$ git push -q -u origin 34-allergens
```

Two lines of `git status` and she read only the first. `?? images/` means **untracked**: Git has never been
told about that folder, so `commit -a` left it out. Her own check passes, because on her disk the picture
exists. The branch goes up without it.

## A machine that is not yours

The quickest way to see what everybody else will get is to **clone the branch into a fresh directory**, as if
you were a new colleague on their first day:

```
ana@vm:~/site$ git clone -q --branch 34-allergens ~/remotes/site.git /tmp/fresh
ana@vm:~/site$ cd /tmp/fresh
ana@vm:/tmp/fresh$ ls
check-links.sh	index.html  menu.html  style.css
ana@vm:/tmp/fresh$ ./check-links.sh && echo all links found
missing: images/allergens.png
```

The picture is not there, and the same check that passed a minute ago now fails. Nothing about the code
changed; only the machine did. The fix is two commands, and `git status` coming back empty is the sign that
nothing is left behind:

```
ana@vm:~/site$ git status --short
?? images/
ana@vm:~/site$ git add images/allergens.png
ana@vm:~/site$ git commit -qm 'Add the allergens picture' -m 'Refs #34'
ana@vm:~/site$ git status --short
```

## The usual suspects

A file that was never added is the most common form, and there are others, all with the same shape
(something true on the author's machine and nowhere else):

- **A setting or a secret** in a local file, or in an environment variable, that the code quietly depends on.
  Lesson 10 kept secrets out of the repository on purpose, which is exactly why the code must say it needs one.
- **A different version** of a language, a library or a tool. The code relies on a feature that arrived in
  version 3.12, and the server runs 3.10.
- **Data only the author has**: a test account, a row in their local database, a file in their Downloads.
- **Case in file names.** On Windows and macOS `Menu.html` and `menu.html` are usually the same file; on the
  Linux server that runs the site, they are two, and the link breaks.

## Who pays

When "it works on my machine" reaches the team, **the cost moves from the author to somebody else**, and
grows on the way. Bruno spends twenty minutes finding out the picture was never pushed. If nobody had
opened the branch, Diego would have found it testing, or a customer would have found it on the site. Ana
would have saved all of it with one `git status` read to the end.
