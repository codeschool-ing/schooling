"""Correct one sale line, the till error of lesson 6, as a Delta update."""
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
result = table.update(
    updates={"net_cents": "net_cents - 1000", "gross_cents": "gross_cents - 1000"},
    predicate="order_id = 112406 AND line_no = 3",
)
print(result)
