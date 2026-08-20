---
title: A table is for data, not for layout
---

A table exists for tabular data — something with rows, columns and meaning in both. A well-marked table tells the screen reader which column each cell belongs to, and the person can navigate between them:

```html
<table>
  <caption>Marks for the term</caption>
  <thead>
    <tr><th scope="col">Student</th><th scope="col">Mark</th></tr>
  </thead>
  <tbody>
    <tr><th scope="row">Ana</th><td>9.0</td></tr>
  </tbody>
</table>
```

`scope` is what makes the difference: without it, the screen reader reads "9.0" without saying whose or of what. With it, it reads "Ana, Mark, 9.0".

Using a table to position things on screen was normal in the 1990s and today is a mistake: it creates false data structure, and Flexbox and Grid do it better. Layout is the next half of the course.
