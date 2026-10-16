---
title: Calling it, and the answers that are not scores
version: 1
---

From the first terminal, three requests and a timing:

```
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/2; echo
{"member_id":2,"p_lapse":0.098,"features_as_of":"2026-02-28","model_version":1}
ana@dev:~/ml$ curl -s -i http://127.0.0.1:8000/lapse/8; echo
HTTP/1.1 404 Not Found
date: Fri, 16 Oct 2026 00:45:10 GMT
server: uvicorn
content-length: 53
content-type: application/json

{"detail":"no features fresh enough for this member"}
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/abc; echo
{"detail":[{"type":"int_parsing","loc":["path","member_id"],"msg":"Input should be a valid integer, unable to parse string as an integer","input":"abc"}]}
ana@dev:~/ml$ curl -s -o /dev/null -w "%{time_total}\n" http://127.0.0.1:8000/lapse/2
0.011410
```

**Member 2** gets a probability, the date of the features it was computed from, and the model
version, everything somebody debugging a strange score needs in the response itself. **Member 8**
gets `404 Not Found` with the reason in the body: lesson 6's online store left them out as too old,
and the service says so instead of inventing a score. **`abc`** never reaches the function: FastAPI
answers `422` and says which part of the request was wrong.

**The last line is the whole round trip, in seconds**, measured by `curl`: about a hundredth of a
second on the recording machine, for a request that read one row from SQLite and ran one
prediction. That is the number lesson 9 watches, along with every other request's.

Member 2's probability here, 0.098, is not the 0.090 lesson 7 printed for the same member, and both
are right: lesson 7 scored the member as of 30 November, and this service scores them as of
tonight's snapshot. A score is always a score *as of* something, which is why the response carries
the date.

Stop the service with Ctrl+C in its terminal when you are done; lesson 9 starts it again.
