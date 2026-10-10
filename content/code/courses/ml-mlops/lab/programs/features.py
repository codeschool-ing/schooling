"""features.py: one row per active member as of a cutoff day, and whether they lapsed.

A member is active at the cutoff if they bought something in the 180 days
before it, and lapsed if they then bought nothing in the 90 days after it.
"""
import sqlite3

import pandas as pd

QUERY = """
WITH recent AS (
  SELECT p.member_id, p.day, p.shop,
         (SELECT sum(price_cents) FROM lines l WHERE l.purchase_id = p.purchase_id) AS cents
  FROM purchases p
  WHERE p.day > date(:cutoff, '-180 days') AND p.day <= :cutoff
)
SELECT m.member_id, m.channel, m.age_band, m.home_shop,
       julianday(:cutoff) - julianday(m.joined)        AS tenure_days,
       julianday(:cutoff) - julianday(max(r.day))      AS recency_days,
       count(*)                                        AS visits_180d,
       sum(r.cents)                                    AS spend_180d,
       avg(r.cents)                                    AS basket_avg,
       avg(r.shop = 'Online')                          AS online_share,
       count(DISTINCT r.shop)                          AS shops_180d,
       NOT EXISTS (SELECT 1 FROM purchases f WHERE f.member_id = m.member_id
                   AND f.day > :cutoff AND f.day <= date(:cutoff, '+90 days')) AS lapsed
FROM members m JOIN recent r USING (member_id)
GROUP BY m.member_id
"""

NUMERIC = ["tenure_days", "recency_days", "visits_180d", "spend_180d", "basket_avg",
           "online_share", "shops_180d"]
CATEGORICAL = ["channel", "age_band", "home_shop"]


def build(cutoff, path="shop.db"):
    with sqlite3.connect(path) as db:
        return pd.read_sql_query(QUERY, db, params={"cutoff": cutoff})
