---
title: Save ids, not objects, and weigh what you save
version: 1
---

**Saved state is small on purpose, and the way to keep it small is to save the id of each thing on
the screen, never the thing itself.** The tempting version is to save the object the screen is
showing, the whole course with its sessions, because then nothing has to be looked up after a
restore. It works in testing, with a plan of four sessions. Then a user with a real plan meets the
limit, and on Android the limit is an exception.

## Measure it

The third mode of `restore.ts` builds a plan of 2,000 generated sessions, a few years of a busy
student, and saves the same screen two ways: as the ids the previous section saved, and with the
open course and the whole plan inside the saved state.

```
ana@dev:~/planner$ node restore.ts sizes
ids only:       80 bytes
the whole plan: 157479 bytes, 153.8 KiB, 1968 times as much
```

**80 bytes against 157,479, almost two thousand times as much, for the same screen.** The 80 do not
grow with the plan: a student with twenty sessions and one with twenty thousand save the same id,
the same scroll position and the same draft. The whole-plan version grows with every session the
user ever adds, which means it is fine on the developer's phone and fails on the phones of the users
who use the app most.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l05-sizes\" aria-label=\"Two bars measuring the same screen's saved state. Saved as ids: 80 bytes, too small to see at this scale. Saved with the whole plan of 2,000 sessions inside: 157,479 bytes. A mark shows 50 KB, the most Android's guide recommends for saved state; the whole plan is about three times over it.\"><defs><marker id=\"l05-sizes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"34\" width=\"1\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ids only: 80 bytes</text><rect x=\"20\" y=\"78\" width=\"600\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the whole plan: 157,479 bytes</text><path d=\"M215 62 L215 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M215 120 L215 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l05-sizes-ah-phosphor)\"></path><text x=\"215\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Android's guide: under 50 KB</text></svg>", "caption": "The same screen, saved two ways. Measured with node restore.ts sizes; the 50 KB mark is from Android's guide to Parcelables and Bundles, read on 30 October 2026."}
```

## What Android does with a large saved state

Android's guide to Parcelables and Bundles, read on 30 October 2026, puts numbers on it:

- saved state travels through the Binder transaction buffer, which "has a limited fixed size,
  currently 1MB", shared by every transaction in progress for the whole process, not per screen;
- when that limit is exceeded, the system throws a `TransactionTooLargeException`, and from Android
  7.0 it is thrown "as a runtime exception", which ends the app;
- for saved state specifically, "We recommend that you keep saved state to less than 50KB of data",
  because the system process holds that data for as long as the user can navigate back to the
  screen, even after the app's process is killed.

**157,479 bytes is about three times the recommendation**, and it is shared with everything else the
app is passing through the same buffer at that moment. The guide's advice in its saving-state page
is the same rule this section's title gives: store "a minimal amount of data necessary, such as an
ID", and reload the rest from where the data lives.

**iOS gives no number, and says the same thing.** Apple's page for `@SceneStorage` asks for
lightweight data, says that "data of a large size, such as model data, should not be stored" there,
and warns that "poor performance may result". React Native has no limit at all, which is the danger
the previous section named: the app can write a whole plan into its own storage on every trip to the
background, and nothing will stop it until the save is too slow to finish in the time the system
allows.

## Why ids are also more correct

**A saved object is a copy, and a copy can be wrong by the time it is read.** If the planner saved
the course object and the user renamed the course on another device, the restore would draw the old
title. Saving `courseId` and looking the course up in the data draws whatever the data says now; the
previous section's restore did exactly that, taking the title from the plan.

**And an id can point at nothing.** A course deleted while the app was dead leaves a saved id with no
course behind it. `restore.ts` refuses that case loudly instead of drawing an empty screen; a real
app would fall back to the course list and say why. Either way the case is handled on purpose, which
is the difference between saving ids and saving copies: with ids, staleness is a lookup that fails
where you can see it, rather than an old copy drawn as if it were current.

Lesson 6 moves from what the system takes away to what the app does with the time it has, starting
with the one thread every screen is drawn on.
