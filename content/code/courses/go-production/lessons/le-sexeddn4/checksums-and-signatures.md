---
title: Proving the file is the one you built
version: 1
---

Somebody downloads `hits-linux-arm64` from a release page. Two questions stand between them and
running it, and they are different questions. **A checksum answers whether the bytes changed on the
way; a signature answers who stands behind the bytes.** A checksum published on the same page as the
file proves little against whoever can change the page, because they can change both. A signature
can only be made with a key the attacker does not have. This section builds both, plus a third
property that makes either worth more: a build anybody can repeat and get the same bytes.

## Checksums

A small release, the two Linux targets with section 02's flags, into `dist/`:

```
ana@vm:~/ship$ for a in amd64 arm64; do CGO_ENABLED=0 GOARCH=$a go build -trimpath -ldflags="-s -w" -o dist/hits-linux-$a .; done
ana@vm:~/ship/dist$ sha256sum hits-* > SHA256SUMS && cat SHA256SUMS
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  hits-linux-amd64
cf602df1c912c17c376d5251934d89b5d1d050e2967e9aa6dba1fc1545a600a9  hits-linux-arm64
ana@vm:~/ship/dist$ sha256sum -c SHA256SUMS
hits-linux-amd64: OK
hits-linux-arm64: OK
```

**`SHA256SUMS` is the conventional file: one line per artefact, a SHA-256 and a name.** `sha256sum
-c` reads it back, hashes each file it names and compares. One byte added to the end of a binary,
the way a truncated or tampered download differs, and the check notices:

```
ana@vm:~/ship/dist$ printf x >> hits-linux-arm64; sha256sum -c SHA256SUMS; echo $?
hits-linux-amd64: OK
hits-linux-arm64: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
1
ana@vm:~/ship$ CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o dist/hits-linux-arm64 . && cd dist && sha256sum -c --quiet SHA256SUMS
hits-linux-arm64: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@vm:~/ship$ rm dist/hits-linux-arm64 && CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o dist/hits-linux-arm64 . && cd dist && sha256sum -c --quiet SHA256SUMS && echo all good
all good
```

The second command is the trap. **Rebuilding did not repair the file**, because `go build -o` first
reads the build ID stamped inside an existing output, and when it matches the build it is about to
do, it leaves the file as it is. One byte on the end does not touch the build ID, so the damaged
file stayed. Deleting it forced a real write, and `--quiet` printed only the failures, of which
there were none.

## A build anybody can repeat

A checksum proves the file is the one that was published. It does not prove the published file came
from the source it claims to. **If the build is reproducible, anybody can check that themselves**:
build the same source with the same toolchain and compare hashes. Here is `hits` built in `~/ship`
and in a copy of its source in `~/ship-copy`, a directory made for the purpose:

```
ana@vm:~/ship$ cp -r go.mod main.go internal ~/ship-copy/
ana@vm:~/ship$ go build -o /tmp/hits-a . && (cd ~/ship-copy && go build -o /tmp/hits-b .) && sha256sum /tmp/hits-a /tmp/hits-b
eb5351838c881861aaf80577463eb4114217b5e674067a69237a96ce81fa240a  /tmp/hits-a
94a083a238a3b4e4faf148c2ce61dd213dd4255611b721f9b3707cb6b559f8fd  /tmp/hits-b
ana@vm:~/ship$ go build -trimpath -o /tmp/hits-a . && (cd ~/ship-copy && go build -trimpath -o /tmp/hits-b .) && sha256sum /tmp/hits-a /tmp/hits-b
c8b3a17e3f4d06ba9836d6e7f63a36171a97b2fce66a936cab723d148f3358b6  /tmp/hits-a
c8b3a17e3f4d06ba9836d6e7f63a36171a97b2fce66a936cab723d148f3358b6  /tmp/hits-b
```

**Same source, different hashes, and the only difference was the directory.** Without `-trimpath`
the binary records `/home/ana/ship` in one and `/home/ana/ship-copy` in the other, in its file names
for stack traces and debugging. With it, both record module paths and the bytes agree. The Go
toolchain makes the rest of a build deterministic by design: no timestamps, no host name, the same
output for the same inputs.

