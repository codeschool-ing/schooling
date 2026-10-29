---
title: Scoped style
version: 1
---

**A `<style scoped>` block applies only to the component it is written in, even though `App.vue` and
`AppFooter.vue` both have a rule for `p`.** In plain CSS the two rules would fight over every
paragraph on the page, and whichever came later would win. Here each one stays at home: the
paragraphs in the header are green, and the one in the footer is grey and smaller.

Nothing in CSS itself does that. The Vue compiler does it, in two halves, and both are visible.

## The attribute on the element

Ask `look` for the footer's HTML as the page has it now:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --text - --html footer
[vite] connecting...
[vite] connected.
== the HTML of footer
<footer data-v-6704560a="" data-v-7a7a37b1=""><p data-v-6704560a="">Built with Vue 3.5.44</p></footer>
```

**Every element `AppFooter` drew carries an extra attribute**, `data-v-` followed by eight characters.
The characters come from the file's path, so they are the same on every run and different for every
component. `App.vue` stamps its own elements with a different one.

## The selector in the stylesheet

The other half is the rule. Ask the dev server for the footer's style the way the page asked for it:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --text - --network | grep AppFooter
net  GET /src/components/AppFooter.vue  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
```

The last line is the style block. Fetching it shows what Vite sends:

```
ana@dev:~/vue/planner$ curl -s 'http://localhost:5173/src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css' | grep -o 'const __vite__css = .*'
const __vite__css = "\np[data-v-6704560a] {\n  color: #666;\n  font-size: 0.875rem;\n}\n"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 235\" role=\"img\" aria-label=\"The two halves of a scoped style, side by side. On the left, the footer&#x27;s HTML as the page has it: the footer element carries data-v-6704560a, AppFooter&#x27;s own attribute, and a second one, data-v-7a7a37b1, which is App.vue&#x27;s, because the root element of a child also gets its parent&#x27;s attribute; the paragraph inside carries data-v-6704560a only. On the right, the style block as Vite sends it: the rule written for p has become p[data-v-6704560a], with colour #666 and font size 0.875rem. Below, the browser applies the rule only where both match.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the HTML: an attribute on every element</text><rect x=\"30\" y=\"36\" width=\"300\" height=\"124\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;footer data-v-6704560a</text><text x=\"96.4\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">data-v-7a7a37b1&gt;</text><text x=\"58.6\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;p data-v-6704560a&gt;</text><text x=\"46.0\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/footer&gt;</text><text x=\"180\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the second one is App.vue's, on the child's root</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the stylesheet: a selector rewritten</text><rect x=\"390\" y=\"36\" width=\"300\" height=\"124\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">p {</text><text x=\"674\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as written</text><text x=\"406\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">p[data-v-6704560a] {</text><text x=\"674\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">as Vite sends it</text><text x=\"419\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">color: #666;</text><text x=\"419\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">font-size: 0.875rem;</text><text x=\"406\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">}</text><line x1=\"180\" y1=\"162\" x2=\"290\" y2=\"188\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"290.0,188.0 282.1,189.3 283.5,183.3\" fill=\"var(--phosphor)\"></polygon><line x1=\"540\" y1=\"162\" x2=\"430\" y2=\"188\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"430.0,188.0 436.5,183.3 437.9,189.3\" fill=\"var(--phosphor)\"></polygon><rect x=\"200\" y=\"190\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the browser applies the rule where both match</text></svg>", "caption": "The compiler marks the elements and rewrites the selector; the browser runs ordinary CSS."}
```

**`p` became `p[data-v-6704560a]`**: a paragraph, and only one carrying this component's attribute.
The two halves meet in the browser, which applies each rule only where both match. That is all
scoping is, and it is why a scoped rule costs nothing at run time: the work was done by the compiler,
and the browser runs ordinary CSS.

## The two places it leaks, on purpose

**A child component's root element gets its parent's attribute too.** `<footer>` is the root of
`AppFooter`, so a scoped rule for `footer` written in `App.vue` would reach it. That is deliberate: it
lets a parent place and space its children, which is a layout decision the parent owns. Everything
*inside* the child is out of the parent's reach.

When a parent really does need to style something deeper, `:deep()` says so out loud:

```css
.courses :deep(p) {
  margin: 0;
}
```

The compiler puts the attribute on `.courses` and leaves `p` bare, so the rule matches any paragraph
inside the list, in this component or in a child. **Use it rarely**, because it ties the parent to the
inside of a child, and the child can no longer change its own markup without breaking somebody else's
style.

Rules that should apply everywhere, a font or the colour of every link, belong in an ordinary
stylesheet imported once from `main.js`, or in a `<style>` block with no `scoped`. The planner keeps
everything scoped until lesson 7 gives it a shared look.
