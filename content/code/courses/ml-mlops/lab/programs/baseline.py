"""baseline.py: what the two models are worth against guessing."""
from sklearn.dummy import DummyClassifier, DummyRegressor
from sklearn.metrics import mean_absolute_error

import features
from regress import examples

train, test = examples("2025-09-30"), examples("2025-11-30")
X = features.NUMERIC

always_stays = DummyClassifier(strategy="most_frequent").fit(train[X], train["lapsed"])
print("always 'stays' predicts lapsed for", int(always_stays.predict(test[X]).sum()), "members")

average = DummyRegressor(strategy="mean").fit(train[X], train["spend_next_90d"])
guess = average.predict(test[X])
print(f"everybody spends the average: R$ {guess[0] / 100:.2f} each")
print(f"mean absolute error: R$ {mean_absolute_error(test['spend_next_90d'], guess) / 100:.2f}")
