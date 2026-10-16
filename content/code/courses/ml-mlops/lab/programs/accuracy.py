"""accuracy.py: the lapse model's accuracy, and a model that knows nothing."""
from sklearn.metrics import accuracy_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")

predicted = lapse.predict(test[COLUMNS])
nobody = [0] * len(test)                       # "every member stays"

print(f"members in the test:      {len(test)}")
print(f"of whom lapsed:           {test['lapsed'].sum()} ({test['lapsed'].mean():.1%})")
print(f"accuracy, lapse model:    {accuracy_score(test['lapsed'], predicted):.1%}")
print(f"accuracy, 'nobody lapses': {accuracy_score(test['lapsed'], nobody):.1%}")
