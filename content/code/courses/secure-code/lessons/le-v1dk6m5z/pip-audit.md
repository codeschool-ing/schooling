---
title: pip-audit, against a real lock
version: 1
---

**pip-audit** reads a list of packages and versions and asks PyPI's advisory data about each one.
It is maintained by the Python Packaging Authority, it needs no account, and it runs in a second.
Install it into the course's environment:

```
(.venv) ana@vm:~/sc/deps$ pip install --progress-bar off pip-audit==2.10.1
Collecting pip-audit==2.10.1
  Downloading pip_audit-2.10.1-py3-none-any.whl.metadata (28 kB)
Collecting CacheControl>=0.13.0 (from CacheControl[filecache]>=0.13.0->pip-audit==2.10.1)
  Downloading cachecontrol-0.14.4-py3-none-any.whl.metadata (3.1 kB)
Collecting cyclonedx-python-lib<12,>=5 (from pip-audit==2.10.1)
  Downloading cyclonedx_python_lib-11.12.0-py3-none-any.whl.metadata (6.9 kB)
Requirement already satisfied: packaging>=23.0.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from pip-audit==2.10.1) (26.3)
Collecting pip-api>=0.0.28 (from pip-audit==2.10.1)
  Downloading pip_api-0.0.35-py3-none-any.whl.metadata (17 kB)
Collecting pip-requirements-parser>=32.0.0 (from pip-audit==2.10.1)
  Downloading pip_requirements_parser-32.0.1-py3-none-any.whl.metadata (9.3 kB)
Collecting requests>=2.31.0 (from pip-audit==2.10.1)
  Downloading requests-2.34.2-py3-none-any.whl.metadata (4.8 kB)
Collecting rich>=12.4 (from pip-audit==2.10.1)
  Downloading rich-15.0.0-py3-none-any.whl.metadata (18 kB)
Collecting tomli>=2.2.1 (from pip-audit==2.10.1)
  Downloading tomli-2.5.0-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (10 kB)
Collecting tomli-w>=1.2.0 (from pip-audit==2.10.1)
  Downloading tomli_w-1.2.0-py3-none-any.whl.metadata (5.7 kB)
Collecting platformdirs>=4.2.0 (from pip-audit==2.10.1)
  Downloading platformdirs-4.13.5-py3-none-any.whl.metadata (5.5 kB)
Collecting license-expression<31,>=30 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading license_expression-30.4.4-py3-none-any.whl.metadata (11 kB)
Collecting packageurl-python<2,>=0.11 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading packageurl_python-0.17.6-py3-none-any.whl.metadata (5.1 kB)
Collecting py-serializable<3.0.0,>=2.1.0 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading py_serializable-2.1.0-py3-none-any.whl.metadata (4.3 kB)
Collecting sortedcontainers<3.0.0,>=2.4.0 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading sortedcontainers-2.4.0-py2.py3-none-any.whl.metadata (10 kB)
Collecting boolean.py>=4.0 (from license-expression<31,>=30->cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading boolean_py-5.0-py3-none-any.whl.metadata (2.3 kB)
Collecting defusedxml<0.8.0,>=0.7.1 (from py-serializable<3.0.0,>=2.1.0->cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading defusedxml-0.7.1-py2.py3-none-any.whl.metadata (32 kB)
Collecting msgpack<2.0.0,>=0.5.2 (from CacheControl>=0.13.0->CacheControl[filecache]>=0.13.0->pip-audit==2.10.1)
  Downloading msgpack-1.2.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (8.3 kB)
Collecting filelock>=3.8.0 (from CacheControl[filecache]>=0.13.0->pip-audit==2.10.1)
  Downloading filelock-4.2.4-py3-none-any.whl.metadata (2.0 kB)
Requirement already satisfied: pip in /home/ana/sc/.venv/lib/python3.13/site-packages (from pip-api>=0.0.28->pip-audit==2.10.1) (26.2.1)
Collecting pyparsing (from pip-requirements-parser>=32.0.0->pip-audit==2.10.1)
  Downloading pyparsing-3.3.3-py3-none-any.whl.metadata (5.9 kB)
Collecting charset_normalizer<4,>=2 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading charset_normalizer-3.5.2-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (46 kB)
Collecting idna<4,>=2.5 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading idna-3.20-py3-none-any.whl.metadata (7.2 kB)
Collecting urllib3<3,>=1.26 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading urllib3-2.8.0-py3-none-any.whl.metadata (7.4 kB)
Collecting certifi>=2023.5.7 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading certifi-2026.10.23-py3-none-any.whl.metadata (2.5 kB)
Collecting markdown-it-py>=2.2.0 (from rich>=12.4->pip-audit==2.10.1)
  Downloading markdown_it_py-4.2.0-py3-none-any.whl.metadata (7.4 kB)
Requirement already satisfied: pygments<3.0.0,>=2.13.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from rich>=12.4->pip-audit==2.10.1) (2.21.0)
Collecting mdurl~=0.1 (from markdown-it-py>=2.2.0->rich>=12.4->pip-audit==2.10.1)
  Downloading mdurl-0.1.2-py3-none-any.whl.metadata (1.6 kB)
Downloading pip_audit-2.10.1-py3-none-any.whl (62 kB)
Downloading cyclonedx_python_lib-11.12.0-py3-none-any.whl (529 kB)
Downloading license_expression-30.4.4-py3-none-any.whl (120 kB)
Downloading packageurl_python-0.17.6-py3-none-any.whl (36 kB)
Downloading py_serializable-2.1.0-py3-none-any.whl (23 kB)
Downloading defusedxml-0.7.1-py2.py3-none-any.whl (25 kB)
Downloading sortedcontainers-2.4.0-py2.py3-none-any.whl (29 kB)
Downloading boolean_py-5.0-py3-none-any.whl (26 kB)
Downloading cachecontrol-0.14.4-py3-none-any.whl (22 kB)
Downloading msgpack-1.2.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (466 kB)
Downloading filelock-4.2.4-py3-none-any.whl (162 kB)
Downloading pip_api-0.0.35-py3-none-any.whl (123 kB)
Downloading pip_requirements_parser-32.0.1-py3-none-any.whl (35 kB)
Downloading platformdirs-4.13.5-py3-none-any.whl (32 kB)
Downloading requests-2.34.2-py3-none-any.whl (73 kB)
Downloading charset_normalizer-3.5.2-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (254 kB)
Downloading idna-3.20-py3-none-any.whl (69 kB)
Downloading urllib3-2.8.0-py3-none-any.whl (135 kB)
Downloading certifi-2026.10.23-py3-none-any.whl (135 kB)
Downloading rich-15.0.0-py3-none-any.whl (310 kB)
Downloading markdown_it_py-4.2.0-py3-none-any.whl (91 kB)
Downloading mdurl-0.1.2-py3-none-any.whl (10.0 kB)
Downloading tomli-2.5.0-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (283 kB)
Downloading tomli_w-1.2.0-py3-none-any.whl (6.7 kB)
Downloading pyparsing-3.3.3-py3-none-any.whl (126 kB)
Installing collected packages: sortedcontainers, boolean.py, urllib3, tomli-w, tomli, pyparsing, platformdirs, pip-api, packageurl-python, msgpack, mdurl, license-expression, idna, filelock, defusedxml, charset_normalizer, certifi, requests, py-serializable, pip-requirements-parser, markdown-it-py, rich, cyclonedx-python-lib, CacheControl, pip-audit
Successfully installed CacheControl-0.14.4 boolean.py-5.0 certifi-2026.10.23 charset_normalizer-3.5.2 cyclonedx-python-lib-11.12.0 defusedxml-0.7.1 filelock-4.2.4 idna-3.20 license-expression-30.4.4 markdown-it-py-4.2.0 mdurl-0.1.2 msgpack-1.2.3 packageurl-python-0.17.6 pip-api-0.0.35 pip-audit-2.10.1 pip-requirements-parser-32.0.1 platformdirs-4.13.5 py-serializable-2.1.0 pyparsing-3.3.3 requests-2.34.2 rich-15.0.0 sortedcontainers-2.4.0 tomli-2.5.0 tomli-w-1.2.0 urllib3-2.8.0
```

