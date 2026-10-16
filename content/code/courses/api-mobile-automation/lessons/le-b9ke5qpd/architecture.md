---
title: Four programs between a test and a tap
version: 1
---

**Appium is a server that turns HTTP requests into taps on a phone.** Your test never touches the
device. It sends a request such as *find the element whose id is `refresh`* to the Appium server
on your computer. The server hands it to a **driver** that knows one platform, and the driver makes
the device do it. The answer comes back the same way, as JSON.

The common picture is of Appium as one program that "controls the phone". It is four, and a
failure can come from any of them. It pays to know which one you are looking at:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 278\" role=\"img\" aria-label=\"Four pieces between a test and the app. On your computer, the client, WebdriverIO or curl, sends HTTP requests to the Appium server on localhost port 4723. Inside the server, a driver for the platform, UiAutomator2 for Android or XCUITest for iOS, reaches the device through adb. On the device, the driver's own app acts on Tickets, the app under test.\"><defs><marker id=\"f15layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"455\" height=\"210\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"247\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">your computer</text><rect x=\"505\" y=\"30\" width=\"175\" height=\"210\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"592\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the device</text><rect x=\"35\" y=\"100\" width=\"135\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"102.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the client</text><text x=\"102.5\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WebdriverIO, curl</text><rect x=\"215\" y=\"66\" width=\"245\" height=\"160\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"337\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the Appium server</text><text x=\"337\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">localhost:4723</text><rect x=\"235\" y=\"120\" width=\"205\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"337.5\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the driver</text><text x=\"337.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">UiAutomator2</text><text x=\"337\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">XCUITest on iOS</text><rect x=\"520\" y=\"100\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">device side</text><text x=\"592.5\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the driver's app</text><rect x=\"520\" y=\"172\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"592.5\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the app under test</text><line x1=\"170\" y1=\"125\" x2=\"233\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f15layers-ah)\"></line><text x=\"201.5\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">HTTP</text><line x1=\"440\" y1=\"135\" x2=\"518\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f15layers-ah)\"></line><text x=\"479\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">adb</text><line x1=\"592\" y1=\"150\" x2=\"592\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f15layers-ah)\"></line><text x=\"350\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one protocol from the client to the server; a driver per platform behind it</text></svg>", "caption": "A test speaks HTTP to the server; the driver inside it speaks to the device through adb, and the driver's app on the device does the tapping."}
```

| piece | what it is | where it runs |
|---|---|---|
| **the client** | a library in your test's language: WebdriverIO for JavaScript in this lesson, or Appium's Java, Python and .NET clients; or curl, in section 04 | your computer, in the test's process |
| **the Appium server** | a Node program, `appium`, listening on port 4723 | your computer |
| **the driver** | a plug-in of the server for one platform: **UiAutomator2** for Android, **XCUITest** for iOS | your computer, inside the server |
| **the device side** | what the driver installs on the device to act there: a small server app on Android, which uses Google's UiAutomator framework; WebDriverAgent on iOS | the emulator, the phone or the iOS simulator |

The Android driver reaches its device side through adb, the tool lesson 14 installed. That is why Appium needs the Android SDK on the computer where the server runs. It is also why a test
fails with the same message whether the emulator is closed or adb has lost track of it.

## The protocol is the web's

**The requests are W3C WebDriver**, the standard every browser automation tool speaks since the
W3C published it in 2018. A session starts with `POST /session`. An element is found with `POST
/session/{id}/element` and clicked with `POST …/element/{element}/click`. The session ends with
`DELETE /session/{id}`. A web test in `web-automation` sends the same requests to a browser's
driver. Appium answers them for an app instead. It adds the commands a phone needs and a browser
does not, such as sending the app to the background in lesson 21.

So a mobile test is an HTTP client, and everything the first half of this course taught about
reading a request and its answer applies to it. Section 04 holds a session by hand with curl to
show it.

## Capabilities: what the session is for

The body of `POST /session` carries the **capabilities**, a JSON object saying what kind of session
you want. The server picks a driver from two of them and passes the rest to that driver:

| capability | what it says | for Tickets |
|---|---|---|
| `platformName` | the platform, a W3C name | `Android` |
| `appium:automationName` | which driver | `UiAutomator2` |
| `appium:app` | the app to install and open | the path of the APK Android Studio built |
| `appium:udid` | which device, when more than one is attached | an adb serial such as `emulator-5554` |

The `appium:` prefix is the W3C rule for a capability the standard does not define. Every
vendor's extension carries its name, so two tools cannot mean different things by one word.
**Appium refuses an extension capability without the prefix.** On iOS the same test asks for
`platformName: iOS` and `appium:automationName: XCUITest`. The driver changes underneath while the requests stay the same. That is the sense of *one driver
for Android and iOS* in the title of this lesson. It means one protocol and one client for both, with a driver per
platform behind it.

**One promise is not made: that the same test runs on both.** An element's id on Android is a resource id. On iOS it is an accessibility identifier, which the
app's developers set separately. A suite that runs on both platforms needs both apps to agree on
their names. That is a promise between developers and testers like the one lesson 14 described,
kept twice.
