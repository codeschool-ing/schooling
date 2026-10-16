---
title: The nightly job, and a verify that has to be read
version: 1
---

Lesson 1 ended with three checks every backup job makes: every program succeeded, the output is
plausible, and the copy has been restored somewhere. pgBackRest covers the first two; the third is
lesson 7. Put them in a script, and make the script **refuse to report success** until the tool
has said so in the one way this version of it says so reliably.

Save this as `nightly-backup.sh`:

```schooling-example
{"language": "bash", "file": "nightly-backup.sh", "parts": [{"code": "#!/usr/bin/env bash\n# nightly-backup.sh: back up, then refuse to call it good until verify says so\nset -euo pipefail\nstanza=main\n", "note": "Stop at the first failure, at any unset variable, and on a failure anywhere in a pipe: lesson 1's silent pipeline is not allowed back in."}, {"code": "pgbackrest --stanza=\"$stanza\" check", "note": "The archive path first. If segments are not reaching the repository, a backup taken now could not be restored to any moment after it."}, {"code": "pgbackrest --stanza=\"$stanza\" backup\n", "note": "With no --type, pgBackRest takes an incremental backup, or a full one if none exists. Retention runs at the end, as the previous sections showed."}, {"code": "report=$(pgbackrest --stanza=\"$stanza\" verify --verbose --output=text)\nif ! grep -q '^status: ok$' <<<\"$report\"; then\n  echo \"verify found a problem:\" >&2\n  echo \"$report\" >&2\n  exit 1\nfi\necho \"backup and verify ok\"", "note": "The verify, asked for its full report. Its exit status is 0 whatever it finds, and without --verbose a healthy repository prints nothing at all, so the script reads the report and only the exact line `status: ok` counts as a pass. Silence is not a pass."}]}
```

It runs as `postgres`, which cannot read your home directory, so install it where every user can
run it, and run it once by hand:

```
ana@vm:~$ sudo install -m 755 nightly-backup.sh /usr/local/bin/nightly-backup.sh
ana@vm:~$ sudo -u postgres /usr/local/bin/nightly-backup.sh
backup and verify ok
ana@vm:~$ echo $?
0
```

**Exit status 0, and one line of output**, which is what a job that is working should look like.
Now the same damage as in the verify section, to the newest full backup, and the job again:

```
ana@vm:~$ sudo -u postgres /usr/local/bin/nightly-backup.sh
verify found a problem:
stanza: main
status: error
  archiveId: 16-1, total WAL checked: 11, total valid WAL: 11
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162752F, status: invalid, total files checked: 1271, total valid files: 1270
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
  backup: 20261010-162752F_20261010-162802I, status: invalid, total files checked: 1271, total valid files: 1270
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
  backup: 20261010-162752F_20261010-162806I, status: invalid, total files checked: 1272, total valid files: 1271
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
ana@vm:~$ echo $?
1
```

The backup itself succeeded, as it did before the damage. The verify found the invalid file, the
script printed the report and **exited with 1**, and anything that watches the job's exit status
now sees what happened.

## Running it every night

A schedule is one line in the `postgres` user's crontab, edited with `sudo crontab -u postgres -e`:

```
30 2 * * * /usr/local/bin/nightly-backup.sh
```

That runs it at 02:30 every day. The schedule was not run in this lab, which has no `cron`
running; on your virtual machine it is there by default. `cron` sends a job's output by e-mail to
the user it runs as, and on a machine with no mail configured that output goes nowhere, so the
schedule is half of the job. **The other half is something that notices when it fails, or when it
does not run at all**: a monitoring system that expects a successful run every night and alerts on
silence as well as on failure. Lesson 7 builds the restore drill on top of this job, and lesson 22
is what happens when the alert fires.
