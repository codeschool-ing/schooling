---
title: Who owns which directory
version: 1
---

**Lesson 2's rule asks for one approval from anybody but the author.** That is the floor. With a
layout by environment, a team usually wants more specific rules: a change to production approved by
somebody responsible for production, a change to `clusters/` by somebody who runs the platform.

A `CODEOWNERS` file says who owns which paths. Gitea reads it from `.gitea/CODEOWNERS` on the
default branch and, when a pull request touches an owned path, asks the owners for a review on its
own. Save this as `.gitea/CODEOWNERS` in `fleet`:

```
apps/bulletin/production/.* @bruno
clusters/.* @bruno
```

Each line is a pattern and the people who own the paths it matches. **Gitea reads the pattern as a
regular expression matched against the whole path**, so `apps/bulletin/production/.*` is every file
under that directory; GitHub and GitLab read the same file with the patterns of `.gitignore`, where
`apps/bulletin/production/` alone would do. Here Bruno owns production and the cluster's
configuration; staging is owned by nobody in particular, so any reviewer will do.

```
ana@laptop:~/fleet$ git switch --quiet -c owners
ana@laptop:~/fleet$ git add .gitea/CODEOWNERS
ana@laptop:~/fleet$ git commit --quiet -m "fleet: owners of production and of the cluster"
ana@laptop:~/fleet$ git switch --quiet -c production-replicas
ana@laptop:~/fleet$ git commit --quiet -am "production: three replicas"
ana@laptop:~/fleet$ git push --quiet -u origin production-replicas 2>/dev/null
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "production-replicas", "base": "main", "title": "production: three replicas"}' http://localhost:3000/api/v1/repos/ana/fleet/pulls | jq .number
11
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" http://localhost:3000/api/v1/repos/ana/fleet/pulls/11 | jq '[.requested_reviewers[].login]'
[
  "bruno"
]
```

The pull request touched `apps/bulletin/production/`, and Gitea put Bruno on it as a reviewer without
anybody choosing him. **A request is not a requirement**: on its own, `CODEOWNERS` routes reviews,
and the protection rule still counts any approval. Gitea's protection has a setting,
`block_on_official_review_requests`, that refuses a merge while a requested owner has not approved,
and GitHub and GitLab have an equivalent. Turning that on is the step from "the right person is
told" to "the right person decides".

**Ownership by directory is one more reason the layout matters.** If staging and production lived in
one file, nobody could own one without owning the other.
