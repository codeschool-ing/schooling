---
title: The first screen of the planner
version: 1
---

**The planner's first screen lists your courses, and it is written in `App.vue` and one more
component.** Everything on it is still fixed text. Lesson 2 makes it reactive, and loads the courses
from a file instead of writing them into the component.

Replace `src/App.vue` with this:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport AppFooter from './components/AppFooter.vue'\n\nconst title = 'Study planner'\nconst courses = [\n  { id: 'statistics', title: 'Statistics', goal: 180 },\n  { id: 'spanish', title: 'Spanish', goal: 120 },\n  { id: 'guitar', title: 'Guitar', goal: 90 },\n]\n</script>", "note": "The script declares what the template reads. A `const` declared in `<script setup>` is visible in the template by name, with no `return` and no export."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p>{{ courses.length }} courses this term</p>\n  </header>", "note": "Double braces put a value in the text. The expression inside is JavaScript, so `courses.length` works."},
 {"code": "  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in courses\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>Goal: {{ course.goal }} minutes a week</p>\n      </li>\n    </ul>\n  </main>", "note": "`v-for` repeats the element once per course. Lesson 5 is about it, and about `:key`, which tells Vue which item is which."},
 {"code": "  <AppFooter />\n</template>", "note": "An imported component is used as a tag. Its name in the template is the name you imported it under."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "`scoped` keeps these rules inside this component. The next section shows how."}
]}
```

And make the folder `src/components` with the footer in it:

```schooling-example
{"language": "html", "file": "src/components/AppFooter.vue", "parts": [
 {"code": "<script setup>\nimport { version } from 'vue'\n</script>\n\n<template>\n  <footer>\n    <p>Built with Vue {{ version }}</p>\n  </footer>\n</template>", "note": "`version` is exported by Vue itself: the version running in the page."},
 {"code": "<style scoped>\np {\n  color: #666;\n  font-size: 0.875rem;\n}\n</style>", "note": "A rule for `p` in this file, and a different one in `App.vue`. Each applies only in its own component."}
]}
```

Save both, and the page in your browser changes without a reload. In the terminal:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

3 courses this term

Statistics

Goal: 180 minutes a week

Spanish

Goal: 120 minutes a week

Guitar

Goal: 90 minutes a week

Built with Vue 3.5.44
```

**The footer says 3.5.44**, which is the Vue in `package.json` and in the lockfile. That is the first
sentence this course could not have written for you: it is your project reporting on itself.

## What a component is, so far

`AppFooter.vue` is a component, and so is `App.vue`. **A component is a piece of the screen with its
own markup, its own state and its own styles**, used by name inside another one. The planner will
grow a component for each thing on the screen that has a job of its own: a course card in lesson 6, a
panel with slots in lesson 7, a form in lesson 14.

The names follow a convention. **A component's file is named in PascalCase, and so is the tag.**
`AppFooter` has two words because one-word names like `Footer` collide with the HTML elements that
exist or might exist one day, and the Vue style guide asks for two.
