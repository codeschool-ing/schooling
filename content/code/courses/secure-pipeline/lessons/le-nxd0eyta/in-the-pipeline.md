---
title: Signing in the pipeline
version: 1
---

Signing by hand proves the mechanism and nothing else. **What a verifier needs is that every image
the CI pushes is signed by the CI, by the same key, with no person in between.** So the signature
becomes a stage, and it goes last: it runs only when every stage before it passed, which makes a
signature mean "this image went through the whole list", not only "somebody had the key".

The stage also attaches two statements to the image, each signed with the same key. One is the
bill of materials lesson 13 already writes beside the run's logs. The other is the **provenance**
of the run: which repository, which commit, which builder. A signed statement about an artefact is
called an **attestation**, and the next section reads both of them back. Save the stage as
`ci/sign.sh`:

```schooling-example
{"language": "sh", "file": "ci/sign.sh", "parts": [{"code": "# The pushed image, signed by digest, and two attestations about it, signed\n# with the same key: its bill of materials and the provenance of this run.\n# The key and its password belong to the CI server, in ~/ci/keys, and never\n# to the repository.", "note": "The stage's whole job: one signature over the image and two signed statements about it. The key is the CI server's, kept outside every repository it builds."}, {"code": "set -euo pipefail\nout=${CI_LOGS:-ci-logs}\nkeys=~/ci/keys\nref=$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' \\\n  \"localhost:5000/linkbox:${CI_COMMIT:-dev}\" | grep '^localhost:5000/')", "note": "The digest of the image this run pushed. `docker push` recorded it in `RepoDigests`, and the line for the registry is the one to sign: a tag could move between this step and the next."}, {"code": "python3 ci/provenance.py >\"$out/provenance.json\"", "note": "The provenance is written beside the run's logs, where `ci/sbom.sh` already put the bill of materials."}, {"code": "export COSIGN_PASSWORD\nCOSIGN_PASSWORD=$(cat \"$keys/password\")", "note": "cosign reads the key's password from `COSIGN_PASSWORD`, so it is read from the file into the environment of this script and nowhere else."}, {"code": "sign() { cosign \"$@\" --yes --key \"$keys/cosign.key\" --signing-config \"$keys/offline.json\"; }", "note": "Every call carries the same three flags: no question to answer, the CI's key, and the signing config with no public services in it."}, {"code": "sign sign \"$ref\"\nsign attest --type cyclonedx --predicate \"$out/sbom.cdx.json\" \"$ref\"\nsign attest --type slsaprovenance1 --predicate \"$out/provenance.json\" \"$ref\"\necho \"signed $ref\"", "note": "The signature, then the two attestations. `--type` names what the statement claims to be, and a verifier asks for it by that name."}]}
```

The provenance comes from a short program, because the CI server is the only party that knows what
it checked out. Save it as `ci/provenance.py`:

```schooling-example
{"language": "python", "file": "ci/provenance.py", "parts": [{"code": "\"\"\"The provenance of this run, as a SLSA v1 predicate: what was built, from\nwhich commit of which repository, by which builder, and when. The image it\ndescribes is the subject of the attestation that carries it.\"\"\"\nimport datetime\nimport json\nimport os\nfrom pathlib import Path\n", "note": "A predicate is the body of a statement. This one follows SLSA's provenance format, version 1, and cosign wraps it in an envelope whose subject is the image's digest."}, {"code": "# The CI server checks the pushed commit out detached, so HEAD holds its hash.\ncommit = Path(\".git/HEAD\").read_text().strip()", "note": "The commit comes from the checkout itself, never from a variable somebody could set. The server's hook checks the pushed commit out detached, so `.git/HEAD` holds its full hash and nothing else."}, {"code": "print(json.dumps({\n    \"buildDefinition\": {\n        \"buildType\": \"https://example.org/linkbox/ci/pipeline/v1\",\n        \"externalParameters\": {\n            \"repository\": \"ci/linkbox.git\",\n            \"ref\": \"refs/heads/\" + os.environ.get(\"CI_BRANCH\", \"main\"),\n        },\n        \"resolvedDependencies\": [\n            {\"uri\": \"git+file:ci/linkbox.git\", \"digest\": {\"gitCommit\": commit}},\n        ],\n    },", "note": "`buildDefinition` is what was asked for: which repository, which branch, and the exact commit that was resolved."}, {"code": "    \"runDetails\": {\n        \"builder\": {\"id\": \"https://example.org/linkbox/ci/post-receive\"},\n        \"metadata\": {\n            \"invocationId\": os.environ.get(\"CI_LOGS\", \"local\"),\n            \"finishedOn\": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec=\"seconds\"),\n        },\n    },\n}, indent=2))", "note": "`runDetails` is who did it and when. The builder's id is a name this course makes up for its hook; a hosted CI writes its own, which is what a verifier can insist on."}]}
```

Then the list gains its last entry. Save it as `ci/stages`:

```
secrets
test
sast
sca
build
image
push
sbom
sign
```

### Where the key is, and what that means

`ci/sign.sh` reads the key from `~/ci/keys`, which is the CI server's home and outside every
clone the hook makes. **Nothing in the repository holds the key or its password**, so a fork, a
clone or a leaked backup of linkbox's history carries none of it. That is the arrangement
`testing-cicd` lesson 9 asks of every secret a pipeline uses, and it is the least this key needs.

It is not the most. **The script that signs comes from the commit being built**, like every stage
in this course: the hook runs whatever `ci/sign.sh` the pushed commit contains. Somebody who can
push a branch can therefore change what the stage does with the key, for that one run. On this
laptop the person who pushes and the person who owns the key are both Ana, so nothing is lost. In
a team they are not the same people, and lesson 16 is about exactly that gap: what a pipeline lets
the author of a change do with credentials the author was never given.

### The run

Commit the three files and push:

@@CAPTURE pipeline@@

The pre-commit hook from lesson 6 scanned the staged files on the way, which is the first four
lines of output. Then the run: `sign` is the ninth stage and it passed. Its log carries the same
`WARNING` about Sigstore's trust root three times, once per call, and apart from those it reads:

@@CAPTURE sign-log@@

**One signature and two attestations, all over one digest.** `Using payload from` names the file
each attestation was made of, and the last line is the reference a deployment can use. Every push
to `main` from now on ends the same way, and so does every branch, because the hook runs the same
list for every branch it receives.
