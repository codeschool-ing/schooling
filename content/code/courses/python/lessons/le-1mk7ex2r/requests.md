---
title: `get`, the query string, `raise_for_status`, `json`, and the timeout
version: 2
---

```python
import requests

r = requests.get("https://pypi.org/pypi/requests/json", timeout=10)
r.raise_for_status()
data = r.json()
```

```sh
>>> r.status_code, r.ok
(200, True)
>>> data["info"]["version"]
'2.34.2'
```

Four lines, and three of them matter. The `timeout` is the one everybody leaves out.

## The timeout is not optional

```python
requests.get(url)              # waits forever, by default
requests.get(url, timeout=10)  # raises after ten seconds
```

```sh
>>> requests.get("http://127.0.0.1:8099/slow", timeout=2)
requests.exceptions.ReadTimeout: … Read timed out. (read timeout=2)
```

**`requests` has no default timeout.** A server that accepts your connection and then says
nothing will hold the call open until something else gives up — and in a scheduled job, that is a
process still sitting there in the morning.

```python
requests.get(url, timeout=(3, 10))   # 3s to connect, 10s to read
```

## `raise_for_status`

```sh
>>> r2 = requests.get("https://pypi.org/pypi/no-such-package-xyzzy/json", timeout=10)
>>> r2.status_code, bool(r2)
(404, False)
>>> r2.raise_for_status()
requests.HTTPError: 404 Client Error: Not Found for url: …
```

**A 404 is a successful HTTP request.** `requests` does not raise on it, so without
`raise_for_status` your next line calls `.json()` on an error document and fails somewhere
confusing.

`bool(r)` is `False` for any 4xx or 5xx, which is why `if r:` reads well and `if r.ok:` reads
better.

## `params`

```python
requests.get(url, params={"a": "1 2", "b": "x&y"})
```

```sh
>>> r.url
'https://pypi.org/simple/?a=1+2&b=x%26y'
```

The spaces and the ampersand were encoded for you. Building the query string yourself is how a
value containing `&` silently becomes two parameters.

## `.json()` and `.text`

```python
r.json()      # parsed, raises ValueError if the body is not JSON
r.text        # the body as a string
r.content     # the body as bytes — for a file, an image, a PDF
```

`r.json()` on an HTML error page raises, which is another reason `raise_for_status` comes first.

## The rest of the verbs

```python
requests.post(url, json={"cents": 1000}, timeout=10)   # a JSON body
requests.post(url, data={"cents": 1000}, timeout=10)   # a form body
requests.put(url, json=…, timeout=10)
requests.delete(url, timeout=10)
```

`json=` sets the `Content-Type` and encodes for you; `data=` sends a form. Choosing the wrong one
is a 400 with a message about the body that reads like a bug in your data.
