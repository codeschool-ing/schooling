---
title: Drivers, versions and Selenium Manager
version: 1
---

**There is no Selenium driver.** There is one driver per browser, written by the people who make
that browser, and Selenium's part is to speak the standard to whichever one you name. The driver
is where the knowledge of a particular browser lives, which is why its maker writes it:

| browser | driver | written by | where it comes from |
|---|---|---|---|
| Chrome | `chromedriver` | Google, in the Chromium project | Chrome for Testing downloads, one per Chrome version |
| Firefox | `geckodriver` | Mozilla | its releases on GitHub |
| Edge | `msedgedriver` | Microsoft | Microsoft's download page, one per Edge version |
| Safari | `safaridriver` | Apple | already in macOS; `safaridriver --enable` once, as an administrator |

`forBrowser('chrome')` in the test is the only line that chooses. Change it to `'firefox'` and
the same test asks for `geckodriver`, which drives Firefox through Mozilla's own channel. **Firefox
and `geckodriver` are not on the machine these transcripts come from**, so nothing in this lesson
ran against them; Safari needs a Mac and Edge was not installed either.

## The version has to match

A driver is built against the browser's insides, and browsers update themselves. `chromedriver`
and `msedgedriver` are released with each browser version, and the rule their makers give is to
use the driver whose **major version**, the first number, is the browser's. `geckodriver`
supports a range of Firefox versions, which its documentation lists, and `safaridriver` is
updated with Safari, so it cannot fall behind.

**This is the failure you meet on the morning after Chrome updated itself.** Here the test from
the last section runs with an old `chromedriver`, version 139, found first on the `PATH`, against
Chrome 141:

```
%%CAP mismatch%%
```

Read the second line of the error: the driver says which Chrome it supports and which it found,
and where. The fix is a driver of the right version, never a change to the test. The same command
with driver 142, a version ahead of the browser, failed in the same way, saying 142. One version
behind was more forgiving: driver 140 opened Chrome 141, and wrote this in its own log while doing
so:

```
%%CAP warn140%%
```

**Do not build on that.** *Has not been tested* is the driver telling you it is guessing.

## Selenium Manager

Until Selenium 4.6, keeping drivers in step with browsers was your job, and a test suite would
break on a Tuesday because a browser had updated. **Selenium Manager** does it now: `build()`
calls it before anything else, and it answers with a driver and a browser. You ran it by hand in
section 02 with `--debug`, and its output reads in order:

- it looks on the `PATH` first. `Found chromedriver ... in PATH` is the line that matters in the
  failure above: a forgotten old driver on the `PATH` is used even when it does not fit. Its own
  log says so in a warning, *advised to delete the driver in PATH and retry*;
- it asks the browser its version, `--version`, and finds `chrome 141`;
- it looks up which driver fits, at the address on the `Discovering versions` line, and downloads
  it into `~/.cache/selenium` if it is not there. Its documentation says it can download a browser
  too, when none is installed.

The two `WARN` lines in that transcript are the machine it ran on having no internet. Yours
fetches the list and, the first time, the driver. One more line is worth knowing about:
`Sending stats to Plausible` means Selenium Manager reports anonymous usage, the browser and
Selenium version, to the Selenium project. `--avoid-stats` turns that off for one run, and its
documentation describes the setting that turns it off for good.

**The answer to a version mismatch is therefore usually to delete something**: the old driver on
the `PATH`, so that Selenium Manager fetches the right one. Lesson 11 meets tools built on the same
drivers, and lesson 17 runs Chrome and Firefox headless.
