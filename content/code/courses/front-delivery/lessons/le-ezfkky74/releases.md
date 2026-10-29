---
title: Releases
version: 1
---

**A release is the name of one build, and every report carries it, so that a stack is read with the maps
of the build that produced it and a fix can be seen to work.** The symbolication in the previous section
only worked because the report said `release` and a folder of maps had that name. Read a stack against
the maps of another build and the positions point at different code, confidently and wrongly.

## Which name

The commit hash is the natural one: it already identifies the code exactly, it costs nothing, and it is
what lesson 3's pipeline builds from. A team that tags versions can use the tag instead, as lesson 7's
library did; what matters is that one name means one build, and that the same name is set in the build
and on the maps.

## In the pipeline

Lesson 3's workflow builds the planner on every push to `main`. A deploy with a collector would set the
three variables there and keep the maps as the run's own artifact, out of the site. The added lines, which
were not run for this course, are these:

```yaml
      - name: Build
        run: npm run build
        env:
          VITE_GRAPHQL_URL: /graphql
          VITE_ERRORS_URL: /errors
          VITE_RELEASE: ${{ github.sha }}
      - name: Keep the source maps out of the site
        run: mkdir maps && mv dist/assets/*.map maps/
      - name: Upload the source maps
        uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        with:
          name: source-maps-${{ github.sha }}
          path: maps/
```

`github.sha` is the full commit hash. The planner's local builds used the short one; either works, as
long as one kind is used everywhere.

## What a release name buys

- **Which build is broken.** An error that started at one release and not before points at the commit
  that introduced it.
- **Whether a fix worked.** A message that stops arriving from the release after the fix, while older
  open tabs keep sending it from the release before, is a fix confirmed.
- **Which users are affected.** A static site's old build keeps running in every tab opened before the
  deploy, sometimes for days. Reports from an old release are those tabs, and they are not a new bug.
