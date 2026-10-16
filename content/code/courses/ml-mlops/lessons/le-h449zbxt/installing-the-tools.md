---
title: Installing DVC and MLflow
version: 1
---

Both are Python packages and go into the course's environment. With it active:

```sh
pip install mlflow==3.17.0 dvc==3.67.1
```

This is the largest install of the course: MLflow brings a web server, a database layer and the
code to load models of many libraries. Lesson 1's size of the whole environment, about a gigabyte
by the last lesson, is mostly this line.

DVC records versions in Git, and Git needs to know who is committing. Once per computer:

```sh
git config --global user.name "Ana"
git config --global user.email ana@example.com
git config --global init.defaultBranch main
```

Use your own name and address. `example.com` is a domain reserved for examples, which is why the
course uses it. The check:

```
ana@dev:~/ml$ git --version; dvc --version; mlflow --version
git version 2.43.0
3.67.1
mlflow, version 3.17.0
```
