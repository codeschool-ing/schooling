---
title: Seeing your own change
version: 1
---

**A cache that is fine for other people's changes is wrong for your own.** The planner's `setDone`,
from lesson 16, still ends with `refresh()`. Press Wednesday's session on the production server, and
look two seconds later:

```
ana@dev:~/planner-next$ look 'http://localhost:3000/?week=2026-10-19' --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 2000' | grep -E 'minutes done|Statistics ·'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min"
```

**80 minutes, and the button not pressed.** The `PATCH` reached the API and the session is done there,
so this is the worst kind of wrong: the optimistic copy showed *pressed*, and when the Action ended, the
page came back from `refresh()` **rendered from the cached planner**, which still had Wednesday undone.
`useOptimistic` did its job and showed the server's value; the server's value was an hour old. To the
student, the click did nothing.

The fix is to say, in the Server Function, that the cached entry is out of date. **`updateTag('planner')`**
expires every entry tagged `planner` at once, so the page this Action re-renders fetches the planner
again. It replaces `refresh()` in both functions of `app/actions.ts`:

```
ana@dev:~/planner-next$ sed -i 's/import { refresh } from .next\/cache./import { updateTag } from '\''next\/cache'\''/; s/^  refresh()/  updateTag('\''planner'\'')/' app/actions.ts && grep -n 'updateTag\|refresh' app/actions.ts
3:import { updateTag } from 'next/cache'
20:  updateTag('planner')
46:  updateTag('planner')
ana@dev:~/planner-next$ npm run build > /dev/null && echo built
built
ana@dev:~/planner-next$ look 'http://localhost:3000/?week=2026-10-19' --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 2000' | grep -E 'minutes done|Statistics ·'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 120 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min" [pressed]
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/statistics | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'
90 of 90 minutes done
```

**120 minutes, and the button pressed.** And the course page, built as a static file at build time,
says 90 of 90, Monday's 50 and Wednesday's 40: it was made from the tagged entry, so it went out of
date with it and was rendered again on the next request.

Next.js has three ways to say a cached entry is out of date, and they answer different questions:

| call | where | what the next reader gets |
|---|---|---|
| `updateTag(tag)` | only in a Server Function | fresh data at once: for the person who just made the change |
| `revalidateTag(tag, 'max')` | a Server Function or a route handler | the old entry once more, while a fresh one is fetched behind it |
| `cacheLife(…)` | inside the cached function | whatever the time limits say, with no call at all |

The planner uses the first, because every change it makes is the student's own. A catalogue that an
editor updates for thousands of readers would use the second, so that no reader waits for the fetch.
And the `curl` from the last section, a change made outside Next.js entirely, is covered only by the
third: for it, the hour stands.
