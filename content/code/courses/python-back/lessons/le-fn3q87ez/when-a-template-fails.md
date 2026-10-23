---
title: When a template fails
version: 1
---

Templates fail in four ways, and Django is loud about three of them. Each of these was produced
with `manage.py shell -c`, which runs a line of Python with the project loaded; `tail -1` keeps the
last line of the traceback, which is the one that names the cause.

## The file is not where Django looked

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template.loader import render_to_string; render_to_string(\"events/event_lsit.html\")" 2>&1 | tail -1
django.template.exceptions.TemplateDoesNotExist: events/event_lsit.html
```

A typo in the name passed to `render`. In a request, with `DEBUG` on, the error page also lists every
directory Django searched and why each one did not have it. That settles the other common cause:
the template is in `events/templates/` without the second `events/`, or in a project-level
`templates/` that `DIRS` does not name.

## A tag that is never closed

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template import Template; Template(\"{% for e in events %}{{ e }}\")" 2>&1 | tail -1
django.template.exceptions.TemplateSyntaxError: Unclosed tag on line 1: 'for'. Looking for one of: empty, endfor.
```

**This one fails when the template is loaded**, before any data is involved, and it names the line
and the tags that would close it. Every block tag has an end tag, and `{% for %}` also accepts
`{% empty %}` in between.

## A filter that does not exist

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template import Template; Template(\"{{ event.starts_at|dat }}\")" 2>&1 | tail -1
django.template.exceptions.TemplateSyntaxError: Invalid filter: 'dat'
```

Same moment, same kind of message. A filter from a library, like `naturaltime` from
`django.contrib.humanize`, also needs that library in `INSTALLED_APPS` and a `{% load %}` at the top
of the template; without them it fails exactly like a typo.

## A variable that does not exist, which does not fail

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.template import Template, Context; print(repr(Template(\"[{{ event.titel }}]\").render(Context({\"event\": {\"title\": \"Django Night\"}}))))"
12 objects imported automatically (use -v 2 for details).

'[]'
```

**`event.titel` printed nothing, and nothing complained.** A variable that cannot be resolved is
replaced by an empty string, on purpose, so that an optional value missing from the context does not
take down the page. The price is that a misspelling produces a page with a hole in it and no
error.

Two habits catch it. Look at the page, which is the only check that sees a missing title. And while
developing, set `'string_if_invalid': 'MISSING %s'` in the `OPTIONS` of `TEMPLATES`, which prints the
name of every variable that failed to resolve; remove it before production, since some of Django's
own templates rely on the empty string.
