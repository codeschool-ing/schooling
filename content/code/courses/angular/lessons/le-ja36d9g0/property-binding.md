---
title: Property binding, and the attribute that is not a property
version: 1
---

**`[name]="expression"` sets a property of a DOM element to the value of an expression, and keeps it
set as the value changes.** Interpolation can only produce text; a property binding passes the value
itself, a number, a boolean, an object, to the element. Replace the bench's template:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<label for="bench-minutes">Minutes</label>
<input id="bench-minutes" type="number" [value]="minutes" [min]="5" [max]="240" />
<progress [value]="minutes" [max]="240" [aria-label]="minutes + ' of 240 minutes'"></progress>
<button type="button" [disabled]="minutes >= 240">More</button>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- heading "Bench" [level=2]
- LabelText
  - text: Minutes
- spinbutton "Minutes": 45
- progressbar "45 of 240 minutes": 45
- button "More"
```

The accessibility tree shows what each binding did: the field is a spin button holding 45, the
progress bar is named by the expression, and the button is enabled, because `45 >= 240` is false.
`[disabled]` takes a boolean, which a plain HTML attribute cannot: in HTML, `disabled="false"` is
still disabled.

## A property is not an attribute

HTML has **attributes**, written in the markup, and the browser builds DOM objects with
**properties** from them. They usually share a name and a starting value, and then they can go their
own ways. A property binding sets the property, and what happens to the markup depends on the
property:

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-bench><h2>Bench</h2><label for="bench-minutes">Minutes</label><input id="bench-minutes" type="number" min="5" max="240"><progress value="45" max="240" aria-label="45 of 240 minutes"></progress><button type="button">More</button></app-bench>
```

`min`, `max` and the progress bar's `value` appear as attributes: those properties **reflect**, which
means the browser writes their value back into the attribute. The field's `value` does not reflect,
and there is no `value="45"` on the `<input>`, yet the field shows 45. For a text field that
difference is the whole point: the `value` attribute is only the starting text, and the `value`
property is what is in the box now, typed or bound. **Angular binds to the DOM's properties, not to
the HTML text.**

Some attributes have no property, and some properties have a different name. A table cell's
`colspan` attribute is the `colSpan` property, with a capital S, and binding the attribute's name
fails:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<table>
  <tr><td [colspan]="2">Two columns</td></tr>
</table>
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A1 ERROR
✘ [ERROR] NG8002: Can't bind to 'colspan' since it isn't a known property of 'td'. [plugin angular-compiler]
```

**`[attr.name]` binds the attribute instead.** Write `[attr.colspan]="2"` and Angular sets the
attribute, by its HTML name, which is what you want for an attribute with no property behind it.
ARIA attributes used to be the most common case. Angular 21 binds them without the prefix, which is
why `[aria-label]` above worked, and `[attr.aria-label]` remains correct and is what older code says.

The next section replaces the bench's template again, so leave the table where it is.
