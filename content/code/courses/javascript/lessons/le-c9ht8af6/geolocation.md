---
title: Geolocation: asking where the user is
version: 1
---

**`navigator.geolocation.getCurrentPosition(success, failure)` asks the browser for the user's
position**, and the browser asks the user. A library site uses it to list the branches nearby:

```html
<!doctype html>
<button id="where">Find libraries near me</button>
<script>
  document.querySelector("#where").addEventListener("click", () => {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude, accuracy } = pos.coords;
        console.log("at", latitude.toFixed(4), longitude.toFixed(4), "within", accuracy, "m");
      },
      (err) => console.log("no position:", err.code, err.message),
      { timeout: 5000 },
    );
  });
</script>
```

```
ana@dev:~/js$ page where.html --fresh --do 'click #where' --wait 500
-- click #where
no position: 1 User denied Geolocation
```

```
ana@dev:~/js$ page where.html --fresh --geo -23.5503,-46.6339 --do 'click #where' --wait 500
-- click #where
at -23.5503 -46.6339 within 0 m
```

Both runs were staged, as the script's header says. In the first, the lab's browser answered the
request as a user who clicked **Block** would: **the failure callback ran with code 1,
`PERMISSION_DENIED`**. In the second, `page --geo` granted the permission and supplied a position,
the coordinates of Praça da Sé in São Paulo, so the success callback ran with them. A real device
reports an `accuracy` in metres, larger indoors and from a laptop's Wi-Fi than from a phone's GPS; the
lab's staged position claims 0.

## Writing it so it works for everybody

- **ask when the user does something that needs it**, as the button here does, never as the page
  loads. A prompt that appears before the user knows why is the one they block, and once blocked the
  page cannot ask again;
- **always write the failure callback.** Denied (code 1), unavailable (code 2) and timed out (code 3)
  are all normal outcomes, and the page needs a way forward for each, such as a field to type a city;
- the API works only on **secure origins**, `https://` or `localhost`, which `127.0.0.1` counts as.
  On a plain `http://` site the request is refused outright;
- the position is personal data. Use it for what you asked it for, and say so.
