---
title: Device clouds, and what renting a phone involves
version: 1
---

**A device cloud is a data centre full of real phones, each on a cable to a computer, rented over
the internet by the minute.** You upload the app, choose devices from a catalogue of makers, models
and versions, and either drive one by hand in a browser window or point an automated suite at it.
Back come the results with a video of the screen, the device's log and screenshots, which is more
than a phone on your desk records on its own.

The names at the time of writing include **Firebase Test Lab**, Google's; **BrowserStack**; **Sauce
Labs**; and **AWS Device Farm**, Amazon's. Most offer iPhones as well as Android phones, which makes
a cloud one of the ways lesson 18 named to test on a real iPhone without owning one, and some
offer emulators and simulators beside the real devices, for less.

## Two ways to use one

- **By hand.** A live session shows a real phone's screen in your browser and sends your clicks to
  it. It is how a tester explores a defect reported from a model nobody on the team owns, the third
  step of lesson 19's list, without buying the phone.
- **Automated.** An Appium session goes to the cloud's server instead of the one on your computer, or
  an Espresso or XCUITest package is uploaded and run there. Section 06 shows both. Several devices
  run at once, each a row of section 04's matrix.

## What it costs

**Every cloud bills by device time, and most also by how many devices may run at the same time.**
The arithmetic is worth doing before choosing a plan: a suite that takes some number of minutes, run
on each of section 04's 12 rows every night, costs twelve times that number in device minutes a
night, and with two devices allowed in parallel it takes six times the suite's length to finish.
Trials, free allowances and prices change often, so none is quoted here; read the vendor's own page
on the day you decide.

What it costs besides money is time and certainty. A cloud phone is slower to reach than an emulator
on your desk: the app is uploaded and installed, every command crosses the internet, and a popular
model can be busy when you ask for it. A failure has more possible causes, too: the app, the phone,
the network between you, or the cloud itself. **The video is what settles it**: watch the run
before filing the defect.

## Your server has to be reachable

The app on a cloud phone asks for boxoffice like any other copy, and **neither `10.0.2.2` nor
`localhost` means your computer from a phone in someone else's building.** There are two answers.
Either the app is built pointing at a test copy of the server that is reachable from the internet,
with test data in it, which is what most teams run their cloud suites against; or the cloud's own
tunnel carries the phone's requests back to your computer. BrowserStack calls its tunnel *Local* and
Sauce Labs calls its own *Sauce Connect*; each is a program you start beside your server.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 288\" role=\"img\" aria-label=\"On your side, the test, a test copy of boxoffice and the cloud's tunnel program. In the cloud's data centre, its Appium server and real phones such as a Galaxy A15, a Moto G24 and a Redmi 13C, plus the video and logs kept for each run. The test sends commands to the cloud's server, which drives a phone; the app on the phone asks boxoffice through the tunnel, back on your side.\"><defs><marker id=\"f20cloud-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"230\" height=\"220\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"135\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">your side</text><rect x=\"40\" y=\"64\" width=\"190\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the test</text><text x=\"135\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">node --test</text><rect x=\"40\" y=\"128\" width=\"190\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><text x=\"135\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a test copy</text><rect x=\"40\" y=\"190\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"135\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the tunnel program</text><text x=\"135\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the cloud's own</text><rect x=\"330\" y=\"30\" width=\"350\" height=\"220\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"505\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the cloud's data centre</text><rect x=\"350\" y=\"64\" width=\"140\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"420\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its server</text><text x=\"420\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Appium, HTTPS</text><rect x=\"520\" y=\"64\" width=\"145\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Galaxy A15</text><text x=\"592.5\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android 14</text><rect x=\"520\" y=\"122\" width=\"145\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Moto G24</text><text x=\"592.5\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android 14</text><rect x=\"520\" y=\"180\" width=\"145\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"592.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Redmi 13C</text><text x=\"592.5\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android 14</text><rect x=\"350\" y=\"128\" width=\"140\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"420\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">video, logs</text><text x=\"420\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">kept for each run</text><line x1=\"230\" y1=\"87\" x2=\"348\" y2=\"87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f20cloud-ah)\"></line><text x=\"289\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">commands</text><line x1=\"490\" y1=\"87\" x2=\"518\" y2=\"87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f20cloud-ah)\"></line><line x1=\"518\" y1=\"212\" x2=\"232\" y2=\"212\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#f20cloud-ah)\"></line><text x=\"430\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the app asks boxoffice through the tunnel</text><line x1=\"135\" y1=\"190\" x2=\"135\" y2=\"176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f20cloud-ah)\"></line><text x=\"350\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10.0.2.2 and localhost mean nothing from a phone in someone else’s building</text></svg>", "caption": "The commands go out to the cloud; the app's own requests have to find their way back to a server it can reach."}
```

Either way, the address the app asks is part of the build: Tickets's `baseUrl` of lesson 14 is one
line, and a cloud build changes it. The test changes too, because lesson 15's test asked boxoffice
for the seats from your computer, and it must ask the same copy of the server the phone does.

## Somebody else's phones

The phone you test on was used by another customer an hour ago and will be used by another after
you. The vendors describe how they clean a device between sessions, and that is their policy to
read, not a guarantee to assume. So:

- **test accounts and test data only**: a real customer's name, card or ticket has no business on a
  rented phone, and in Brazil the LGPD has something to say about putting it there;
- **secrets as environment variables of the run**, never typed into the app on screen and never in
  the test's code, for the reasons lesson 3 gave;
- **the videos and screenshots are stored on the vendor's servers**, so whatever the screen showed is
  now there too.
