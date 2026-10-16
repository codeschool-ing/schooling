---
title: The model on the device
version: 1
---

The third place is the device itself: a till in a shop, a phone app, a sensor. **The model is copied
to it and runs there**, so it answers with no network and no server. That rules out the way the
other two loaded it: a device has no MLflow, often no Python, and no room for a gigabyte of
libraries. What it needs is the model in a **portable format** and a small runtime that executes
that format.

**ONNX**, Open Neural Network Exchange, is the common one: a file that describes a model as a graph
of standard operations, which runtimes in many languages and on many devices can execute.
`skl2onnx` converts a scikit-learn pipeline to it, scaler and encoder included. Save this as
`export_edge.py`:

```python
"""export_edge.py: the champion as an ONNX file, which runs without Python or scikit-learn."""
import mlflow
from mlflow import MlflowClient
from skl2onnx import to_onnx
from skl2onnx.common.data_types import FloatTensorType, StringTensorType

import features
from project import MODELS, ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
version = MlflowClient().get_model_version_by_alias("lapse", "champion").version
model = mlflow.sklearn.load_model(f"models:/lapse/{version}")

inputs = ([(c, FloatTensorType([None, 1])) for c in features.NUMERIC]
          + [(c, StringTensorType([None, 1])) for c in features.CATEGORICAL])
onnx = to_onnx(model, initial_types=inputs, options={"zipmap": False})
out = MODELS / f"lapse-v{version}.onnx"
out.write_bytes(onnx.SerializeToString())
print(f"{out.name}: {out.stat().st_size} bytes, version {version}")
```

The converter has to be told each input column's type, because an ONNX file declares its inputs:
the seven numbers as 32-bit floats, the three categories as strings. `zipmap: False` makes the
probabilities come out as a plain table rather than a list of dictionaries.

Then the device's side: no MLflow, no scikit-learn, only `onnxruntime` and the file. Save this as
`edge.py`:

```python
"""edge.py: score members with the ONNX file and onnxruntime alone, as a device would."""
import sys

import numpy as np
import onnxruntime
import pandas as pd

import features
from project import DATA, MODELS

session = onnxruntime.InferenceSession(str(MODELS / sys.argv[1]))
rows = pd.read_csv(DATA / "test.csv").head(3)

feed = {c: rows[[c]].to_numpy(np.float32) for c in features.NUMERIC}
feed |= {c: rows[[c]].to_numpy(str) for c in features.CATEGORICAL}
label, probabilities = session.run(None, feed)
print(rows[["member_id"]].assign(p_lapse=probabilities[:, 1].round(3)).to_string(index=False))
```

```
ana@dev:~/ml$ python export_edge.py
lapse-v1.onnx: 1803 bytes, version 1
ana@dev:~/ml$ python edge.py lapse-v1.onnx
 member_id  p_lapse
         1    0.123
         2    0.090
         3    0.106
```

**The whole model is 1,803 bytes**, and the three probabilities it gives are the ones lesson 7's
`champion.py` printed for the same members from the same version: 0.123, 0.090 and 0.106. The
conversion changed the format and not the answers. That check, the same rows scored both ways
before a file is shipped, belongs in the export step every time: a converter that silently handles
one step differently is training-serving skew moved onto a device.
