---
title: Who draws the screen, three ways
version: 1
---

**Every tool in this lesson answers lesson 1's question in its own way: who draws the screen?** There
are three possible answers, and each tool sits at one of them. Knowing which tells you most of what to
expect from it before reading a line of its documentation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l10-who-draws\" aria-label=\"Three answers to who draws the screen, from left to right. A WebView: Capacitor and Ionic, and on the desktop Electron and Tauri; it reuses the whole web app. The platform's own views: React Native and NativeScript; they reuse the rules, in TypeScript. Its own engine: Flutter paints every pixel itself; it reuses nothing of a web app. The further right, the less of the web app comes along.\"><defs><marker id=\"l10-who-draws-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"125\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a WebView</text><rect x=\"20\" y=\"40\" width=\"210\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Capacitor, Ionic</text><text x=\"125.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Electron, Tauri</text><rect x=\"20\" y=\"120\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"125.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole web app</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the platform's views</text><rect x=\"255\" y=\"40\" width=\"210\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">React Native</text><text x=\"360.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NativeScript</text><rect x=\"255\" y=\"120\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rules, in TypeScript</text><text x=\"595\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">its own engine</text><rect x=\"490\" y=\"40\" width=\"210\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Flutter</text><rect x=\"490\" y=\"120\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"595.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing of the web app</text><path d=\"M20 186 L700 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-who-draws-ah-paper-dim)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">less of the web app comes along</text></svg>", "caption": "The question from lesson 1, answered three ways. Each step to the right reuses less, and has to buy something for it."}
```

| tool | who draws | the language | what of the planner it reuses |
|---|---|---|---|
| Capacitor, Ionic | a WebView | HTML, CSS, TypeScript | everything |
| React Native | the platform's own views | TypeScript, with React | the rules, `planner.ts` |
| NativeScript | the platform's own views | TypeScript, with any of several frameworks | the rules |
| **Flutter** | **its own engine**, pixel by pixel | Dart | nothing; the rules are rewritten |

**Flutter is the one that is different in kind.** It does not ask the platform for a button or a list:
it paints every pixel itself, with an engine called Impeller on phones, into one surface the platform
gives it, the way a game does. That is why a Flutter app looks the same on every system, and why it
has to do itself everything the platform would otherwise give for free, accessibility included. The
next section shows what that means with the planner.

**Ionic is not a fourth way at all.** It is a set of components that look and behave like phone
controls, written for the web, and it runs in the same WebView as everything else Capacitor wraps,
which is why it shares its row. The two come from the same company, and Ionic's own apps are
Capacitor apps.
