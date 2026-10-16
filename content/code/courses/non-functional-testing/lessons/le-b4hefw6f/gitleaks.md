---
title: Scanning the files and the history
version: 1
---

**gitleaks** is a secret scanner: a single program that reads text and reports what looks like a
key, a token or a password, by a list of rules. Some rules know the exact shape of one provider's
keys; one of them, `generic-api-key`, looks for a name like `api_key` or `secret` followed by a
value random enough to be one. It reads three kinds of input, and each is a subcommand:

| | reads | use it for |
|---|---|---|
| `gitleaks dir` | the files on disk, as they are now | a directory, a build output, a copy of a server's configuration |
| `gitleaks git` | every commit of a repository's history | the repository, on every push, and once over everything it ever held |
| `gitleaks stdin` | whatever is piped into it | a log, a single file, a quick check of one line |

## Installing it

gitleaks is one program, published for each system on its GitHub releases page. In the VM:

```sh
curl -fsSLO https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz
tar -xzf gitleaks_8.30.1_linux_x64.tar.gz gitleaks
sudo install gitleaks /usr/local/bin/
```

On a Mac with Apple silicon the file is `gitleaks_8.30.1_linux_arm64.tar.gz`. **Those three lines
were not run for this course**, because the computer it was recorded on cannot reach GitHub; the
gitleaks in the transcripts was built from the same v8.30.1 source. Check that yours answers:

```
ana@nft:~$ gitleaks version
v8.30.1
```

## A repository with a mistake in it

Make a throwaway repository called `leaky`, in your home directory and not inside `~/boxoffice`.
The two `export` lines fix the author and the date of every commit you make in this terminal, so
that your commit hashes come out the same as the ones printed here. A real repository never does
this; it is here so the transcripts and your screen can be compared line by line.

```
ana@nft:~$ mkdir -p ~/leaky && cd ~/leaky
ana@nft:~/leaky$ git init -q -b main
ana@nft:~/leaky$ export GIT_AUTHOR_NAME=ana GIT_AUTHOR_EMAIL=ana@nft.test GIT_COMMITTER_NAME=ana GIT_COMMITTER_EMAIL=ana@nft.test
ana@nft:~/leaky$ export GIT_AUTHOR_DATE=2026-10-01T10:00:00-03:00 GIT_COMMITTER_DATE=2026-10-01T10:00:00-03:00
```

Create the settings file with `nano settings.ini` and paste this in. The key is random letters and
digits, made up for this lesson, and no provider has ever issued it:

```ini
# leaky/settings.ini
# The box office's payment settings. The key below was made up for lesson 18
# and was never issued by anybody.
[payment]
url = https://payments.example.test/v1
timeout_seconds = 5
payment_api_key = "nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"
```

Then commit it:

```
ana@nft:~/leaky$ git add settings.ini && git commit -q -m "payment settings"
ana@nft:~/leaky$ git log --oneline
ad0a6bc payment settings
```

That is the mistake, committed. Now the usual repair: somebody notices, deletes the line and
commits again. The `sed` below deletes it; doing it by hand in `nano` is the same thing.

```
ana@nft:~/leaky$ sed -i '/payment_api_key/d' settings.ini
ana@nft:~/leaky$ git commit -q -am "take the key out of the settings"
ana@nft:~/leaky$ git log --oneline
d35bad3 take the key out of the settings
ad0a6bc payment settings
```

## Two scans, two answers

Ask gitleaks about the directory first, which is what a scan of the files on disk sees:

```
ana@nft:~/leaky$ gitleaks dir --no-banner --no-color; echo "exit $?"
4:53PM INF scanned ~202 bytes (202 bytes) in 3.4ms
4:53PM INF no leaks found
exit 0
```

**No leaks found, and an exit code of 0.** The settings file holds no key any more, and the `.git`
directory, where the history lives, is not one of the files `dir` reads. Now ask about the history:

```
ana@nft:~/leaky$ gitleaks git --no-banner --no-color --verbose; echo "exit $?"
Finding:     payment_api_key = "nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"
Secret:      nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
RuleID:      generic-api-key
Entropy:     4.875000
File:        settings.ini
Line:        7
Commit:      ad0a6bc9d70d4677797a3da73054ec968696f1b0
Author:      ana
Email:       ana@nft.test
Date:        2026-10-01T13:00:00Z
Fingerprint: ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7

4:53PM INF 2 commits scanned.
4:53PM INF scanned ~255 bytes (255 bytes) in 44.2ms
4:53PM WRN leaks found: 1
exit 1
ana@nft:~/leaky$ git show HEAD~1:settings.ini | grep key
# The box office's payment settings. The key below was made up for lesson 18
payment_api_key = "nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"
```

The same repository, and this time **one leak, in commit `ad0a6bc`**, the first one, at line 7 of
`settings.ini`. The exit code is 1, which is what lets a pipeline fail on it without reading a
word. `git show` proves the point the scanner is making: the second commit removed the line from
the file, and the first commit still has it, for anybody who asks.

Each finding names the same things, and they are the fields a report on a leak needs:

- **`RuleID`** is which rule matched, here the generic one. A rule named after a provider, such as
  one for a cloud platform's access keys, is stronger evidence than a generic match.
- **`Entropy`** measures how random the value is. 4.875 is high, the score of something generated
  rather than typed, which is why a generic rule trusts it.
- **`Commit`, `Author`, `Date`** say when the key arrived and who to ask about it.
- **`Fingerprint`** is the finding's identity: commit, file, rule and line. It is what you write
  down when a finding has been dealt with, which "A hook that refuses the commit" does.

## Why the fake key looks real

A scanner that reported every `api_key = "changeme"` in every tutorial would be switched off within
a week. So gitleaks skips values that contain words like `fake` or `example`, and a test value has
to look like a real one to be found:

```
ana@nft:~/leaky$ echo 'payment_api_key = "fake-7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G"' | gitleaks stdin --no-banner --no-color
4:53PM INF scanned ~55 bytes (55 bytes) in 38ms
4:53PM INF no leaks found
ana@nft:~/leaky$ echo 'payment_api_key = "lesson18-7Zq2vRmX9kLp4Tn8Wc3Yb6Hd"' | gitleaks stdin --no-banner --no-color
4:53PM INF scanned ~54 bytes (54 bytes) in 37.7ms
4:53PM WRN leaks found: 1
```

**The first line is not reported and the second is**, and the only difference is a word in the
value. That is a convenience for real repositories, which are full of placeholders, and a trap for
a test: a check written with an obviously fake value proves only that gitleaks ignores it. It is
also why the key in `settings.ini` is random characters and the word saying it is made up is in
the comment above it, where the rule does not look.

## When it finds one for real

What to do is the order of "How a key ends up in a repository", and nothing in it is a git
command until the end. **Rotate first**: revoke the key at the provider and deploy a new one,
because that is the step that makes every copy of the history harmless. Then read the provider's
log for the old key's use. Only then decide whether to rewrite the history with `git filter-repo`
or the BFG Repo-Cleaner, knowing that it changes every hash from that commit on and recalls no
clone. In this lesson the key was never real, so there is nothing to rotate, and `leaky` keeps its
history as it is.
