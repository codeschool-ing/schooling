---
title: Resources, verbs and status codes
version: 2
---

Lesson 1 drove the routers through their CLI: text in, text out, and a script that has to
recognise prompts. **An API replaces the conversation with requests and structured answers.**
Most network equipment sold today has one beside its CLI, and the most common kind is a REST API
over HTTPS: the device publishes **resources** at addresses, and a client acts on them with the
**verbs** of HTTP.

The lab's routers have one at `https://<router>.example.net/api/v1`, served by `devapid`, the
program the previous section started. Asking it something without saying who you are:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem https://edge1.example.net/api/v1/system
HTTP/1.1 401 Unauthorized
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:42 GMT
Content-Type: application/json
Content-Length: 72
WWW-Authenticate: Bearer realm="devapi"

{
  "error": "missing or unknown token: log in at /api/v1/auth/login"
}
```

Everything an HTTP answer carries is in that transcript. The first line is the **status code**,
`401 Unauthorized`. The lines after it are **headers**, one name and value each; `Content-Type`
says the body is JSON and `WWW-Authenticate` says which kind of credentials the server wants.
After the blank line comes the **body**, which here explains the refusal in a sentence.

The resources of this API, and what each verb means on them:

| resource | GET | POST | PUT | PATCH | DELETE |
|---|---|---|---|---|---|
| `/system` | read the device's facts | | | | |
| `/interfaces` | list interfaces | | | | |
| `/interfaces/eth2` | read one | | | change some fields | |
| `/routes` | list the routing table | | | | |
| `/static-routes` | list static routes | create one | | | |
| `/static-routes/192.0.2.128%2F25` | read one | | create or replace | | remove |

**The verb says what to do, and the address says to what.** `GET` never changes anything, which
is what makes it safe to repeat. `POST` to a collection creates something inside it. `PUT` to an
item makes that item exactly the body sent, whether it existed or not. `PATCH` changes the fields
it names and leaves the rest. `DELETE` removes.

The status code is the first thing a program should read, grouped by its first digit:

| code | means | met in this lesson |
|---|---|---|
| 2xx | it worked | `200 OK`, `201 Created`, `204 No Content` |
| 4xx | the request is wrong, and sending it again unchanged will fail again | `401`, `403`, `404`, `405`, `409`, `422`, `429` |
| 5xx | the server failed; the same request may work later | none, on a good day |

**A 4xx is your problem to fix, a 5xx is the server's.** That one distinction decides whether a
script should retry, and `429 Too Many Requests` is the one 4xx where retrying, after a wait, is
exactly right. Section 07 is about it.
