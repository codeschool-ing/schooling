---
title: Turning words into numbers the model can use
version: 1
---

A learning algorithm does arithmetic, so every feature has to be a number. Three of Ponto Final's
are words: `channel`, `age_band` and `home_shop`. **The tempting fix is to number them**, Paulista 0,
Pinheiros 1, Cambuí 2 and so on, and it is wrong in a way no error message reports: the model then
believes Cambuí is twice Pinheiros, and that Savassi sits between Cambuí and Batel. It will happily
fit a weight to that order, which does not exist.

**One-hot encoding gives each value its own column**, holding 1 for the value the row has and 0 for
every other. Nothing is bigger than anything else. This program shows what one member becomes;
save it as `encode.py`:

```python
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
```

```
ana@dev:~/ml$ python encode.py
channel age_band home_shop
  store    25-34   Savassi
  channel_app            0
  channel_store          1
  channel_web            0
  age_band_18-24         0
  age_band_25-34         1
  age_band_35-49         0
  age_band_50-64         0
  age_band_65+           0
  home_shop_Batel        0
  home_shop_Cambuí       0
  home_shop_Moinhos      0
  home_shop_Online       0
  home_shop_Paulista     0
  home_shop_Pinheiros    0
  home_shop_Savassi      1
```

Three words became sixteen columns: three channels, five age bands and seven home shops, with
exactly one 1 in each group. `Online` is a home shop because members who joined on the web or the
app are filed under it by the generator.

## The value that was not there at training

The encoder learns its columns from the rows it was fitted on, and **a value that appears only
later has no column**. The app arrived in September 2025, so a model trained on an older cutoff
would never have seen `channel_app`. What happens when it then meets one is a decision, and
scikit-learn makes you write it down: `classify.py` passes `handle_unknown="ignore"`, which
encodes an unknown value as all zeros, the same as "none of the channels I know". Leave it out and
the encoder raises an error on the first app member.

Neither choice is right in general. Ignoring keeps the service answering, with a model that knows
nothing about the new channel; refusing stops it, loudly. **What is never right is not knowing which
one your model does**, and lesson 10 is about noticing that the rows have started to carry values,
and mixes of values, the model never saw.

Ordered categories are the exception that is worth a sentence. `age_band` does have an order, and a
modeller may encode it as 0 to 4 on purpose. That is a choice about the meaning of the column, made
by somebody who knows it, which is exactly what numbering the shops was not.
