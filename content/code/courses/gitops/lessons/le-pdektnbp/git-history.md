---
title: What Git and the server remember
version: 1
---

**Git answers *what* and *when*; the Git server answers *who agreed*.** A commit carries an author,
a committer, two dates and a message, and its hash ties them to exactly one tree of files. The pull
request around it carries what the commit cannot: who opened it, who approved, what the check said,
and who merged.

The commits that reached `main` of `fleet`, newest first:

```
ana@laptop:~/fleet$ git log --first-parent --format='%h %ad %s' --date=format:'%m-%d %H:%M' main | head -n 8
dbee7f1 10-16 04:53 Merge pull request 'staging: no debugging account' (#23) from revert-staging-debug into main
4378df8 10-16 04:48 Merge pull request 'staging: a debugging account' (#22) from staging-debug into main
79a931a 10-16 04:48 Merge pull request 'staging-applier: its namespace and its sealed secrets' (#21) from staging-applier-extra into main
db03e43 10-16 04:43 Merge pull request 'staging: applied as staging-applier' (#20) from staging-applier into main
2ae2f39 10-16 04:42 Merge pull request 'production: the token comes from Vault' (#19) from production-vault into main
378dd13 10-16 04:41 Merge pull request 'external-secrets: the operator, 1.3.2' (#18) from external-secrets into main
c4ba102 10-16 04:40 Merge pull request 'vault: an identity to check tokens with, and one for production' (#17) from vault-auth into main
839828e 10-16 04:40 Merge pull request 'production: a token encrypted with SOPS' (#16) from production-token into main
```

`--first-parent` follows `main` and nothing else, so each line is one pull request, newest first:
the revert that ended lesson 11 on top, pull request 23, and the changes of lessons 9 to 11 below
it. The dates are the server's, written when each merge happened.

Each `Merge pull request` line is the server's: it records the pull request's number and the branch,
and its second parent is the commit somebody wrote. **The author of that commit is text**, as lesson
8 said; what the server adds is the account that pushed and the accounts that reviewed, which it
records whatever the commit claims. Gitea's API gives them for any pull request, with lesson 2's
`$AS_ANA` and `$API`:

```
ana@laptop:~/fleet$ N=$(curl -s -H "$AS_ANA" "$API/pulls?state=closed&limit=1" | jq '.[0].number'); echo $N
23
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/pulls/$N | jq '{title, opened_by: .user.login, merged_by: .merged_by.login, merged_at, merge_commit_sha}'
{
  "title": "staging: no debugging account",
  "opened_by": "ana",
  "merged_by": "ana",
  "merged_at": "2026-10-16T04:53:32Z",
  "merge_commit_sha": "dbee7f14f470f86002116cfceee7fad4278fa244"
}
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/pulls/$N/reviews | jq -c '.[] | {by: .user.login, state, submitted_at}'
{"by":"bruno","state":"APPROVED","submitted_at":"2026-10-16T04:53:32Z"}
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/commits/$(git rev-parse HEAD^2)/statuses | jq -c '.[] | {context, status, by: .creator.login}'
{"context":"validate","status":"success","by":"ci"}
```

Pull request 23: opened by `ana`, approved by `bruno`, merged by `ana`, at a time and onto a commit
the server recorded. Its commit carries one status, `validate`, posted by the `ci` account. Nothing
here depends on what the commit says about itself.

The signed commit from lesson 8 is the one place the history says more than the server does: Git
checks its signature against the allowed signers, here, on your own machine, with nothing to trust
but the key list:

```
ana@laptop:~/fleet$ git log --show-signature -1 --format='%h %an %s' $(git log --no-merges --format=%h --grep='back to the signed chart' -1)
Good "git" signature for ana@example.org with ED25519 key SHA256:JTvPwQC6FsWa2odLTarjFyxrssN4MZrlG4wj3RfMRUo
74e4555 Ana Lima preview: back to the signed chart
```

**Three questions, three places to ask.** What changed: the diff of the commit. Who agreed: the pull
request's reviews. Who wrote it: the signature, where there is one, and the account that pushed,
where there is not.
