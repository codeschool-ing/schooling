---
title: Apollo Client, from the terminal
version: 1
---

**Apollo Client runs anywhere JavaScript does, Node included, so its cache can be watched step by step
before it goes near a page.** Install it in the planner, with RxJS, which it uses to deliver results that
change over time:

```
ana@dev:~/planner$ npm install --save-exact @apollo/client@4.3.3 rxjs@7.8.2 2>&1 | tail -1
found 0 vulnerabilities
```

**Apollo Client 4.3.3** and **RxJS 7.8.2**. Both go in `dependencies`, not `devDependencies`: unlike
`graphql` in lesson 9, they will run in the browser. `@apollo/client` imports `graphql` itself, which the
planner already has.

This script asks the lesson's server five things and prints, after each, part of what the client's cache
holds. Start the GraphQL server from lesson 9 in a second terminal first:

```schooling-example
{"language": "javascript", "file": "api/cache.mjs", "parts": [
 {"code": "// api/cache.mjs: what Apollo Client keeps, step by step, against the lesson's server\nimport { ApolloClient, HttpLink, InMemoryCache, gql } from \"@apollo/client\";\n\nconst client = new ApolloClient({\n  link: new HttpLink({ uri: \"http://127.0.0.1:4000/graphql\" }),\n  cache: new InMemoryCache(),\n});", "note": "A client is a link, which says how to reach the server, and a cache, which keeps the answers. `InMemoryCache` is Apollo's cache; `HttpLink` sends each operation as the `POST` lesson 9 sent by hand."},
 {"code": "const PLANNER = gql`\n  query Planner {\n    courses {\n      id\n      title\n      sessions {\n        id\n        date\n        minutes\n        done\n      }\n    }\n  }\n`;\nconst show = (label, value) => console.log(`${label}:`, JSON.stringify(value));", "note": "`gql` parses a query once, when the module loads, into the tree the client works with; a mistake in it fails here rather than at the server."},
 {"code": "await client.query({ query: PLANNER });\nshow(\"1. keys\", Object.keys(client.cache.extract()));\nshow(\"   Session:6\", client.cache.extract()[\"Session:6\"]);\n\nawait client.query({ query: PLANNER });\nshow(\"2. asked again\", \"answered from the cache\");", "note": "Step 1 asks for the planner and prints the cache's keys, then one entry. Step 2 asks the same thing again."},
 {"code": "await client.mutate({\n  mutation: gql`\n    mutation MarkDone($id: Int!) {\n      markDone(id: $id) {\n        id\n        done\n      }\n    }\n  `,\n  variables: { id: 6 },\n});\nshow(\"3. Session:6\", client.cache.extract()[\"Session:6\"]);", "note": "Step 3 marks session 6 done, asking back only its `id` and `done`, and prints the entry again."},
 {"code": "await client.mutate({\n  mutation: gql`\n    mutation AddSession($input: NewSession!) {\n      addSession(input: $input) {\n        id\n        date\n        minutes\n        done\n      }\n    }\n  `,\n  variables: { input: { course: \"git\", date: \"2026-10-20\", minutes: 30 } },\n});\nshow(\"4. Course:git sessions\", client.cache.extract()[\"Course:git\"].sessions);\n\nawait client.query({ query: PLANNER, fetchPolicy: \"network-only\" });\nshow(\"5. Course:git sessions\", client.cache.extract()[\"Course:git\"].sessions);", "note": "Step 4 adds a session to git and prints what the cache thinks git's sessions are. Step 5 asks the planner again, from the network this time."}
]}
```

```
ana@dev:~/planner$ node api/cache.mjs
1. keys: ["Session:1","Session:5","Course:html-css","Session:2","Session:4","Session:6","Course:javascript","Session:3","Course:git","ROOT_QUERY"]
   Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":false}
2. asked again: "answered from the cache"
3. Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":true}
4. Course:git sessions: [{"__ref":"Session:3"}]
5. Course:git sessions: [{"__ref":"Session:3"},{"__ref":"Session:7"}]
```

The next three sections read this output one step at a time. The GraphQL server's terminal has its own
half of the story, the operations that reached it:

```
ana@dev:~/planner$ node api/server.mjs
GraphQL on http://127.0.0.1:4000/graphql
Planner
MarkDone
AddSession
Planner
```

**Four operations for five steps.** Step 2 never reached the server, and Apollo named every request by
its operation without being told: it sends `operationName` from the query itself, which `ask.mjs` in
lesson 9 did not.
