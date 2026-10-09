---
title: A workflow file, line by line
version: 2
---

GitHub Actions reads pipelines from YAML files in `.github/workflows/` of the repository. Each file
is a **workflow**: the events that start it, and the jobs it runs. This one does what lesson 5's
hook did, plus the coverage of lesson 4, on GitHub's machines. The directory is new,
`mkdir -p .github/workflows`, and the file goes in it. Save it as `.github/workflows/ci.yml`:

```schooling-example
{
  "language": "yaml",
  "file": ".github/workflows/ci.yml",
  "parts": [
    {
      "code": "name: CI\n\non:\n  pull_request:\n    branches: [main]\n  push:\n    branches: [main]\n\npermissions:\n  contents: read\n\nconcurrency:\n  group: ci-${{ github.ref }}\n  cancel-in-progress: true\n",
      "note": "The name shown on the web page, and the **triggers** of lesson 5 section 04: pull requests to `main` and pushes to `main`. `permissions` limits what the token GitHub gives every run may do, here only read the code; lesson 9 is about that line. `concurrency` cancels a run when a newer one starts for the same branch, which section 09 shows happening."
    },
    {
      "code": "jobs:\n  fast:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 5\n    steps:\n      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0\n        with:\n          python-version: \"3.13\"\n          cache: pip\n          cache-dependency-path: requirements-dev.txt\n      - run: pip install -r requirements-dev.txt\n      - run: python -m pytest -q -m \"not integration and not functional and not acceptance\"\n",
      "note": "The first **job**, `fast`. `runs-on` picks a fresh virtual machine; `timeout-minutes` stops a job that hangs. Its **steps** run in order: `uses:` runs an **action**, a packaged step somebody published, and `run:` runs a shell command. The setup step caches pip's downloads under a key derived from `requirements-dev.txt`, which is lesson 5 section 08 in one line."
    },
    {
      "code": "  suite:\n    needs: fast\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    strategy:\n      fail-fast: false\n      matrix:\n        python: [\"3.11\", \"3.12\", \"3.13\"]\n        tz: [\"America/Sao_Paulo\", \"UTC\"]\n    steps:",
      "note": "The second job only starts once `fast` passes: `needs` is an edge in the job graph. Its `strategy.matrix` turns one job into six, three Pythons by two time zones, and `fail-fast: false` lets every cell finish, for the reason lesson 5 section 07 gave."
    },
    {
      "code": "      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0\n        with:\n          python-version: ${{ matrix.python }}\n          cache: pip\n          cache-dependency-path: requirements-dev.txt\n      - run: pip install -r requirements-dev.txt\n      - name: Tests in ${{ matrix.tz }}\n        shell: bash\n        env:\n          TZ: ${{ matrix.tz }}\n        run: |\n          set -euo pipefail\n          coverage run -p -m pytest -q --junitxml=junit.xml",
      "note": "`${{ matrix.python }}` is filled in per cell. The test step names its shell, so it runs with `pipefail`, and starts with `set -euo pipefail` anyway; the time zone reaches the tests through `env`."
    },
    {
      "code": "      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1\n        if: always()\n        with:\n          name: results-${{ strategy.job-index }}\n          path: |\n            junit.xml\n            .coverage.*\n          include-hidden-files: true\n",
      "note": "`if: always()` uploads the JUnit report and the coverage data **even when the tests failed**, as an artifact named after the cell's index, so six cells give six artifacts."
    },
    {
      "code": "  coverage:\n    needs: suite\n    if: always()\n    runs-on: ubuntu-24.04\n    timeout-minutes: 5\n    steps:\n      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0\n        with:\n          python-version: \"3.13\"\n      - run: pip install coverage==7.16.2\n      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1\n        with:\n          pattern: results-*\n          merge-multiple: true\n      - run: coverage combine && coverage report",
      "note": "The last job runs after the matrix, whatever its result, downloads all six artifacts into one directory and produces the combined coverage report of lesson 4 section 09."
    }
  ]
}
```

## Checked, not run

This workflow has **not run on GitHub**: the lab has no repository there, and nothing in this course
pushes to one. If you have a GitHub account you can push `shipquote` to a repository of your own
and watch it run, but no lesson depends on that. What the lab can do is check the file with
**actionlint**, an open-source static checker for GitHub Actions workflows. It is written in Go and
installs with Ubuntu's own Go, into `~/go/bin`:

```sh
sudo apt-get install -y golang-go
go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.7
export PATH="$PATH:$HOME/go/bin"
```

The `export` lasts as long as the terminal; the same line at the end of `~/.bashrc` makes it
permanent. Run from the project's directory, actionlint finds the workflows by itself:

```
ana@laptop:~/shipquote$ actionlint; echo "exit status $?"
exit status 0
```

Silence and an exit status of 0 mean actionlint found nothing to report: the YAML parses, every key
is one GitHub knows, and every `${{ }}` expression refers to something that exists. (actionlint
can also pass each `run:` script to ShellCheck, which this lab does not have installed.) The next
section shows what it does report, and what it cannot know, so commit the file first, with
`git add .github && git commit -m "Run the checks on GitHub Actions"`, and the next section can
break it and put it back.

## Where the parts came from

Every piece of that file has a counterpart in the lab's hook from lesson 5. The trigger is the `if`
on the branch name; the job is the loop body; the matrix is the two nested loops; the artifact is the
run directory; the clean checkout is `actions/checkout` on a fresh machine. **A workflow file is
that script, rewritten as a description the service turns into machines.** The difference that
matters most is that GitHub runs it on the pull request, before the merge, and can refuse the merge
when it fails, which section 08 sets up.
