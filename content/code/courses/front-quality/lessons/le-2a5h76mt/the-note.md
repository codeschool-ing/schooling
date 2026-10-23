---
title: A note on each session, written the quick way
version: 1
---

**The planner gains a feature this lesson: a note on a study session**, a line or two about what to
cover. Notes have line breaks, and the quickest way to keep them on the page is to turn each `\n` into a
`<br>` and write the result with `innerHTML`. That is exactly how cross-site scripting gets into
applications: not by anybody deciding to allow it, but by a line written to keep some formatting.

Here is the feature, in three files. A session may carry a `note`; `addSession` takes one; and the
course page shows it and has a field for it:

```
ana@dev:~/planner$ git diff src/planner.ts src/view.ts
diff --git a/src/planner.ts b/src/planner.ts
index 979e7ab..80218df 100644
--- a/src/planner.ts
+++ b/src/planner.ts
@@ -10,6 +10,7 @@ export interface Session {
   date: string;
   minutes: number;
   done: boolean;
+  note?: string;
 }
 
 export interface Plan {
@@ -17,14 +18,15 @@ export interface Plan {
   sessions: Session[];
 }
 
-export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
+export function addSession(plan: Plan, course: string, date: string, minutes: number, note = ""): Plan {
   if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
   if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
   if (!Number.isInteger(minutes) || minutes < 1 || minutes > 600) {
     throw new Error(`minutes must be a whole number from 1 to 600, not ${minutes}`);
   }
   const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;
-  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
+  const session = { id, course, date, minutes, done: false, ...(note ? { note } : {}) };
+  return { ...plan, sessions: [...plan.sessions, session] };
 }
 
 export function markDone(plan: Plan, id: number): Plan {
diff --git a/src/view.ts b/src/view.ts
index 31c6742..52e94e0 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -33,16 +33,23 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
       tick.addEventListener("click", () => update(markDone(plan, s.id)));
       item.append(tick);
     }
+    if (s.note) {
+      const note = el("p", "", "note");
+      note.innerHTML = s.note.replace(/\n/g, "<br>");
+      item.append(note);
+    }
     list.append(item);
   }
   const form = el("form", "", "add");
   form.innerHTML = `<label>Date <input name="date" type="date"></label>
     <label>Minutes <input name="minutes" type="number" min="1" max="600"></label>
+    <label>Note <textarea name="note"></textarea></label>
     <button>Add session</button>`;
   form.addEventListener("submit", (event) => {
     event.preventDefault();
     const data = new FormData(form);
-    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes"))));
+    const note = String(data.get("note") ?? "");
+    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes")), note));
   });
   root.append(list, form, el("p", `This week: ${weekTotal(plan, day, course.id)} min`, "week"));
 }
```

**Read the line with `innerHTML`.** It writes the note into the page as markup, so whatever markup the
note contains is built. A note is text a person typed, and later, when sessions are kept on the server,
text that came from somewhere else. A test of the feature says what it must do, in the terms of lesson
3: a note appears as the text that was typed. Add it to the end of `src/view.test.ts`:

```typescript
// src/view.test.ts, below what is there
test("a note is shown as the text that was typed", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.type(screen.getByLabelText("Date"), "2026-10-23");
  await user.type(screen.getByLabelText("Minutes"), "15");
  await user.type(screen.getByLabelText("Note"), "chapter <b>3</b>, again");
  await user.click(screen.getByRole("button", { name: "Add session" }));
  expect(screen.getByText("chapter <b>3</b>, again")).toBeInTheDocument();
});
```

**The witness is `<b>`**, the plainest markup there is. If the page shows the characters `<b>3</b>`, the
note stayed text. If it shows a bold **3**, the page built an element out of what a person typed, and it
would have built any other element just the same, a script included. No script is needed to prove it, and none is used.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts 2>&1 | grep -E -A3 "^ FAIL|Unable to find|class=\"note\""
 FAIL  src/view.test.ts > a note is shown as the text that was typed
TestingLibraryElementError: Unable to find an element with the text: chapter <b>3</b>, again. This could be because the text is broken up by multiple elements. In this case, you can provide a function for your text matcher to make your matcher more flexible.

Ignored nodes: comments, script, style
<body>
--
          class="note"
        >
          chapter 
          <b>
```

**Red, and the dump shows why**: the paragraph holds `chapter `, then a `<b>` element. The page built an
element from the note. Commit the flawed version as it is, so the fix is a diff of its own:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A note on each session"
```
