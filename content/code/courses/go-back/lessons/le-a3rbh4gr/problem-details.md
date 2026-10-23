---
title: One shape for every error
version: 1
---

By section 04, boxoffice had four ways to say no: a bad id, an unreadable body, invalid values, and
the store's refusals still to come. If each handler invented its own error format, a client would
need a parser per route. **An API's errors should have one shape, and there is a standard one: RFC
9457, "Problem Details for HTTP APIs"**, published in 2023 to replace RFC 7807 of 2016 with the same
format. It is a JSON object with a few agreed members, sent as `application/problem+json`:

| member | holds |
|---|---|
| `type` | a URI naming the kind of problem; `about:blank` when the status says it all |
| `title` | a short summary of that kind, the same for every occurrence; with `about:blank`, the status phrase |
| `status` | the HTTP status again, for whoever logs the body without the headers |
| `detail` | this occurrence, in words a client developer can act on |
| anything else | extensions; boxoffice adds `errors`, the field-by-field map from section 04 |

boxoffice's version is one type and one function, in the file that also holds section 06's `fail`:

```go
// boxoffice/problem.go
package main

import (
	"errors"
	"log"
	"net/http"
)

// problem is an error response in the shape RFC 9457 describes.
type problem struct {
	Type   string            `json:"type"`
	Title  string            `json:"title"`
	Status int               `json:"status"`
	Detail string            `json:"detail,omitempty"`
	Errors map[string]string `json:"errors,omitempty"`
}

// writeProblem sends an error as application/problem+json.
func writeProblem(w http.ResponseWriter, status int, detail string, fields map[string]string) {
	w.Header().Set("Content-Type", "application/problem+json")
	writeJSON(w, status, problem{
		Type:   "about:blank",
		Title:  http.StatusText(status),
		Status: status,
		Detail: detail,
		Errors: fields,
	})
}

// fail turns an error from the store into the response it deserves.
func fail(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		writeProblem(w, http.StatusNotFound, err.Error(), nil)
	case errors.Is(err, ErrSoldOut):
		writeProblem(w, http.StatusConflict, err.Error(), nil)
	default:
		log.Printf("unexpected error: %v", err)
		writeProblem(w, http.StatusInternalServerError, "", nil)
	}
}
```

`writeProblem` sets the precise media type and then hands the value to `writeJSON`, which keeps a
`Content-Type` that was already set; that is the line section 02 left room for. Every error
boxoffice writes from now on goes through it, including the two middlewares of lesson 2 that wrote
text: section 07 shows `requireStaff` and `recoverPanics` changed to use it. Here is the 401 they
now give:

```
ana@vm:~/boxoffice$ curl -si --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
HTTP/1.1 401 Unauthorized
Content-Type: application/problem+json
Vary: Origin
Www-Authenticate: Bearer realm="boxoffice"
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 96

{"type":"about:blank","title":"Unauthorized","status":401,"detail":"a staff token is required"}
```

**`detail` is safe to show, and a 500's `detail` is empty on purpose.** The message of an unexpected
error can name a file, a query or a hostname, so `fail` sends it to the log and gives the client
only the status. The `type` stays `about:blank` throughout boxoffice because none of its errors
needs more than its status to be understood; an API with forty kinds of refusal would give each a
URI with a page explaining it.

## The two answers boxoffice does not write

One request still gets plain text:

```
ana@vm:~/boxoffice$ curl -si -X DELETE localhost:8080/events
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD
Content-Type: text/plain; charset=utf-8
Vary: Origin
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 19

Method Not Allowed
```

**The 404 and 405 the mux writes for paths and methods it has no pattern for are its own**, and
`ServeMux` has no setting to change their format. The obvious fix is a catch-all pattern, `/`, whose
handler writes a JSON 404. It has a cost that is easy to miss:

```go
// catchall/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "every event")
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/problem+json")
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintln(w, `{"type":"about:blank","title":"Not Found","status":404}`)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

```
ana@vm:~/catchall$ curl -s localhost:8080/events
every event
ana@vm:~/catchall$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: application/problem+json
Date: Fri, 16 Oct 2026 22:36:38 GMT
Content-Length: 56

{"type":"about:blank","title":"Not Found","status":404}
ana@vm:~/catchall$ curl -si -X DELETE localhost:8080/events
HTTP/1.1 404 Not Found
Content-Type: application/problem+json
Date: Fri, 16 Oct 2026 22:36:38 GMT
Content-Length: 56

{"type":"about:blank","title":"Not Found","status":404}
```

The unknown path got its JSON 404, and so did `DELETE /events`, **which used to be a 405**. With `/`
registered for every method, the mux always finds a pattern for `/events`, so it never reaches the
point of saying "the path exists, the method does not", and the `Allow` header goes with it. A
client that sent the wrong method is now told the resource does not exist, which is false.

boxoffice keeps the mux's own text answers for those two cases. **A correct status in the wrong
format beats a well-formatted wrong status**, and a client can always fall back to the status code
when the body is not JSON. Lesson 5 counts this among the places where the standard library is
thinner than a framework.
