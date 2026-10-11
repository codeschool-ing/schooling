---
title: The screen readers, and how a tester starts one
version: 1
---

A screen reader turns what is on the screen into speech, or into braille on a refreshable
display, and lets its user move through it from the keyboard or by touch. **It does not read the
pixels.** It asks the operating system's accessibility interface, which asks the browser, which
answers from the accessibility tree: a version of the page that holds, for every element that
matters, a role, a name and a state. Everything a screen reader user learns about the booking page
comes through that tree. That is why the next section reads the tree, and why a page can look
perfect and say nothing.

## The readers worth knowing

| reader | where | what it costs | how to start it |
|---|---|---|---|
| **NVDA** | Windows | free, open source, from NV Access | install it from nvaccess.org; `Ctrl+Alt+N` starts it once the installer has set up the shortcut |
| **JAWS** | Windows | commercial, from Freedom Scientific, with a time-limited demo mode | from the Start menu after installing |
| **Narrator** | Windows | built in | `Win+Ctrl+Enter` |
| **VoiceOver** | macOS, iOS, iPadOS | built in | `Cmd+F5` on a Mac; on an iPhone, Settings, Accessibility, VoiceOver |
| **Orca** | Linux, GNOME | free, usually installed with the desktop | `Super+Alt+S` in GNOME |
| **TalkBack** | Android | built in | Settings, Accessibility, TalkBack; or hold both volume keys if the shortcut is on |

**Which ones to test with is a question about users, not about tools.** WebAIM's surveys of screen
reader users have for years found NVDA and JAWS the most used on desktops, and VoiceOver on
phones. The pairings matter as much as the readers: NVDA is usually tested with Firefox or Chrome,
JAWS with Chrome or Edge, VoiceOver with Safari. A combination that works says little about a
different one, because each browser builds its own tree and each reader reads it in its own way.

## The few commands a tester needs

A screen reader user knows hundreds of commands. A tester needs about a dozen, and the same dozen
exist in every desktop reader under different keys. NVDA's are below; the modifier, written
**NVDA**, is `Insert` by default, or `Caps Lock` if you choose the laptop layout.

| to do this | NVDA | VoiceOver on a Mac |
|---|---|---|
| stop speaking | `Ctrl` | `Ctrl` |
| read from here on | `NVDA+Down` | `VO+A` (VO is `Ctrl+Option`) |
| next and previous item | `Down`, `Up` in browse mode | `VO+Right`, `VO+Left` |
| next heading, next form field, next link | `H`, `F`, `K` | the Rotor, `VO+U`, then arrows |
| list of headings or links | `NVDA+F7` | the Rotor, `VO+U` |
| move between controls | `Tab`, as without a reader | `Tab` |
| type into a field | `Enter` on it, which switches to focus mode | interact with `VO+Shift+Down` |
| turn it off | `NVDA+Q` | `Cmd+F5` |

NVDA's **browse mode and focus mode** are the one idea that trips testers up. In browse mode,
letter keys are navigation commands: `H` jumps to the next heading. In focus mode, which NVDA
enters on its own when you reach a text field, letter keys type. A page that steals keystrokes
with its own shortcuts behaves differently in each, which is one more thing to test.

## Where it runs, for this course

**None of this was run for these lessons, and no transcript in them is speech.** The lab the
course was recorded in has no desktop and no sound, so a screen reader cannot run there; on your
own VM it is the same, because the VM has no desktop either. A screen reader runs on **your own
computer**, as lesson 1 said, against the box office in the VM. Start the server so that it
answers other machines:

```sh
cd ~/boxoffice && BOXOFFICE_HOST=0.0.0.0 python3 app.py
```

and open `book.html`, then `book4.html`, at the VM's address in your own browser, as lesson 1
explains. Then start the reader and close your eyes, or turn the screen's brightness down to
nothing; a tester who can see the page fills in from sight whatever the speech leaves out.

What these lessons capture instead is the half that can be captured honestly: what the browser
**tells** the screen reader. The words a particular reader then speaks depend on the reader, its
version, its settings and the browser, and quoting a speech output that nobody recorded would be
inventing one.
