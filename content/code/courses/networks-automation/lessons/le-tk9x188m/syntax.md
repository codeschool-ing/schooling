---
title: Values, loops and filters
version: 1
---

Jinja2 has three kinds of markup inside ordinary text. **`{{ ... }}` prints the value of an
expression.** **`{% ... %}` is a statement**, a loop or a condition, and prints nothing itself.
`{# ... #}` is a comment and disappears. Everything else is copied to the output as it is.

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from jinja2 import Environment\n"
    },
    {
      "code": "TEMPLATE = \"\"\"hostname {{ hostname }}\n{% for i in interfaces %}\ninterface {{ i.name }}\n description {{ i.description | upper }}\nexit\n{% endfor %}\"\"\"\n",
      "note": "**A template is text with holes in it.** `{{ ... }}` prints a value and `{% ... %}` is logic: here a loop, closed by `endfor`."
    },
    {
      "code": "data = {\n    \"hostname\": \"edge1\",\n    \"interfaces\": [\n        {\"name\": \"eth1\", \"description\": \"uplink to core1\"},\n        {\"name\": \"eth2\", \"description\": \"branch LAN\"},\n    ],\n}\n\ntemplate = Environment().from_string(TEMPLATE)\nprint(template.render(data))",
      "note": "**The data is plain Python**: a string and a list of dictionaries, the shape a YAML file gives you."
    }
  ],
  "output": "hostname edge1\n\ninterface eth1\n description UPLINK TO CORE1\nexit\n\ninterface eth2\n description BRANCH LAN\nexit"
}
```

The loop ran once per interface, and inside it `i.name` reached into the dictionary: Jinja2 lets a
dot stand for a key, so `i.name` and `i["name"]` are the same thing. The `|` sends a value through a
**filter**, a function that transforms it; `upper` is one of the fifty or so that come with
Jinja2, next to `default`, `join`, `replace`, `int` and `length`.

The output has a problem that is easy to miss on a screen and impossible to miss in a diff: **blank
lines that nobody wrote.** They come from the lines that held only a `{% %}` tag. The tag printed
nothing, but the newline after it was ordinary text, and Jinja2 copied it. The next section is about
where they come from and how to stop them.

Conditions look like Python's, with `{% if %}`, `{% elif %}`, `{% else %}` and a closing `{%
endif %}`. Tests use `is`: `{% if i.description is defined %}` asks whether the key exists at all.
The template this lesson builds uses both.
