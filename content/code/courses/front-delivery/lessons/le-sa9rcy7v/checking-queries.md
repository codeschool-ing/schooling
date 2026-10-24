---
title: Checking every query against the schema
version: 1
---

**A query is a string, so TypeScript cannot see a misspelt field in it, and the first to notice would be
the server, at run time, in front of a user.** The schema is in the repository, though, and the `graphql`
package that runs the server can also check a query against it without running anything. A test that
does that for every operation the planner sends finds the mistake on the computer where it was made, and
in lesson 3's pipeline before a deploy.

```typescript
// src/queries.test.ts
import { buildSchema, parse, validate } from "graphql";
import { expect, test } from "vitest";
import schemaSource from "../api/schema.graphql?raw";
import { MARK_DONE, PLANNER } from "./queries";

const schema = buildSchema(schemaSource);

test.each([
  ["Planner", PLANNER],
  ["MarkDone", MARK_DONE],
])("%s is valid against the schema", (_name, query) => {
  expect(validate(schema, parse(query)).map((error) => error.message)).toEqual([]);
});
```

`?raw` is Vite's way of importing a file's text as a string, and Vitest understands it as Vite does.
`parse` turns a query into a tree and fails on bad syntax; `validate` checks the tree against the schema
and returns a list of errors, empty when the query is sound.

```
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep -E 'Test Files|Tests'
 Test Files  2 passed (2)
      Tests  7 passed (7)
```

Commit the lesson's work, with the schema, the server and the client together:

```
ana@dev:~/planner$ git add -A && git commit -qm "Read and save sessions through GraphQL when VITE_GRAPHQL_URL is set"
```

## Watching it catch one

Rename a field in the fragment, the way a hurried edit would, and run the tests again:

```
ana@dev:~/planner$ sed -i 's/    minutes$/    minute/' src/queries.ts
ana@dev:~/planner$ npm test 2>&1 | grep -E 'Cannot query|Tests'
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 2 ⎯⎯⎯⎯⎯⎯⎯
+   "Cannot query field \"minute\" on type \"Session\". Did you mean \"minutes\"?",
      Tests  2 failed | 5 passed (7)
```

Both operations fail, because both spread the fragment, and the message names the field and suggests the
one that exists. Put it back as it was committed:

```
ana@dev:~/planner$ git restore src/queries.ts
ana@dev:~/planner$ git status --short
```

## What it does not check

It checks the queries against **the schema file in this repository**. If the team that runs the server
changes the real schema and nobody updates the file, the test passes and the planner breaks. Larger teams
close that gap by downloading the schema from the server in the pipeline, or by publishing it as a
package with versions, as lesson 7 published the design system.

It also does not check the TypeScript types written by hand in `api.ts` against the fields asked for.
That is what code generators such as GraphQL Code Generator do: they read the schema and the queries and
write the types, so a field removed from a query is a type error wherever the code used it.
