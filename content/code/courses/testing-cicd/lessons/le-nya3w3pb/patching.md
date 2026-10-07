---
title: Patching, and where a name is looked up
version: 2
---

When code has no seam, a test can still replace a collaborator by **patching**: swapping the object
a name refers to, for the duration of the test, and putting it back afterwards. In Python that is
`unittest.mock.patch`, or pytest's `monkeypatch`. It is the tool for code you cannot change. It also
has a trap that catches almost everybody once, and `shipquote` falls into it on purpose.

Here is a test file written for this section, and only for it. Both tests want
`CarrierClient.rate` to receive a canned answer of 1999 cents without touching the network. Save it
as `tests/test_patch_trap.py`:

```python
import io
from unittest import mock

from shipquote.carrier import CarrierClient


def test_patching_the_module_after_the_default_was_taken():
    answer = mock.MagicMock()
    answer.__enter__.return_value = io.BytesIO(b'{"cents": 1999}')
    with mock.patch("urllib.request.urlopen", return_value=answer):
        client = CarrierClient("http://127.0.0.1:9", "t")
        assert client.rate("01310100", 1200) == 1999


def test_handing_the_double_in_through_the_seam():
    answer = mock.MagicMock()
    answer.__enter__.return_value = io.BytesIO(b'{"cents": 1999}')
    client = CarrierClient("http://127.0.0.1:9", "t",
                           opener=mock.Mock(return_value=answer))
    assert client.rate("01310100", 1200) == 1999
```

The first patches `urllib.request.urlopen`, the function the client uses by default. The second
passes the double through the `opener` parameter. Port 9 on 127.0.0.1 has nothing listening, so any
request that really leaves would be refused. Delete the file once you have run it: it exists to
fail.

```
ana@laptop:~/shipquote$ python -m pytest tests/test_patch_trap.py -q --tb=line
F.                                                                       [100%]
=================================== FAILURES ===================================
E   ConnectionRefusedError: [Errno 111] Connection refused

During handling of the above exception, another exception occurred:
E   urllib.error.URLError: <urlopen error [Errno 111] Connection refused>

The above exception was the direct cause of the following exception:
E   shipquote.carrier.CarrierError: <urlopen error [Errno 111] Connection refused>
/home/ana/shipquote/shipquote/carrier.py:29: shipquote.carrier.CarrierError: <urlopen error [Errno 111] Connection refused>
=========================== short test summary info ============================
FAILED tests/test_patch_trap.py::test_patching_the_module_after_the_default_was_taken
1 failed, 1 passed in 0.17s
```

**The patch had no effect.** The first test made a real connection to port 9 and was refused; the
second passed. The reason is in one line of `carrier.py`:

```python
    def __init__(self, base_url, token, timeout=2.0,
                 opener=urllib.request.urlopen):
```

A default argument is evaluated **once, when the function is defined**, which is when the module
is imported. At that moment `opener`'s default became the real `urlopen` function. Patching the
name `urllib.request.urlopen` later changes what the name points to, and the default still holds
the original object.

## Patch where the name is used

The same thing happens with `from urllib.request import urlopen` at the top of a module: that line
copies the reference into the module's own namespace, and patching `urllib.request.urlopen`
afterwards does not reach the copy. The rule is in the `unittest.mock` documentation: **patch the
name where it is looked up, not where it is defined.** For code that does
`from urllib.request import urlopen` in `shipquote/carrier.py`, the target is
`"shipquote.carrier.urlopen"`.

Notice also how the failure looked. The test did not fail with "the patch did not apply"; it failed
with a connection error three exceptions deep. **A patch that misses its target fails as something
else**, or, worse, passes against a real service that happened to answer. That is the strongest
reason to prefer a seam: the second test cannot miss, because the double is handed over in plain
sight.
