---
title: A key for the CI server, and the first signature
version: 1
---

A signature here is the same arithmetic as anywhere else: a private key turns a digest into a
signature, and the matching public key checks it. **What makes it useful in a pipeline is who holds
the private key.** If every developer can sign, a signature says "somebody on the team", which a
verifier cannot act on. If only the CI server can, a signature says "this went through the
pipeline", and that is a claim a deployment can require.

The tool is `cosign`, from the Sigstore project, an open project under the Linux Foundation.
`gitops` lesson 8 used it to sign a chart and an image from a laptop; here the key belongs to the
CI server and the signing becomes a stage. The commands are the same, and the difference is where
the key lives. It installs like every tool in this course, the release and its checksum:

```
ana@vm:~$ curl -fsSLO https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-linux-amd64
ana@vm:~$ curl -fsSL https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign_checksums.txt | grep " cosign-linux-amd64$" | sha256sum --check
cosign-linux-amd64: OK
ana@vm:~$ install -m 755 cosign-linux-amd64 ~/.local/bin/cosign && rm cosign-linux-amd64
ana@vm:~$ cosign version | grep GitVersion
GitVersion:    v3.1.3
```

The release is a single binary, so there is nothing to unpack.

### The keys, beside the server and away from the code

The CI server of this course is the directory `~/ci`, so its keys go in `~/ci/keys`, which no
clone of linkbox ever contains. The private key is encrypted with a password, the password is a
random string in a file only Ana can read, and `cosign` reads it from the variable
`COSIGN_PASSWORD` instead of asking for it:

```
ana@vm:~/linkbox$ mkdir -p ~/ci/keys && cd ~/ci/keys
ana@vm:~/ci/keys$ openssl rand -base64 24 > password && chmod 600 password
ana@vm:~/ci/keys$ COSIGN_PASSWORD=$(cat password) cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
ana@vm:~/ci/keys$ cosign signing-config create --out offline.json
ana@vm:~/ci/keys$ jq . offline.json
{
  "mediaType": "application/vnd.dev.sigstore.signingconfig.v0.2+json",
  "rekorTlogConfig": {},
  "tsaConfig": {}
}
ana@vm:~/ci/keys$ ls -l
total 16
-rw------- 1 ana ana 653 Oct 23 09:33 cosign.key
-rw-r--r-- 1 ana ana 178 Oct 23 09:33 cosign.pub
-rw------- 1 ana ana 104 Oct 23 09:33 offline.json
-rw------- 1 ana ana  33 Oct 23 09:33 password
ana@vm:~/ci/keys$ cd ~/linkbox
```

Four files, and they are not equally secret. **`cosign.key` and `password` together can sign
anything in the CI's name**; either alone cannot. `cosign.pub` is the opposite: it is useless for
signing and has to be everywhere a verification happens. `offline.json` is the fourth, and it
needs a paragraph of its own.

### Why a signing config with nothing in it

By default `cosign` signs for the public world. It records every signature in **Rekor**, Sigstore's
public transparency log, and asks a public timestamp authority for a timestamp, so that anybody can
check later that the signature existed at a given moment. That is the right default for a project
whose images are public. For linkbox it would publish, forever, the digest of every image and the
name of a registry that exists only on a laptop. And on the machine these lessons were recorded on
the choice was made anyway: Sigstore's public services cannot be reached from it, so a signature
that depended on them could not be made at all.

A **signing config** is a file that lists the services `cosign` should use. The one created above
lists none: an empty `rekorTlogConfig` and an empty `tsaConfig`. **What is left is the key, and
nothing else.** On your own machine, with internet access, signing without `--signing-config`
would write to Rekor; whether that is acceptable is a decision about what your digests reveal, and
for a private service the answer is usually no.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l14-flow\" aria-label=\"Signing and verifying. The CI server holds cosign.key and its password in ~/ci/keys and signs the digest it pushed; the signature goes to the registry beside the image, under a tag named after the digest. A verifier holding cosign.pub fetches both, checks the signature over the digest, and only then deploys that digest.\"><defs><marker id=\"sp-l14-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l14-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l14-flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the CI server</text><rect x=\"20\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/keys</text><text x=\"110.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cosign.key + password</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the registry</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the image</text><text x=\"360.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox@sha256:…</text><rect x=\"270\" y=\"100\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the signature</text><text x=\"360.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tag sha256-…</text><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a verifier</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cosign verify</text><text x=\"610.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--key cosign.pub</text><path d=\"M200 65 L230 65 L230 122 L268 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-phosphor)\"></path><text x=\"215\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">signs the digest</text><path d=\"M518 65 L452 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-paper-dim)\"></path><path d=\"M518 80 L490 80 L490 122 L452 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-paper-dim)\"></path><text x=\"485\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fetches both</text><rect x=\"520\" y=\"120\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passes: deploy the digest</text><rect x=\"520\" y=\"172\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fails: refuse</text><path d=\"M610 90 L610 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-phosphor)\"></path><path d=\"M700 70 L712 70 L712 190 L702 190\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-flow-ah-amber)\"></path></svg>", "caption": "The private key never leaves the CI server; the public key goes wherever a verification happens."}
```

### Sign the digest

The digest comes from the image the CI server pushed for the last commit. `docker inspect` lists
every reference the image is known by, and the line for this registry is the one to sign:

```
ana@vm:~/linkbox$ REF=$(docker inspect --format "{{range .RepoDigests}}{{println .}}{{end}}" localhost:5000/linkbox:$(git rev-parse --short HEAD) | grep ^localhost:5000/); echo $REF
localhost:5000/linkbox@sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
ana@vm:~/linkbox$ export COSIGN_PASSWORD=$(cat ~/ci/keys/password)
ana@vm:~/linkbox$ cosign sign --yes --key ~/ci/keys/cosign.key --signing-config ~/ci/keys/offline.json $REF
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Signing artifact...
Pushing signature to: localhost:5000/linkbox
ana@vm:~/linkbox$ unset COSIGN_PASSWORD
ana@vm:~/linkbox$ curl -s localhost:5000/v2/linkbox/tags/list | jq -c .tags
["de3591e","main","sha256-a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179"]
```

The `WARNING` is `cosign` failing to reach Sigstore's trust root, which it tries on every run; with
internet access it does not appear, and a signature made with a key does not need it. `--yes`
answers the question `cosign` asks before signing, which is about the public log and does not apply
here. **The signature is in the registry now, under a tag named after the digest it signs**, so
anybody who can read the image can find it, and the registry needed no new feature to hold it.

### Verify it

Verifying needs the image, the public key, and a decision about the log.
`--insecure-ignore-tlog=true` says that no log entry is expected, which is true of every signature
in this course, and the flag carries that name because skipping the log removes the public record
of when a signature was made:

```
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true $REF | jq .
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5000/linkbox@sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
[
  {
    "critical": {
      "identity": {
        "docker-reference": "localhost:5000/linkbox@sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179"
      },
      "image": {
        "docker-manifest-digest": "sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179"
      },
      "type": "https://sigstore.dev/cosign/sign/v1"
    },
    "optional": {}
  }
]
```

The `WARNING` says exactly that, and for these signatures it is the design. The list of checks is
the one `cosign` prints every time, whether or not a log was involved. **The JSON is what was
actually signed**: a small document naming the image's digest under `docker-manifest-digest`. That
is why a signature cannot be moved to other bytes, and why the next section can show it refusing.
