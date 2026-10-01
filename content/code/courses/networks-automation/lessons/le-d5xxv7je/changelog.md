---
title: A change, from NetBox to the router
version: 1
---

With the data in NetBox, a change starts there. edge2's LAN description changes through the API,
the configurations are rendered again, and lesson 10's `push.py` compares them with the routers:

```python
from nb import connect

nb = connect()
interface = nb.dcim.interfaces.get(device="edge2", name="eth2")
interface.description = "branch 2 LAN, floor 1"
interface.save()
print(f"edge2 eth2: {interface.description}")
```

```
ana@ctl:~$ cd sot && python rename.py && python render_nb.py > /dev/null && python push.py
edge2 eth2: branch 2 LAN, floor 1
core1: matches
edge1: matches
edge2:
interface eth2
- description branch LAN
interface eth2
+ description branch 2 LAN, floor 1
```

**Only edge2 has something to do**, and the diff is exactly the field that changed in NetBox. This
is lesson 10's flow with the YAML file replaced by an object in NetBox, and the rest of the chain did
not notice.

What NetBox adds is a record of the change on its side. Every write, from the web interface or the
API, is kept in a change log with the user, the time and the object before and after:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/core/object-changes/?changed_object_type=dcim.interface&ordering=-time&limit=1" | jq ".results[0] | {time, user_name, action, object_repr, before: .prechange_data.description, after: .postchange_data.description}"
{
  "time": "2026-10-01T19:22:18.964589-03:00",
  "user_name": "ana",
  "action": {
    "value": "update",
    "label": "Updated"
  },
  "object_repr": "eth2",
  "before": "branch LAN",
  "after": "branch 2 LAN, floor 1"
}
```

**The router's history from lesson 11 says when the configuration changed; NetBox's change log says
who changed the intent, and from what.** Together they answer the question lesson 11 could not: who
decided this. The `user_name` is `ana` because the token is hers, which is the argument for giving
each person and each pipeline its own token rather than sharing one.
