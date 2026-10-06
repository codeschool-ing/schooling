---
title: The browser's own reaction
version: 1
---

Some events come with something the browser does by itself: **a click on a link navigates, a submit
sends the form and loads a new page, a key in a field types a letter**. That built-in reaction is the
event's **default action**, and a listener can cancel it with `event.preventDefault()`:

```html
<!doctype html>
<a id="more" href="details.html">Details</a>
<script>
  document.querySelector("#more").addEventListener("click", (event) => {
    event.preventDefault();
    console.log("stayed on", location.pathname, "cancelled:", event.defaultPrevented);
  });
</script>
```

```
ana@dev:~/js$ page default.html --do 'click #more'
-- click #more
stayed on /default.html cancelled: true
```

The link pointed at `details.html`, and the page **stayed on `/default.html`**: the navigation never
happened. `event.defaultPrevented` reports that it was cancelled, which is how a listener further up
can tell that somebody below already handled the event.

## When to cancel

- **a form your script will send itself.** Every form in the next section calls `preventDefault()` on
  submit, because otherwise the browser would send the fields and replace the page before the script
  could do anything with them. Lesson 16 sends the data with `fetch` instead;
- a link that a script turns into something else, such as opening a panel, while keeping a real
  `href` so the link still works for somebody whose script has not loaded.

**Cancel the default action only when your code replaces it.** A link that does nothing when clicked
and has no fallback, or a key that types nothing, breaks things users rely on, including the browser's
own accessibility features. `preventDefault` does not stop the event's journey; that is
`stopPropagation`, and the two are independent.
