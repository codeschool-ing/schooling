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
