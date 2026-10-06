---
title: Who may deploy where
version: 1
---

Environments differ in what is at stake, so they differ in who may change them. A rule of thumb that
holds in most teams: **the closer to customers, the fewer the hands, and the more of them are
machines.**

| environment | who deploys | how |
|---|---|---|
| development | any developer | by hand or by the pipeline |
| preview | the pipeline, for each pull request | automatically |
| staging | the pipeline, after the checks | automatically, from `main` |
| production | the pipeline, after the gate | with an approval, or by rule |

Two properties make that table hold rather than merely describe intentions.

**The pipeline's credentials are per environment.** The job that deploys to staging cannot reach
production, because it never receives production's credentials. On GitHub Actions that is what
*environments* with their own secrets and protection rules are for, as lesson 7 section 08 showed;
on GitLab, protected environments do the same. A person who wants to deploy to production by hand
finds there is no key to do it with.

**Every deploy leaves a record.** Which artifact, which hash, which environment, who or what started
it, and when. The pipeline's own history is one record; a deploy script can append a line to a log
too. When production misbehaves at 15:10, the first useful fact is the deploy at 15:02, and an
environment whose changes have no record forces everybody to guess.

## The emergency exception

Every team eventually needs to change production faster than the pipeline allows. The answer that
keeps the rules intact is a **break-glass procedure**: a separate, audited way in, used rarely, that
alerts people when it is used, followed by putting the same change through the pipeline so the
environment matches its definition again. The answer that breaks them is an engineer with permanent
access who edits a file on the server, which is section 07's drift with a good reason behind it.

Lesson 9 takes the credentials in that table seriously: where they are kept, how a job receives them,
and how little each one should be able to do.
