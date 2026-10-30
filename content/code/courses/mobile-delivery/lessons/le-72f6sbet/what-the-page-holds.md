---
title: What the store page holds
version: 1
---

**A store listing is a form with fixed boxes, and every box has a limit the store enforces when
you save it.** Writing the listing is less like writing a web page and more like filling in a
customs declaration: what goes where is decided, and the creativity is in what you put inside.
*Read from App Store Connect's reference pages, October 2026, and from Google's Play Console Help
as published in 2025, which the recording machine could not reach; not run.*

| what the person sees | App Store | Google Play |
|---|---|---|
| the name | **name**, 2 to 30 characters | **title**, up to 30 characters |
| the line under it | **subtitle**, up to 30 characters | **short description**, up to 80 characters |
| the long text | **description**, up to 4000 characters, plain text | **full description**, up to 4000 characters |
| hidden words for search | **keywords**, up to 100 **bytes** | none: Google reads the text itself |
| text changed without a release | **promotional text**, up to 170 characters | none |
| what changed in this version | **What's New**, up to 4000 characters | **release notes**, per release |

Two rows deserve a second look. **Apple's keywords are counted in bytes, not characters**, and in
UTF-8 an accented letter is two bytes, so a Portuguese keyword list reaches the limit before an
English one of the same length. And **promotional text is the only text on Apple's page you can
change without submitting a new version**, which makes it the place for "new this term" and not
the description.

## What belongs to the app and what to the version

On the App Store, the name and subtitle belong to the **app** and are changed with a new version;
the description, keywords, screenshots and What's New belong to the **version** being submitted.
On Google Play, the listing is edited on its own, and changes to it go through review like a
release does. In both, **a change to the listing is reviewed**, so a typo fixed on Friday evening
can be live on Monday.

## Localised, field by field

Every one of those boxes exists **per language**. A listing in `en-US` and `pt-BR` is two
complete sets of text, two sets of screenshots, two keyword lists. A language you add and leave
half-filled falls back to the primary language for the missing boxes, which is how a Brazilian
visitor ends up reading a Portuguese name above an English description. Lesson 18 measures what
that costs in installs.

## The same page for the three platforms

A Kotlin app has one page, on Google Play; a Swift app has one, on the App Store. **A React Native
app has two**, one per store, with different limits and different picture sizes, and it is the
same work twice. The next sections keep both stores side by side for that reason.
