---
title: Route parameters, as inputs
version: 1
---

**A route parameter is part of the address that changes from one visit to the next, and with input
binding it reaches the component as an input.** `courses/:courseId` gives `CoursePage` its
`courseId`, the same input lesson 8 set by hand with `courseId="javascript"`. The component does not
know, or need to know, where the value came from, which is why it did not change.

A parameter the planner has no course for:

```
ana@dev:~/planner$ look http://localhost:4200/courses/rust --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
There is no course called rust.
```

The address matched the route, the input was `rust`, and `course()` found nothing, so the page says
so with lesson 8's last branch. A typo in a URL is a normal event, and the page treats it as one.

## The parameter can change under a component

**The router reuses a component when the next address matches the same route.** Going from
`/courses/git` to `/courses/javascript` keeps the same `CoursePage` and sets a new `courseId`. With
an input and `computed`, that is nothing to think about: `course()` reads `courseId()`, so it
follows. Code written before input binding reads the parameter from `ActivatedRoute`, and often
like this:

```typescript
export class OldCoursePage implements OnInit {
  private readonly route = inject(ActivatedRoute);
  courseId = '';

  ngOnInit(): void {
    this.courseId = this.route.snapshot.paramMap.get('courseId') ?? '';
  }
}
```

`snapshot` is the parameter at the moment `ngOnInit` ran, once. When the router reuses the
component for another course, `ngOnInit` does not run again, and the page goes on showing the first
course under the second one's address. The fix in such code is `route.paramMap`, an Observable that
emits every change; the fix this course uses is the input, which is a signal and cannot be read
stale.

| how a component gets `courseId` | follows a change of course |
|---|---|
| an input, with `withComponentInputBinding()` | yes |
| `route.paramMap`, subscribed | yes |
| `route.snapshot.paramMap`, read once | no |
