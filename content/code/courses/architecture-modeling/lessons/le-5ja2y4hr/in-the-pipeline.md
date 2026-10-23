---
title: In the pipeline: a broken diagram fails the build
version: 1
---

**The payoff of diagrams as text is that a machine can check them on every change.** A small script
that renders every diagram in the repository and fails if any of them does not render turns *the
diagrams are up to date* from a hope into a rule, which is lesson 11's fitness function applied to
the documentation itself.

## The script

Save this as `check-diagrams.sh` in the `diagrams` folder:

```sh
#!/bin/sh
# Render every diagram source in this folder; fail if any of them does not render.
failed=0
for f in *.mmd; do
  npx mmdc --quiet -i "$f" -o "/tmp/check-${f%.mmd}.svg" > /dev/null 2>&1 \
    && echo "ok      $f" || { echo "FAILED  $f"; failed=1; }
done
for f in *.puml; do
  java -jar plantuml-1.2026.9.jar -checkonly "$f" > /dev/null 2>&1 \
    && echo "ok      $f" || { echo "FAILED  $f"; failed=1; }
done
exit $failed
```

It loops over the Mermaid files, renders each to a throwaway file and reports it; then it asks
PlantUML, with `-checkonly`, whether each `.puml` file would render, which is stricter than
`-syntax`: it also refuses a file with no complete diagram in it. Any failure sets the exit status to 1, which is what makes
a pipeline go red.

## Running it

With the two broken files from earlier still in the folder, it fails, naming them:

```
ana@vm:~/diagrams$ sh check-diagrams.sh; echo "exit status $?"
FAILED  broken.mmd
ok      ticket.mmd
FAILED  broken.puml
ok      hold.puml
ok      purchase.puml
exit status 1
```

Remove them, and it passes:

```
ana@vm:~/diagrams$ rm broken.mmd broken.puml
ana@vm:~/diagrams$ sh check-diagrams.sh; echo "exit status $?"
ok      ticket.mmd
ok      hold.puml
ok      purchase.puml
exit status 0
```

## In a real pipeline

In a repository, the same script runs as a step of the continuous integration that already builds
the code: it installs the pinned versions, runs the script, and blocks the merge when it fails.
Three habits make it work:

- **Pin the versions in the pipeline too.** The pipeline should render with exactly the versions the
  team uses, or a diagram that renders on a laptop fails in CI, or the reverse.
- **Check, and publish what you render.** The same step can publish the rendered SVGs to the
  documentation site, so the pictures people read are always the ones the sources describe.
- **Fail on the model, not only on the syntax.** For Structurizr, `validate` checks the model:
  relationships to elements that do not exist, duplicate names. That is a deeper check than any
  parser.