A tool that checks dependencies has dependencies too, 24 of them, which is the first section of
this lesson in one transcript. Every name in that list is now code in your environment.

### A lock from last year

Here is the kind of file a project accumulates: a `requirements.txt` with exact versions, written
when each was current and not touched since. Save it in `~/sc/deps`, and commit it:

```
# requirements.txt
flask==3.1.3
jinja2==3.1.4
requests==2.31.0
```

`-r` audits the file rather than the environment, so it checks exactly the versions the project
says it installs:

```
(.venv) ana@vm:~/sc/deps$ pip-audit -r requirements.txt
Found 12 known vulnerabilities in 2 packages
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
jinja2   3.1.4   PYSEC-2026-1475 3.1.5
jinja2   3.1.4   PYSEC-2026-1472 3.1.5
jinja2   3.1.4   PYSEC-2026-1471 3.1.6
jinja2   3.1.4   PYSEC-2026-1471 3.1.6
jinja2   3.1.4   PYSEC-2026-1475 3.1.5
jinja2   3.1.4   PYSEC-2026-1472 3.1.5
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
```

**Read the identifiers, not the count.** pip-audit reports twelve, and each identifier appears
twice in the list, because the advisory data answered each one twice. There are six distinct
advisories, three for each package, and for each one the last column is the version to move to.
The highest fixed version per package is the one that clears all of them: `3.1.6` for Jinja2 and
`2.33.0` for requests.

### The fix is a new pin

Change the two lines. Jinja2 goes to `3.1.6`, the highest fixed version listed. For requests the
current release, `2.34.2`, is later than every fixed version in the list, and staying on a
current release is better than landing exactly on the minimum:

```
# requirements.txt
flask==3.1.3
jinja2==3.1.6
requests==2.34.2
```

```
(.venv) ana@vm:~/sc/deps$ git diff
diff --git a/requirements.txt b/requirements.txt
index 00907dd..15dcfe2 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,4 +1,4 @@
 # requirements.txt
 flask==3.1.3
-jinja2==3.1.4
-requests==2.31.0
+jinja2==3.1.6
+requests==2.34.2
```

```
(.venv) ana@vm:~/sc/deps$ pip-audit -r requirements.txt
No known vulnerabilities found
```

A clean audit says no **published** advisory matches these versions today. It says nothing about
flaws nobody has reported yet, and it is only true until the next advisory, which is why the audit
belongs in a routine and not in a one-off check.

::: track devsecops
In your track, `secure-pipeline` lesson 5 runs this same audit in the pipeline, on every change,
and decides what happens to a build when it fails. This lesson introduces the tool; that one
operates it.
:::

::: track *
The natural home for this command is the pipeline that tests every change, so that a new advisory
fails a build on the day it is published. Lesson 19 puts it next to the other automated checks of
this course.
:::
