---
title: What a screen reader does
version: 1
---

**A screen reader turns the page into speech or braille, one element at a time.** It does not read the
pixels. It reads a structure the browser builds beside the page, the **accessibility tree**, in which each
element that matters has a **role** (*link*, *button*, *heading*), a **name** (*Done*, *JavaScript*) and,
where it has one, a **state** (*checked*, *expanded*, *level 1*). A button that says *Done* on the screen
and has no name in the tree is, to a screen reader user, a button that says nothing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l12-tree\" aria-label=\"Two columns. On the left, the top of the planner's course page as it is drawn: an arrow, the heading JavaScript, a session row with a Done button. On the right, the same elements as the accessibility tree describes them, each as a role, a name and a state: a link named with the arrow, a heading named JavaScript at level 1, a list item holding the text 2026-10-22 · 30 min and a button named Done. Arrows join each drawn element to its line in the tree. A note says that a screen reader reads only the right-hand column.\"><defs><marker id=\"l12-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">what is drawn</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">what the tree says</text><rect x=\"30\" y=\"34\" width=\"240\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">←</text><text x=\"50\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">JavaScript</text><text x=\"50\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2026-10-22 · 30 min</text><rect x=\"185\" y=\"146\" width=\"56\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Done</text><text x=\"390\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">role</text><text x=\"500\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">name</text><text x=\"610\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">state</text><rect x=\"380\" y=\"48\" width=\"320\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">link</text><text x=\"500\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"←\"</text><text x=\"610\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"></text><rect x=\"380\" y=\"92\" width=\"320\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">heading</text><text x=\"500\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"JavaScript\"</text><text x=\"610\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">level 1</text><rect x=\"380\" y=\"144\" width=\"320\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button</text><text x=\"500\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Done\"</text><text x=\"610\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"></text><path d=\"M278 62 L372 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-tree-ah-paper-dim)\"></path><path d=\"M278 106 L372 106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-tree-ah-paper-dim)\"></path><path d=\"M278 158 L372 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-tree-ah-paper-dim)\"></path><text x=\"540\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">a screen reader reads only this column</text></svg>", "caption": "The page and its accessibility tree. The tree is built by the browser from the HTML, and it is all a screen reader has: here it names the back link with a symbol."}
```

There is one for every system, and most people who use one use the one their system ships with or the free
one for it:

| system | screen reader | turned on with |
|---|---|---|
| Windows | **NVDA**, free and open source; JAWS, paid; Narrator, built in | NVDA: Ctrl+Alt+N once installed; Narrator: Ctrl+Win+Enter |
| macOS | **VoiceOver**, built in | Cmd+F5 |
| Linux | **Orca**, built in to GNOME | Super+Alt+S |
| iOS, Android | VoiceOver; TalkBack | in the system's accessibility settings |

## How people move through a page

Hardly anybody listens to a page from the top. A screen reader user **skims**, the way a sighted person's
eye does, and the reader gives them ways to jump by role:

- **by heading**, with H in NVDA's browse mode, or VoiceOver's rotor (Ctrl+Option+U), which lists the
  headings, the links and the landmarks of the page, each in its own list;
- **by landmark**, to the main content, the navigation, the footer;
- **by control**, through a list of every link or every form field on the page;
- and **by Tab**, through what takes the focus, exactly as lesson 11 walked it.

Each of those lists is built from the tree. A page with no headings has nothing in the headings list; a
page whose links all say *click here* has a links list of identical lines. **That is why the tree is the
thing to test**, and the next section prints the planner's.

## Two modes

A screen reader on a page has two modes. In **browse mode** the keys move through the content and a single
letter jumps: H to the next heading, K to the next link in NVDA. In **focus mode** the keys go to the
control, so that typing in a field types. It switches between them by itself as the focus enters
and leaves a field. That is why a custom control that never tells the reader what it is can leave somebody
typing H and getting a heading instead of a letter.
