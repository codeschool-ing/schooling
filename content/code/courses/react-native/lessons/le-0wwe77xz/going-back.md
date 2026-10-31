---
title: Going back, which Android asks of every app
version: 1
---

**The stack gives back for free.** On iOS, the header's back button and a swipe from the left edge pop
the top screen; on Android, the system back action does, from the navigation bar or a swipe from either
edge in gesture navigation. On the web, the browser's back button moves through the same history,
because the `NavigationContainer` keeps the address bar in step. Nothing in the planner had to be
written for any of it.

## When back must ask first

Lesson 11 adds a form to add a session. Going back from a half-filled form would discard it, and a person
who pressed back by accident loses their typing. React Navigation's answer is an event fired *before* a
screen is removed, which the screen can stop:

```tsx
useEffect(() => {
  return navigation.addListener("beforeRemove", (e) => {
    if (!dirty) return;            // nothing typed: let it go
    e.preventDefault();            // stop the navigation
    Alert.alert("Discard this session?", "", [
      { text: "Keep editing", style: "cancel" },
      { text: "Discard", style: "destructive", onPress: () => navigation.dispatch(e.data.action) },
    ]);
  });
}, [navigation, dirty]);
```

`beforeRemove` covers every way of leaving, the header button, the swipe and Android's back, which is why
it is better than listening to Android's `BackHandler` directly. `BackHandler` remains for the rare screen
that is not in a navigator at all. Lesson 11 writes this listener for real.

## Back is not always "the previous screen"

On a tab, Android's back returns to the first tab, then leaves the app, which is the platform's
convention. On a screen opened from a notification, there may be no previous screen at all. And after a
sign-in, back should not return to the sign-in form. Each of these is a decision about the stack's
contents, made with `navigation.reset` or by choosing what to push, and the rule to keep in mind is the
person's: **back goes where they came from, or out.**

*Android's back action and the iOS swipe were not tried on a device for this course*; the web build's
history was, through the back link a pushed screen shows in its header.
