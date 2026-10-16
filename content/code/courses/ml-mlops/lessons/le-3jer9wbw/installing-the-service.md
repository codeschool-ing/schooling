---
title: Installing what a service needs
version: 1
---

The rest of the lesson needs four more libraries: **FastAPI** to describe a web service in Python,
**Uvicorn** to run it, **skl2onnx** to export a model to a portable format, and **ONNX Runtime** to
run that format without scikit-learn. With the environment active:

```sh
pip install fastapi==0.143.0 uvicorn==0.54.0 skl2onnx==1.20.0 onnxruntime==1.31.0
```

```
ana@dev:~/ml$ pip list 2>/dev/null | grep -iE '^(fastapi|uvicorn|skl2onnx|onnxruntime|onnx) '
fastapi                            0.143.0
onnx                               1.23.2
onnxruntime                        1.31.0
skl2onnx                           1.20.0
uvicorn                            0.54.0
```

These are the last libraries the course installs. `pip list` filtered to the four, with `onnx`
alongside because skl2onnx brings it, is the check that they are in the environment and at the
pinned versions.
