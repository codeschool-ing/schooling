---
title: A secret in a commit, and the morning after
version: 1
---

**A secret that reaches a commit has leaked, and the fix is to replace it at whatever issued it.**
Deleting the line, deleting the file and even rewriting the history come after, and none of them is the
fix. None of them reaches the copies that already exist: every clone, every fork, every cache of a public
repository, and every automated scanner that reads new commits within minutes of a push.

## How it gets there

The template's `.gitignore` leaves out `*.local`, and that is the whole of what keeps `.env.local` out of
the repository. `git check-ignore` says which rule applies to a path:

```
ana@dev:~/planner$ git check-ignore -v .env.local .env
.gitignore:13:*.local	.env.local
```

`.env.local` is ignored by line 13; `.env` is not ignored at all, because the template expects `.env` to
hold values everybody shares. **A secret in `.env` goes to the repository with the next `git add .`**,
which is exactly what happens here:

```
ana@dev:~/planner$ echo 'SUPPORT_TOKEN=tok-demo-not-a-real-secret' > .env
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -qm "Support widget settings"
ana@dev:~/planner$ git show --stat --oneline HEAD
4d59503 Support widget settings
 .env | 1 +
 1 file changed, 1 insertion(+)
```

Then the mistake is noticed, and the file is taken out of the repository and added to `.gitignore`:

```
ana@dev:~/planner$ git rm -q --cached .env
ana@dev:~/planner$ echo '.env' >> .gitignore
ana@dev:~/planner$ git commit -qam "Keep .env out of the repository"
ana@dev:~/planner$ git ls-files .env .env.staging
.env.staging
```

The file is gone from the latest commit. **The history still has it**, and so does anybody who fetched in
between:

```
ana@dev:~/planner$ git log --oneline -p -- .env | head -12
b6d9312 Keep .env out of the repository
diff --git a/.env b/.env
deleted file mode 100644
index 9e2d192..0000000
--- a/.env
+++ /dev/null
@@ -1 +0,0 @@
-SUPPORT_TOKEN=tok-demo-not-a-real-secret
4d59503 Support widget settings
diff --git a/.env b/.env
new file mode 100644
index 0000000..9e2d192
```

## The order that works

1. **Replace the secret at the service that issued it**, and revoke the old one. This is the only step
   that makes the leaked copy useless, so it comes first, before anything about git, and it is not
   optional because the repository was private, the push was quick or nobody seems to have noticed.
2. **Look at what the old one did** while it was out: the service's own logs say whether anybody used it.
3. **Then tidy the repository.** Take the file out and ignore it, as above. Rewriting history to remove
   it, with a tool such as `git filter-repo` and a force-push, is worth doing on a repository others will
   clone, and it changes nothing about the secret, which step 1 already dealt with.

GitHub runs **secret scanning** on repositories, and with **push protection** on it refuses a push that
contains a key in a format it recognises, before the commit reaches it. That catches the common formats of
the common services. It does not catch a token in a format it has never seen, like the one in this
section, so it is a net under the rule, never the rule.

## Undoing the demonstration

The two commits above were never pushed, so they can be removed from your history without hurting
anybody. That is the one situation in which this is safe:

```
ana@dev:~/planner$ git reset -q --hard HEAD~2 && rm .env
ana@dev:~/planner$ git log --oneline
4c6079f Declare the variables the planner reads
4ea0d5e A staging mode
567e767 Take the title from VITE_TITLE
f58474d Serve dist/ the way a static host does
833a261 The study planner
ana@dev:~/planner$ git status --short
```

Had they been pushed, the order above would apply in full, starting with step 1.
