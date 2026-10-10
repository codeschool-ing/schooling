"""skew.py: the same model, fed features computed by somebody else's code."""
import joblib
import pandas as pd
from sklearn.metrics import roc_auc_score

from model import COLUMNS
from project import ROOT

model = joblib.load(ROOT / "models/lapse.joblib")
ours = pd.read_csv(ROOT / "data/test.csv")

# the website team's copy of the features: money in reais, shares in percent
theirs = ours.copy()
theirs["spend_180d"] = ours["spend_180d"] / 100
theirs["basket_avg"] = ours["basket_avg"] / 100
theirs["online_share"] = ours["online_share"] * 100


def top_300(rows, p):
    return set(rows.assign(p=p).nlargest(300, "p")["member_id"])


p_ours = model.predict_proba(ours[COLUMNS])[:, 1]
p_theirs = model.predict_proba(theirs[COLUMNS])[:, 1]
for name, p in (("our features", p_ours), ("their features", p_theirs)):
    print(f"{name:15} mean p {p.mean():.3f}  AUC {roc_auc_score(ours['lapsed'], p):.3f}")
shared = top_300(ours, p_ours) & top_300(theirs, p_theirs)
print(f"members in both top-300 lists: {len(shared)}")
print(f"members whose probability moved by more than 0.1: {(abs(p_ours - p_theirs) > 0.1).sum()}")
