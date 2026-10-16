---
title: Installing Appium into the project
version: 1
---

**Appium is an npm package, and it goes into the boxoffice project like Newman did in lesson 6.**
The version is then written in `package.json`, and a teammate's `npm ci` gets the same one. Most
guides install it globally with `npm install -g appium`. That works, and leaves the version in a
command somebody typed once, which is the habit lesson 6 talked you out of. The client library,
WebdriverIO, goes in beside it. In `~/boxoffice`:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact appium@3.8.0 webdriverio@9.32.0
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated whatwg-encoding@3.1.1: Use @exodus/bytes instead for a more spec-conformant and faster implementation
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.

added 583 packages, and audited 584 packages in 23s

122 packages are looking for funding
  run `npm fund` for details

35 vulnerabilities (8 moderate, 20 high, 7 critical)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

`--save-exact` pins both, as it pinned Newman: Appium 3.8.0 and WebdriverIO 9.32.0. **The 35
vulnerabilities are npm's audit of the whole tree**, Newman's 19 of lesson 6 included. Lesson 6's
reasoning holds for the new ones. These are tools that run on your machine against servers you
started, never code that reaches a user. So the versions stay pinned, and the report is read again
when a new release comes out. `npx` finds the program inside the project:

```
ana@laptop:~/boxoffice$ npx appium --version
3.8.0
```

## The Android driver

Appium arrives with no drivers at all. **Each driver is a package of its own, installed through
Appium.** Appium records it in the same `package.json`, because it noticed it is installed in a
project rather than globally. The command prints a line for every step as it goes. The last three
are the result, so keep those:

```
ana@laptop:~/boxoffice$ npx appium driver install uiautomator2@8.7.0 2>&1 | tail -3
i Driver uiautomator2@8.7.0 successfully installed
- automationName: UiAutomator2
- platformNames: ["Android"]
```

They say what the driver answers to: sessions that ask for `automationName` `UiAutomator2` on
`platformName` `Android`. The `i` in front is Appium's mark for information.

## Asking whether the computer is ready

Each driver carries a **doctor**, a list of checks for what it needs on the computer. Run it before
anything else, because what it finds would otherwise arrive as a failed session much later. It
prints one line per check, with a tick or a cross in front. Then come a summary and a line of
advice, and `grep` keeps those two here:

```
ana@laptop:~/boxoffice$ npx appium driver doctor uiautomator2 2>&1 | grep -E 'fixes needed|Bye'
info Doctor ### Diagnostic completed, 2 required fixes needed, 2 optional fixes possible. ###
info Doctor Bye! Run doctor again when all manual fixes have been applied!
```

**2 required fixes** and 2 optional ones. The checks, as the doctor printed them on the recording
machine, `npx appium driver doctor uiautomator2` with nothing after it:

| the doctor's line | result |
|---|---|
| `ANDROID_HOME is set to: /home/ana/Android/Sdk` | passed |
| `adb, emulator exist in '/home/ana/Android/Sdk'` | passed |
| `JAVA_HOME environment variable is NOT set!` | **failed, required** |
| `$JAVA_HOME environment variable must be set` | **failed, required** |
| `bundletool.jar cannot be found` | failed, optional |
| `ffmpeg exists at '/usr/bin/ffmpeg'` | passed |
| `gst-launch-1.0 and/or gst-inspect-1.0 cannot be found` | failed, optional |

The two that passed first are what lesson 14 set up: `ANDROID_HOME`, and `adb` and `emulator`
inside it. Below the checks the doctor prints a paragraph per failure saying what to do, and its
last line is `Error: × Treatment required`.

**The required fix is `JAVA_HOME`**, reported twice. The driver runs Java tools from the SDK to
check and sign the packages it installs on the device, so it needs to know where a JDK is. Lesson 7
installed one; tell the terminal where. On Ubuntu, add this line to `~/.bashrc` and open a new
terminal:

```sh
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

If you skipped lesson 7, Android Studio carries a JDK of its own, in a folder called `jbr` inside
the place it is installed. On a Mac that is `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
On Windows it is `C:\Program Files\Android\Android Studio\jbr`, and it goes in a user variable named
`JAVA_HOME`. Then the doctor again:

```
ana@laptop:~/boxoffice$ npx appium driver doctor uiautomator2 2>&1 | grep -E 'fixes needed|Bye'
info Doctor ### Diagnostic completed, 0 required fixes needed, 2 optional fixes possible. ###
info Doctor Bye! All issues have been fixed!
```

The full output now has `JAVA_HOME is set to: /usr/lib/jvm/java-21-openjdk-amd64` passed, and a
second check that `bin/java` exists under it. **Two warnings remain, and both are optional.** One is
bundletool, for apps shipped as Android App Bundles rather than an APK. The other is GStreamer, for
streaming the device's screen to the computer. Tickets is an APK and nothing in this course
streams a screen, so leave them. `ffmpeg` was found because the recording machine happens to have
it. On yours that line may be a third optional warning, for recording the screen as a video, and
the same answer applies.

## The server

`npx appium` starts the server. Started as it comes, it says where it is listening:

```
ana@laptop:~/boxoffice$ npx appium
[Appium] Appium REST http interface listener started on http://0.0.0.0:4723
	http://127.0.0.1:4723/ (only accessible from the same host)
	http://192.0.2.2:4723/
```

**`0.0.0.0` means every network interface of the computer**, and the second address it lists is
the recording machine's own address on its network. Anybody who can reach that address on port
4723, on the same office or café Wi-Fi, can open a session on your server. They can install an app
on the attached phone, read its screen, take a screenshot. A server that drives devices deserves at
least the care of one that sells tickets. Stop it with Ctrl-C and **start it on the loopback address
only**, in a terminal of its own, in `~/boxoffice`. Leave it running while you work:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1
dbug Appium Creating hash file directory: /home/ana/boxoffice/node_modules/.cache/appium
[Appium] Welcome to Appium v3.8.0
[Appium] Non-default server args:
[Appium] { address: '127.0.0.1' }
[Appium] The autodetected Appium home path: /home/ana/boxoffice
[Appium] Attempting to load driver uiautomator2...
[Appium] Requiring driver at /home/ana/boxoffice/node_modules/appium-uiautomator2-driver/build/lib/index.js
[Appium] AndroidUiautomator2Driver has been successfully loaded in 0.592s
[Appium] Appium REST http interface listener started on http://127.0.0.1:4723
[Appium] Available drivers:
[Appium]   - uiautomator2@8.7.0 (automationName 'UiAutomator2')
[Appium] No plugins have been installed. Use the "appium plugin" command to install the one(s) you want to use.
```

`Non-default server args` repeats the one choice you made. The rest says where Appium keeps its
drivers, in the project it detected, and which drivers it loaded. It listens on `127.0.0.1` now,
which only programs on your own computer can reach. The `dbug` line is Appium's bookkeeping. It
keeps a fingerprint of `package.json` in a cache folder, to notice when the list of drivers changes,
and most Appium commands print one. Ask it, from another terminal,
the question every test asks first:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/status | jq
{
  "value": {
    "ready": true,
    "message": "The server is ready to accept new connections",
    "build": {
      "version": "3.8.0"
    }
  }
}
```

`ready: true` and the version: the server is up and willing to start a session. It does not say a device is attached, and it could not. The server learns which device a session
is for when the session asks.
