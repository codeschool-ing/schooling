---
title: The planner loads its data
version: 1
---

**The planner stops carrying its courses in the component and reads them from a file the dev server
serves, into refs.** Three courses and six study sessions, all in October 2026, in one JSON file. This
is the data every later lesson uses, and the planners of the other three framework courses in the track
read the same shape.

## The file

Anything in the project's `public` folder is served as it is, at the root of the address. Save this as
`public/courses.json` in the planner:

```schooling-example
{"language": "json", "file": "public/courses.json", "parts": [
 {"code": "{\n  \"courses\": [\n    { \"id\": \"statistics\", \"title\": \"Statistics\", \"goal\": 180 },\n    { \"id\": \"spanish\", \"title\": \"Spanish\", \"goal\": 120 },\n    { \"id\": \"guitar\", \"title\": \"Guitar\", \"goal\": 90 }\n  ],", "note": "Each course has an id, which is what a session points at, a title for people, and a weekly goal in minutes."},
 {"code": "  \"sessions\": [\n    { \"id\": \"s1\", \"course\": \"statistics\", \"date\": \"2026-10-12\", \"minutes\": 50, \"done\": true },\n    { \"id\": \"s2\", \"course\": \"statistics\", \"date\": \"2026-10-19\", \"minutes\": 45, \"done\": true },\n    { \"id\": \"s3\", \"course\": \"spanish\", \"date\": \"2026-10-19\", \"minutes\": 30, \"done\": true },\n    { \"id\": \"s4\", \"course\": \"statistics\", \"date\": \"2026-10-21\", \"minutes\": 60, \"done\": false },\n    { \"id\": \"s5\", \"course\": \"guitar\", \"date\": \"2026-10-22\", \"minutes\": 20, \"done\": false },\n    { \"id\": \"s6\", \"course\": \"spanish\", \"date\": \"2026-10-23\", \"minutes\": 40, \"done\": false }\n  ]\n}", "note": "Six sessions: one in the week of 12 October and five in the week of 19 October, three of them done. Dates are written YYYY-MM-DD, which sorts as text in date order."}
]}
```

## The component

`App.vue` now starts with two empty refs and fills them when the file arrives:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')", "note": "Two refs, empty to begin with, and a third for an error message. The template draws whatever they hold, so it draws an empty list first."},
 {"code": "fetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    sessions.value = data.sessions\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n</script>", "note": "The request starts during setup, which runs once. When the data arrives, assigning `.value` redraws everything that read the refs. `javascript` lesson 16 covers `fetch` and why a status check comes first."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>{{ courses.length }} courses, {{ sessions.length }} sessions planned</p>\n  </header>\n  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in courses\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>Goal: {{ course.goal }} minutes a week</p>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>", "note": "`v-if`, `v-else-if` and `v-else` choose one of three paragraphs. Lesson 5 is about them; here they say loading, failed or loaded."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "The style is unchanged from lesson 1."}
]}
```

With the planner's dev server running (stop the sandbox's first, or it will have taken port 5173):

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --network
net  GET /  200
net  GET /src/main.js  200
net  GET /src/App.vue  200
net  GET /node_modules/.vite/deps/vue.js?v=74705bde  200
net  GET /src/App.vue?vue&type=style&index=0&scoped=7a7a37b1&lang.css  200
net  GET /@id/__x00__plugin-vue:export-helper  200
net  GET /src/components/AppFooter.vue  200
net  GET /@vite/client  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
net  GET /node_modules/vite/dist/client/env.mjs  200
[vite] connecting...
net  GET /courses.json  200
[vite] connected.
== the text of #app
Study planner

3 courses, 6 sessions planned

Statistics

Goal: 180 minutes a week

Spanish

Goal: 120 minutes a week

Guitar

Goal: 90 minutes a week

Built with Vue 3.5.44
```

The request for `/courses.json` is the last one, after every module of the page: the component had
to exist before its setup could ask for anything. **In the gap, the page said "Loading…"**, which is
why the header has three states and not one.

## The failure that answers 200

Move the file away and load the page again:

```
ana@dev:~/vue/planner$ mv public/courses.json /tmp/courses.json
ana@dev:~/vue/planner$ look http://localhost:5173/
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

Could not load the courses: Unexpected token '<', "<!DOCTYPE "... is not valid JSON

Built with Vue 3.5.44
ana@dev:~/vue/planner$ curl -si http://localhost:5173/courses.json | head -n 3
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
ana@dev:~/vue/planner$ mv /tmp/courses.json public/
```

The error is not "not found". **The dev server answered 200 with the HTML of the page**, because an
application with its own routes (lesson 12) wants every unknown address to load the application, and
Vite does that for anything it does not have. So `response.ok` was true, and `response.json()` failed
on the first character, `<`. The message names it, `"<!DOCTYPE "... is not valid JSON`, and that
phrase is worth recognising: **it means the request reached a page instead of the data**, nearly
always because the address is wrong.

Put the file back with `mv /tmp/courses.json public/`, and the page shows the courses again.

## What changed and what did not

The template is the same template, and the list is drawn by the same `v-for`. What changed is that
`courses` is a ref, so the template read `courses.value` without saying so, and was drawn again when
the value was replaced. The header counts the sessions as well as the courses, and the planner does
nothing with them yet. Lesson 3 adds up the week from them.
