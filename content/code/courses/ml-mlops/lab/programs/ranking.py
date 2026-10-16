"""ranking.py: scores that judge the order of the probabilities, not one cut of them."""
from sklearn.metrics import average_precision_score, roc_auc_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
test["p"] = lapse.predict_proba(test[COLUMNS])[:, 1]

print(f"ROC AUC            {roc_auc_score(test['lapsed'], test['p']):.3f}   (a coin: 0.5)")
print(f"average precision  {average_precision_score(test['lapsed'], test['p']):.3f}   "
      f"(a coin: {test['lapsed'].mean():.3f}, the share who lapse)")
for n in (100, 300, 530):
    top = test.nlargest(n, "p")
    print(f"of the top {n:3}, lapsed: {top['lapsed'].sum():3} ({top['lapsed'].mean():.0%})")
