---
title: Three packages
version: 1
---

**The library comes in three parts, and the planner uses all three.** `@testing-library/dom` holds the
queries and works on any DOM, with or without a framework, which is why this course can use it on a
plain TypeScript page; each framework's own version, such as `@testing-library/react`, is this package
with a `render` for that framework's components. `@testing-library/user-event` acts like a person:
it types a key at a time and clicks with the pointer. `@testing-library/jest-dom` adds matchers to
`expect`, such as `toBeInTheDocument` and `toHaveAccessibleName`, that read like the sentence they
check.

```
ana@dev:~/planner$ npm install --save-exact -D @testing-library/dom@10.4.2 @testing-library/user-event@14.6.8 @testing-library/jest-dom@7.0.1

added 22 packages, and audited 111 packages in 5s

found 0 vulnerabilities
```

`jest-dom` began as a Jest library, and despite the name it has a module for Vitest:
`import "@testing-library/jest-dom/vitest"` at the top of a test file adds the matchers to Vitest's
`expect`. That is all the setup there is.
