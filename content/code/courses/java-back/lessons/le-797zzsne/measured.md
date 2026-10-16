---
title: Startup and size, measured
version: 1
---

PROSE1

```sh
#!/usr/bin/env bash
# Start a jar, print how long it takes to answer its first request, and the
# line in which the framework reports its own startup time.
jar=$1
url=$2
log=$(mktemp)
java -jar "$jar" > "$log" 2>&1 &
pid=$!
start=$(date +%s%N)
until curl -s -o /dev/null "$url"; do
    sleep 0.02
done
echo "first answer after $(( ($(date +%s%N) - start) / 1000000 )) ms"
grep -E 'Javalin started in|Started [A-Za-z]+ in' "$log"
kill "$pid"
wait "$pid" 2> /dev/null
rm -f "$log"
```

PROSE2
