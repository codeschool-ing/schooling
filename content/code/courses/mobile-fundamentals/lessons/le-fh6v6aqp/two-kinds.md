---
title: Two kinds of link, and who is allowed to answer each
version: 1
---

**A deep link is a link that opens a particular screen inside an app, and there are two kinds: one
with the app's own scheme, and an ordinary `https` address the app has proved it owns.** The
first looks like `planner://course/sql`, the second like `https://planner.example.com/course/sql`.
Both can land the student on the same screen. They differ in who is allowed to answer them, and in
what happens when the app is missing.

## A custom scheme: easy, and anybody's

**An app declares a scheme of its own, and the system hands it every link that starts with it.** The
planner says it handles `planner:`, and a tap on `planner://course/sql` in a chat opens the planner.
Nothing has to exist on the web, which is why a custom scheme is the first thing most apps try.

**The catch is that the claim is not checked.** Any app can declare `planner:` too. Apple's documentation
on custom URL schemes says a reverse-DNS name "doesn't prevent other apps from registering the same
scheme and handling the associated links", and recommends universal links instead. Android's
documentation on deep links says a custom scheme can still bring up the *disambiguation dialog*, the
system's "open with" list, when another app registers the same one. Either way, a link the planner
sends may open somebody else's app, and the student is not warned.

**Apple's same page adds the rule this lesson's parser is built on: a link is input from outside.**
It says to validate every parameter, discard malformed links, and limit what a link may do to actions
that put none of the user's data at risk. A link opens a screen. It never deletes a course or sends
anything anywhere, whoever crafted it.

## A verified link: a web address the site vouches for

**A verified link is an ordinary `https` URL, plus a file on that website naming the app allowed to
open it.** On Android these are *App Links*, and on iOS *universal links*. When the app is installed,
the system fetches the file from the domain and checks it against the app; only if they match does a
tap on the address open the app directly. Anyone can claim `planner:`, but only whoever controls
`planner.example.com` can put a file there.

The app's half is a declaration of which domain it means. On Android it is an intent filter in the
manifest, with `autoVerify` asking the system to check the site:

```xml
<!-- AndroidManifest.xml: the planner claims its own website's links -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="http" />
    <data android:scheme="https" />
    <data android:host="planner.example.com" />
</intent-filter>
```

On iOS it is the Associated Domains capability, added in Xcode, which writes one entry per domain
into the app's entitlements in the form `<service>:<domain>`. For universal links the service is
`applinks`, so the planner's entry is `applinks:planner.example.com`. Both fragments follow each
platform's documentation, and **neither was built or run on a device for this course**: there is no
Android SDK and no Mac on the machine it was recorded on. The website's half, the two files, is the
part this lesson does run, in a later section.

| | custom scheme | verified link |
|---|---|---|
| looks like | `planner://course/sql` | `https://planner.example.com/course/sql` |
| who may claim it | any app that declares it | only an app the website's file names |
| app not installed | the link goes nowhere | the browser opens the web page |
| Android's name | a deep link | an App Link, from Android 6 |
| iOS's name | a custom URL scheme | a universal link |

**On Android 12 and later, an unverified web link opens the browser.** Android's documentation on
deep links, as read on 30 October 2026, says a web intent reaches an app only if the app is approved
for that domain, and otherwise resolves to the user's default browser. So an app that declares
`https://planner.example.com` without a valid file on the site does not get its links at all; it gets
the same treatment as an app that never asked.

**Verification is also why the two kinds age differently.** A custom scheme keeps working the same way
for as long as the app is installed. A verified link depends on a file somebody has to keep serving,
on a domain somebody has to keep renewing, and the section on the two files shows what the platforms
check when they fetch it.
