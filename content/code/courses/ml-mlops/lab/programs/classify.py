"""classify.py: the lapse model with every feature, categories included."""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

train = features.build("2025-09-30")
test = features.build("2025-11-30")
X = features.NUMERIC + features.CATEGORICAL

model = make_pipeline(
    make_column_transformer(
        (StandardScaler(), features.NUMERIC),
        (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
    ),
    LogisticRegression(max_iter=1000),
)
model.fit(train[X], train["lapsed"])

test["p_lapse"] = model.predict_proba(test[X])[:, 1]
test["predicted"] = model.predict(test[X])
print(test[["member_id", "channel", "recency_days", "p_lapse", "predicted", "lapsed"]]
      .head(4).round(3).to_string(index=False))
print("predicted to lapse:", int(test["predicted"].sum()), "of", len(test))
print("actually lapsed:   ", int(test["lapsed"].sum()), "of", len(test))
