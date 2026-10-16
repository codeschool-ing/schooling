---
title: Getting Power BI Desktop, and three ways to have it
version: 1
---

Power BI Desktop is free, and it is a Windows program. Which path you take depends on the computer
you have.

## On a Windows computer — the recommended path

Install it from the **Microsoft Store**: search for *Power BI Desktop*. The Store version updates
itself every month, which matters for a product that changes this often. Microsoft also offers a
standalone installer from its download centre; it does the same job and does not update itself.

It runs on the Windows computer, while Lantern's database runs inside the virtual machine from
lesson 1. The simplest bridge between the two is a set of files, which the next section exports.

## In a Windows virtual machine, on a Mac or on Linux

There is no Power BI Desktop for macOS or Linux. A Windows virtual machine is the way to run it:
UTM on Apple silicon, VirtualBox elsewhere, with Windows 11 inside. It costs a Windows licence, or
an evaluation copy that expires, and memory: a Windows machine running Power BI wants several
gigabytes of its own on top of the Ubuntu machine from lesson 1, so on a computer with 8 GB the two
will not run comfortably at once. This is the most expensive path in the course.

## Online, in the Power BI service

The service runs in any browser and opens reports others have published. It can also build some
reports from a model that already exists in the service. What it does not replace, at the time of
writing, is Desktop as the place where a model is first built from a database. It needs a work or
school account; a personal e-mail address is not accepted.

## If none of these is open to you

Then this lesson is read rather than done. Nothing later in the course depends on Power BI: lesson
5 continues with Metabase and Streamlit, which run on the machine you already have. The ideas in
this lesson — relationships, filter context, measures that change with the question — reappear in
every BI tool, and the SQL beside each formula is something you can run today.

## When it does not work

- **The Store says the app is not available for your device.** Power BI Desktop runs on 64-bit
  Windows; Windows on ARM computers are handled by Microsoft's own compatibility notes, which change
  between releases.
- **It opens and then closes, or is very slow.** It is memory. Close other programs, or give the
  Windows virtual machine more.
- **Numbers arrive multiplied by a hundred.** That is a locale problem with the files, and the next
  section says how to avoid it.
