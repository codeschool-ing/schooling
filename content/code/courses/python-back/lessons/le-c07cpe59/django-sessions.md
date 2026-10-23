---
title: Sessions: Django's default
version: 1
---

A **session** is a row on the server and a random key in a cookie. Lesson 5 logged in with curl;
this time, look at the cookie file between the steps. Start the development server and fetch the
login form:

```
ana@vm:~/agenda$ curl -s -c jar.txt http://127.0.0.1:8000/admin/login/ -o /dev/null -w "%{http_code}\n"
200
ana@vm:~/agenda$ grep -vE '^(# |$)' jar.txt | cut -f1,6
127.0.0.1	csrftoken
```

Only `csrftoken` so far: lesson 3's CSRF cookie. Post the form, as lesson 5 did:

```
ana@vm:~/agenda$ curl -s -b jar.txt -c jar.txt http://127.0.0.1:8000/admin/login/ -d "csrfmiddlewaretoken=$(grep csrftoken jar.txt | cut -f7)" -d username=bruno -d password=m4-orchard-copper-17 -d next=/admin/ -o /dev/null -w "%{http_code} %{redirect_url}\n"
302 http://127.0.0.1:8000/admin/
ana@vm:~/agenda$ grep -vE '^(# |$)' jar.txt | cut -f1,6
#HttpOnly_127.0.0.1	sessionid
127.0.0.1	csrftoken
```

**`sessionid` arrived, and curl marks it `#HttpOnly_`**: the browser keeps the cookie but never
hands it to JavaScript, so a script injected into a page cannot read it. The key is the
`session_key` of a new row:

```
ana@vm:~/agenda$ psql agenda -c "select session_key, expire_date from django_session order by expire_date"
           session_key            |          expire_date          
----------------------------------+-------------------------------
 5v7savbx916xvx3uasda8levshotmjw2 | 2026-10-30 20:25:05.226206-03
 0smz9pjrmznxj5jzt7e7dw02jgns0g48 | 2026-10-30 20:25:17.61332-03
 auryossackfeqd6yi973yefmoqo32ahz | 2026-11-05 20:35:16.152252-03
(3 rows)
```

The two older rows are lesson 5's logins, still valid for two weeks from that day, which is Django's
default lifetime. With every request, Django's `AuthenticationMiddleware` reads the cookie, looks the
row up and puts the user in `request.user`, as lesson 2's table promised.

## A session and the API

DRF accepts the same session. Lesson 6 said what that costs: **a request authenticated by a cookie
must carry the CSRF token**, because a browser attaches cookies to requests other sites make it send:

```
ana@vm:~/agenda$ curl -s -b jar.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{"capacity": 22}'; echo
{"detail":"CSRF Failed: CSRF token missing."}
ana@vm:~/agenda$ curl -s -b jar.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -H "X-CSRFToken: $(grep csrftoken jar.txt | cut -f7)" -d '{"capacity": 22}'; echo
{"slug":"testing-dojo","title":"Testing dojo","starts_at":"2026-11-26T19:00:00-03:00","venue":"Community Centre, room 3","capacity":22,"description":"","taken":3}
```

## Taking it back

Logging out deletes the row. Keep a copy of the cookie file, log out, and try the old copy:

```
ana@vm:~/agenda$ cp jar.txt before-logout.txt
ana@vm:~/agenda$ curl -s -b jar.txt -c jar.txt -X POST http://127.0.0.1:8000/admin/logout/ -H "X-CSRFToken: $(grep csrftoken jar.txt | cut -f7)" -o /dev/null -w "%{http_code}\n"
200
ana@vm:~/agenda$ curl -s -b before-logout.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -H "X-CSRFToken: $(grep csrftoken before-logout.txt | cut -f7)" -d '{"capacity": 24}'; echo
{"detail":"Authentication credentials were not provided."}
```

**The cookie still holds the old key, and the key now leads nowhere.** That is the strength of a
session: the server can end one at any moment, for one person or for everybody, by deleting rows.
