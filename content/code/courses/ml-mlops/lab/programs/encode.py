"""encode.py: what the model actually receives for one member."""
from sklearn.preprocessing import OneHotEncoder

import features

members = features.build("2025-09-30")
encoder = OneHotEncoder().fit(members[features.CATEGORICAL])

print(members[features.CATEGORICAL].head(1).to_string(index=False))
columns = encoder.get_feature_names_out()
row = encoder.transform(members[features.CATEGORICAL].head(1)).toarray()[0]
for name, value in zip(columns, row):
    print(f"  {name:22} {value:.0f}")
