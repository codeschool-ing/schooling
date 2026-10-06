---
title: The same pipeline on GitLab CI
version: 1
---

GitLab reads its pipeline from one file at the root of the repository, `.gitlab-ci.yml`. The ideas
are the ones of the last four sections; the vocabulary and the layout differ. Step 8 of `shipquote`
wrote the same checks for it:

```schooling-example
{
  "language": "yaml",
  "file": ".gitlab-ci.yml",
  "parts": [
    {
      "code": "stages: [fast, test, report]\n\nworkflow:\n  rules:\n    - if: $CI_PIPELINE_SOURCE == \"merge_request_event\"\n    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH",
      "note": "**Stages** run in order, and every job in a stage runs in parallel. The `workflow` rules are the triggers: a pipeline for a merge request, and one for the default branch."
    },
    {
      "code": "default:\n  image: python:3.13-slim\n\nvariables:\n  PIP_CACHE_DIR: \"$CI_PROJECT_DIR/.cache/pip\"\n\ncache:\n  key:\n    files: [requirements-dev.txt]\n  paths: [.cache/pip]",
      "note": "Every job runs **in a container**, from `image`. The pip cache lives in the project directory so the runner can keep it between jobs, under a key computed from `requirements-dev.txt`."
    },
    {
      "code": "\nfast:\n  stage: fast\n  script:\n    - pip install -q -r requirements-dev.txt\n    - python -m pytest -q -m \"not integration and not functional and not acceptance\"",
      "note": "A job is a name at the top level with a `stage` and a `script`: a list of shell commands, and the first that fails stops the job."
    },
    {
      "code": "\nsuite:\n  stage: test\n  image: python:${PYTHON}-slim\n  parallel:\n    matrix:\n      - PYTHON: [\"3.11\", \"3.12\", \"3.13\"]\n        TZ: [\"America/Sao_Paulo\", \"UTC\"]\n  script:\n    - pip install -q -r requirements-dev.txt\n    - coverage run -p -m pytest -q --junitxml=junit.xml\n  artifacts:\n    when: always\n    paths: [\".coverage.*\"]\n    reports:\n      junit: junit.xml",
      "note": "`parallel: matrix` makes six jobs from two lists, and each cell's variables reach the script as environment variables, `TZ` included. The image itself depends on the cell, so every Python version runs in its own official container. `artifacts: when: always` keeps the coverage files and hands the JUnit report to GitLab, which shows the failures on the merge request."
    },
    {
      "code": "\ncoverage:\n  stage: report\n  when: always\n  script:\n    - pip install -q coverage==7.16.2\n    - coverage combine\n    - coverage report\n  coverage: '/^TOTAL.*\\s(\\d+)%$/'",
      "note": "The report stage runs after the tests whatever happened, receives the earlier stages' artifacts, combines them, and a regular expression tells GitLab where the total coverage is in the output."
    }
  ]
}
```

## Running it

This file **was run**, on this machine, by `gitlab-ci-local`, an open-source program that reads a
`.gitlab-ci.yml` and runs its jobs in Docker the way GitLab's runner would. It is an emulator, not
GitLab, and the lab is clear about that because it matters: it does not show a merge request, it
does not enforce anything, and its behaviour can differ from GitLab's in details. For checking that
a pipeline does what its author meant, before pushing it, it is a good tool.

First the jobs the file defines, and then the pipeline itself:

```
ana@laptop:~/shipquote$ gitlab-ci-local --list
parsing and downloads finished in 87 ms.
json schema validated in 263 ms
name                             description  stage   when        allow_failure  environment  needs
fast                                          fast    on_success  false                     
suite: [3.11,America/Sao_Paulo]               test    on_success  false                     
suite: [3.11,UTC]                             test    on_success  false                     
suite: [3.12,America/Sao_Paulo]               test    on_success  false                     
suite: [3.12,UTC]                             test    on_success  false                     
suite: [3.13,America/Sao_Paulo]               test    on_success  false                     
suite: [3.13,UTC]                             test    on_success  false                     
coverage                                      report  always      false                     
ana@laptop:~/shipquote$ gitlab-ci-local > gcl.log 2>&1
ana@laptop:~/shipquote$ grep -E "^ (PASS|FAIL)|pipeline finished" gcl.log
 PASS  fast                           
 PASS  suite: [3.11,America/Sao_Paulo]
 PASS  suite: [3.11,UTC]              
 PASS  suite: [3.12,America/Sao_Paulo]
 PASS  suite: [3.12,UTC]              
 PASS  suite: [3.13,America/Sao_Paulo]
 PASS  suite: [3.13,UTC]              
 PASS  coverage                        81% coverage
pipeline finished in 30 s
ana@laptop:~/shipquote$ grep -E "^coverage .*(Combined|TOTAL)" gcl.log
coverage                        > Combined 2 files, skipped 4
coverage                        > TOTAL                     164     32     24      4    81%
```

Eight jobs: `fast`, the six matrix cells named after their values, and `coverage`, whose `when`
is `always`. All eight passed, in **30 seconds** of wall-clock time, with each matrix cell in a
separate container from the official Python images 3.11, 3.12 and 3.13. The coverage job combined
the six data files into **81%**, the same figure as every other measurement in this course since
lesson 4.

Its first output line is worth a look: `Combined 2 files, skipped 4`. `coverage combine` skips a data
file whose content is identical to one it has already combined, and four of the six cells had
measured exactly the same lines as another. A union is not changed by a duplicate, so nothing was
lost; the line is a reminder that the report is a union of what ran, not a sum.

## What the emulator could not do

It could not apply the `workflow` rules the way GitLab does for a merge request, since there is no
merge request; it cannot block a merge; and it ran on one machine where GitLab would spread the six
cells over whatever runners are free. Those are the parts of a CI service that are about the team
rather than the jobs, and they are the subject of section 08 for GitHub. On GitLab the same
protection is the project setting that a merge request can only merge when its pipeline succeeds.
