"""confusion.py: the four kinds of answer, at the default threshold of 0.5."""
from sklearn.metrics import confusion_matrix, precision_score, recall_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
predicted = lapse.predict(test[COLUMNS])

(tn, fp), (fn, tp) = confusion_matrix(test["lapsed"], predicted)
print(f"                 predicted stays  predicted lapses")
print(f"actually stayed  {tn:15}  {fp:16}")
print(f"actually lapsed  {fn:15}  {tp:16}")
print(f"precision {precision_score(test['lapsed'], predicted):.3f}  "
      f"recall {recall_score(test['lapsed'], predicted):.3f}")
