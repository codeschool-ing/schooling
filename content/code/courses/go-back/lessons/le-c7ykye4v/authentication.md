---
title: Authentication, and who the request is
version: 1
---

Two questions sound alike and have different answers. **Authentication asks who is calling.
Authorisation asks whether that caller may do this.** HTTP gives each its own status: `401
Unauthorized`, despite the name, means "I do not know who you are", and `403 Forbidden` means "I
know who you are, and no". boxoffice needs both. Anyone may list events, staff may call the
`/admin/` routes, and only a manager may read the sales report.

## A token in a header

The simplest scheme that is not a password typed on every request is a **bearer token**: a long
random string the server knows, which the client sends as `Authorization: Bearer <token>`.
Whoever bears it is let in, which is the whole meaning of the name and the whole of its weakness.
A token must therefore be long enough that guessing is hopeless, sent only over HTTPS outside a
laptop, and kept out of logs and repositories.

`openssl rand -hex 16` prints sixteen random bytes as hex, 128 bits, which is long enough. boxoffice
reads two of them from the environment, one per role:

```
ana@vm:~/boxoffice$ export BOXOFFICE_MANAGER_TOKEN=$(openssl rand -hex 16)
ana@vm:~/boxoffice$ export BOXOFFICE_DOOR_TOKEN=$(openssl rand -hex 16)
ana@vm:~/boxoffice$ echo $BOXOFFICE_MANAGER_TOKEN $BOXOFFICE_DOOR_TOKEN
5ca82ad2121fe5f238c90ab37b7106cd 9c101e9b24e371302e323f6964aee17c
```

**Your two values will differ**; they are random. Lesson 14 gives configuration a proper home, and
until then an environment variable keeps the secret out of the source code and out of the command
line, where `ps` would show it to every user of the machine.

```go
// boxoffice/auth.go
package main

import (
	"context"
	"crypto/subtle"
	"net/http"
	"strings"
)

type roleKey struct{}

// requireStaff lets a request through only if it carries one of the tokens,
// and puts the role that token belongs to into the request's context.
func requireStaff(tokens map[string]string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role := ""
			if got, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer "); ok {
				for token, owner := range tokens {
					if subtle.ConstantTimeCompare([]byte(got), []byte(token)) == 1 {
						role = owner
					}
				}
			}
			if role == "" {
				w.Header().Set("WWW-Authenticate", `Bearer realm="boxoffice"`)
				http.Error(w, "a staff token is required", http.StatusUnauthorized)
				return
			}
			ctx := context.WithValue(r.Context(), roleKey{}, role)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// staffRole is the role requireStaff found, or "" outside it.
func staffRole(ctx context.Context) string {
	role, _ := ctx.Value(roleKey{}).(string)
	return role
}
```

The middleware takes the map of token to role, and on every request:

- cuts `Bearer ` off the front of the header, and gives up if it is not there;
- compares what is left with **every** token, using `subtle.ConstantTimeCompare`;
- refuses with 401 and a `WWW-Authenticate` header naming the scheme when nothing matched;
- otherwise puts the role into the request's context and calls `next` with that request.

**Why not `==`.** Comparing two strings with `==` stops at the first byte that differs, so a wrong
token that starts with the right characters takes a little longer to refuse than one that does
not. Measured often enough over a network, that difference can be used to guess a token one
character at a time. `ConstantTimeCompare` takes the same time whatever matches, and the loop does
not stop at a match either, so the time says nothing about which token it was.

**Why the context.** The handler behind the middleware needs to know the role, and its signature has
no room for one. `go-concurrency` lesson 10 named request-scoped values as the one thing
`context.WithValue` is for, and this is one. The key is `roleKey{}`, an unexported type of the
package's own, so no other package can read or overwrite the value by accident. `staffRole` is the
only way in, and it answers `""` when the middleware was not on the path.

The handler that uses it:

```go
// boxoffice/admin.go
package main

import (
	"fmt"
	"net/http"
)

func salesReport(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if staffRole(r.Context()) != "manager" {
			http.Error(w, "only a manager may read the sales report", http.StatusForbidden)
			return
		}
		for _, e := range store.List() {
			fmt.Fprintf(w, "%d\t%s\t%d sold\n", e.ID, e.Name, e.Sold)
		}
	}
}
```

## Every answer it gives

```
ana@vm:~/boxoffice$ curl -si localhost:8080/admin/report
HTTP/1.1 401 Unauthorized
Content-Type: text/plain; charset=utf-8
Vary: Origin
Www-Authenticate: Bearer realm="boxoffice"
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 26

a staff token is required
ana@vm:~/boxoffice$ curl -s -H 'Authorization: Bearer 0123456789abcdef' localhost:8080/admin/report
a staff token is required
ana@vm:~/boxoffice$ curl -si -H "Authorization: Bearer $BOXOFFICE_DOOR_TOKEN" localhost:8080/admin/report
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Vary: Origin
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 41

only a manager may read the sales report
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" localhost:8080/admin/report
1	Jazz at the Docks	0 sold
2	Chamber Choir	80 sold
```

No header: 401, with `WWW-Authenticate` telling the client which scheme to use. A made-up token:
the same 401, with no hint that it was nearly right. **The door token is a real one**, so the
caller is known, and the answer is 403 from the handler. The manager's token gets the report.

## What this is not

Bearer tokens in environment variables are right for a service called by a handful of staff tools.
They have no expiry, no way to revoke one person's access without changing everyone's, and no
login screen. **Real user accounts are a different design**: passwords stored as slow hashes,
sessions or short-lived signed tokens, and often an identity provider speaking OpenID Connect.
Whatever the design, its check lands in exactly this place, a middleware that decides who the
request is and passes that on in the context, and the handlers behind it do not change.
