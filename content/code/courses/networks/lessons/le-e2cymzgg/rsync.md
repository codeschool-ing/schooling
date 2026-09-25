---
title: rsync: sending only what changed
version: 1
---

Copying a whole folder every night to back it up resends everything, every night. `rsync` compares
both sides first and sends only the difference:

```
ana@laptop:~$ rsync -av Documents/ office:backup/
sending incremental file list
created directory backup
./
Apache-2.0
BSD
GPL-3
LGPL-3
MPL-2.0

sent 72,755 bytes  received 143 bytes  48,598.67 bytes/sec
total size is 72,384  speedup is 0.99
ana@laptop:~$ rsync -av Documents/ office:backup/
sending incremental file list

sent 141 bytes  received 12 bytes  306.00 bytes/sec
total size is 72,384  speedup is 473.10
ana@laptop:~$ echo "Reviewed on 25 September." >> Documents/MPL-2.0; rm Documents/BSD
ana@laptop:~$ rsync -av Documents/ office:backup/
sending incremental file list
./
MPL-2.0

sent 925 bytes  received 182 bytes  2,214.00 bytes/sec
total size is 70,911  speedup is 64.06
ana@laptop:~$ rsync -avn --delete Documents/ office:backup/
sending incremental file list
deleting BSD

sent 135 bytes  received 26 bytes  107.33 bytes/sec
total size is 70,911  speedup is 440.44 (DRY RUN)
```

The first run copied five files and sent `72,755` bytes. The second, a moment later, found nothing
to do and sent `141`, just the comparison. After one file was edited and another deleted, the
third sent only `MPL-2.0`, in `925` bytes for a file of more than 16 thousand:
within a file that changed, rsync sends only the parts that differ. To decide a file is unchanged at
all, it compares size and modification time, which is fast.

`-a` keeps permissions, times and folders as they were, and `-v` lists what it does. **The trailing
slash matters**: `Documents/` copies what is inside the folder into `backup`, while `Documents` would
create `backup/Documents`.

The deleted `BSD` is still on the server, because rsync does not delete unless told to. `--delete` makes
the copy an exact mirror, removing on the server whatever is gone from the laptop, and `-n` shows what it
would do without doing it. **Always run `--delete` with `-n` first**: with the source and the
destination swapped, it empties the folder you meant to keep.
