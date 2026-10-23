---
title: x
version: 1
---

Save it as `~/threads.py`:

```python
# Start threads that sleep, one after another, until the system refuses one.
# Run it only in a container with --pids-limit: on a machine with no limit it
# stops at whatever the kernel allows, which is a great many.
import threading
import time

started = 0
try:
    while True:
        threading.Thread(target=time.sleep, args=(5,), daemon=True).start()
        started += 1
except RuntimeError as error:
    print(f"{started} threads started, then: {error}")
```
