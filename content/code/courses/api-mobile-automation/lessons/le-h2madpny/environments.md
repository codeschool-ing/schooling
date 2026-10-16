---
title: The lab environment
version: 1
---

**An environment is a named set of variables, and switching it points the same requests at another
server.** A team usually has several: `lab` for a laptop, `staging` for the shared test server,
sometimes one per developer. The requests stay the same and only the values change. The drop-down
in the top-right corner of Postman says which one is active, and *No environment* means none is.

This course needs one, called `lab`. Open your editor and save it as `postman/lab.postman_environment.json`:

```json
{
  "name": "lab",
  "values": [
    {"key": "baseUrl", "value": "http://localhost:8080", "type": "default", "enabled": true},
    {"key": "clientId", "value": "ci-tests", "type": "default", "enabled": true},
    {"key": "clientSecret", "value": "ci-secret", "type": "secret", "enabled": true},
    {"key": "token", "value": "", "type": "secret", "enabled": true}
  ],
  "_postman_variable_scope": "environment"
}
```

`name` is what the drop-down shows. `values` holds the variables, each with a `key`, a `value`, a
`type` and `enabled`, which lets a variable be switched off without deleting it.
`_postman_variable_scope` tells an importer that this file is an environment rather than a
collection. jq says whether the file is valid JSON at all, which is worth asking of any file you
edited by hand before you hand it to another program:

```
ana@laptop:~/boxoffice$ jq empty postman/lab.postman_environment.json && echo valid JSON
valid JSON
```

`jq empty` reads a file and prints nothing when it parses, so the `echo` runs only when it did.
The variables, one per line:

```
ana@laptop:~/boxoffice$ jq -r '.values[] | [.key, .type, .value] | @tsv' postman/lab.postman_environment.json
baseUrl	default	http://localhost:8080
clientId	default	ci-tests
clientSecret	secret	ci-secret
token	secret	
```

## Four values, and why each is here

- `baseUrl` is the address of boxoffice. An environment for another server would differ here
  first.
- `clientId` and `clientSecret` are the credentials of the `ci-tests` client of lesson 3, the one
  allowed to read and create orders.
- `token` is empty. You fill it by hand in section 06, after asking boxoffice for one, and lesson 5
  replaces the hand with a script.

**`secret` hides a value on the screen. It does not protect the file.** Postman draws a secret's
value as dots and asks before showing it, which keeps it out of a screenshot or a screen share. The
file on disk still says `ci-secret` in plain text, as the transcript shows. That is acceptable here
for one reason: boxoffice prints the same secret in its own source and listens only for your own
requests. For a real API, leave the value empty in the file you share and type it into Postman on
your machine only, for the reasons lesson 3 gave about secrets in files.

Postman keeps two values for each variable for exactly that purpose. One travels when the
environment is exported or shared with a team, and the other stays on your computer. The app has
renamed those two columns over its versions. What matters is which one a file carries, and an
exported file carries only the shared one.

## Importing it

In Postman, **Import**, then choose the file or drop it on the window. The environment appears in
the environments list in the sidebar; choose `lab` in the top-right drop-down to make it active.
The request of section 03 can now be written `{{baseUrl}}/v1/shows`, and hovering over the name
shows the value it will send and the scope it came from.

## When an import fails

The most common reason is a hand edit that broke the JSON. This copy lost the comma after its first
value:

```
ana@laptop:~/boxoffice$ jq empty postman/lab.postman_environment.json
jq: parse error: Expected separator between values at line 5, column 5
```

jq names the line and column where it gave up, and the column is past the mistake rather than on it.
The comma is missing at the end of line 4, and jq only noticed at the start of the next value.
Postman's own message is usually less precise, so run `jq empty` on the file first.
