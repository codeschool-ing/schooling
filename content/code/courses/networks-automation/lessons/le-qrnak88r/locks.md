---
title: Locks
version: 1
---

The candidate is shared, and two scripts editing it at once would each commit the other's half
finished work. **NETCONF's answer is a lock on a datastore**, taken with `lock` and given back with
`unlock`. While one session holds it, every other session's edit is refused:

```schooling-example
{
  "language": "python",
  "file": "locks.py",
  "parts": [
    {
      "code": "from ncclient.operations import RPCError\n\nfrom nc import connect, interface_config\n\nEDIT = interface_config(\"<interface><name>eth2</name><description>from session B</description></interface>\")\n"
    },
    {
      "code": "with connect() as a, connect() as b:\n    print(\"A session\", a.session_id, \"B session\", b.session_id)\n    a.lock(\"candidate\")\n    print(\"A: lock candidate: ok\")",
      "note": "**Two sessions, as two scripts or two people would have.** A takes the lock on the candidate."
    },
    {
      "code": "    try:\n        b.edit_config(target=\"candidate\", config=EDIT)\n    except RPCError as e:\n        print(\"B: edit-config:\", e.tag, \"-\", e.message)\n    a.unlock(\"candidate\")\n    print(\"A: unlock candidate: ok\")\n    b.edit_config(target=\"candidate\", config=EDIT)\n    print(\"B: edit-config: ok\")\n    b.discard_changes()",
      "note": "**B is refused, and told who holds the lock.**"
    }
  ]
}
```

```
ana@ctl:~$ python locks.py
A session 9 B session 10
A: lock candidate: ok
B: edit-config: lock-denied - Operation failed, lock is already held
A: unlock candidate: ok
B: edit-config: ok
```

The refusal has its own tag, **`lock-denied`**, which is what a script should look for: it means
"somebody else is changing this device, try again later", not "your change is wrong". The error
also carries the session id of the holder; `nc1` numbered these two sessions 9 and 10.

A lock belongs to a session. **If the session that holds it dies, the lock is released**, so a
crashed script cannot lock a device forever. That is also why a lock is no substitute for
coordination between people: a colleague typing at the CLI of a device without NETCONF will not
see it, and a device that is configured both ways at once is configured by whoever wrote last.

The habit this suggests for every change script is short: **lock, discard whatever is in the
candidate, edit, validate, commit, unlock.** Discarding first throws away an edit somebody
abandoned, and the lock guarantees nobody adds one in the middle.
