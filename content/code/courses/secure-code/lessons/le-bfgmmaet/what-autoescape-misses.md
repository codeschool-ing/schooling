---
title: What autoescaping does not do for you
version: 1
---

Autoescaping is the reason most Flask pages are fine, and it covers one context: HTML text and
quoted HTML attributes. **Everything else is still yours**, and most real escaping flaws in Flask
or Django code live in the gaps below rather than in a template that forgot to escape.

### Switching it off

Three ways to tell Jinja that a value is already safe HTML, each of which turns the escaping off
for that value:

| | what it does | when it is right |
|---|---|---|
| the `safe` filter, in a template | marks the value as HTML | for HTML the application itself generated, never for anything a person typed |
| `Markup(value)`, in Python | the same, in code | same rule; it is easier to miss in a review than the filter |
| `{% autoescape false %}` | switches escaping off for a whole block | almost never |

`|safe` on a patient's message is the usual way a Jinja template becomes unsafe.
Lesson 7 shows what goes wrong, and how a message that must keep some formatting is cleaned
instead of trusted.

### Building HTML before the template sees it

Escaping happens when the template renders a value. **HTML assembled in Python first**, with an
f-string or `+`, and then passed in with `|safe` because otherwise it would show as text, has
already skipped the escaping for every value inside it. The fix is to pass the values to the
template and let it build the HTML.

### Contexts the escaping does not understand

- **Inside `<script>`, and in event attributes such as `onclick="…"`.** HTML escaping produces
  HTML entities, and the JavaScript engine reads what is left after the HTML parser has undone
  them. Use `tojson` for data in a script, and keep data out of `on…` attributes altogether: put
  it in a `data-` attribute and read it from JavaScript.
- **Inside `<style>` and `style="…"`.** CSS has its own syntax and its own escaping, and the
  practical rule is to never put user data there.
- **The destination of a link.** Escaping `href` makes the text of the address harmless. It does
  not make a `data:` or `javascript:` address into a web page, which is why the fix kept a
  scheme allowlist, lesson 2's idea applied to the output.

### Templates that are not HTML

Flask only autoescapes templates whose names end in `.html`, `.htm`, `.xml`, `.xhtml` or `.svg`,
plus `render_template_string`. A template called `email.txt` that renders into an HTML e-mail is not
escaped at all. Name templates for what they produce, and check the setting when a project
renders anything unusual.
