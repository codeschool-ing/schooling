#!/bin/bash
# sweep.sh: how many addresses would the rule flag at each threshold?
for n in 2 3 4 10; do
  sed "s/gte: 10/gte: $n/" spray.yml > try.yml
  ~/sigma/bin/sigma convert -t sqlite try.yml -o try.sql 2>/dev/null
  printf 'gte %-3s %s addresses\n' "$n" "$(bash grouped.sh try.sql | tail -n +3 | wc -l)"
done
