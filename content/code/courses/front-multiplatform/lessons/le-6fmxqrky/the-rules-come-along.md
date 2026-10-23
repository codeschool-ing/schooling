---
title: The planner's rules come along
version: 1
---

**`src/planner.ts` goes into the native app as it is, byte for byte**, and so does the data. Copy both
from the planner, and check that the copy is the same file:

```
ana@dev:~/planner-native$ mkdir src
ana@dev:~/planner-native$ cp ../planner/src/planner.ts ../planner/public/courses.json src/
ana@dev:~/planner-native$ cp ../planner/look.mjs .
ana@dev:~/planner-native$ cmp ../planner/src/planner.ts src/planner.ts && echo identical
identical
```

`cmp` prints nothing when two files are identical, which is why `&& echo identical` is there. A copy is
the simplest way to share one file between two projects. A team with several apps would keep the rules
in a package of their own, in a monorepo, so both apps import one file; the point here is only that the
file needs no change at all.

Now replace `App.tsx` with the planner's screen. It is one component, which lesson 8 splits into screens:

```schooling-example
{"language": "typescript", "file": "App.tsx", "parts": [{"code": "// App.tsx: the planner's screen, drawn with React Native's own components.\nimport { useState } from \"react\";\nimport { Pressable, StyleSheet, Text, View } from \"react-native\";\nimport { markDone, mondayOf, weekTotal, type Plan } from \"./src/planner\";\nimport data from \"./src/courses.json\";\n", "note": "React Native's components come from `react-native`, not from the DOM, and the planner's rules and data from the two files copied from `~/planner`. Importing JSON works as it does with Vite."}, {"code": "// The transcripts open the web build with ?today=2026-10-21, as lesson 1 does.\nconst query = typeof location === \"undefined\" ? \"\" : location.search;\nconst today = new URLSearchParams(query).get(\"today\") ?? new Date().toISOString().slice(0, 10);\n", "note": "On a phone there is no address bar, so `location` does not exist; the check keeps the `?today=` of lesson 1 working in the browser and falls back to the real date everywhere else."}, {"code": "export default function App() {\n  const [plan, setPlan] = useState<Plan>(data);\n  const [open, setOpen] = useState<string | null>(null);\n  const total = weekTotal(plan, mondayOf(today));\n  return (\n    <View role=\"main\" style={styles.screen}>\n      <Text role=\"heading\" style={styles.title}>Study planner</Text>\n      <Text>This week: {total.done} of {total.planned} minutes done</Text>\n      {plan.courses.map((course) => (\n        <View key={course.id}>\n          <Pressable role=\"button\" onPress={() => setOpen(open === course.id ? null : course.id)}>\n            <Text style={styles.course}>{course.name}</Text>\n          </Pressable>\n          {open === course.id &&\n            plan.sessions.filter((s) => s.course === course.id).map((s) => (\n              <View key={s.id} style={styles.row}>\n                <Text>{s.date}, {s.minutes} min</Text>\n                {s.done ? <Text>done</Text> : (\n                  <Pressable role=\"button\" onPress={() => setPlan(markDone(plan, s.id))}>\n                    <Text style={styles.action}>Mark done</Text>\n                  </Pressable>\n                )}\n              </View>\n            ))}\n        </View>\n      ))}\n    </View>\n  );\n}\n", "note": "The component. Two pieces of state, the plan and the open course, and the week's total worked out from them on every draw by `weekTotal`, unchanged. Pressing a course opens or closes it; pressing **Mark done** replaces the plan with the one `markDone` returns. `role` tells assistive technology what each element is, as `<h1>` and `<button>` did on the web."}, {"code": "const styles = StyleSheet.create({\n  screen: { flex: 1, padding: 24, gap: 8 },\n  title: { fontSize: 28, fontWeight: \"700\" },\n  course: { fontSize: 20, paddingVertical: 8 },\n  row: { flexDirection: \"row\", gap: 12, paddingLeft: 16 },\n  action: { color: \"#0a58ca\" },\n});", "note": "Styles are JavaScript objects, with names that look like CSS in camelCase and numbers without units. Lesson 8 is about what is and is not there."}]}
```

Check the types, which also checks that the planner's functions are called the way `planner.ts`
declares them:

```
ana@dev:~/planner-native$ npx tsc --noEmit
```

**No output is the pass.** Then export the app for the web, serve the export as a static host would, and
open it with `look.mjs`, copied from the planner too:

```
ana@dev:~/planner-native$ npx expo export --platform web > /dev/null
ana@dev:~/planner-native$ ls dist
_expo
favicon.ico
index.html
metadata.json
```

```
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- main:
  - heading "Study planner" [level=1]
  - text: "This week: 75 of 125 minutes done"
  - button "Spanish A2"
  - button "Statistics"
  - button "Guitar"
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click 'Spanish A2' --click 'Mark done'
- main:
  - heading "Study planner" [level=1]
  - text: "This week: 105 of 125 minutes done"
  - button "Spanish A2"
  - text: 2026-10-19, 30 min done 2026-10-22, 30 min done
  - button "Statistics"
  - button "Guitar"
```

**The week is the planner's week**: 75 of 125, then 105 of 125 after marking the Spanish session of
22 October done, the same numbers lesson 4 printed, from the same function. What drew them is
different. In the web build, `react-native-web` turned `<Text>` into HTML; on a phone the same
component would be a native label. The `role` props are why the tree still says `heading` and `button`:
without them, a `<Pressable>` is a box that takes touches and tells a screen reader nothing about it.

Commit it, in the repository `create-expo-app` made:

```
ana@dev:~/planner-native$ git add . && git commit -q -m "The planner, drawn with React Native" && git log --oneline
174d42d The planner, drawn with React Native
a56282e Initial commit
```
