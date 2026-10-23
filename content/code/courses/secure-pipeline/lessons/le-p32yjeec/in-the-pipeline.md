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

```
ana@vm:~/linkbox$ git add ci/sbom.sh ci/stages
ana@vm:~/linkbox$ git commit -q -m "a bill of materials for every image pushed"
8:54AM INF 0 commits scanned.
8:54AM INF scanned ~286 bytes (286 bytes) in 182ms
8:54AM INF no leaks found
```

```
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 4e552d7        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 10s        
remote: build: passed in 1s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 6s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   1d23ec6..4e552d7  main -> main
```

The two files are in the run's directory, beside the logs:

```
ana@vm:~/linkbox$ ls ~/ci/runs/1/logs
build.log
image.log
push.log
sast.log
sbom.cdx.json
sbom.log
sbom.spdx.json
sca.log
secrets.log
test.log
ana@vm:~/linkbox$ jq ".components | length" ~/ci/runs/1/logs/sbom.cdx.json
2190
```

### Where to keep it

**Beside the run, for now.** `~/ci/runs/N/logs` holds every run's SBOM, named for nothing but the
run, and the commit and the image tag tie them together. That is enough to answer "which runs
shipped packaging 26.3" with one loop over the directory:

```
ana@vm:~/linkbox$ for f in ~/ci/runs/*/logs/sbom.cdx.json; do jq -r --arg f "$f" ".components[] | select(.name == \"packaging\") | \"\(\$f): \(.name) \(.version)\"" "$f"; done
/home/ana/ci/runs/1/logs/sbom.cdx.json: packaging 26.3
```

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

```
ana@vm:~/linkbox$ syft -q dir:. | head -n 14
NAME          VERSION  TYPE                    
blinker       1.9.0    python  (+1 duplicate)  
click         8.1.7    python  (+1 duplicate)  
flask         3.1.3    python  (+1 duplicate)  
gunicorn      22.0.0   python  (+1 duplicate)  
iniconfig     2.3.1    python                  
itsdangerous  2.2.0    python  (+1 duplicate)  
jinja2        3.1.6    python  (+1 duplicate)  
markupsafe    2.1.3    python  (+1 duplicate)  
packaging     26.3     python                  
pluggy        1.7.0    python                  
pygments      2.21.0   python                  
pytest        9.0.3    python  (+1 duplicate)  
werkzeug      3.1.9    python  (+1 duplicate)
```

From the repository, with the virtual environment the tests made, syft finds every pin twice (once
in `requirements.txt`, once installed in `.venv`), finds pytest and its dependencies, which never
reach the image, and finds no Debian package, because the base image is not in the repository.
**An SBOM describes the thing it was made from**, and the thing that runs is the image, which is why
the stage reads the image.
