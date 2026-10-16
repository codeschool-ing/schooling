---
title: Going back to any version
version: 1
---

Two commits, two models, and the working directory holds version 2's. **Getting version 1 back is
two commands**: Git restores the code and the pointer files, and DVC restores the data and the model
they point to.

```
ana@dev:~/ml$ git checkout -q v1 && dvc checkout
M       models/lapse.joblib
ana@dev:~/ml$ python -c "import json; print(json.load(open(\"models/lapse.json\"))[\"data_sha256\"])"
d04183235c0e66c2
ana@dev:~/ml$ md5sum models/lapse.joblib && grep -A2 "path: models/lapse.joblib" dvc.lock | grep "md5: "
cf238ebab7e13284d31b1e29bb8f8df7  models/lapse.joblib
      md5: cf238ebab7e13284d31b1e29bb8f8df7
      md5: cf238ebab7e13284d31b1e29bb8f8df7
ana@dev:~/ml$ git checkout -q main && dvc checkout
M       models/lapse.joblib
```

After `git checkout v1`, `dvc checkout` saw that the model on disk did not match `dvc.lock` and
replaced it from the cache; `M` marks the file it changed. The training file's fingerprint is
`d04183235c0e66c2` again, the one lesson 5 printed, and the model file's MD5 is the one `dvc.lock`
records for v1, twice because the file is training's output and evaluation's input. Back on `main`, the same two commands put version 2's model back.

**That is what reproducible means in practice**: not "we could probably rebuild it", but the
exact bytes of the model that sent last month's vouchers, recovered by name. It also means the
answer to an auditor's question, *what data did this model learn from?*, is a commit and a hash.

`dvc checkout` restores from the local cache. On a new computer, or after the cache is cleared, `git
clone` followed by `dvc pull` fetches the same files from the remote, which is why section 05 set
one up and section 06 pushed to it.
