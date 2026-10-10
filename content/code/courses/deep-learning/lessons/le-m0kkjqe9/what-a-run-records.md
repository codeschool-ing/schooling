---
title: What a run has to record
version: 1
---

Three weeks from now a file will say `0.9583`, and the question will be *which run was that*. A
number with no record beside it cannot be reproduced, compared or trusted, and **memory is not a
record**: by the twentieth run nobody remembers which one had the learning rate changed by hand.

A run can be repeated when five things are written down beside its result:

| what | why it matters |
| --- | --- |
| the configuration | every setting, including the ones left at their defaults |
| the seed | the previous two sections showed what it moves |
| the code version | the same settings on different code are a different experiment |
| the data version | a new split, or a library that changed the data, moves the result |
| the library versions | a new release of PyTorch or NumPy can compute the same thing in a different order |

Then the metrics themselves. Writing all of that by hand is what nobody does on the twentieth run,
so a program writes it.

## A line per run

Save as `~/dl/track.py`:

```schooling-example
{
  "language": "python",
  "file": "track.py",
  "parts": [
    {
      "code": "\"\"\"track: append one line of JSON per run to runs.jsonl, with everything that made the number.\"\"\"\nimport datetime\nimport hashlib\nimport json\nimport platform\nimport subprocess\n\nimport numpy as np\nimport sklearn\nimport torch\n\nimport digits",
      "note": "Only the standard library and what the course already installed. A tracking file needs no server."
    },
    {
      "code": "def code_version():\n    \"\"\"The commit the directory is at, and whether any file differs from it.\"\"\"\n    git = lambda *args: subprocess.run([\"git\", *args], capture_output=True,\n                                       text=True, check=True).stdout\n    return {\"commit\": git(\"rev-parse\", \"--short\", \"HEAD\").strip(),\n            \"dirty\": git(\"status\", \"--porcelain\") != \"\"}",
      "note": "The code version is the commit, plus a flag saying whether the files on disk still match it. `check=True` makes a directory that is not a repository an error, never a run recorded with no version."
    },
    {
      "code": "def data_version(seed=0):\n    \"\"\"The training set's fingerprint: change one pixel and it changes.\"\"\"\n    (x, y), _, _ = digits.load(seed)\n    digest = hashlib.sha256(x.tobytes() + y.tobytes()).hexdigest()[:12]\n    return {\"split_seed\": seed, \"train\": len(y), \"sha256\": digest}",
      "note": "A hash of the bytes the network trained on. A new scikit-learn that changed the data, or a different split, gives a different fingerprint even though the code is the same."
    },
    {
      "code": "def record(config, seed, metrics, path=\"runs.jsonl\"):\n    entry = {\n        \"time\": datetime.datetime.now().isoformat(timespec=\"seconds\"),\n        \"config\": config,\n        \"seed\": seed,\n        \"code\": code_version(),\n        \"data\": data_version(),\n        \"versions\": {\"python\": platform.python_version(), \"torch\": torch.__version__,\n                     \"numpy\": np.__version__, \"sklearn\": sklearn.__version__},\n        \"threads\": torch.get_num_threads(),\n        \"metrics\": metrics,\n    }\n    with open(path, \"a\") as f:\n        f.write(json.dumps(entry) + \"\\n\")\n    return entry",
      "note": "One dictionary per run, written as one line and appended: the file only grows, and a crash halfway through a run leaves every earlier line intact. The number of threads is there for the reason the determinism section gives."
    }
  ]
}
```

And as `~/dl/run.py`, the program that trains and records:

```schooling-example
{
  "language": "python",
  "file": "run.py",
  "parts": [
    {
      "code": "\"\"\"run: train one configuration with one seed, and record it.\"\"\"\nimport argparse\n\nimport exp\nimport track\n\np = argparse.ArgumentParser()\np.add_argument(\"--hidden\", type=int, default=32)\np.add_argument(\"--lr\", type=float, default=0.01)\np.add_argument(\"--epochs\", type=int, default=10)\np.add_argument(\"--batch-size\", type=int, default=32)\np.add_argument(\"--seed\", type=int, default=0)\na = p.parse_args()",
      "note": "Every setting is an argument with a default, so a run is changed from the command line and never by editing the file. An edit is a new version of the code; an argument is just a different run of the same one."
    },
    {
      "code": "config = {\"hidden\": a.hidden, \"lr\": a.lr, \"epochs\": a.epochs, \"batch_size\": a.batch_size}\n_, acc = exp.run(config, a.seed)\nentry = track.record(config, a.seed, {\"val_acc\": round(acc, 4)})\nprint(f\"seed {a.seed}  val acc {acc:.4f}  commit {entry['code']['commit']}\"\n      + (\"  (uncommitted changes)\" if entry[\"code\"][\"dirty\"] else \"\"))",
      "note": "Train, record, then print one line. The record is written before anything is printed, so a run that appears on the screen is a run that is in the file."
    }
  ]
}
```

The format is **JSON Lines**: one JSON object per line, appended. Every line is readable on its own,
`tail` shows the latest run, and a run that dies halfway leaves every earlier line as it was. A
single JSON array would have to be read, extended and rewritten whole on every run, and a crash
during the rewrite loses all of it.

## The code version is a commit

The cleanest name for the state of a directory of code is a git commit: one short hash that pins
every file exactly. `~/dl` is not a repository yet. First tell git what to leave out, in
`~/dl/.gitignore`:

```
# .gitignore: what git leaves out of ~/dl
.venv/
__pycache__/
runs.jsonl
```

The environment is gigabytes of installed libraries, and `requirements.txt` already names them.
`__pycache__` is Python's compiled leftovers. And `runs.jsonl` is output rather than code. Git asks
for a name and an address once per machine, and then the first commit:

```
PENDING git
```

`git status --short` listed ten files and nothing from `.venv`: the five programs of this lesson so
far, the three from lessons 1 and 9, `requirements.txt` and the `.gitignore`. They are commit
`HASH` now. One run, and its record:

```
PENDING record
```

**Seed 0 gave 0.9167, the same number `spread.py` printed for it**: a new process, a different
program calling `exp.run`, and the same result to the last digit. The record carries the commit,
`"dirty": false`, the data's fingerprint and every version that took part.

## The run nobody can repeat

Now the case the `dirty` flag exists for. Edit a program without committing, and run:

```
PENDING dirty
```

The new line in `runs.jsonl` names commit `HASH`, and **the code that ran is not commit `HASH`**:
it has a line the commit does not. Here the line is a comment and changes nothing, but the flag
cannot know that and should not try. `git checkout exp.py` put the file back as the commit has it,
and `git status` is quiet again.

The rule this gives is short: **a result from a dirty run is a lead, not a finding.** Commit, run
again, and keep that one. The report in the next section leaves dirty runs out for that reason.
