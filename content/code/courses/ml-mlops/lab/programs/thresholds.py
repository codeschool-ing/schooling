"""thresholds.py: the same probabilities, cut at different places."""
import features
from model import COLUMNS, trained

VOUCHER = 10.00          # reais: what marketing pays for each voucher sent
SAVED = 60.00            # reais: what a lapsing member who is won back is worth

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
p = lapse.predict_proba(test[COLUMNS])[:, 1]
lapsed = test["lapsed"].to_numpy() == 1

print("threshold  flagged  precision  recall  net value")
for threshold in (0.1, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6):
    flagged = p >= threshold
    caught = (flagged & lapsed).sum()
    value = caught * SAVED - flagged.sum() * VOUCHER
    print(f"{threshold:9.2f}  {flagged.sum():7}  {caught / flagged.sum():9.3f}  "
          f"{caught / lapsed.sum():6.3f}  R$ {value:8.2f}")
