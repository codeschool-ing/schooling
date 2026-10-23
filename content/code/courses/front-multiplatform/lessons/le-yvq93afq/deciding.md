---
title: Deciding, and the cost of deciding wrong
version: 1
---

**The decision is not "web or native" for ever. It is which path for this app, now, with these
people.** A wrapper is the right answer far more often than its reputation says, and the wrong answer
in a few cases that are easy to recognise once named.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l06-decide\" aria-label=\"Three questions in order. First: does the core of the app happen outside its screen, in widgets, a watch, background work? If yes, go native or to React Native. If no, second: is the core an interaction the web does badly on a phone, such as long lists all day or heavy gestures? If yes, measure first, and if the ceiling is the platform's, go native or React Native. If no, third: does the app do something its website cannot? If yes, wrap it. If no, the website, perhaps as a Progressive Web App, may be the right answer and no store at all.\"><defs><marker id=\"l06-decide-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"48.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">does the core happen</text><text x=\"115.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">outside the screen?</text><rect x=\"260\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"48.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">is the core what the web</text><text x=\"355.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">does badly on a phone?</text><rect x=\"500\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"48.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">does it do what its</text><text x=\"595.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">website cannot?</text><path d=\"M210 55 L260 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"235\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">no</text><path d=\"M450 55 L500 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"475\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"20\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"188.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">native, or</text><text x=\"115.0\" y=\"201.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">React Native</text><rect x=\"260\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"188.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">measure first:</text><text x=\"355.0\" y=\"201.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">whose ceiling is it?</text><rect x=\"500\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">wrap it</text><rect x=\"500\" y=\"200\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"595.0\" y=\"215.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the website, perhaps</text><text x=\"595.0\" y=\"228.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">as a PWA</text><path d=\"M115 80 L115 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"128\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">yes</text><path d=\"M355 80 L355 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"368\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">yes</text><path d=\"M260 195 L210 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><path d=\"M560 80 L560 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"573\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">yes</text><path d=\"M680 80 L680 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"668\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">no</text></svg>", "caption": "Three questions, in this order. Most apps reach the third, and most of those are right to be wrapped."}
```

## Wrap when

- **the app is mostly screens of information and forms**, which is most apps: lists, details, a
  checkout, a planner;
- **the team is a web team**, and a second codebase in Swift and Kotlin would be maintained by nobody;
- **the web app exists and works**, and the phone adds a few capabilities a plugin covers;
- **time matters more than the last ten per cent of feel**, as it does for a first version.

## Go native, or to React Native, when

- **the core of the app happens outside its screen**: widgets, a watch, background work, deep system
  integration, from the table two sections back;
- **the core is interaction the web does badly on a phone**: long lists scrolled all day, heavy
  gestures, real-time graphics, a camera with processing on every frame;
- **the measurement says the ceiling is the platform's**, after the app's own design has been fixed,
  which is the order the measuring section insists on.

## What being wrong costs, in each direction

**Wrapping an app that needed to be native** costs the review, the ratings, and then a rewrite that
starts late, often with the store listing to keep. The signs show early, in the checklist and the
measurement, which is why they come before the submission.

**Writing native an app that could have been wrapped** costs two codebases from the first day, every
feature written twice and tested twice, and a team that has to know three platforms instead of one.
That cost is quieter and much more common: it does not fail a review, it only makes every week more
expensive.

**React Native is the middle of the two**, and lessons 7 to 9 are about what it buys. It keeps one
language and one team, and gives the platform's own controls back, at the price of rewriting the
screens. For the planner, after this lesson, the honest verdict is that the wrapper is right: nothing
in it happens off the screen except the reminder, which a plugin already handles. The next lessons
build the native version anyway, so that the comparison is made with both in your hands.
