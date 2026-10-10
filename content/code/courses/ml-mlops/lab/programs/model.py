"""model.py: the lapse model, defined once, for every program that trains it."""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

COLUMNS = features.NUMERIC + features.CATEGORICAL


def make_model():
    return make_pipeline(
        make_column_transformer(
            (StandardScaler(), features.NUMERIC),
            (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
        ),
        LogisticRegression(max_iter=1000),
    )


def trained(cutoff):
    rows = features.build(cutoff)
    return make_model().fit(rows[COLUMNS], rows["lapsed"])
