---
title: App Store Connect, where the app is a record
version: 1
---

**App Store Connect is the website where an app exists as a record before it exists on the store:
its name, its bundle identifier, its builds, its testers, its listing and its reviews.** The archive
from lesson 21 section 09 is uploaded into it, and nothing reaches TestFlight or the App Store
without passing through it. It needs the paid membership that lesson 21 section 02 priced at 99 US
dollars a year. **Nothing in this lesson was run for the course**: no record was created and no
build was uploaded. It is written from Apple's App Store Connect help, its upcoming-requirements page
and the App Review Guidelines, all read on 30 October 2026, and the dates and numbers below are
theirs on that day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l22-pipeline\" aria-label=\"The path from an archive to the store. The archive is uploaded to App Store Connect and processed. It reaches internal testers at once. The first build for external testers goes to App Review first. When the version is submitted, App Review reads the app and its listing against the guidelines. An approved build is released. A rejected one comes back with a guideline number, for a reply, a fix and a new build, or once for an appeal.\"><defs><marker id=\"l22-pipeline-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l22-pipeline-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l22-pipeline-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">upload</text><text x=\"80\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the archive, lesson 21</text><rect x=\"160\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">processing</text><text x=\"220\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes or longer</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">TestFlight</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">internal at once</text><rect x=\"440\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">App Review</text><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">against the guidelines</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">released</text><text x=\"640\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">at once or on a date</text><path d=\"M140 70 L158 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><path d=\"M280 70 L298 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><path d=\"M420 70 L438 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><path d=\"M560 70 L578 70\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><rect x=\"300\" y=\"150\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">external testers</text><text x=\"360\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">first build reviewed</text><path d=\"M360 100 L360 148\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l22-pipeline-ah-wire)\"></path><rect x=\"440\" y=\"200\" width=\"260\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">rejected: a guideline number</text><text x=\"570\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reply, fix, new build</text><text x=\"570\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">or one appeal</text><path d=\"M500 100 L500 198\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-pipeline-ah-amber)\"></path><path d=\"M440 250 C 120 260, 60 200, 70 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l22-pipeline-ah-paper-dim)\"></path><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a higher build number</text></svg>", "caption": "Every build passes through App Store Connect, and every way back from a rejection is a new build with a higher number."}
```

## The record comes first

Apple's help page *Add a new app* says it in its first line: "Before uploading a build of your app to
App Store Connect, first create an app record". The record takes a platform, a name, a primary
language, the **bundle identifier** registered in lesson 21 and a SKU, an identifier of your own for
your records. Its status starts as *Prepare for Submission*, and the help page warns of the step that
trips people first: the Account Holder has to have signed the latest agreement in the *Business*
section before any app can be added.

**The name is taken per localisation**, and it is the one field that collides with strangers. The
page's own answer, when somebody else holds the name you wanted, is to choose another, or to file a
claim if you hold the trademark.

## The build has to be recent enough

Each upload is checked against Apple's current minimums, and they move every year. On 30 October 2026
the upcoming-requirements page said that since 28 April 2026 "apps uploaded to App Store Connect must
be built with Xcode 26 or later using an SDK for iOS 26", and that since 9 September 2026 iOS apps
"must target iOS 13 or later". The planner targets iOS 17 and lesson 1 wrote it against Xcode 27.1,
so it meets both. **Read that page before every release**: an upload built with last year's Xcode is
refused at the upload, before anybody has looked at the app.

After upload a build is *processed*, which takes from minutes to longer, and then appears under
TestFlight with its version and build number. A build number used before for the same version is
refused, which is lesson 1 section 08's `CFBundleVersion` at work.

## Roles

App Store Connect has roles of its own, separate from the developer account's: an **Account
Holder**, **Admins**, **App Managers** who may create records and submit, **Developers** who may
upload, and roles for finance, marketing and sales. The add-a-new-app page requires "Account Holder,
App Manager, or Admin". A person who writes the code and uploads builds needs no more than Developer,
and **giving everybody Admin is how a contractor ends up able to remove the app**.
