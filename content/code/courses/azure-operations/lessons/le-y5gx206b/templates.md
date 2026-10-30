---
title: Templates, and the one a team cannot skip
version: 1
---

**A template is a piece of YAML in its own file that a pipeline includes.** Three teams that each copy
the same eight lines of test setup will have three different versions of them within a year; a template
makes the eight lines one file with parameters. This one is steps:

```yaml
# templates/python-test.yml
parameters:
  - name: pythonVersion
    type: string
    default: '3.12'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: ${{ parameters.pythonVersion }}
  - script: python -m pip install -r requirements.txt
    displayName: Install
  - script: python -m unittest discover -s tests
    displayName: Test
```

The pipeline includes it where the steps used to be, and passes the parameter:

```yaml
      - job: test_and_push
        steps:
          - template: templates/python-test.yml
            parameters:
              pythonVersion: '3.12'
          - task: Docker@2
            # ...as before
```

`${{ parameters.pythonVersion }}` is a **template expression**, and the doubled braces matter: it is
resolved when the YAML is compiled, before any agent exists, so it can decide what steps there are.
`$(Build.SourceVersion)`, with a dollar and parentheses, is a **macro**, filled in at run time, so it can
only change a value inside a step. Mixing them up is the commonest template bug: a `$(variable)` used to
decide whether a stage exists is still a literal string when that decision is made.

Templates come in four kinds, by what they hold: **stages**, **jobs**, **steps** and **variables**. A
pipeline includes them at the matching level, and a template can include others.

## A template a pipeline must extend

Including a template is voluntary: a team can delete the line. **`extends` is the form that can be made
compulsory.** The shop's pipeline extends a template owned by the platform team, kept in another
repository and referenced at a tag:

```yaml
# azure-pipelines.yml, in the shop's repository
resources:
  repositories:
    - repository: platform
      type: git
      name: platform/pipeline-templates
      ref: refs/tags/v3

extends:
  template: secure-build.yml@platform
  parameters:
    buildSteps:
      - script: python -m unittest discover -s tests
```

The platform team's `secure-build.yml` decides what runs around the steps it is given: perhaps it runs
a dependency scan first and refuses a step that is a `task` it does not allow. Then the protection that
makes it compulsory goes on the **environment** or the service connection, as a check called **required
template**: a deployment to `shop-production` is refused unless the run extends `secure-build.yml` from
that repository. That check is lesson 3's subject. The point here is the division of labour: the
application team owns its steps, the platform team owns the frame, and neither can quietly change the
other's.

Both files above were **not run**, for the same reason as the pipeline: there is no Azure DevOps
organisation in the lab.
