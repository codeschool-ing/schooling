---
title: Build once, promote the same bytes
version: 2
---

The artifact is the thing a release deploys: a tarball, a wheel, a container image, a mobile app
bundle. The rule that matters about it is short: **build it once, and deploy those same bytes
everywhere.** A pipeline that builds again for staging and again for production tests one thing and
ships another, and every difference between the builds, a dependency released in between, a flag on
one machine, is a difference nobody tested.

`shipquote`'s artifact is a tarball of the committed tree, built by a script in a new directory,
`mkdir ops`. Save it as `ops/build.sh`:

```schooling-example
{
  "language": "sh",
  "file": "ops/build.sh",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# Build the release artifact: the committed tree at HEAD with its version\n# stamped in, as one tarball, and the SHA-256 that names those exact bytes.\n# The version is the tag on HEAD without its \"v\", or dev-<commit> if none.\nset -euo pipefail",
      "note": "The script stops at the first failing command, and a failing pipe counts as failing, as lesson 5 section 05 asked of every step."
    },
    {
      "code": "tag=$(git describe --tags --exact-match 2>/dev/null || true)\nversion=${tag#v}\nversion=${version:-dev-$(git rev-parse --short HEAD)}\nname=shipquote-$version",
      "note": "The version comes from a **tag on the current commit**, `v1.4.0` becoming `1.4.0`. With no tag the build is called `dev-` and the commit's short hash, so an untagged build can never pass for a release."
    },
    {
      "code": "mkdir -p dist\ngit archive --format=tar.gz --prefix=\"$name/\" \\\n  --add-virtual-file=\"$name/shipquote/VERSION:$version\" \\\n  -o \"dist/$name.tar.gz\" HEAD",
      "note": "`git archive` writes **what is committed and nothing else**, the same rule as lesson 5's clean checkout, and adds one virtual file: the version, stamped inside the artifact."
    },
    {
      "code": "(cd dist && sha256sum \"$name.tar.gz\" > \"$name.tar.gz.sha256\")\necho \"dist/$name.tar.gz\"",
      "note": "The SHA-256 of the tarball, written beside it. That hash is the artifact's identity from here on."
    }
  ]
}
```

The build names the release after a tag, so the release needs one, on a commit that holds
everything it deploys with. Four more scripts belong to it: `deploy.sh`, `restart.sh` and
`rollback.sh`, shown whole in section 06, and `smoke.sh`, in section 07. Save those four now as
well, then make all five executable, commit, and tag the commit as release 1.4.0:

```sh
chmod +x ops/*.sh
git add ops
git commit -m "Build one artifact, deploy it, and check it answers"
git tag -a v1.4.0 -m "shipquote 1.4.0"
```

Then the build, twice:

```
ana@laptop:~/shipquote$ git describe --tags
v1.4.0
ana@laptop:~/shipquote$ ops/build.sh
dist/shipquote-1.4.0.tar.gz
ana@laptop:~/shipquote$ cat dist/shipquote-1.4.0.tar.gz.sha256
4b61176498717d0fb05adae2b03d1b2dfafb346899610aab7197818b75d0d5f3  shipquote-1.4.0.tar.gz
ana@laptop:~/shipquote$ rm -rf dist && ops/build.sh > /dev/null && cat dist/shipquote-1.4.0.tar.gz.sha256
4b61176498717d0fb05adae2b03d1b2dfafb346899610aab7197818b75d0d5f3  shipquote-1.4.0.tar.gz
```

The build printed the artifact's path, and its hash begins `4b611764`; yours begins with something
else, because the archive records the commit's time and yours was made at another one. Then
`dist/` was deleted and the build run again, and **the hash is the same**. `git archive` sets every file's timestamp from the
commit rather than from the clock, so the same commit gives the same bytes. A build with that
property is called **reproducible**, and it means anybody can check that an artifact came from the
commit it claims: build it again and compare the hash.

## Why the hash and not the name

A file called `shipquote-1.4.0.tar.gz` can be replaced by another file with the same name. A hash
cannot. Section 08 deploys to production with the hash checked first, and shows what happens to an
artifact that changed by one byte on its way there. Container registries make the same distinction:
`shipquote:1.4.0` is a tag anybody with write access can move, and `shipquote@sha256:…` is the image
itself.
