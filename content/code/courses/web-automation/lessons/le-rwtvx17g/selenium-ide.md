---
title: Selenium IDE and the .side file
version: 1
---

Selenium IDE is the Selenium project's own recorder, and the oldest of the three. Most people met it
as a browser extension for Chrome and Firefox, the 3.x versions. Its repository on GitHub, read for
this lesson at a commit of 6 October 2026, describes the version being developed, `4.0.1-beta.14`,
as "an electron application written to enable recording and playback of selenium scripts".
**Neither was installed for this course and nothing here was recorded by it**: both need a screen,
and this machine has none. What follows comes from reading the repository's source, and the
recording below was written by hand in the shape the IDE saves.

## A recording is a JSON file

The IDE saves a project as a `.side` file, and the file is JSON. Its package `side-model` declares
the shape:

| level | fields | what it holds |
|---|---|---|
| project | `id`, `version`, `name`, `url`, `urls`, `tests`, `suites`, `plugins` | the address the recording started at, and everything below |
| test | `id`, `name`, `commands` | one recording session |
| command | `id`, `comment`, `command`, `target`, `targets`, `value` | one step |
| suite | `id`, `name`, `persistSession`, `parallel`, `timeout`, `tests` | a group of tests, named by their ids |

A suite names its tests by `id`, never by name or by position, which is the same rule this
course's own catalogue is built on. Here is the shop's recording, in that shape: open the shop, add a
banana and a mango, check that the basket says 2. It was written for this lesson, not saved by the
IDE; the ids are random, as the IDE's are, and a real file carries more alternatives in each
`targets` list:

```json
{
  "id": "8cf56054-7eec-43c5-9b43-e8d168f36162",
  "version": "2.0",
  "name": "quitanda",
  "url": "http://localhost:3000",
  "tests": [{
    "id": "65e32ef8-abf6-4431-8975-904e4df9557e",
    "name": "two fruit",
    "commands": [{
      "id": "316bcab5-aef8-484c-a3a1-9420e14605b6",
      "comment": "",
      "command": "open",
      "target": "/",
      "targets": [],
      "value": ""
    }, {
      "id": "f70a4846-d54b-4100-a710-6991378db0f3",
      "comment": "",
      "command": "setWindowSize",
      "target": "1280x800",
      "targets": [],
      "value": ""
    }, {
      "id": "6cd35dcc-81ce-46a0-b8b1-a6aa61a01518",
      "comment": "",
      "command": "click",
      "target": "css=#card-4821 > button",
      "targets": [
        ["css=#card-4821 > button", "css:finder"],
        ["xpath=//button[@type='button' and text()='Add to basket']", "xpath:attributes"],
        ["xpath=//li[@id='card-4821']/button", "xpath:idRelative"],
        ["xpath=//li/button", "xpath:position"],
        ["xpath=//button[contains(.,'Add to basket')]", "xpath:innerText"]
      ],
      "value": ""
    }, {
      "id": "39bd0e5f-ad46-44d2-b977-3f02e2db2fde",
      "comment": "",
      "command": "click",
      "target": "css=#card-1730 > button",
      "targets": [
        ["css=#card-1730 > button", "css:finder"],
        ["xpath=//li[@id='card-1730']/button", "xpath:idRelative"],
        ["xpath=//li[2]/button", "xpath:position"]
      ],
      "value": ""
    }, {
      "id": "4d488bcb-cd0f-4999-b1c8-3330b1a8749f",
      "comment": "the count was still 0 on the first replay",
      "command": "pause",
      "target": "1000",
      "targets": [],
      "value": ""
    }, {
      "id": "0ef44d89-3d4c-40ac-bd9c-83a5277f7ef5",
      "comment": "",
      "command": "assertText",
      "target": "css=[data-testid=\"basket-count\"]",
      "targets": [
        ["css=[data-testid=\"basket-count\"]", "css:data-attr"],
        ["xpath=//span", "xpath:position"]
      ],
      "value": "2"
    }]
  }],
  "suites": [{
    "id": "e84078bf-3142-47f6-9ad6-b91f1e8d3b7e",
    "name": "Default Suite",
    "persistSession": false,
    "parallel": false,
    "timeout": 300,
    "tests": ["65e32ef8-abf6-4431-8975-904e4df9557e"]
  }],
  "plugins": [],
  "urls": ["http://localhost:3000/"]
}
```

## How the IDE chose those targets

The targets are not invented; they are what the IDE's locator builders give for these elements when
their code is read against the shop's page. **The builders run in a fixed order, and the first
name that finds the element alone becomes `target`.** The order, from
`locator-builders.ts`:

1. `css:data-test-id`, which looks only at the attributes `data-test-id` and `data-test`;
2. `id`, `linkText` and `name`;
3. `css:data-attr`, the first `data-*` attribute of the element itself;
4. `css:finder`, a CSS path built by a library;
5. six kinds of XPath, ending with `xpath:position` and `xpath:innerText`.

**The basket count comes out well.** It carries `data-testid`, which the first builder does not
look for, because the shop spells it without the second hyphen, but the third one takes it:
`css=[data-testid="basket-count"]`. **The banana's button comes out badly.** It has no `id`, no
`name` and no `data-*` attribute of its own, so the first builder that answers is `css:finder`. That
one hands the element to a library, `@medv/finder` 1.1.3, which tries an element's `id`, then its
classes, then its tag, and climbs towards the root until the selector is unique. The button has
neither of the first two, its tag matches nine buttons, and its parent has an `id`: the random one.
Hence `#card-4821 > button`, a name that was true while the recording was made and false on the next
load.

**Same recorder, same page, one good name and one broken one.** The difference was never the tool's
skill. It was whether the page carried a stable handle on the element the builder was asked to name,
and the cards carry their test id on the `li`, one level above the button.

## What playback does

The repository's `side-runtime` package replays a recording through `selenium-webdriver`, and its
code settles three things a tester needs to know:

- **A `click` waits.** It polls for its target to be found and displayed, for up to the implicit
  wait: `5 * 1000` milliseconds by default, which the command-line runner's `--timeout` changes.
- **An `assertText` reads once.** It waits for the element to exist, reads its text a single time and
  compares. If the count is still `0` at that instant, the step fails, which is why the recording
  above carries a `pause` with a comment beside it.
- **The alternatives are not tried.** The lookup takes the first match of `target`, and the loop that
  would try `targets` is commented out, under the comment "Fallback selectors are not visible or
  editable enough for now." The list is saved for a person, who can choose another entry in the IDE
  when the first one breaks.

Two more packages in the same repository widen what a `.side` file can be used for. The command-line
runner, `selenium-side-runner` (4.0.13), plays a project without opening the IDE, so a CI server can
run it. And a set of code-export packages turns a recording into a program: JavaScript with Mocha,
Python with pytest, Java with JUnit, C# with NUnit or xUnit, and Ruby with RSpec. Neither was run
here. Exported code keeps the targets the builders chose, so a random id leaves the IDE inside the
program.
