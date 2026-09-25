---
title: The shortcuts worth knowing on all three
version: 1
---

A few shortcuts save more time in support than any others, because they work on a stranger's
computer without finding anything first.

| to | Windows | macOS | Ubuntu (GNOME) |
|---|---|---|---|
| search and open anything | **Win**, type | **Cmd-Space**, type | **Super**, type |
| switch between apps | **Alt+Tab** | **Cmd-Tab** | **Alt+Tab** |
| lock the screen | **Win+L** | **Ctrl-Cmd-Q** | **Super+L** |
| take a screenshot of an area | **Win+Shift+S** | **Cmd-Shift-4** | **Print Screen** |
| stop a frozen app | **Ctrl+Shift+Esc** | **Cmd-Option-Esc** | System Monitor |
| open the file manager | **Win+E** | Finder in the Dock | **Super**, "Files" |
| type a path in it | **Alt+D** | **Cmd-Shift-G** | **Ctrl+L** |
| show hidden files | *View > Show* | **Cmd-Shift-.** | **Ctrl+H** |
| open settings | **Win+I** | **Cmd-Space**, "Settings" | **Super**, "Settings" |

**Lock the screen every time you leave a desk**, including somebody else's that you are working on. It is
the cheapest security habit there is, and the one people most often skip.

## From a terminal

Each system can also open its file manager or settings from the command line, which is handy when
you are already in one:

```sh
explorer .              # Windows: File Explorer in the current folder
start ms-settings:      # Windows: the Settings app
open .                  # macOS: Finder in the current folder
open -a "System Settings"
xdg-open .              # Linux desktop: the default file manager here
```

**None of these were run for this lesson.** The last line needs a desktop, and lesson 3's server has
none: on a server, `xdg-open` has nothing to open.
