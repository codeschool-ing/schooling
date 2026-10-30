---
title: Running it without a screen
version: 1
---

**Every transcript in this lesson started with `xvfb-run -a`**, because the computer it was recorded on
has no screen. **Xvfb** is an X server, the program that draws windows on Linux, that keeps its display
in memory instead of on a monitor. A window opened on it is drawn, takes clicks from Playwright, and is
never seen. `xvfb-run` starts one, runs the command with the `DISPLAY` variable pointing at it, and stops
it afterwards; `-a` picks a free display number.

```sh
sudo apt install xvfb xauth
xvfb-run -a node desk.mjs
```

On a desktop you do not need it: `node desk.mjs` and `npm start` use the display you are looking at. **In
continuous integration you do**, and that is the reason this section exists: a GitHub Actions runner or
any build server has no screen either, and a test of an Electron app there runs exactly as these
transcripts did. Windows and macOS runners have a display of their own and need nothing.

Two things about it are worth knowing before the first failure:

- **Without a display, Electron stops at once**, with an error saying it could not open one. That message
  is the sign to wrap the command in `xvfb-run`.
- **A desktop Linux has a session bus**, D-Bus, that Electron and Chromium talk to for notifications,
  power and accessibility, and a bare server does not. Chromium prints errors about it and carries on;
  this course's machine runs one, as a desktop would, so the transcripts are free of them.

What `xvfb-run` cannot give is the look of the real thing: the window manager's title bar, the system's
fonts and its scaling. **A desktop app is checked on a desktop**, of each system it ships to, before a
release; Xvfb is for the checks that a machine can repeat.
