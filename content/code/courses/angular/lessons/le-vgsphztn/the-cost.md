---
title: What a component library costs, and when it pays
version: 1
---

**A library is code the browser downloads.** The same build as at the start of the lesson:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'Initial total|courses-routes'
                      | Initial total  | 294.50 kB |                81.56 kB
chunk-RJNJDY6E.js     | courses-routes |  44.80 kB |                10.34 kB
```

The first download grew by about 20 kB, most of it the theme's styles, which every page needs. The
course area's chunk grew from 45 kB to 197 kB: the checkbox, the dialog and the parts of the CDK they
bring are used only on a course's pages, so they went into its lazy chunk, and a visit to the week
alone does not download them. Lesson 18's split is paying for itself here.

| choose | when |
|---|---|
| Angular Material | the application can look like Material, and you want its components finished, accessible and maintained by somebody else |
| the CDK, with your own styles | the application has its own design, and you want the behaviour of hard controls without the look |
| your own components | the control is simple, and a native element styled with CSS does the job, as every control in the planner did until this lesson |

**What not to do is half of each**: a Material component restyled until it looks like something else
fights its own theme on every update. Material's theme is its CSS custom properties, the ones
`mat.theme` wrote, and changing those is the supported way to make it yours.

```
ana@dev:~/planner$ git status --short
 M angular.json
 M package-lock.json
 M package.json
 M src/index.html
?? src/material-theme.scss
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Material and the CDK: a checkbox, a dialog, an announcement"
```
