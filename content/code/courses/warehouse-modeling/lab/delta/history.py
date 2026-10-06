"""List the table's commits, oldest first."""
from deltalake import DeltaTable

for commit in reversed(DeltaTable("lake/sales").history()):
    print(commit["version"], commit["operation"], commit.get("operationParameters", {}))
