---
title: A bill of materials for every image pushed
version: 1
---

An SBOM made by hand on a Tuesday describes Tuesday's image. **The one worth having is made by the
pipeline, for every image it pushes, from that image and nothing else**, and kept where the run is
kept. That is one more stage, after `push`, so that it describes exactly the bytes that are now in
the registry.

### The stage

Save it as `ci/sbom.sh`:

```sh
# The bill of materials of the image this run pushed, in CycloneDX and in
# SPDX, kept beside the run's logs.
set -euo pipefail
out=${CI_LOGS:-ci-logs}
syft -q "localhost:5000/linkbox:${CI_COMMIT:-dev}" \
  -o cyclonedx-json="$out/sbom.cdx.json" -o spdx-json="$out/sbom.spdx.json"
```

Three decisions are in those six lines. It reads the image **from the registry**, by the tag of
this run's commit, so the SBOM describes what was pushed rather than what happens to be in the local
Docker. It writes **both formats** from one run of syft, which reads the image once. And it writes
them into the run's own log directory, so that each run's SBOM sits beside the logs that say how
that image was built and checked.

The list, with the new stage at the end, as `ci/stages`:

```
secrets
test
sast
sca
build
image
push
sbom
```

It goes last because it describes the pushed image; a run that broke before `push` has nothing to
describe. And it breaks the build if syft fails, which is deliberate: **an image with no bill of
materials is an image nobody can answer questions about later**, and finding that out on the day of
the advisory is too late.

### The run

Commit both, and push to the CI:

@@CAPTURE commit@@

@@CAPTURE push@@

The two files are in the run's directory, beside the logs:

@@CAPTURE run-files@@

### Where to keep it

**Beside the run, for now.** `~/ci/runs/N/logs` holds every run's SBOM, named for nothing but the
run, and the commit and the image tag tie them together. That is enough to answer "which runs
shipped packaging 26.3" with one loop over the directory:

@@CAPTURE across-runs@@

It has two weaknesses that a real installation has to fix. The SBOM and the image live in different
places, so a copy of the image somewhere else arrives without its list; and nothing proves the list
was written by the pipeline rather than edited afterwards. **Lesson 14 fixes both at once**: it
signs the SBOM and attaches it to the image in the registry as an attestation, so the list travels
with the image and carries the pipeline's signature.

Larger organisations also send every SBOM to a service that stores and indexes them, so that the
question "who has packaging 26.3" is asked once across every team's images instead of once per
directory. OWASP's Dependency-Track is the common open-source one. It was not run for this course;
what it does is the loop above, at the scale of a company, with the scanning of the next section
done every day against new advisories.

### What an image SBOM cannot see

An SBOM is only as complete as the records the generator finds. syft read the Debian package
database and the Python `dist-info` directories, and anything installed without leaving such a
record is invisible to it:

- **a binary copied in by hand**, a `COPY` of a downloaded tool or a `curl` in a `RUN`, has no
  package record, so it appears, at best, as a file with no name and no version;
- **code vendored into the application**, a library pasted into `app.py`, is part of linkbox as far
  as any tool can tell;
- **what the image does at run time**, such as a package installed when the container starts, is in
  no layer at all.

The source tree is a different measurement again, not a better one:

@@CAPTURE dir@@

From the repository, with the virtual environment the tests made, syft finds every pin twice (once
in `requirements.txt`, once installed in `.venv`), finds pytest and its dependencies, which never
reach the image, and finds no Debian package, because the base image is not in the repository.
**An SBOM describes the thing it was made from**, and the thing that runs is the image, which is why
the stage reads the image.
