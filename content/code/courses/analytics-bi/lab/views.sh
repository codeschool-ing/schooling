# Sourced by the capture scripts: rebuild the shop, then every view the
# lessons before this one created, each taken out of the .md that shows it.
# Usage: views_up_to N   (N = the lesson number whose views to include)
views_up_to() {
  local here; here=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  bash "$here/lab.sh" shop 9>&-
  local n=$1
  local fence="$here/lab/fence.py"
  local L="$here/lessons"
  if [ "$n" -ge 1 ]; then
    python3 "$fence" "$L/le-0wmh3j1s/order-value.md" 'CREATE VIEW order_totals' | bash "$here/lab.sh" exec 'psql -qX -v ON_ERROR_STOP=1 lantern' 9>&-
  fi
  if [ "$n" -ge 2 ]; then
    python3 "$fence" "$L/le-j8nbfcaw/three-revenues.md" 'CREATE VIEW order_revenue' | bash "$here/lab.sh" exec 'psql -qX -v ON_ERROR_STOP=1 lantern' 9>&-
  fi
  if [ "$n" -ge 3 ]; then
    python3 "$fence" "$L/le-h13c3qmk/building-the-layer.md" '-- semantic.sql' > /tmp/abi-semantic.sql
    chmod 644 /tmp/abi-semantic.sql
    bash "$here/lab.sh" exec 'psql -qX -v ON_ERROR_STOP=1 lantern -f /tmp/abi-semantic.sql' 9>&-
    bash "$here/lab.sh" exec "psql -qX lantern -c 'DROP ROLE IF EXISTS metabase'" 9>&-
    { python3 "$fence" "$L/le-h13c3qmk/a-role-for-tools.md" 'CREATE ROLE metabase'
      python3 "$fence" "$L/le-h13c3qmk/a-role-for-tools.md" 'GRANT USAGE ON SCHEMA semantic'; } \
      | bash "$here/lab.sh" exec 'psql -qX -v ON_ERROR_STOP=1 lantern' 9>&-
  fi
}
