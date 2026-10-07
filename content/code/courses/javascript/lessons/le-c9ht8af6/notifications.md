---
title: Notifications and the Permissions API
version: 2
---

A notification is a message the operating system shows **outside the page**, even when its tab is in
the background: a reserved book is ready to collect. Because it reaches outside the page, it needs the
user's permission, and the **Permissions API** lets a page ask what has been decided so far without
asking the user anything:

```html
<!doctype html>
<script>
  for (const name of ["geolocation", "notifications"]) {
    navigator.permissions.query({ name }).then((status) => console.log(name, status.state));
  }
</script>
```

```
ana@dev:~/js$ page permissions.html --fresh
geolocation prompt
notifications prompt
ana@dev:~/js$ page permissions.html --fresh --geo -23.5503,-46.6339 --grant notifications
geolocation granted
notifications granted
```

Each permission is in one of three states:

- **`prompt`**: nobody has decided. Asking will show the browser's question. That is where a fresh
  profile starts, as the first run shows;
- **`granted`**: allowed, as in the second run, where `page` granted both;
- **`denied`**: refused. **The page cannot ask again**; only the user can change it, in the
  browser's site settings.

## Showing one

Showing a notification is two steps: `await Notification.requestPermission()`, which shows the
question if the state is `prompt` and returns the answer, and then `new Notification("Iracema is
ready to collect", { body: "Shelf A, until Friday" })`. **This was not captured**: the browser `page`
drives runs without a screen and cannot display a notification, so a transcript would show only its failure,
which is not what a real browser does.

The rules are the ones geolocation taught, for the same reason:

- **ask in response to something the user did**, such as switching on "tell me when it is ready".
  Browsers ignore or quietly block a request made as the page loads;
- **use `navigator.permissions.query` to decide what to show**: an "enable notifications" button when
  the state is `prompt`, a note about the browser's settings when it is `denied`, nothing when it is
  `granted`;
- a notification that arrives when the page is closed needs a **service worker** and a push service,
  which belong to the offline chapters of the next courses rather than to this one.