The strongest version of the test is a different machine altogether. The image of section 03 built
`hits` in a Debian 13 container, as root, in `/src`:

```
ana@vm:~/ship$ podman create --name peek hits:1 >/dev/null && podman cp peek:/hits from-image && podman rm peek >/dev/null
ana@vm:~/ship$ sha256sum hits from-image dist/hits-linux-amd64
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  hits
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  from-image
e4d54644658448881c3cbc00d20e6cd02977d97f47b61eded56a54e7d4c781ad  dist/hits-linux-amd64
```

**Three builds, on Ana's Ubuntu and in a Debian container, one hash.** The binary that section 02
built, the one copied out of the image and the release's `amd64` file are the same 2,650,272 bytes.
What they share is the source, Go 1.27.1, and the settings `go version -m` records: `CGO_ENABLED=0`,
`GOARCH=amd64`, `GOAMD64=v1` and `-trimpath`.

An image is harder, because a build writes the time into it. Distroless shows the fix:

```
ana@vm:~/ship$ podman image inspect --format "{{.Created}}" gcr.io/distroless/static-debian12:nonroot
1970-01-01 00:00:00 +0000 UTC
ana@vm:~/ship$ podman build -q --no-cache --cap-drop=all --network=none --timestamp 0 -t hits:r1 .
46957a7c1dc10917f735d000e2ac6b26903754e5f01d0933b3413cd4ea9498c8
ana@vm:~/ship$ podman build -q --no-cache --cap-drop=all --network=none --timestamp 0 -t hits:r2 .
46957a7c1dc10917f735d000e2ac6b26903754e5f01d0933b3413cd4ea9498c8
ana@vm:~/ship$ podman build -q --no-cache --cap-drop=all --network=none -t hits:r2 .
7bd7cea71b0cff8e9ebe4e5bb5106f1b1a65d8fb821e3bfebc12a80dd5bd97da
```

**Google builds distroless with every date set to the start of 1970, and `--timestamp 0` asks Podman
for the same.** Two builds with no cache and that flag produced one image id, and the build without
it a different one, from the same files. `--no-cache` matters here: a cached layer keeps the date it
was first made with, so a cached build can hand back an older image whatever `--timestamp` says.
With the bases pinned by digest, as section 04 left the `Containerfile`, that id is a property of
the source tree and can be checked by anybody with the same two bases.

## Signing with cosign

cosign, from the Sigstore project, signs files and container images. It is a Go program, so it
installs like every tool in this course; the build takes about three minutes:

```
ana@vm:~/ship$ go install github.com/sigstore/cosign/v3/cmd/cosign@v3.1.3
ana@vm:~/ship$ cosign version 2>&1 | grep -e GitVersion -e GoVersion -e Platform
GitVersion:    v3.1.3
GoVersion:     go1.27.1
Platform:      linux/amd64
```

A signature needs a key pair. **The private key signs and never leaves Ana's machine; the public key
verifies and goes out with every release.** cosign encrypts the private key with a password, which
it asks for twice at a terminal or takes from `COSIGN_PASSWORD`. `read -rs` puts the password in
that variable without echoing it or writing it into the shell's history:

```
ana@vm:~/ship$ read -rs COSIGN_PASSWORD; export COSIGN_PASSWORD
ana@vm:~/ship$ cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
ana@vm:~/ship$ stat -c "%a  %n" cosign.key cosign.pub
600  cosign.key
644  cosign.pub
```

Mode 600 on the private key, and it sits in `~/ship`, outside `dist/`. **It also cannot reach an
image**, because section 03's `.containerignore` starts with `*`: a key in the build context is the
classic way to publish one.

### No public log, on purpose

By default cosign v3 takes the services it uses from Sigstore's own signing configuration, and those
include Rekor, Sigstore's public transparency log. A signature recorded there stays there: run with
`--use-signing-config=false`, this cosign stopped to ask before uploading, and its question said the
record "cannot be removed later". For a key on a laptop and a course exercise, that is a record
nobody needs. A configuration of your own replaces Sigstore's, and an empty one names no service at
all:

