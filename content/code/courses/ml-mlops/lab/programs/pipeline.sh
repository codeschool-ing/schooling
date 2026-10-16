# pipeline.sh: the lapse model, from the shop to a scored model, stopping at the first failure.
set -e
cd "$(dirname "$0")"
python build_dataset.py 2025-08-31 data/train.csv
python build_dataset.py 2025-11-30 data/test.csv
python validate.py data/train.csv
python validate.py data/test.csv
python train.py data/train.csv models/lapse.joblib
python evaluate.py models/lapse.joblib data/test.csv
