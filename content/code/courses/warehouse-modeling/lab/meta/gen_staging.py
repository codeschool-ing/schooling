"""Write the staging SQL from sources.json instead of by hand."""
import json
import sys

meta = json.load(open(sys.argv[1]))

print("SET TimeZone = 'America/Sao_Paulo';")
print(f"CREATE SCHEMA {meta['schema']};")
for t in meta["tables"]:
    options = ["sample_size = -1"]
    if "types" in t:
        pairs = ", ".join(f"'{c}': '{ty}'" for c, ty in t["types"].items())
        options.append(f"types = {{{pairs}}}")
    path = f"{meta['directory']}/{t['name']}.csv"
    print(f"CREATE TABLE {meta['schema']}.{t['name']} AS "
          f"FROM read_csv('{path}', {', '.join(options)});")
