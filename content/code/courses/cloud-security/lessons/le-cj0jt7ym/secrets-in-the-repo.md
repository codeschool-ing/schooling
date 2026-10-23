---
title: A key in the repository stays in the repository
version: 1
---

**A secret committed to a repository is published to everybody who will ever clone it, and deleting
the line in a later commit does not take it back.** The fix for a leaked key is always to make the
key worthless, never only to make it invisible. This section finds one with a scanner and then shows
why finding it in today's files is not enough.

## An old configuration

In 2019, bia set up the monthly reports bucket with Terraform from her laptop, and to make it work
she wrote an access key into the provider block. The key below is invented for this lesson and was
never valid anywhere; the shape is what matters. Make a repository for it:

```sh
mkdir -p ~/aws/reports && cd ~/aws/reports
git init -q
git config user.name bia
git config user.email bia@clinic.example
```

Save this as `main.tf`:

```hcl
provider "aws" {
  region     = "sa-east-1"
  access_key = "AKIA2E0A8F3B244C9986"
  secret_key = "zhYmT8kq3NfR7cW2pLx9vB4aJd6sE1uGo5iHtM0y"
}

resource "aws_s3_bucket" "reports" {
  bucket = "clinic-reports"
}
```

Commit it, as bia did, and run Checkov's secrets scanner over the directory. It looks for the shapes
of known credentials and for long random-looking strings:

```
ana@laptop:~/aws/reports$ git add main.tf && git commit -q -m "Monthly reports bucket"
ana@laptop:~/aws/reports$ checkov -d . --framework secrets --compact --quiet --skip-download; echo "exit status $?"
secrets scan results:

Passed checks: 0, Failed checks: 2, Skipped checks: 0

Check: CKV_SECRET_2: "AWS Access Key"
	FAILED for resource: df3cdbabb93a89194b3b2526eafe279dd8ff98f2
	File: /main.tf:3-4
Check: CKV_SECRET_6: "Base64 High Entropy String"
	FAILED for resource: ec4af7bd32f6ea96ede723fdfe88cf3b30ab6ac5
	File: /main.tf:4-5

exit status 1
```

Two findings for one credential. `CKV_SECRET_2` recognises the access key id by its shape: twenty
characters starting with `AKIA`, which is how a long-lived IAM user key begins, as lesson 7 explains.
`CKV_SECRET_6` knows nothing about AWS. It flags the secret key because forty characters of that
randomness rarely mean anything else. The scanner hides most of the value in its output, so its own
report does not leak the secret a second time.

## Removing it, and what that does not remove

The provider needs no key in the file: it reads the credentials from the environment, as `env.sh`
does, or from a profile. Change the provider block to this, and commit:

```hcl
provider "aws" {
  region = "sa-east-1"
}
```

```
ana@laptop:~/aws/reports$ git commit -q -am "Take the keys out of the provider"
ana@laptop:~/aws/reports$ checkov -d . --framework secrets --compact --quiet --skip-download; echo "exit status $?"

exit status 0
ana@laptop:~/aws/reports$ git log -p -S AKIA2E0A8F3B244C9986 --format='%an %s' | grep -E '^bia|AKIA'
bia Take the keys out of the provider
-  access_key = "AKIA2E0A8F3B244C9986"
bia Monthly reports bucket
+  access_key = "AKIA2E0A8F3B244C9986"
```

The files are clean and the scanner passes. **The history still holds the key**, and `git log -S`
finds it in the very commit that added it, and in the one that took it out. Every clone made before
today has it, and so does every fork, every CI cache and every backup of the repository. A scanner
that reads only the current files answers a narrower question than the one that matters.

::: track devsecops
The `secure-pipeline` course's lesson 6 runs a scanner over the whole history and blocks a push that
carries a secret, which is the place to catch one before it is published at all.
:::

::: track *
Scanners built for this, such as gitleaks and TruffleHog, read every commit of the history rather
than the files as they stand, and are usually run on every push so a secret is stopped before it is
published. They were not run for this course.
:::

## What to do with a leaked key

In this order, and the order is the point:

1. **Make the key worthless.** Deactivate it, then delete it once nothing breaks; lesson 7 does
   exactly this with a key that leaked. Until this step, everything else is cosmetic.
2. **Find out what it did.** The key's last use, and every call it made, are in the account's
   records; lesson 15 reads them.
3. **Replace it with something that cannot leak the same way**: credentials from the environment on
   a laptop, a role for anything that runs in the cloud or in a pipeline (lesson 14).
4. **Then, if you like, clean the history.** Rewriting a repository removes the line from the copies
   you control, and from none of the others. It is housekeeping, never the remedy.

A real key published on a public repository is found quickly, by people who scan public code for
exactly this, which is why GitHub works with AWS to recognise AWS keys pushed to public repositories and report them. Nothing in
that arrangement was run here.
