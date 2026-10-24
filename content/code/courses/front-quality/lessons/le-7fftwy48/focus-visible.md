---
title: A focus that can be seen
version: 1
---

**Lesson 1's stylesheet has a line that hides where the focus is:**

```css
button:focus { outline: none; }
```

It is one of the commonest lines on the web, and it is written for a good reason applied the wrong way.
A browser used to draw its focus ring around a button whenever it was clicked, people found the ring
ugly after a mouse click, and the quickest way to remove it was to remove it for everyone. The person it
was removed from is the one person who needs it: somebody on a keyboard, who now presses Tab and sees
nothing move. That fails 2.4.7 *Focus Visible*, level AA.

## The test

An outline is a style, so this test asks the browser for the style of the focused element. Add it to
`e2e/keyboard.spec.ts`:

```typescript
// e2e/keyboard.spec.ts, below what is there
test("the focused control can be seen", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await tabThrough(page, 2);
  const done = page.getByRole("button", { name: "Done" });
  await expect(done).toBeFocused();
  const outline = await done.evaluate((e) => {
    const style = getComputedStyle(e);
    return { style: style.outlineStyle, width: parseFloat(style.outlineWidth) };
  });
  expect(outline.style).not.toBe("none");
  expect(outline.width).toBeGreaterThanOrEqual(2);
});
```

The focus arrives by Tab, the way it arrives for the person the test speaks for. The test asks for an
outline that is drawn and at least two pixels wide, which is the thickness 2.4.13 *Focus Appearance*
asks for at AAA; AA only asks that the focus can be seen at all.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts -g 'can be seen' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (370ms)
    Expected: not "none"
  1 failed
```

## The fix: `:focus-visible`

**CSS has a selector for exactly the case the old line was trying to handle.** `:focus-visible` matches a
focused element only when the browser judges that the person needs to see the focus: always after a key
press, and not after a mouse click on a button. A text field matches it however it was reached, because
the person is about to type into it. Replace the line:

```css
:focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }
```

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index ada6bc6..69ba45a 100644
--- a/src/style.css
+++ b/src/style.css
@@ -7,7 +7,7 @@ li { padding: 0.4rem 0; border-bottom: 1px solid #ddd; }
 .mins { color: #555; }
 .session.done { color: #6b6b6b; }
 .tick { font-size: 0.7rem; padding: 1px 4px; }
-button:focus { outline: none; }
+:focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
 @keyframes pulse { 50% { transform: scale(1.06); } }
```

The colour is the planner's link green, at **5.99:1** against white, well past the 3:1 a focus indicator
needs to stand out from what is around it. The offset puts two pixels of white between the button and
the ring, so the ring is seen against the page rather than against the button's own grey.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l11-focus\" aria-label=\"Two drawings of the same Done button with the focus on it. On the left, under the rule button:focus { outline: none; }, the button looks exactly as it does without the focus: nothing shows that Tab arrived. On the right, under :focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }, a green ring three pixels thick surrounds the button with a gap of two pixels between them.\"><defs><marker id=\"l11-focus-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button:focus { outline: none; }</text><rect x=\"145\" y=\"62\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"180\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">Tab arrived, and nothing shows it</text><text x=\"540\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:focus-visible { outline: 3px … }</text><rect x=\"500\" y=\"57\" width=\"80\" height=\"46\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></rect><rect x=\"505\" y=\"62\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"540\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">a 3px ring, 2px away, at 5.99:1</text><path d=\"M350 80 L370 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-focus-ah-paper-dim)\"></path></svg>", "caption": "The same button, focused from the keyboard, under the old rule and the new one. The ring is drawn outside the button, so it is seen against the page."}
```

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (340ms)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (253ms)
  2 passed (4.7s)
```

**How the browser decides.** A key press makes the next focus visible; a mouse click on a button makes it
not. A focus moved by a script inherits the decision from whatever the person did last, which is what the
next two sections rely on: the focus they send somewhere after a key press shows its ring, and after a
click it does not.
