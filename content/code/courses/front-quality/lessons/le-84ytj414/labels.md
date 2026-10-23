---
title: A placeholder is not a label
version: 1
---

**A placeholder is grey text inside an empty field, and it disappears the moment somebody types.** It
looks like a label to a person who sees the form once. It fails everybody else:

- **A person who is interrupted** comes back to a field that says `15` and no longer says what the
  15 is. Somebody with a poor short-term memory meets that every time.
- **A person using a screen reader** may hear the placeholder or may not: the HTML specification
  says a placeholder is a hint, not a label, and assistive technology treats it as a last resort.
- **A person with low vision** meets grey text on white, which is exactly the contrast a placeholder
  is designed not to have.

WCAG, the accessibility standard lesson 10 introduces, says it in success criterion 3.3.2: a field
needs a label or instructions, and a visible label is the plain way to give one. **A test that
finds fields by their labels fails until the labels exist**, which is why the rewritten test is red
and why that is the test working.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l03-names\" aria-label=\"Two versions of the planner's Minutes field, each shown as markup on the left and as what the accessibility tree holds on the right. Before: an input with placeholder Minutes and no label; the tree holds a spinbutton whose name is taken from the placeholder as a last resort, and getByLabelText finds nothing. After: the same input inside a label that says Minutes; the tree holds a spinbutton named Minutes, from the label, and both getByLabelText and a screen reader find it.\"><defs><marker id=\"l03-names-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the markup</text><text x=\"450\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the accessibility tree</text><text x=\"640\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">getByLabelText(\"Minutes\")</text><text x=\"14\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">before</text><rect x=\"70\" y=\"40\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">&lt;input name=\"minutes\"</text><text x=\"80\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">  type=\"number\"</text><text x=\"80\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">  placeholder=\"Minutes\"&gt;</text><rect x=\"330\" y=\"40\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">spinbutton</text><text x=\"450.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">name: \"Minutes\", from the placeholder,</text><text x=\"450.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a last resort, and hidden once you type</text><path d=\"M270 85 L330 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><path d=\"M570 85 L595 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><rect x=\"595\" y=\"65\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nothing found</text><text x=\"14\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">after</text><rect x=\"70\" y=\"150\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">&lt;label&gt;Minutes</text><text x=\"80\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">  &lt;input name=\"minutes\"</text><text x=\"80\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">    type=\"number\"&gt;&lt;/label&gt;</text><rect x=\"330\" y=\"150\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">spinbutton</text><text x=\"450.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">name: \"Minutes\", from the label</text><path d=\"M270 195 L330 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><path d=\"M570 195 L595 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><rect x=\"595\" y=\"175\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the field</text></svg>", "caption": "The tree is what a screen reader reads and what the queries ask. A label gives the field a name that stays; a placeholder lends it one until the first key."}
```

## The fix

A `<label>` wrapped around its field is the simplest way to tie the two together: the label's text
becomes the field's name, a click on the text puts the cursor in the field, and a screen reader says
both. In `src/view.ts` the form becomes:

```
ana@dev:~/planner$ git diff src/view.ts
diff --git a/src/view.ts b/src/view.ts
index 2a75128..31c6742 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -36,8 +36,8 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     list.append(item);
   }
   const form = el("form", "", "add");
-  form.innerHTML = `<input name="date" type="date" placeholder="Date">
-    <input name="minutes" type="number" placeholder="Minutes">
+  form.innerHTML = `<label>Date <input name="date" type="date"></label>
+    <label>Minutes <input name="minutes" type="number" min="1" max="600"></label>
     <button>Add session</button>`;
   form.addEventListener("submit", (event) => {
     event.preventDefault();
```

`min` and `max` say the range on the field itself, so the browser's own number input refuses a
value outside it, and the person learns the rule before `addSession` has to refuse it. The
placeholders go: the label says what they said, and it stays there.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  19:53:22
   Duration  1.08s (environment 58%, tests 26%, import 9%, transform 6%)
```

All three pass, and the planner's form now has names that a test, a screen reader and a person with
a half-filled form can all read. **Nothing in the component tests changed to make this pass**; the
page changed to meet them, which is the direction it should always be.

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Label the form fields, and test by role and label"
```