```
ana@vm:~/ship$ cosign signing-config create --out no-tlog.json && cat no-tlog.json; echo
{"mediaType":"application/vnd.dev.sigstore.signingconfig.v0.2+json","rekorTlogConfig":{},"tsaConfig":{}}
```

**One signature over `SHA256SUMS` covers every file it lists**, so that is the file to sign:

```
ana@vm:~/ship$ cosign sign-blob --key cosign.key --signing-config no-tlog.json --bundle dist/SHA256SUMS.sigstore.json dist/SHA256SUMS
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Using payload from: dist/SHA256SUMS
Signing artifact...
Wrote bundle to file dist/SHA256SUMS.sigstore.json
```

The warning is this lab's: cosign tries to fetch Sigstore's trust root before anything else, and
this machine is not allowed to reach that address. A signature with a key of Ana's own does not need
it, and the bundle was written. **The bundle is a small JSON file holding the signature and the hash
it covers**, and it goes on the release page beside `SHA256SUMS` and `cosign.pub`.

Verifying is what the person downloading does:

```
ana@vm:~/ship$ cosign verify-blob --key cosign.pub --bundle dist/SHA256SUMS.sigstore.json --insecure-ignore-tlog dist/SHA256SUMS
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the blob.
Verified OK
ana@vm:~/ship$ sed "2s/^......../00000000/" dist/SHA256SUMS > forged; cosign verify-blob --key cosign.pub --bundle dist/SHA256SUMS.sigstore.json --insecure-ignore-tlog forged; echo $?
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the blob.
Error: failed to verify signature: could not verify message: invalid signature when validating ASN.1 encoded signature
error during command execution: failed to verify signature: could not verify message: invalid signature when validating ASN.1 encoded signature
1
```

**`Verified OK` for the real file; exit status 1 for a copy with the arm64 checksum rewritten**,
which is what an attacker who replaced the binary would have to do to the list. Without
`--insecure-ignore-tlog`, cosign insists on the log entry this signature deliberately does not have,
and the warning is fair: with no public log, nobody but Ana can see when her key signed something.
The chain runs from the signature to the list and from the list to the binaries, and the link in the
middle is visible in the bundle:

```
ana@vm:~/ship$ jq -r .messageSignature.messageDigest.digest dist/SHA256SUMS.sigstore.json | base64 -d | od -An -tx1 -v | tr -d " \n"; echo
6fd31c4913f2aa88e729d3d55ccd34e9a3046219c0b486edb80b7a6d95ac96e3
ana@vm:~/ship$ sha256sum dist/SHA256SUMS
6fd31c4913f2aa88e729d3d55ccd34e9a3046219c0b486edb80b7a6d95ac96e3  dist/SHA256SUMS
```

The bundle stores the SHA-256 of `SHA256SUMS` in base64; decoded, it is the hash `sha256sum` prints.
**What cosign signed is that hash**, and `SHA256SUMS` in turn holds the hash of each binary. Your
key and your signature will differ from these, because a new key pair is random and so is each ECDSA
signature. The hash will not, if your build matched Ana's.

## What was not run here

Three things a real release adds, described and not run in this lab, which has no registry, no
account with an identity provider and no route to Sigstore's services.

**Keyless signing replaces the key pair with an identity.** `cosign sign-blob` with no `--key` sends
you through a login with an identity provider, such as GitHub or Google, or takes the identity of a
CI job. Sigstore's certificate authority, Fulcio, issues a certificate for that identity that lives
for minutes, the signature goes into Rekor, and a verifier checks the identity with
`--certificate-identity` and `--certificate-oidc-issuer` instead of a public key. There is no
private key to lose, and the log is what makes that safe.

**Provenance and an SBOM say how the file was made.** Provenance is a signed statement of how an
artefact was built: which source, which commit, which builder. An SBOM, a software bill of
materials, lists what went into it. `cosign attest-blob` signs either kind of statement. For a Go
binary, `go version -m` already prints a small SBOM, the modules and settings the build recorded.

**An image is signed separately from the binary.** `cosign sign` signs an image in a registry and
stores the signature beside it in the same registry, addressed by the image's digest. Always sign a
digest, never a tag, for the reason section 04 gave: a tag can be moved after the signature was
made. A release that ships both a binary and an image signs both.
