---
title: Checking HTML with a validator
version: 1
---

You have now seen the browser repair three kinds of mistake without saying anything. **A validator** is the program that says something: it reads your file against the rules of HTML and lists every place the file breaks them. It does not draw the page, and it does not guess.

This course uses `html-validate`, a validator that runs on your own machine, installed by `lab.sh`. The best-known alternative is the W3C's Nu HTML Checker at `validator.w3.org`, which you can use by pasting a page into a form; the two agree on what HTML is and disagree on some matters of style.

## The broken page, read by a validator

Here is `broken.html` from section 07, the page that looked fine:

```
ana@laptop:~/site$ html-validate -f text broken.html
/home/ana/site/broken.html:2:2: error [close-order] Unclosed element '<html>'
/home/ana/site/broken.html:8:2: error [close-order] Unclosed element '<p>'
/home/ana/site/broken.html:9:2: error [close-order] Unclosed element '<p>'
/home/ana/site/broken.html:9:2: error [element-permitted-content] <p> element is not permitted as content under <b>
/home/ana/site/broken.html:9:15: error [close-order] Unclosed element '<i>'
/home/ana/site/broken.html:9:33: error [close-order] End tag '</b>' seen but there were open elements
/home/ana/site/broken.html:10:2: error [element-permitted-content] <p> element is not permitted as content under <b>
/home/ana/site/broken.html:10:15: error [element-permitted-content] <div> element is not permitted as content under <b>
/home/ana/site/broken.html:11:2: error [close-order] End tag '</body>' seen but there were open elements
```

Each line is a file, a line and column, a rule's name in brackets and what is wrong. It found all three repairs from section 07: the `<p>` elements implicitly inside the `<b>`, the `</b>` met while the `<i>` was still open, and the `<div>` that a `<b>` cannot contain at line 10.

It also reported the unclosed `<p>` elements on lines 8 and 9, and that is a matter of style rather than of the language. **HTML lets you omit `</p>`**: the standard says a paragraph ends when the next block starts, and the browser follows it. This validator's preset reports it anyway, because a page that closes every element is one where the next mistake is easy to see. The course agrees with it, and every page from here on closes its paragraphs.

## The blank page

```
ana@laptop:~/site$ html-validate -f text unclosed-title.html
/home/ana/site/unclosed-title.html:5:8: error [parser-error] failed to tokenize "Opening ho...", expected </title>.
```

One line, at line 5, column 8: the title opened and the closing tag was never found. That is the page whose window was blank, and the validator points at the exact place in two seconds, where looking at the screen would have shown nothing at all.

## The missing doctype

```
ana@laptop:~/site$ html-validate -f text quirks.html
/home/ana/site/quirks.html:1:1: error [missing-doctype] Document is missing doctype
```

The page from section 06 that was 4 pixels shorter. The browser never mentioned quirks mode, and the validator names it on line 1.

## A clean file says nothing

```
ana@laptop:~/site$ html-validate -f text skeleton.html; echo "exit status $?"
exit status 0
```

**No output and an exit status of 0** is a pass, and that is what a command-line tool means by success. It is also what makes a validator useful beyond your own machine: a project can run it on every change and refuse one that fails, so a broken page never reaches anybody. `testing-cicd` is where checks like that are built.

## What a validator cannot tell you

A validator checks the rules of the language. It cannot tell you that a heading is not really a heading, that a page has three `<h1>` elements when it means one, or that a link reads *click here*. Those are questions about meaning, and they are lesson 2. It also says nothing about how the page looks, which is everything from lesson 5 on.
