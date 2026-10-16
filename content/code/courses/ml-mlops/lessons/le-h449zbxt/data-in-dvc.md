---
title: The data goes into DVC
version: 1
---

`dvc add` takes a file out of Git's hands. It copies the file into DVC's cache, named by the hash of
its contents, writes a small **pointer file** beside it, and adds the original to `.gitignore`. Git
then versions the pointer, and the pointer names the data exactly.

```
ana@dev:~/ml$ dvc add shop.db

To track the changes with git, run:

	git add .gitignore shop.db.dvc

To enable auto staging, run:

	dvc config core.autostage true
ana@dev:~/ml$ cat shop.db.dvc
outs:
- md5: 95a15782c27b9c79017e02ac78df66bf
  size: 5939200
  hash: md5
  path: shop.db
ana@dev:~/ml$ dvc remote add -d store ~/dvc-store
Setting 'store' as a default remote.
ana@dev:~/ml$ git add . && git commit -qm "the lapse pipeline, and the shop it reads" && git log --oneline
4bb4b2d the lapse pipeline, and the shop it reads
```

`shop.db.dvc` is the whole of what Git sees: an MD5 hash of the file's bytes, its size and its name.
**Change one row of the shop and the hash changes**, so a commit that holds this pointer names one
exact database. Your hash will most likely differ from this one even with the same rows, because
SQLite's file layout depends on the version that wrote it; what matters is that your hash names
your file.

The cache lives in `.dvc/cache`, inside the project, which protects nothing if the disk dies. A
**remote** is where the cache is copied for safekeeping: here a directory, `~/dvc-store`, and in a
team a bucket in object storage or a shared drive, named the same way. `dvc push` copies what the
remote lacks.

**The first commit is the code and the pointer, together.** From now on, any commit names a version
of the programs and a version of the shop at once, which is the pair lesson 5's record could only
half name.
