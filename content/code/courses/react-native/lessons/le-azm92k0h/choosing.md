---
title: Four stores, for four kinds of thing
version: 1
---

**Everything in memory is gone when the app is closed**, and on a phone the system closes apps without
asking, to free memory for the one in front. Whatever the planner should still know next time has to be
written somewhere. React Native has no single answer, because the things worth keeping are not one kind
of thing:

| store | holds | read | for |
|---|---|---|---|
| AsyncStorage | strings under keys | asynchronously | a cache, a setting, a draft: small things read once |
| MMKV | strings, numbers, booleans under keys | synchronously, in microseconds | a value needed before the first frame |
| SQLite | tables and rows | with SQL queries | records you count, filter, sort and join |
| SecureStore | short strings under keys | asynchronously | secrets: a token, a key |

Lesson 13's file system is the fifth place, for files.

**The question that picks the store is what you will ask of the data.** "Give me back what I saved" is a
key-value store. "Which course did I study most this month" is a query, and a key-value store would make
you load everything and add it up yourself. "Is this safe if the phone is stolen" is the secure store,
and nothing else.

Two things are true of all of them. **They belong to the app**: no other app can read them, and
uninstalling deletes them, so none of them is a backup. **And they belong to the phone**: nothing here
reaches the person's other devices, which is the server's job. This lesson uses each of the four for what
it is for, and says where the line is.
