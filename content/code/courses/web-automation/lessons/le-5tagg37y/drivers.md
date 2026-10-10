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
ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js
✖ adding a banana puts one item in the basket (339.211472ms)
ℹ tests 1
ℹ suites 0
ℹ pass 0
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 536.84098

✖ failing tests:

test at selenium/shop.test.js:18:1
✖ adding a banana puts one item in the basket (339.211472ms)
  Error [SessionNotCreatedError]: session not created: This version of ChromeDriver only supports Chrome version 139
  Current browser version is 141.0.7390.37 with binary path /home/ana/bin/google-chrome
      at Object.throwDecodedError (/home/ana/quitanda/node_modules/selenium-webdriver/lib/error.js:523:15)
      at parseHttpResponse (/home/ana/quitanda/node_modules/selenium-webdriver/lib/http.js:527:13)
      at Executor.execute (/home/ana/quitanda/node_modules/selenium-webdriver/lib/http.js:459:28)
      at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {
    remoteStacktrace: '#0 0x55f2353c108a <unknown>\n#1 0x55f234e60a70 <unknown>\n#2 0x55f234ea18f7 <unknown>\n#3 0x55f234ea07e5 <unknown>\n#4 0x55f234e9aad6 <unknown>\n#5 0x55f234e965a7 <unknown>\n#6 0x55f234ee693e <unknown>\n#7 0x55f234ee5f06 <unknown>\n#8 0x55f234ed81b3 <unknown>\n#9 0x55f234ea459b <unknown>\n#10 0x55f234ea5971 <unknown>\n#11 0x55f23538625b <unknown>\n#12 0x55f235389fa9 <unknown>\n#13 0x55f23536d339 <unknown>\n#14 0x55f23538ab58 <unknown>\n#15 0x55f235351c1f <unknown>\n#16 0x55f2353ae118 <unknown>\n#17 0x55f2353ae2f6 <unknown>\n#18 0x55f2353c0066 <unknown>\n#19 0x7f6fb829cb84 <unknown>\n#20 0x7f6fb8329ecc <unknown>\n'
  }
```

Read the first two lines of the error: the driver says which Chrome it supports, which it found,
and where. The fix is a driver of the right version, never a change to the test. The same command
with driver 142, a version ahead of the browser, failed in the same way, saying 142. One version
behind was more forgiving: driver 140 opened Chrome 141, and wrote this in its own log while doing
so:

```
[1791661619.997][WARNING]: This version of ChromeDriver has not been tested with Chrome version 141.
```

**Do not build on that.** *Has not been tested* is the driver telling you it is guessing.

## Selenium Manager

Until Selenium 4.6, keeping drivers in step with browsers was your job, and a test suite would
break on a Tuesday because a browser had updated. **Selenium Manager** does it now: `build()`
calls it before anything else, and it answers with a driver and a browser. You ran it by hand in
section 02 with `--debug`, and its output reads in order:

- it looks on the `PATH` first. `Found chromedriver ... in PATH` is the line that matters in the
  failure above: a forgotten old driver on the `PATH` is used even when it does not fit;
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
