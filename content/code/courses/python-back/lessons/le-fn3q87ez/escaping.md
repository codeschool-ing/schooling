---
title: Escaping, the defence you get for free
version: 1
---

The list template prints the search term back: `Results for {{ q }}`. Whatever the person typed in
the address bar goes into the page. So try typing HTML:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/events/?q=<b>dojo</b>" | grep Results
<p>Results for &lt;b&gt;dojo&lt;/b&gt;</p>
```

**Django escaped it.** `<` became `&lt;` and `>` became `&gt;`, so the browser shows the characters
instead of reading them as a tag. Every `{{ variable }}` is escaped this way unless something says
otherwise, which is the right default: a template cannot know whether a variable came from the
code or from a stranger.

## Why it matters

If `q` were printed raw, a link to `/events/?q=<script>…</script>` would run that script in the
browser of whoever opened the link, **with their session on this site**. That is cross-site
scripting, and it is the most common defect in web applications that build HTML by hand. The
defence is not to filter out "dangerous" input, which always misses a case. It is to **escape on
output**, everywhere, which is what the template does without being asked.

The ordinary search still works, because escaping changes only the five characters that mean
something in HTML:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/events/?q=dojo" | grep -A4 "<ul>"
<ul>
  
  <li>
    <a href="/events/testing-dojo/">Testing dojo</a>,
    Thu 26 Nov, 19:00 at Community Centre, room 3
```

## Turning it off, and when not to

`{{ value|safe }}` and `mark_safe()` in Python tell Django a string is already HTML and must be
printed as it is. They exist for HTML **the application itself produced**: the output of a Markdown
renderer you trust, a fragment built by your own code with every variable escaped. **They are never
for anything a person typed**, and a `|safe` on a variable that came from a form is the defect this
section describes, with a filter's name on it.

One context still needs care. Inside a `<script>` block, escaping HTML is not enough, because the
rules of JavaScript strings are different. Django's filter for that case is `json_script`, which
writes a value into the page as JSON inside a tag that a script reads, and is safe where a
`{{ value }}` pasted into JavaScript is not.
