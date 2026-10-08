---
title: The same requests, from Python
version: 1
---

`curl` is the right tool for looking at an API. A program that does something with the answer is
written in Python, with `requests`:

```schooling-example
{
  "language": "python",
  "file": "login.py",
  "parts": [
    {
      "code": "from pathlib import Path\n\nimport requests\n\nBASE = \"https://edge1.example.net/api/v1\"\nCA = \"lab-ca.pem\"\npassword = Path(\"~/.netops-password\").expanduser().read_text().strip()\n",
      "note": "**The address of the API and the file that proves who the server is.** `lab-ca.pem` is the lab's certificate authority; section 09 is about why it is named here."
    },
    {
      "code": "r = requests.post(f\"{BASE}/auth/login\", json={\"username\": \"netops\", \"password\": password},\n                  verify=CA, timeout=10)\nr.raise_for_status()\ntoken = r.json()[\"token\"]\n",
      "note": "**Log in once.** The password travels in one request, and what comes back is a token that expires."
    },
    {
      "code": "r = requests.get(f\"{BASE}/system\", headers={\"Authorization\": f\"Bearer {token}\"},\n                 verify=CA, timeout=10)\nr.raise_for_status()\nprint(r.json())",
      "note": "**Every other request carries the token**, in the `Authorization` header, and never the password."
    }
  ]
}
```

```
ana@ctl:~$ python login.py
{'hostname': 'edge1', 'software': 'FRRouting 8.4.4', 'uptime_seconds': 18, 'management_address': '192.0.2.12'}
```

What came back is a Python dictionary, `r.json()`, built from the body. **No parsing was written**:
the fields are already named, and `data["hostname"]` is a string whatever the router's CLI would
have printed around it. That is the first thing an API buys over the screen-scraping of lesson 1.

Three details in the script matter more than they look:

- **`raise_for_status()`** turns any 4xx or 5xx into an exception. Without it, `requests` returns
  a `401` as happily as a `200`, and the next line fails with a confusing `KeyError` instead.
- **`timeout=10`**. `requests` has no timeout unless you give one, and a device that accepts the
  connection and never answers will hold the script forever.
- **`verify=CA`** names the certificate authority to check the router's certificate against.
  Section 09 shows what happens without it.

Every script from here on needs the same address, the same certificate authority and the same
token, so they move into a small client that the rest of the lesson imports. The constructor
logs in, `request` sends and `all` follows pages, and the next three sections use each of them.

```schooling-example
{
  "language": "python",
  "file": "devapi.py",
  "parts": [
    {
      "code": "import time\nfrom pathlib import Path\n\nimport requests\n\n\nclass Device:\n    def __init__(self, host, username=\"netops\", password_file=\"~/.netops-password\"):\n        self.base = f\"https://{host}.example.net/api/v1\"\n        self.http = requests.Session()\n        self.http.verify = \"lab-ca.pem\"\n        password = Path(password_file).expanduser().read_text().strip()\n        r = self.http.post(f\"{self.base}/auth/login\", timeout=10,\n                           json={\"username\": username, \"password\": password})\n        r.raise_for_status()\n        self.http.headers[\"Authorization\"] = \"Bearer \" + r.json()[\"token\"]\n",
      "note": "**A small client for the routers' API**, the file every later script in this lesson imports. It holds what every request shares: the address, the certificate authority and the token."
    },
    {
      "code": "    def request(self, method, path, **kwargs):\n        url = path if path.startswith(\"https://\") else self.base + path\n        for attempt in range(4):\n            r = self.http.request(method, url, timeout=10, **kwargs)\n            if r.status_code != 429 or attempt == 3:\n                break\n            wait = int(r.headers.get(\"Retry-After\", \"1\"))\n            print(f\"  429 on {path}: waiting {wait} s\")\n            time.sleep(wait)\n        r.raise_for_status()\n        return r.json() if r.content else None\n",
      "note": "**One place sends every request.** A 429 means \"too fast\": the client waits the number of seconds the server gave in `Retry-After` and tries again, three times at most. Any other error status becomes an exception, so nothing fails silently."
    },
    {
      "code": "    def all(self, path, **params):\n        page = self.request(\"GET\", path, params=params)\n        while True:\n            yield from page[\"results\"]\n            if not page[\"next\"]:\n                return\n            page = self.request(\"GET\", page[\"next\"])",
      "note": "**Pagination, followed to the end.** The server answers one page and a `next` link; this generator follows the links and hands out the items one at a time, so the caller never sees a page."
    }
  ]
}
```
