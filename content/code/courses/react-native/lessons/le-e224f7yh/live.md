---
title: The planner against a real server
version: 1
---

**Tests prove the logic; this section watches the requests.** The web build is exported with the
server's address, served as in lesson 8, and opened while `server.mjs` runs in its own terminal:

```sh
EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web
npx -y serve@14.2.6 --single -l 8082 dist
```

Three visits: the courses, the week with guitar's session marked done, and the courses again in a
**fresh** browser, with no cache at all:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- progressbar "Minutes done this week"
- button "Spanish A2 2 sessions planned"
- button "Statistics 2 sessions planned"
- button "Guitar 2 sessions planned"
- text: Saved in this browser
- tablist:
  - tab "Courses" [selected]
  - tab "This week"
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/week?today=2026-10-21' --click 'Mark 20 min on 2026-10-21 done'
- heading "This week" [level=1]
- heading "2026-10-19" [level=2]
- text: 30 min, done
- heading "2026-10-20" [level=2]
- text: 45 min, done
- heading "2026-10-21" [level=2]
- text: 20 min, done
- heading "2026-10-22" [level=2]
- text: 30 min
- button "Mark 30 min on 2026-10-22 done": Mark done
- tablist:
  - tab "Courses"
  - tab "This week" [selected]
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 95 of 125 minutes done"
- progressbar "Minutes done this week"
- button "Spanish A2 2 sessions planned"
- button "Statistics 2 sessions planned"
- button "Guitar 2 sessions planned"
- text: Saved in this browser
- tablist:
  - tab "Courses" [selected]
  - tab "This week"
```

**The third visit read 95 from a browser that had never seen the press.** The change reached the server,
and a new client fetched it. Here is what the server's terminal printed meanwhile:

```
listening on 8008
GET /
GET /plan
POST /sessions/s9/done
POST /sessions/s9/done
GET /plan
GET /plan
POST /sessions/s3/done
GET /plan
GET /plan
```

Read it as a timeline. `GET /` is the recording machine checking that the server had started, and is
not the app's. The next three lines are the `curl` commands of the section on the server. Then the app:
the first visit's `GET /plan`; the second visit's `GET /plan`, the press's `POST /sessions/s3/done`, and
another `GET /plan`, which is `onSettled` invalidating the query and fetching the server's version; and
the third visit's `GET /plan`.

**No `OPTIONS` before the `POST`.** A browser asks a server first whether a cross-origin request is
allowed only when the request is not a simple one, a JSON body or a custom header for instance; a `POST`
with neither is sent straight away, and the server's `access-control-allow-origin` lets the page read
the answer. **Every request in that log is one the code of this lesson asked for, and none is a
duplicate**, which is the sign the cache is doing its job.
