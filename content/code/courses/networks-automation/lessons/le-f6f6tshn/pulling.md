---
title: Reading every router at once
version: 2
---

The backup reuses lesson 8's Nornir inventory, cut down to the three routers, and asks each one for
its running configuration through NAPALM. The project is a new directory, `~/net` on `ctl`, put
together from two earlier lessons: lesson 8's `config.yaml` and the two inventory files that do
not change, and lesson 10's data, templates and `render.py`, which section 07 uses. Git also needs
to know who is committing, once per account:

```
ana@ctl:~$ git config --global user.name ana && git config --global user.email ana@example.net && git config --global init.defaultBranch main
ana@ctl:~$ mkdir -p net/inventory && cp config.yaml net/ && cp inventory/groups.yaml inventory/defaults.yaml net/inventory/ && cp -r tpl/data tpl/templates tpl/render.py net/
```

The one inventory file that changes is the list of hosts, which here is the three routers and
nothing else. `net/inventory/hosts.yaml`:

```yaml
---
core1:
  hostname: core1.example.net
  groups: [routers]
edge1:
  hostname: edge1.example.net
  groups: [routers]
edge2:
  hostname: edge2.example.net
  groups: [routers]
```

The same script then commits whatever changed:

```schooling-example
{
  "language": "python",
  "file": "backup.py",
  "parts": [
    {
      "code": "import pathlib\nimport subprocess\nimport sys\n\nfrom nornir import InitNornir\nfrom nornir_napalm.plugins.tasks import napalm_get\n\nnr = InitNornir(config_file=\"config.yaml\")"
    },
    {
      "code": "result = nr.run(task=napalm_get, getters=[\"config\"], getters_options={\"config\": {\"retrieve\": \"running\"}})\n\nrepo = pathlib.Path(\"backups\")\nfor host, r in sorted(result.items()):\n    if r.failed:",
      "note": "**Every router at once, read-only.** `napalm_get` with the `config` getter asks each router for its running configuration; nothing is changed anywhere."
    },
    {
      "code": "        print(f\"{host}: FAILED, kept the previous copy: {str(r[0].exception).splitlines()[0]}\")\n        continue\n    (repo / f\"{host}.conf\").write_text(r[0].result[\"config\"][\"running\"])\n\n\ndef git(*args):\n    return subprocess.run([\"git\", \"-C\", str(repo), *args], capture_output=True, text=True, check=True).stdout\n\n\ngit(\"add\", \"--all\")\nchanged = git(\"diff\", \"--cached\", \"--name-only\").split()",
      "note": "**A router that did not answer is said out loud.** Its file is left as it was, which is the danger: the repository still looks complete, with a copy that is a day older every night."
    },
    {
      "code": "if changed:\n    git(\"commit\", \"--quiet\", \"-m\", \"backup: \" + \", \".join(f.removesuffix(\".conf\") for f in changed))\n    print(\"committed:\", \", \".join(changed))\nelse:\n    print(\"no change since the last backup\")",
      "note": "**A commit only when something changed**, named after what did. The history is then a list of changes, and a night with nothing in it leaves no trace."
    },
    {
      "code": "sys.exit(1 if result.failed else 0)",
      "note": "**The exit status carries the failure**, so whatever runs this every night, cron or a pipeline, can tell a partial backup from a good one."
    }
  ]
}
```

`napalm_get` is the getter interface from lesson 8, run by Nornir on every host in parallel. The
`config` getter returns a dictionary with `running`, `startup` and `candidate`; FRR keeps no
separate startup configuration in this setup, so only `running` is asked for. Other platforms
would add `startup` to the backup, and the difference between the two is worth its own alert: a
change that was never saved disappears on the next reload.

The repository is an ordinary Git repository with no remote, created once:

```
ana@ctl:~$ cd net && git init --quiet backups && ls
backup.py
backups
compare.py
config.yaml
data
inventory
render.py
restore.py
templates
```

The first run writes and commits all three files:

```
ana@ctl:~$ cd net && python backup.py
committed: core1.conf, edge1.conf, edge2.conf
ana@ctl:~$ cd net && git -C backups log --oneline
4ad37d6 backup: core1, edge1, edge2
```

**The file is exactly what the router sent**, nothing removed, nothing reordered. That is a
choice. A backup that cleaned up its input would be a copy of what the script thought mattered, and
the day it mattered, the line that was cleaned away would be the one missing. Cleaning up belongs
to the comparison, which section 07 does.
