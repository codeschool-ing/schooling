---
title: A form is a suggestion
version: 1
---

A browser is one way to send a request, not the only one. **The same `POST` can come from `curl`,
a Python script, a test, another company's integration or a version of the mobile app that was
written before the form changed.** None of them runs the HTML attributes, because none of them
reads the HTML.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-paths\" aria-label=\"Three ways a sign-up reaches Vereda's server, and which checks each one passes through. A patient in a browser passes the browser's checks, required, maxlength, type email, before the request leaves. A script using curl, and an old version of the mobile app, send the request straight to the server and pass no browser check at all. All three arrive at the same route, so only the server's checks see every request.\"><defs><marker id=\"l03-paths-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">patient, browser</text><rect x=\"20\" y=\"130\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a script with curl</text><rect x=\"20\" y=\"210\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an old mobile app</text><rect x=\"230\" y=\"30\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"47.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">browser checks:</text><text x=\"315.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">required, maxlength,</text><text x=\"315.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">type=email</text><path d=\"M180 60 L230 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><rect x=\"470\" y=\"110\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /signup</text><rect x=\"470\" y=\"180\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the server's checks</text><path d=\"M400 60 L440 60 L440 125 L470 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><path d=\"M180 150 L470 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><path d=\"M180 230 L440 230 L440 145 L470 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><path d=\"M540 154 L540 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-paths-ah-paper-dim)\"></path><text x=\"585\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the only checks every request passes</text></svg>", "caption": "The browser's checks sit on one of the paths in. The server's sit on all of them."}
```

This lesson's application is Vereda's sign-up page. Make its folder and repository as before:

```
(.venv) ana@vm:~/sc$ mkdir signup
(.venv) ana@vm:~/sc$ cd signup
(.venv) ana@vm:~/sc/signup$ git init -b main
Initialized empty Git repository in /home/ana/sc/signup/.git/
```

Here is the version where every rule lives in the HTML. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "from flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nPATIENTS = []\n"}, {"code": "PAGE = \"\"\"<form method=\"post\" action=\"/signup\">\n  <label>Name <input name=\"name\" required maxlength=\"60\"></label>\n  <label>E-mail <input name=\"email\" type=\"email\" required maxlength=\"120\"></label>\n  <label>Birth date <input name=\"birth\" type=\"date\" required max=\"2026-11-01\"></label>\n  <button>Sign up</button>\n</form>\"\"\"\n\n", "note": "Every rule is in the HTML: three required fields, two lengths, an e-mail type, a latest birth date. A browser enforces them before it sends anything."}, {"code": "@app.get(\"/signup\")\ndef form():\n    return render_template_string(PAGE)\n\n\n@app.post(\"/signup\")\ndef signup():\n    PATIENTS.append(dict(request.form))\n    return \"Welcome\", 201", "note": "The server stores whatever fields arrived, all of them, because the form already checked. That sentence is the flaw."}]}
```

A browser opening `http://127.0.0.1:5000/signup` will not let anybody send that form with an empty
name, a 61-character one, or a birth date after 1 November 2026. Start the application with
`flask --app app run`, and from a second terminal send a sign-up the browser would never have sent:
an empty name, an address with no `@`, and a birth date five years in the future.

```
(.venv) ana@vm:~/sc/signup$ curl -s -w '\n%{http_code}\n' -d 'name=&email=lucia&birth=2031-01-01' http://127.0.0.1:5000/signup
Welcome
201
```

`Welcome`, and the status code `curl -w` was asked to print: 201. **The server stored all three
values.** `curl -d` sends form fields
exactly as a browser would, encoded the same way, to the same route, and the server cannot tell
the difference, because there is none to tell. Every rule in the HTML was skipped by not using
the HTML.

### The browser's own tools say the same thing

You do not even need a terminal. The developer tools of every current browser (F12, or
`Ctrl+Shift+I`) let the person at the keyboard edit the page: delete `required`, change
`maxlength`, then press the button. Firefox and Chrome both allow it, on purpose, because the page
is the user's to inspect. **Anything the browser enforces, the person at the browser can switch
off**, which is exactly why it is the server's check that counts.
