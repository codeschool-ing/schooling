---
title: Signing an image, and checking the signature
version: 1
---

**Signing an image means signing its digest with a private key, so that anybody with the public key
can check that this exact image was signed by whoever holds that key.** Binary Authorization's
attestations are this, stored in Google's Container Analysis. The same idea, with an open-source tool
you can run, is **cosign**, from the Sigstore project. Binary Authorization accepts Sigstore
signatures in GKE's check-based platform policies, so what follows is close to what a real signing step
does, against the local registry of lesson 2. **None of it is Binary Authorization**:
nothing here refuses a deployment. It shows what is being checked.

cosign publishes an image of itself, so it needs no installation. This line makes `cosign` a command in
your terminal that runs that image with your current directory mounted, as you, on the host's network
so that it can reach `localhost:5000`:

```sh
cosign() { docker run --rm --network host --user "$(id -u):$(id -g)" -v "$PWD":/w -w /w -e COSIGN_PASSWORD gcr.io/projectsigstore/cosign:v2.6.1 "$@"; }
```

Like the variables of lesson 1, it lives in that terminal only. Start the local registry again, build
the shop's image, push it under the tag `a1b2c3d`, and keep its digest:

```sh
docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0
docker build -q -t localhost:5000/shop/api:a1b2c3d api
docker push -q localhost:5000/shop/api:a1b2c3d
```

## A key pair

```
ana@laptop:~/gcp/shop$ cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
```

`COSIGN_PASSWORD` was set to nothing (`export COSIGN_PASSWORD=`) before this, so the private key is
not protected by a password. **That is for this lab only.** A real signing key never sits in a file: it
lives in Cloud KMS, which lesson 18 is about, and cosign signs with it by name, `--key gcpkms://…`,
without the private half ever leaving Google.

## Signing a digest

```
ana@laptop:~/gcp/shop$ cosign sign --key cosign.key --tlog-upload=false --yes localhost:5000/shop/api@sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352
Pushing signature to: localhost:5000/shop/api
```

**The signature is over the digest**, and cosign stores it in the registry beside the image, as an
artifact tagged with the digest and `.sig`. `--tlog-upload=false` keeps it off Sigstore's public
transparency log, which a real pipeline would write to and this lab does not.

Anybody with `cosign.pub` can now check it:

```
ana@laptop:~/gcp/shop$ cosign verify --key cosign.pub --insecure-ignore-tlog --offline localhost:5000/shop/api@sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352 2>&1 | grep -v 'Could not fetch'
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5000/shop/api@sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"localhost:5000/shop/api"},"image":{"docker-manifest-digest":"sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352"},"type":"cosign container image signature"},"optional":null}]
```

The warning is cosign saying, correctly, that it did not check the transparency log, because nothing
was written to it. The `grep` removes a second warning, about not reaching Sigstore's servers to
refresh their keys, which depends on your network and says nothing about this signature. Then the
result: the signature verifies against the public key, and the payload names the digest it was made
over.

## The tag moves; the signature does not

Now the move from lesson 2: add the eraser to `api/app.py`, rebuild, and push under the **same tag**.
Then ask cosign to verify the tag:

```
ana@laptop:~/gcp/shop$ cosign verify --key cosign.pub --insecure-ignore-tlog --offline localhost:5000/shop/api:a1b2c3d 2>&1 | grep -v 'Could not fetch'
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found
```

**No signatures found.** cosign resolved the tag to its new digest and looked for a signature over that
digest; there is none, because nobody signed the new image. The old signature is still in the
registry, over the old digest, and it says nothing about anything else. A policy that requires a
signature therefore refuses an image that somebody pushed over a signed tag, which is exactly the
mistake lesson 2 showed passing in silence.
