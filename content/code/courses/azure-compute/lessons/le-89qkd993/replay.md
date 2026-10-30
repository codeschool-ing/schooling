---
title: x
version: 1
---

```python
from datetime import datetime, timezone
```

```python
    logging.info('order_flow for %s, replaying=%s, now=%s, context=%s', order['order'], context.is_replaying,
                 datetime.now(timezone.utc).time(), context.current_utc_datetime.time())
```
