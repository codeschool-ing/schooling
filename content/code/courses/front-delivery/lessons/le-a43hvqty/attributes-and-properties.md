---
title: Attributes, properties and the lifecycle
version: 1
---

**An element has two ways to receive data: attributes, which are strings written in HTML, and properties,
which are any JavaScript value set from code.** Built-in elements keep the two in step where it makes sense:
`input.value` and the `value` attribute, `button.disabled` and `disabled`. A custom element has to do it
itself, and `<planner-session>` shows the three cases.

| | attribute | property | kept in step by |
|---|---|---|---|
| `date` | `date="2026-10-15"` | none | the attribute alone |
| `minutes` | `minutes="45"`, a string | none | `Number(...)` when drawing |
| `done` | present or absent | `element.done`, a boolean | the getter and setter, which read and write the attribute |

**Attributes are always strings.** `minutes="45"` arrives as `"45"`, and `"45" + 15` is `"4515"`. That is
why `#render` converts it, and why richer data, a list of sessions or an object, goes in through a
property set from JavaScript rather than through HTML. A boolean attribute is true by being present:
`done` and `done=""` and `done="false"` are all true to `hasAttribute`, which surprises everybody once.

## The lifecycle

The browser calls the class at four moments, and the element uses two of them:

| callback | runs when | `<planner-session>` |
|---|---|---|
| `constructor` | the element is created, before it is in a page | builds the shadow root and wires the button |
| `connectedCallback` | the element is put into a document | draws |
| `attributeChangedCallback` | an attribute named in `observedAttributes` changes | draws again |
| `disconnectedCallback` | the element is removed | not needed: nothing to clean up |

**`disconnectedCallback` is where an element that starts a timer or listens on `window` must stop**, or the
listener outlives the element; javascript lesson 19 showed what a leak like that costs. This element only
listens on its own button, which goes when it goes.

## Upgrades

HTML can contain `<planner-session>` before the class is registered: the browser treats it as an unknown
element until `customElements.define` runs, then **upgrades** every one already in the page, calling each
constructor and callback in turn. That is why the demo page can put the rows in its HTML and register the
class in a script after them, and why a server-rendered page can send the tags before any JavaScript
arrives: they show their light content, the course name, until the script makes them whole.
