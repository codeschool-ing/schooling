---
title: What the two forms ask
version: 1
---

**Both stores ask the same underlying question, what data leaves the phone and what happens to
it, and both publish your answer on the app's page.** Apple calls the result **privacy details**,
shown as a label of three boxes; Google calls the form **Data safety**. Neither is checked against
the app before it goes live. Both are a declaration you are answerable for, and a false one is a
reason to remove the app. *Read from Apple's App Privacy Details page, October 2026, and from
Google's Play Console Help as published in 2025; not run.*

## What "collect" means

Apple defines it precisely: **data is collected when it is transmitted off the device in a way
that lets you or a third party access it for longer than it takes to serve the request in real
time.** Two consequences follow, and both surprise people:

- Data that never leaves the phone is **not collected**. The planner's sessions, kept only in the
  phone's database, need no declaration.
- Data sent once and thrown away after answering, a search query answered and not logged, is
  **not collected** either. The same query written to a log for a month is.

## Apple's three boxes

| box | what puts data in it |
|---|---|
| **Data Used to Track You** | it is linked with other companies' data for advertising, or shared with a data broker |
| **Data Linked to You** | it is tied to the person's identity, through their account, their device or anything else |
| **Data Not Linked to You** | it is collected, and nothing ties it back to who sent it |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-label\" aria-label=\"Apple's privacy label as three boxes, with the planner's four kinds of data placed in them. Data Used to Track You is empty. Data Linked to You holds the e-mail address and the courses and sessions, because the account ties them to the person. Data Not Linked to You holds the crash reports and the product events, which carry no account. A note says that data which never leaves the phone appears in no box.\"><rect x=\"20\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Data Used to Track You</text><text x=\"120\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">none: nothing is shared with an advertiser</text><rect x=\"260\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Data Linked to You</text><rect x=\"276\" y=\"62\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e-mail address</text><rect x=\"276\" y=\"102\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">courses and sessions</text><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the account ties them to the person</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Data Not Linked to You</text><rect x=\"516\" y=\"62\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">crash reports</text><rect x=\"516\" y=\"102\" width=\"168\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">product events</text><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">no account, a random install id</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">data that never leaves the phone is in no box at all</text></svg>", "caption": "The planner's four kinds of data in Apple's three boxes. What decides the box is whether something ties the data to the person, not how sensitive the data feels."}
```

For each kind of data, Apple also asks the **purposes**: app functionality, analytics, product
personalisation, your own advertising, third-party advertising, other.

## Google's form

Google asks for each kind of data whether it is **collected**, whether it is **shared** with a
third party, for which purposes, whether collecting it is **optional**, and two questions about the
app as a whole: is data **encrypted in transit**, and can people **ask for their data to be
deleted**. It also asks what Apple does not: whether the data is processed **ephemerally**, in
memory only.

## The same answer on three platforms

Nothing in either form depends on the language of the app. A React Native app answers the same
questions for the same data, once in each console. What differs between platforms is where the
data is collected in the code, and section "Code you did not write" is the part people miss.
