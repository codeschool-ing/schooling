---
title: Reading the findings
version: 1
---

**A list of findings is not a list of tasks.** What makes one urgent is whether a fix exists, how
bad it is, and whether the vulnerable code is anywhere your program uses. The scanner can answer the
first two.

## Fixed, or not

One high finding from the Debian image, and how all 163 break down:

```
ana@vm:~$ trivy image --input debian.tar --format json | jq "[.Results[0].Vulnerabilities[] | select(.Severity == \"HIGH\")][0] | {VulnerabilityID, PkgName, InstalledVersion, FixedVersion, Status}"
{
  "VulnerabilityID": "CVE-2026-76642",
  "PkgName": "bsdutils",
  "InstalledVersion": "1:2.41.5-0+deb13u1",
  "FixedVersion": null,
  "Status": "affected"
}
ana@vm:~$ trivy image --input debian.tar --format json | jq -r "[.Results[0].Vulnerabilities[].Status] | group_by(.) | map(\"\(.[0])=\(length)\") | join(\" \")"
affected=161 fix_deferred=2
ana@vm:~$ trivy image --input debian.tar --ignore-unfixed --format json | jq -r -f severities.jq
none
```

`"FixedVersion": null` and `"Status": "affected"`: **Debian knows about it and has not shipped a fix**.
That is true of 161 of the 163. `--ignore-unfixed` hides those and leaves nothing, which says
something useful: **rebuilding this image today would remove none of them**. They will go when Debian
ships fixes and the image is rebuilt on top of them.

A smaller base is the other way to make such a list shorter, and it is the argument of lesson 14
seen from the scanner's side: the packages that are not there have no advisories.

## A gate in the pipeline

`--exit-code 1` makes Trivy fail when it finds anything at the severities named, which is how a
pipeline refuses an image:

```
ana@vm:~$ trivy image --input shelf.tar --exit-code 1 --severity HIGH,CRITICAL > /dev/null; echo "exit $?"
exit 1
ana@vm:~$ trivy image --input debian.tar --exit-code 1 --severity HIGH,CRITICAL > /dev/null; echo "exit $?"
exit 1
```

**Both fail**, `shelf` on its one high finding. A gate on `HIGH,CRITICAL` with `--ignore-unfixed` is
the common compromise: it blocks what can be fixed, and does not block every build on what nobody
can. Lesson 26 puts a scan in the pipeline.

## Fixing the one that can be fixed

`shelf`'s high finding has a fix, `golang.org/x/text` 0.39.0. Ana has no Go on her machine (lesson 1),
so the update runs in the `golang:1.25` image, as her user, with her source mounted:

```
ana@vm:~$ cd shelf
ana@vm:~/shelf$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -v ~/gopkg:/go/pkg -e GOCACHE=/tmp/gocache -e GOPROXY=off -e GOFLAGS=-mod=mod golang:1.25 sh -c "go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor"
go: upgraded golang.org/x/sync v0.17.0 => v0.21.0
go: upgraded golang.org/x/text v0.29.0 => v0.39.0
ana@vm:~/shelf$ git diff --stat -- go.mod go.sum vendor/modules.txt
 go.mod             | 4 ++--
 go.sum             | 8 ++++----
 vendor/modules.txt | 8 ++++----
 3 files changed, 10 insertions(+), 10 deletions(-)
ana@vm:~/shelf$ grep x/text go.mod
	golang.org/x/text v0.39.0 // indirect
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.6.1 -t shelf:1.6.1 . && docker save shelf:1.6.1 -o ../shelf-1.6.1.tar
sha256:86e45ec8b235ba9a9c609562080de0c89dcb4b97ee52608f627b9bb1dc420abf
ana@vm:~/shelf$ cd ..
ana@vm:~$ trivy image --input shelf-1.6.1.tar --format json | jq -r -f severities.jq
UNKNOWN=1
```

**`go get` raised `x/text` to the fixed version**, and `golang.org/x/sync` with it, because the new
version needs it. `go mod tidy` and `go mod vendor` brought `go.sum` and `vendor/` along, and the
rebuilt image scans clean of the high finding. In the lab, `GOPROXY=off` makes Go use modules that
were downloaded before the lab started, verified against the checksum database's saved answers;
on a normal machine, the same command downloads them.

**What is left is `tzdata` in the base**, fixed upstream in Debian, not yet in the distroless image.
That fix arrives when Google rebuilds distroless and Ana rebuilds `shelf` on it. With the base pinned
by digest (lesson 16), it arrives as a pull request that changes the digest, and is tested before it
ships.
