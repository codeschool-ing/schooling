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
