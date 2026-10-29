---
title: A server to ask
version: 1
---

**A GraphQL server is a schema, a function for each field that is not plain data, and an HTTP endpoint
that takes a query and returns JSON.** The one this lesson uses is built on `graphql`, the reference
implementation the GraphQL Foundation maintains in JavaScript, with Node's own HTTP server around it. It
keeps the planner's sessions in memory, starting from `public/courses.json`, so every restart begins from
the same six sessions.

Install the package in the planner, pinned:

```
ana@dev:~/planner$ npm install --save-dev --save-exact graphql@17.0.2 2>&1 | tail -1
found 0 vulnerabilities
```

**graphql 17.0.2**. It goes in `devDependencies` because the planner's build does not ship it to the
browser: the server uses it here, and the test at the end of the lesson uses it to check queries.

```schooling-example
{"language": "javascript", "file": "api/server.mjs", "parts": [
 {"code": "// api/server.mjs\nimport { readFileSync } from \"node:fs\";\nimport { createServer } from \"node:http\";\nimport { buildSchema, graphql } from \"graphql\";\n\nconst schema = buildSchema(readFileSync(new URL(\"schema.graphql\", import.meta.url), \"utf8\"));\nconst data = JSON.parse(readFileSync(new URL(\"../public/courses.json\", import.meta.url), \"utf8\"));", "note": "The schema is read from the file in the previous section and turned into an executable schema; the data is the planner's own JSON."},
 {"code": "const ofCourse = (id) => data.sessions.filter((s) => s.course === id);\nconst course = (c) => ({\n  ...c,\n  sessions: () => ofCourse(c.id).map(session),\n  minutesPlanned: () => ofCourse(c.id).reduce((n, s) => n + s.minutes, 0),\n});\nconst session = (s) => ({ ...s, course: () => course(data.courses.find((c) => c.id === s.course)) });", "note": "A course and a session are plain objects with a function for each field that has to be worked out. When a query asks for `sessions` or `minutesPlanned`, `graphql` calls the function; when it does not, nothing runs."},
 {"code": "const rootValue = {\n  courses: () => data.courses.map(course),\n  course: ({ id }) => {\n    const found = data.courses.find((c) => c.id === id);\n    return found ? course(found) : null;\n  },\n  markDone: ({ id }) => {\n    const found = data.sessions.find((s) => s.id === id);\n    if (!found) return null;\n    found.done = true;\n    return session(found);\n  },\n  addSession: ({ input }) => {\n    if (!data.courses.some((c) => c.id === input.course)) throw new Error(`No course \"${input.course}\"`);\n    const id = Math.max(0, ...data.sessions.map((s) => s.id)) + 1;\n    const added = { id, ...input, done: false };\n    data.sessions.push(added);\n    return session(added);\n  },\n};", "note": "One function per field of `Query` and `Mutation`, each taking that field's arguments. An unknown course answers `null`, which the schema allows; an unknown course in `addSession` throws, which becomes an error in the answer."},
 {"code": "createServer(async (req, res) => {\n  if (req.method !== \"POST\" || req.url !== \"/graphql\") {\n    res.writeHead(404).end();\n    return;\n  }\n  let body = \"\";\n  for await (const chunk of req) body += chunk;\n  const { query, variables, operationName } = JSON.parse(body);\n  const result = await graphql({ schema, source: query, rootValue, variableValues: variables, operationName });\n  console.log(`${operationName ?? \"(anonymous)\"}${result.errors ? \" with errors\" : \"\"}`);\n  res.writeHead(200, { \"content-type\": \"application/json\" }).end(JSON.stringify(result));\n}).listen(4000, \"127.0.0.1\", () => console.log(\"GraphQL on http://127.0.0.1:4000/graphql\"));", "note": "The endpoint: a `POST` to `/graphql` with a JSON body holding the query, its variables and its name. `graphql()` checks the query against the schema, runs it, and returns `{ data, errors }`, which goes back as JSON with a 200. Each request is logged by the name of the operation it ran."}
]}
```

This server is a stand-in for the API another team would run, and it leaves out what such a server needs:
a database, authentication, a check on who may change which session, and a limit on how much a single
query may ask for. It answers only on `127.0.0.1`, so nothing outside this computer reaches it.

Start it in a second terminal and leave it running for the rest of the lesson:

```
ana@dev:~/planner$ node api/server.mjs
GraphQL on http://127.0.0.1:4000/graphql
```

## The first question, by hand

A GraphQL request is an ordinary HTTP `POST` with a JSON body, so `curl` can send one. The query is a
string inside that JSON, and the `echo` after it only ends the line, since the answer does not:

```
ana@dev:~/planner$ curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"query": "{ courses { id title } }"}'; echo
{"data":{"courses":[{"id":"html-css","title":"HTML and CSS"},{"id":"javascript","title":"JavaScript"},{"id":"git","title":"Git"}]}}
```

`{ courses { id title } }` asked for two fields of every course, and the answer is `data` with exactly
that, in the same nesting. Typing JSON with a query inside it is tiresome, so the rest of the lesson uses
a small script that takes the query as it is written and prints the answer laid out:

```javascript
// api/ask.mjs: node api/ask.mjs 'QUERY' ['VARIABLES AS JSON']
const [query, variables = "{}"] = process.argv.slice(2);
const response = await fetch("http://127.0.0.1:4000/graphql", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ query, variables: JSON.parse(variables) }),
});
console.log(JSON.stringify(await response.json(), null, 2));
```
