"""Which files would vacuum delete: those no current version still needs."""
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
stale = table.vacuum(retention_hours=0, dry_run=True, enforce_retention_duration=False)
print(len(stale), "file(s) no longer referenced by the current version")
