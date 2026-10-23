---
title: syft, on the image in the registry
version: 1
---

syft is Anchore's SBOM generator. It reads the same records a scanner reads, package databases and
language metadata, and writes them out as a list instead of matching them against advisories.

### Installing it

The way lesson 1 installed uv: the release from GitHub, its published checksum, `install`. From your
home directory:

```
ana@vm:~$ curl -fsSLO https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_linux_amd64.tar.gz
ana@vm:~$ curl -fsSL https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_checksums.txt | grep " syft_1.54.1_linux_amd64.tar.gz$" | sha256sum --check
syft_1.54.1_linux_amd64.tar.gz: OK
ana@vm:~$ tar -xzf syft_1.54.1_linux_amd64.tar.gz syft
ana@vm:~$ install -m 755 syft ~/.local/bin/ && rm syft syft_1.54.1_linux_amd64.tar.gz
ana@vm:~$ syft --version
syft 1.54.1
```

`sha256sum --check` prints `OK` only for the file the project published, and lesson 12 showed what
that check is worth.

### The image it reads

The SBOM should describe the image that ships, which for linkbox is the one in the registry. If the registry is empty, because the lab was rebuilt or its container recreated, run the pipeline on the laptop first, with the branch set so that `push` moves the tag `main`:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ CI_COMMIT=$(git rev-parse --short=7 HEAD) CI_BRANCH=main ci/pipeline.sh
secrets: passed in 0s
test: passed in 2s
sast: passed in 3s
sca: passed in 12s
build: passed in 1s
image: passed in 0s
push: passed in 1s
pipeline passed with 0 warning(s)
```

### The table

With no output format, syft prints a table, one row per package. The image has more rows than fit
on a page, so here are the first twelve, the count of Debian packages, and the Python ones in full:

```
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main | head -n 12
NAME                   VERSION                      TYPE    
base-files             13.8+deb13u7                 deb     
blinker                1.9.0                        python  
ca-certificates        20250419+deb13u1             deb     
click                  8.1.7                        python  
flask                  3.1.3                        python  
gcc-14-base            14.2.0-19                    deb     
gunicorn               22.0.0                       python  
itsdangerous           2.2.0                        python  
jinja2                 3.1.6                        python  
libbz2-1.0             1.0.8-6                      deb     
libc-bin               2.41-12+deb13u4              deb     
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main | awk "\$NF == \"deb\"" | wc -l
38
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main | grep " python "
blinker                1.9.0                        python  
click                  8.1.7                        python  
flask                  3.1.3                        python  
gunicorn               22.0.0                       python  
itsdangerous           2.2.0                        python  
jinja2                 3.1.6                        python  
markupsafe             2.1.3                        python  
packaging              26.3                         python  
werkzeug               3.1.9                        python  
```

**Thirty-eight Debian packages and nine Python ones.** The Debian ones come from
`/var/lib/dpkg/status.d` in the distroless base, the same records Trivy counted 162 findings in.
The Python ones come from the `dist-info` directories under `/packages`, where lesson 8's Dockerfile
put them. Eight of the nine are pinned in `requirements.txt`. The ninth, `packaging 26.3`, is the one
this lesson set out to explain.

### Both formats, from one run

A table is for people. For tools, syft writes the two standard formats, and one run can write both:
each `-o` names a format and a file.

```
ana@vm:~/linkbox$ mkdir ~/sbom
ana@vm:~/linkbox$ syft -q localhost:5000/linkbox:main -o cyclonedx-json=$HOME/sbom/linkbox.cdx.json -o spdx-json=$HOME/sbom/linkbox.spdx.json
ana@vm:~/linkbox$ ls -l ~/sbom
total 2344
-rw-r--r-- 1 ana ana  678631 Oct 23 08:54 linkbox.cdx.json
-rw-r--r-- 1 ana ana 1716646 Oct 23 08:54 linkbox.spdx.json
```

The two files describe the same 47 packages and one operating system, and differ in size by about a megabyte. The next section opens both and shows where the difference comes from.

### Which image, exactly

The SBOM names its subject: `localhost:5000/linkbox` with version `main`, as the next section
shows. **A tag is a name that moves.** Tomorrow's push moves `main` to a different image, and an
SBOM that says only "main" will then describe an image that `main` no longer points at. The pipeline's
stage at the end of this lesson reads the image by the tag of one commit instead, which nothing in
the pipeline ever moves. Lesson 14 goes the rest of
the way and ties the SBOM to the image's digest with a signature.
