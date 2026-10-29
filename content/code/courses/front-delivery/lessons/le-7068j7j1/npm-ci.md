---
title: npm ci, and the lockfile it trusts
version: 1
---

**`npm ci` installs exactly what `package-lock.json` records, and refuses to run if the lockfile and
`package.json` disagree.** `npm install` does something else: it reads `package.json`, resolves any ranges
to the newest version that fits, and writes the lockfile to match. That is what you want while adding a
dependency on your own computer. It is the wrong thing on a machine whose job is to check what you
committed, because it may quietly install something you never had.

| | `npm install` | `npm ci` |
|---|---|---|
| reads | `package.json`, and the lockfile as a hint | the lockfile, and `package.json` only to check it agrees |
| writes the lockfile | yes, when anything changes | never |
| `node_modules` | updates what is there | deletes it and starts again |
| a disagreement | resolved silently | an error, and nothing is installed |

## Watching it refuse

Change a version in `package.json` by hand without telling npm, which is how a lockfile goes stale
in real life (a merge, an edit in a hurry), and ask `npm ci` to install:

```
ana@dev:~/planner$ sed -i 's/"typescript": "6.0.3"/"typescript": "6.0.2"/' package.json
ana@dev:~/planner$ npm ci
npm error code EUSAGE
npm error
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error
npm error Invalid: lock file's typescript@6.0.3 does not satisfy typescript@6.0.2
npm error
npm error Clean install a project
npm error
npm error Usage:
npm error npm ci
npm error
npm error Options:
npm error [--install-strategy <hoisted|nested|shallow|linked>] [--legacy-bundling]
npm error [--global-style] [--omit <dev|optional|peer> [--omit <dev|optional|peer> ...]]
npm error [--include <prod|dev|optional|peer> [--include <prod|dev|optional|peer> ...]]
npm error [--strict-peer-deps] [--foreground-scripts] [--ignore-scripts] [--no-audit]
npm error [--no-bin-links] [--no-fund] [--dry-run]
npm error [-w|--workspace <workspace-name> [-w|--workspace <workspace-name> ...]]
npm error [-ws|--workspaces] [--include-workspace-root] [--install-links]
npm error
npm error aliases: clean-install, ic, install-clean, isntall-clean
npm error
npm error Run "npm help ci" for more info
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_52_02_174Z-debug-0.log
```

**`npm ci` stopped before installing anything**, and named both sides of the disagreement: the version
`package.json` asks for and the one the lockfile has. On CI that is a red build with the reason in the
log, which is exactly where you want to learn about it. Put `package.json` back:

```
ana@dev:~/planner$ git checkout package.json
Updated 1 path from the index
ana@dev:~/planner$ npm ci

added 18 packages, and audited 19 packages in 1s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

`npm ci` deleted `node_modules` and installed every package again from the lockfile, at the versions it
records, without asking the registry which versions are newest.

## The rule for the lockfile

Because CI trusts it, **the lockfile is committed, and it changes only through npm**: `npm install
<package>` to add or upgrade, `npm uninstall` to remove, and the result committed in the same commit as
`package.json`. A pull request that changes one without the other fails `npm ci`, which is CI doing its
job. Never edit `package-lock.json` by hand, and never delete it to make an error go away: a deleted
lockfile is regenerated with whatever versions are newest that day, which is the opposite of a pin.
