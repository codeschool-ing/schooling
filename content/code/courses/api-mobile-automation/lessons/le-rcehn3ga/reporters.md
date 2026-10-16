---
title: Reporters, the run as a file
version: 1
---

**A reporter decides what Newman does with the results, and a run can have several at once.** The
`cli` reporter is the one you have been reading. The others write files, for programs rather than
people: a pipeline that draws a list of tests, a dashboard, a script that counts failures over a
month. Two come with Newman, and the third that people usually mean is somebody else's package.

| reporter | writes | for |
|---|---|---|
| `cli` | the output of section 03 | a person at a terminal, or a pipeline's log |
| `junit` | an XML file in the JUnit format | almost every CI system, which reads it to show tests by name |
| `json` | the whole run as JSON, every request and response included | your own scripts |
| `htmlextra` | an HTML page with every request | a person, in a browser; a third-party package, `newman-reporter-htmlextra`, installed separately |

`--reporters` takes a list, and each file reporter takes an `--reporter-<name>-export` with the path
to write. Arguments after `--` go from npm to the script, so the project's script grows without
being edited:

```
ana@laptop:~/boxoffice$ npm run test:api -- --reporters cli,junit,json --reporter-junit-export results/newman.xml --reporter-json-export results/newman.json > /dev/null
ana@laptop:~/boxoffice$ ls results
bail.json  newman.json	newman.xml
```

The output went to `/dev/null` this time, because the point is the two files. Newman created the
`results/` directory itself, the one `.gitignore` already excludes.

## JUnit, the format a pipeline reads

JUnit began as Java's test framework, and its XML report became the format CI systems agree on, the
way problem details became one for errors. Each request with tests is a `<testsuite>`, each assertion a
`<testcase>`, and a failed assertion carries a `<failure>` inside it:

```
ana@laptop:~/boxoffice$ grep -c '<testcase' results/newman.xml
18
ana@laptop:~/boxoffice$ grep -B1 -A2 '<failure' results/newman.xml
    <testcase name="HEAD answers like GET" time="0.003" classname="ShowsHeadOneShow">
      <failure type="AssertionFailure" message="expected response to have status code 200 but got 405">
        <![CDATA[Failed 1 times.]]>
        <![CDATA[Collection JSON ID: 9a80d684-c139-45e1-b410-6c84cbd7c8f6.]]>
```

Eighteen test cases, one per assertion, and the failure carries the same message the terminal
showed. A CI system that reads the file draws the eighteen names and marks one red. It can also tell
you that the same test has failed on every run since it was written, which the terminal output
cannot.

## JSON, the format your own scripts read

The JSON report holds everything Newman knew, which makes it large and makes jq the way in:

```
ana@laptop:~/boxoffice$ jq '.run.stats.assertions' results/newman.json
{
  "total": 18,
  "pending": 0,
  "failed": 1
}
ana@laptop:~/boxoffice$ jq -r '.run.failures[] | .source.name + ": " + .error.message' results/newman.json
HEAD one show: expected response to have status code 200 but got 405
```

The first is the same count the table printed. The second lists every failure by request and message,
the shape a script would post to a chat channel or append to a file. **When a question about a run is
not answered by the table, the answer is in this file**, and it can be asked of yesterday's run as
well as today's.

`htmlextra` makes a page a person can browse, with each request and response laid out. It is not
part of Newman: it installs like any other package, with `npm install --save-dev`. It was not used
for this course. **A third-party reporter is code that reads every request and response of your
run**, tokens included, so it deserves the same look as any other dependency before it goes in.
