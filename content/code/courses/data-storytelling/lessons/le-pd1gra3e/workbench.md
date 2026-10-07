---
title: Your workbench
version: 1
---

This course has no software of its own to install, and the platform gives you no machine. What you need
is small, and **you set it up yourself, on your own computer, now**, because every exercise from here on
asks you to make something: a slide, a summary, a chart with the right title.

## What goes in it

1. **A folder** for the course, called `storytelling` or anything you will find again. Everything you
   make goes in it, one file per lesson.
2. **A spreadsheet**, to recompute any number before you put it on a slide.
3. **A slide tool**, to draw the slides the lessons ask for.
4. **The Faro table**, saved as `faro.csv` in the folder. Copy the block from the previous section with
   the copy button and paste it into a plain-text editor, then save it under that name. Save it as
   plain text with UTF-8 encoding if the editor asks.
5. **An analysis of your own**, which is the real subject of the course from lesson 4 on.

## Three ways to get a spreadsheet and a slide tool

- **Installed, and recommended: LibreOffice.** Free, open source, and the same on Windows, macOS and
  Linux. Download it from libreoffice.org and install it like any program; Calc is the spreadsheet and
  Impress is the slide tool. It costs a few hundred megabytes of disk, works offline, nothing you make
  leaves your computer, and every formula in this course was checked in it.
- **In a virtual machine.** For a computer whose own system you would rather not touch: install
  VirtualBox, create a Linux virtual machine with Ubuntu or Debian, and inside it run
  `sudo apt install libreoffice`. It costs several gigabytes of disk and a share of the computer's memory
  while it runs, which is a lot for a spreadsheet, so take this path only if the first one is closed to
  you.
- **Online: Google Sheets and Google Slides.** Nothing to install, and it runs on a weak computer or a
  Chromebook. It costs your computer nothing, but it needs a Google account and a connection, and your
  files live on Google's servers, which matters when the analysis is your employer's data.

If your company or university already gives you Microsoft 365, Excel and PowerPoint do the same job, and
every formula here has the same name in Excel.

Whichever you pick, the lessons describe what to do rather than which menu to open, because the menus
differ and the ideas do not.

## The first thing to compute

Open `faro.csv` in the spreadsheet. The columns land in A to E, with the header in row 1 and the
twenty-four rows below it. In an empty cell, type the cancellation rate for customers whose first
delivery was late:

```localised
=SUMIFS(E2:E25,C2:C25,"late")/SUMIFS(D2:D25,C2:C25,"late")
```

It adds the cancellations in the rows marked `late`, and divides them by the subscribers in those same
rows. Format the cell as a percentage and it reads **41.5%**. Change `"late"` to `"on time"` in both
places and it reads **17.4%**. Those are the two numbers this whole course is built on, and you have just
computed them rather than taken them on trust, which is a habit lesson 12 makes into a method.

## When it does not work

- **Everything lands in column A.** The spreadsheet guessed the wrong separator. Open the file again and,
  in the import dialog, choose comma as the separator and nothing else. In a Portuguese locale the
  default guess is often a semicolon.
- **The formula is refused.** In a Portuguese locale the function is spelled differently and the
  separator is a semicolon. The lesson's block shows your locale's spelling; type that one.
- **The formula shows as text.** The cell was formatted as text before you typed. Clear the format and
  type it again.
- **Accents look wrong** in a file you made yourself later. Save CSV files as UTF-8.
- **The installer is refused** on a work computer. Use the online path for Faro, and ask IT before you put
  your employer's data anywhere: the analysis of your own may have to stay on the tools they allow.

## Your own analysis

From lesson 4 on, every exercise is done twice: once on Faro, where the answers are known, and once on
an analysis of your own, where they are not. Choose it now.

::: track bi
Use the analysis you built in the BI track: the dashboard and the questions behind it from
`analytics-bi`, or the model you designed in `warehouse-modeling`. Pick one finding from it that somebody
should act on.
:::

::: track data-science
Use a model from the data-science track, the classifier or the regression you trained in
`machine-learning`. Your story is not the model's accuracy; it is what the model lets somebody decide.
:::

::: track *
Use any analysis you have done, at work or for study. If you have none, take a public data set from your
city or your country's statistics office and ask it one question somebody would care about.
:::

Write the question at the top of a file called `my-analysis.txt` in the folder. It will change as the
course goes on, and that is the point.
