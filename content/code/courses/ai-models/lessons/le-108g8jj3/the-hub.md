---
title: The Hub is a set of repositories
version: 1
---

A model on Hugging Face is **a repository**: a name of the form `owner/model`, a set of files, and a
history of versions, kept with git. `Qwen/Qwen3-8B` is a repository owned by the Qwen organisation;
anybody can create `someone/Qwen3-8B-whatever` beside it. Lesson 11's licence files "in the
respective Hugging Face repositories" are files in exactly these.

The library programs use to fetch from the Hub is `huggingface_hub`. Its download function says, in
its first six parameters, what identifies a file:

```
ana@desk:~/desk$ python -c "import inspect, huggingface_hub as h; print(h.__version__); print(*list(inspect.signature(h.hf_hub_download).parameters)[:6], sep=chr(10))"
2.1.1
repo_id
filename
subfolder
repo_type
revision
library_name
```

**`repo_id` and `filename`** name the file. **`revision`** says which version of it: a branch, a tag
or a commit hash. Left out, it means the newest commit on the main branch, which is lesson 2 section
06's alias in another form: the same name, a different file next month, if the owner pushes.

That is why this course pins a commit for every source it reads, and why a program that downloads
weights should do the same. **A model fetched by `repo_id` alone is a model that can change between
two deployments** without anybody on ana's side changing a line. Pinned to a commit hash, it is the
same bytes every time, and lesson 5's evaluation stays true of it.

## What is in a repository

The files that make up lesson 1 section 02's box: the weights, often split into several files; the
tokenizer and its configuration, which holds the chat template; a configuration file with the
architecture numbers lesson 3 computed with; and the `README.md`, which is the model card. Weight
files in the `safetensors` format hold only numbers. Some older repositories still carry weights in
Python's pickle format, which can run code when loaded, and are a reason to prefer repositories that
publish `safetensors` and to load nothing from a source you have not checked.
