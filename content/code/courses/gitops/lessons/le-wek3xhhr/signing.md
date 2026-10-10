---
title: Signing an image
version: 1
---

**By default `cosign` signs for the public world.** It records every signature in Rekor, Sigstore's
public transparency log, and adds a timestamp from a public timestamp authority, so that anybody can
check later when the signature was made. Both are services on the internet. A signature of an image
on your laptop's registry does not belong in a public log, and this laptop's registry is not on the
internet anyway, so `cosign` is told which services to use with a **signing config**: a file listing
them. One with no services at all is a signature with the key and nothing else:

```
ana@laptop:~/signing$ cosign signing-config create --out offline.json
ana@laptop:~/signing$ jq . offline.json
{
  "mediaType": "application/vnd.dev.sigstore.signingconfig.v0.2+json",
  "rekorTlogConfig": {},
  "tsaConfig": {}
}
```

A signing config with an empty `rekorTlogConfig` and an empty `tsaConfig`: no log to record in, no
authority to timestamp. What is left is the key.

**A signature covers a digest, never a tag.** Lesson 7 showed a tag can move; a signature over a tag
would follow it to whatever it points at next. So the digest of `bulletin:1.2` is looked up first,
the same way lesson 7 did, and the image is signed by that:

```
ana@laptop:~/signing$ DIGEST=$(curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5001/v2/bulletin/manifests/1.2 | tr -d "\r" | awk "tolower(\$1) == \"docker-content-digest:\" { print \$2 }"); echo $DIGEST
sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18
ana@laptop:~/signing$ cosign sign --key cosign.key --signing-config offline.json -y localhost:5001/bulletin@$DIGEST
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Signing artifact...
Pushing signature to: localhost:5001/bulletin
ana@laptop:~/signing$ curl -s localhost:5001/v2/bulletin/tags/list | jq -c .tags
["1.0","1.1","1.2","sha256-55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18","stable"]
```

The `WARNING` is the recording machine failing to reach Sigstore's trust root, which `cosign` tries to
fetch on every run; with internet access it does not appear, and a signature made with a key does not
need it. `-y` answers yes to the question `cosign` asks before signing, which is about the public
log and does
not apply here. The signature is in the registry now, as one more tag of `bulletin`, named after the
digest it signs: **anybody who can read the image can find its signature**, and the registry needed
nothing new to store it.

In a pipeline this is one step after the push, run by CI with the key from its secret store. It
signs what was just built, by the digest the push reported, and never by a tag somebody could move
between the two steps.
