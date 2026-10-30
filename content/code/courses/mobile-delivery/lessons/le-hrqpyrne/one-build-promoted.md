---
title: One build, promoted
version: 1
---

**The build that reaches production is the build your testers tried, byte for byte.** It is
uploaded once, with its own version code, and then **promoted** from track to track: the store
moves the same file to a wider audience. A team that rebuilds at the top of the ladder ships a
binary nobody tested, built from whatever the branch looked like that morning, and the beta tested
something else.

Both stores make the rule hard to break. **A version code, once uploaded, can never be uploaded
again** on Google Play, and an iOS build number is unique within its version. Lesson 9 is about
those numbers; here they are what makes "the same build" checkable.

## The tracks as a script

The rules of the last two sections fit in a page of TypeScript: each track holds one version code,
an upload refuses a code already used, a promotion copies a code upward, and a person gets the
highest code among the tracks they belong to. Three people are on the planner's tracks: Ana is on
the team, on internal and closed; Bruno is a student on the closed beta; Carla only has the store
version. Save this as `tracks.ts`:

```schooling-example
{"language": "typescript", "file": "tracks.ts", "parts": [{"code": "// tracks.ts: Google Play's testing tracks as data, and which build each person gets\ntype Track = \"internal\" | \"closed\" | \"open\" | \"production\";\nconst onTrack = new Map<Track, number>();\nconst used = new Set<number>();", "note": "Each track holds one version code. `used` remembers every code ever uploaded, on any track."}, {"code": "function upload(code: number, track: Track) {\n  if (used.has(code)) return console.log(`upload ${code} to ${track}: refused, version code already used`);\n  used.add(code);\n  onTrack.set(track, code);\n  console.log(`upload ${code} to ${track}`);\n}", "note": "An upload with a code that was ever used is refused, whatever the track."}, {"code": "function promote(from: Track, to: Track) {\n  const code = onTrack.get(from)!;\n  onTrack.set(to, code);\n  console.log(`promote ${code} from ${from} to ${to}`);\n}", "note": "A promotion uploads nothing: the same code is placed on a wider track."}, {"code": "const people: [string, Track[]][] = [\n  [\"Ana\", [\"internal\", \"closed\", \"production\"]],\n  [\"Bruno\", [\"closed\", \"production\"]],\n  [\"Carla\", [\"production\"]],\n];\nfunction show() {\n  for (const [who, tracks] of people) {\n    const codes = tracks.flatMap((t) => (onTrack.has(t) ? [onTrack.get(t)!] : []));\n    console.log(`    ${who.padEnd(6)} gets ${Math.max(...codes)}`);\n  }\n}", "note": "Each person sees the highest code among the tracks they are on."}, {"code": "upload(41, \"internal\"); promote(\"internal\", \"closed\"); promote(\"closed\", \"production\"); show();\nupload(42, \"closed\"); show();\nupload(43, \"internal\"); show();\nupload(42, \"production\"); promote(\"closed\", \"production\"); show();", "note": "Four moments in the planner's month, in order."}]}
```

```
ana@dev:~/planner$ node tracks.ts
upload 41 to internal
promote 41 from internal to closed
promote 41 from closed to production
    Ana    gets 41
    Bruno  gets 41
    Carla  gets 41
upload 42 to closed
    Ana    gets 42
    Bruno  gets 42
    Carla  gets 41
upload 43 to internal
    Ana    gets 43
    Bruno  gets 42
    Carla  gets 41
upload 42 to production: refused, version code already used
promote 42 from closed to production
    Ana    gets 43
    Bruno  gets 42
    Carla  gets 42
```

Read it from the top:

- **Build 41 climbs the ladder by promotion**, and all three people have it.
- **Build 42 goes straight to the closed track**, and Ana gets it even though the internal track
  still holds 41: she is on both, and 42 is higher.
- **Build 43 is the team's fix**, on internal only, so Ana has it and the students do not.
- **The rebuilt 42 is refused.** Somebody built the beta's code again and tried to upload it to
  production; the code is taken. The right move is the last line: promote the 42 that Bruno has been
  using, and Carla gets it.

## On iOS

TestFlight and the App Store work the same way with different words. A build is uploaded once to
App Store Connect, tested in TestFlight, and the **same build** is then chosen for the App Store
version and submitted for review. Nothing is rebuilt, and Xcode's archive of that build is kept,
because lesson 13 needs its symbols to read the crashes it produces.

## In a pipeline

The pipeline of lesson 10 builds **once**, on the commit being released, uploads to the lowest
track, and from there every step is a promotion triggered by a person. Fastlane, in lesson 11, has
an action for exactly this: `upload_to_play_store` with `track_promote_to`, which moves a release
without uploading anything.
