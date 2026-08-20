---
title: The skeleton of every page
---

Every HTML document has the same frame, and it is worth typing it out by hand a few times before letting the editor generate it:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>My page</title>
</head>
<body>
  <h1>Hello</h1>
</body>
</html>
```

`<!DOCTYPE html>` is not a tag: it is a declaration telling the browser to use standards mode. Without it, the browser enters *quirks mode* and starts imitating bugs from 1990s browsers — the most famous of them changes the whole box model, and the layout falls apart with no error showing up at all.

The `lang` on `<html>` is not decoration either: it is what makes the screen reader pick the right pronunciation and the spell checker pick the right dictionary.
