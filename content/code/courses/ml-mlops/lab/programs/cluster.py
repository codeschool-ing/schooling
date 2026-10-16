"""cluster.py: kinds of reader, from the share of each category in what they bought."""
import sqlite3

import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

SHARES = """
SELECT p.member_id, t.category, count(*) AS books
FROM purchases p JOIN lines l USING (purchase_id) JOIN titles t USING (title_id)
WHERE p.day <= '2025-11-30'
GROUP BY p.member_id, t.category
"""

with sqlite3.connect("shop.db") as db:
    books = pd.read_sql_query(SHARES, db)
shares = books.pivot_table(index="member_id", columns="category", values="books", fill_value=0)
shares = shares[shares.sum(axis=1) >= 5]                # members with five books or more
shares = shares.div(shares.sum(axis=1), axis=0)         # each row now adds up to 1

for k in range(2, 11):
    groups = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(shares)
    print(f"k={k:2}  silhouette {silhouette_score(shares, groups, random_state=0):.3f}")

k = 8
shares["group"] = KMeans(n_clusters=k, n_init=10, random_state=0).fit_predict(shares)
centres = shares.groupby("group").mean()
for g, row in centres.iterrows():
    top = row.sort_values(ascending=False).head(2)
    print(f"group {g}: {int((shares['group'] == g).sum()):4} members, "
          + ", ".join(f"{c} {v:.0%}" for c, v in top.items()))
