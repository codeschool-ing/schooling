---
title: Required checks, so red means no merge
version: 1
---

**A check that nobody is obliged to wait for is a suggestion.** CI turning red on a pull request matters
only if the pull request then cannot be merged, and that is a setting on the repository, not part of the
workflow.

On GitHub it is a **branch ruleset**, or the older **branch protection rule**, on `main`. In the
repository's **Settings**, under **Rules**, a ruleset for the default branch with two rules turned on does
it:

- **Require a pull request before merging**, so nobody pushes to `main` directly and skips the checks;
- **Require status checks to pass**, with `CI / check` added to the list, so the merge button stays grey
  until that job is green on the latest commit of the pull request.

**This was not run for this course**; it needs a repository on GitHub, and the screens are GitHub's to
rearrange. What lasts is the shape: a named check, required, on the branch everybody deploys from.

## Three ways a required check gets around

Each of these is a real way red code reaches `main`, and each has a setting or a habit against it:

| how | against it |
|---|---|
| an administrator merges anyway, because the rule lets them | turn off the bypass for administrators, or keep a list of who may bypass and why |
| the check's name changes, so the rule waits for a check that never runs again, and someone removes it | name jobs on purpose and change them rarely; a renamed job is a change to the rule too |
| the pull request was green, but `main` moved since, and the merge of the two is broken | require the branch to be up to date before merging, or use GitHub's merge queue, which checks the merge itself |

## The checks and the deploy

The host's build from lesson 1 is a second, separate pipeline. Vercel, Netlify and Cloudflare Pages each
report their deploy as a check on the pull request too, beside `CI / check`. **Require yours, and let
theirs be informational**: a host's build failing tells you the deploy would fail, while your check tells
you the code is wrong, and only the second is a reason to block a merge that the host could retry.
