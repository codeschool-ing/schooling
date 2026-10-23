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
