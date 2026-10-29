---
title: Listening to the planner
version: 1
---

**This section has no transcript.** A screen reader speaks, and what it says depends on which reader, which
version, which browser and which settings, so a recording would be true of one machine and read as true of
all of them. What follows is the procedure, and what to listen for in the planner; run it with the reader
your system has.

## Getting started

- **macOS**: Cmd+F5 starts VoiceOver. VO means Ctrl+Option held together; VO+Right Arrow reads the next
  item, VO+U opens the rotor with its lists of headings, links and landmarks, and Cmd+F5 again stops it.
- **Windows**: install NVDA from nvaccess.org and start it with Ctrl+Alt+N. Down Arrow reads the next
  item, H jumps to the next heading, D to the next landmark, Insert+F7 lists the links and headings, and
  Insert+Q quits.
- **Linux, GNOME**: Super+Alt+S starts and stops Orca. Its browse mode uses the same single letters as
  NVDA's, H for a heading among them.

Start it, open the planner, and turn the volume down before the first word.

## What to listen for

1. **On the course list**: the heading is announced as *heading level 1*, the list says how many items it
   has, and each link is read by the course's name alone, with no file name before it. In Safari the list
   may not be announced as one: WebKit drops the list role from a list styled `list-style: none`, as the
   planner's is, on purpose, and `role="list"` on the `ul` gives it back where the count matters.
2. **Jump by landmark**: there is one, *main*, and it holds everything.
3. **Open a course and listen to the first words**: the heading's name, because lesson 11 moved the focus
   there.
4. **Tab to the back link**: *All courses, link*, and no arrow.
5. **Press Done**: the row is read with *done* at its end.
6. **Add a session**: *Session added*, with its date and minutes, read once, and the focus in the date
   field.

Anything that sounds wrong is a finding, even when no test failed. Write it down as the reader said it,
with the reader's name and version: *"NVDA 2025.3, Firefox: the date field is read as 'edit, blank'"*
is a report somebody can act on, and *"the date field sounds odd"* is not.
