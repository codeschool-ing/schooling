---
title: The planner's data, written down before it is declared
version: 1
---

**A store form is easy to fill in honestly when the answers already exist in a list, and hard when they
have to be remembered.** So the planner keeps one: every kind of data it touches, why it touches it,
the store's word for that reason, the furthest place the data travels, and whether a student could use
the app without giving it. The form's answers are then worked out from the list, not typed into a web
page from memory, and the list lives in the repository beside the code that would have to change for
any of it to change.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-where\" aria-label=\"Data flowing from the app to the three places it can go, and what each means for the store's declaration. Left, the device only: not collected, nothing to declare; the planner's courses, sessions and reminder times stay here. Middle, your own server: collected, declared with its purpose. Right, a third-party SDK's company: collected and shared, declared even though the code is not yours.\"><defs><marker id=\"l13-where-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-where-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"300\" y=\"14\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the app</text><rect x=\"30\" y=\"90\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the device only</text><rect x=\"270\" y=\"90\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">your own server</text><rect x=\"510\" y=\"90\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a third-party</text><text x=\"600.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">SDK's company</text><path d=\"M330 48 L120 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-where-ah-phosphor)\"></path><path d=\"M360 48 L360 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-where-ah-paper-dim)\"></path><path d=\"M390 48 L600 90\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-where-ah-amber)\"></path><text x=\"120\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">not collected</text><text x=\"120\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing to declare</text><text x=\"360\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">collected</text><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">declared, with its purpose</text><text x=\"600\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">collected and shared</text><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">declared, though the</text><text x=\"600\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">code is not yours</text><rect x=\"30\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the planner: courses, sessions,</text><text x=\"120.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">reminder times</text></svg>", "caption": "Where the data goes decides what the form says. The planner keeps everything in the left-hand box."}
```

**Where the data goes is the column that decides almost everything.** Data that stays on the device is
not collected, in Apple's definition, however much of it there is. Data that reaches your own server
is collected. Data that reaches another company, including the company behind an SDK inside your app,
is collected and shared. The figure is the planner's choice drawn out: everything it holds sits in the
left-hand box.

## The inventory, and the program that reads it

Save this as `inventory.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "inventory.ts", "parts": [{"code": "// inventory.ts: every kind of data the planner touches, and where each one goes\nexport type Goes = \"device\" | \"our server\" | \"third party\";\nexport type Purpose = \"App Functionality\" | \"Analytics\" | \"Product Personalization\" | \"Third-Party Advertising\";\nexport type Item = {\n  what: string; // the kind of data, as a person would name it\n  why: string; // the reason, in a sentence; an entry without one is refused\n  purpose: Purpose; // the store's word for the reason\n  goes: Goes; // the furthest place it travels\n  optional: boolean; // can the student use the app without giving it?\n};\n", "note": "One entry per kind of data. `purpose` uses four of the names on Apple's list of purposes, and `goes` has the three places of the figure above. `why` is a sentence for a person; `purpose` is the word for the form."}, {"code": "// The check: every entry says why, before anything is declared.\nexport function check(items: Item[]): void {\n  const bare = items.filter((i) => i.why.trim() === \"\").map((i) => i.what);\n  if (bare.length > 0) throw new Error(`no reason given for: ${bare.join(\", \")}`);\n}\n", "note": "The refusal. An entry whose reason is empty, or only spaces, stops everything, and the message names every such entry at once rather than the first."}, {"code": "// The answers a store form asks for, worked out from the inventory. Data that\n// never leaves the device is not collected; data that reaches a third party,\n// an SDK's company included, is collected and shared.\nexport function declare(items: Item[]): string[] {\n  check(items);\n  const away = items.filter((i) => i.goes !== \"device\");\n  if (away.length === 0) return [\"collected: nothing\", \"shared: nothing\"];\n  return away.map((i) => {\n    const shared = i.goes === \"third party\" ? \"shared\" : \"not shared\";\n    const opt = i.optional ? \"optional\" : \"required\";\n    return `collected: ${i.what} (${i.purpose}; ${shared}; ${opt})`;\n  });\n}", "note": "The definitions of the previous section, as code. Only what leaves the device is listed; reaching a third party is what makes it shared. `declare` calls `check` first, so no answer is ever printed from an inventory with a hole in it."}]}
```

A second file holds three inventories. The first is the planner as it is. The second is the same
planner with two SDKs added, a crash reporter and an analytics kit, the way a team adds them on an
ordinary afternoon. The third has an entry somebody added without saying why. Save it as
`declare.ts`:

```typescript
// declare.ts: three inventories, and what each one makes the planner declare
import { declare, type Item } from "./inventory.ts";

const planner: Item[] = [
  { what: "courses", why: "to list what the student is taking", purpose: "App Functionality", goes: "device", optional: false },
  { what: "study sessions", why: "to plan the week and add it up", purpose: "App Functionality", goes: "device", optional: false },
  { what: "reminder times", why: "to remind before a session", purpose: "App Functionality", goes: "device", optional: true },
];

const withSdks: Item[] = [
  ...planner,
  { what: "crash logs", why: "to find and fix crashes", purpose: "App Functionality", goes: "third party", optional: false },
  { what: "screens opened, with a device id", why: "to see which screens are used", purpose: "Analytics", goes: "third party", optional: false },
];

const careless: Item[] = [
  ...planner,
  { what: "contacts", why: "", purpose: "Product Personalization", goes: "our server", optional: true },
];

const inventories: [string, Item[]][] = [
  ["the planner", planner],
  ["with two SDKs", withSdks],
  ["careless", careless],
];

for (const [name, items] of inventories) {
  console.log(`${name}: ${items.length} kinds of data`);
  try {
    for (const line of declare(items)) console.log("  " + line);
  } catch (e) {
    console.log("  refused: " + (e as Error).message);
  }
}
```

Run it:

```
ana@dev:~/planner$ node declare.ts
the planner: 3 kinds of data
  collected: nothing
  shared: nothing
with two SDKs: 5 kinds of data
  collected: crash logs (App Functionality; shared; required)
  collected: screens opened, with a device id (Analytics; shared; required)
careless: 4 kinds of data
  refused: no reason given for: contacts
```

## What the three answers say

**The planner as it is declares nothing, because nothing leaves the phone.** Courses, sessions and
reminder times are all `device`, so the form's answer is that no data is collected and none is shared.
That is not a loophole: it is the definition, and it is the strongest privacy statement an app can
make, because it is the one a person does not have to trust anybody to keep.

**Two SDKs turn three lines of nothing into two lines of collection, both shared.** Neither is the
planner's own code, and both put the planner's name on the answer. The analytics entry carries a
device id, which is the detail that links screens to a device, and that is the kind of data Apple's
form asks about as *linked to the user*. Nothing about the planner's screens changed between the first
inventory and the second. Only the libraries did.

**The careless inventory is refused before anything is declared.** `contacts` has an empty `why`,
and `check` stops the whole declaration rather than printing one with a hole in it. Notice that
`why: ""` is a perfectly good `string` to TypeScript, and that `node` strips the types without
checking them at all, as lesson 1 said. The rule that every entry has a reason is a rule the program
enforces when it runs, because no type can say "a sentence that means something". An entry nobody can
explain is the clearest sign of data not worth collecting, which is the next section's subject.

Commit the two files, so that the inventory changes in the same commits as the code it describes:

```
ana@dev:~/planner$ git add inventory.ts declare.ts
ana@dev:~/planner$ git commit -q -m "The planner's data inventory, and what it declares"
```
