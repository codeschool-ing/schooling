---
title: Tests that run at the same time as the code
version: 1
---

A server handles requests concurrently, so a test that sends one request at a time leaves the most
dangerous part untested. This one creates an event with ten seats and has fifty buyers try for one seat
each, all at once, through the whole router:

```go
// boxoffice/concurrency_test.go
package main

import (
	"net/http"
	"strings"
	"sync"
	"testing"
)

// Fifty buyers want one seat each of an event with ten left. Ten get one.
func TestConcurrentPurchases(t *testing.T) {
	srv := newTestServer(t)
	body := `{"name": "Small Room", "seats": 10}`
	req, _ := http.NewRequest("POST", srv.URL+"/admin/events", strings.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+managerToken)
	resp, err := srv.Client().Do(req)
	if err != nil || resp.StatusCode != http.StatusCreated {
		t.Fatalf("creating the event: %v %v", resp, err)
	}
	resp.Body.Close()

	var wg sync.WaitGroup
	sold := 0
	for range 50 {
		wg.Go(func() {
			resp, err := srv.Client().Post(srv.URL+"/events/3/tickets", "application/json",
				strings.NewReader(`{"quantity": 1, "email": "fan@example.com"}`))
			if err != nil {
				t.Error(err)
				return
			}
			resp.Body.Close()
			if resp.StatusCode == http.StatusCreated {
				sold++
			}
		})
	}
	wg.Wait()
	if sold != 10 {
		t.Errorf("%d tickets sold, want 10", sold)
	}
}
```

`wg.Go`, from go-concurrency, starts each buyer in a goroutine and counts it into the `WaitGroup`. The event
is number 3 because `newMemStore` already holds two. Run normally, it passes:

```
ana@vm:~/boxoffice$ go test -run TestConcurrentPurchases .
ok  	example.com/boxoffice	(cached)
```

**And it is wrong.** Run the same test with the race detector:

```
ana@vm:~/boxoffice$ go test -race -run TestConcurrentPurchases .
==================
WARNING: DATA RACE
Read at 0x00c0000192a8 by goroutine 21:
  example.com/boxoffice.TestConcurrentPurchases.func1()
      /home/ana/boxoffice/concurrency_test.go:35 +0x27a

Previous write at 0x00c0000192a8 by goroutine 20:
  example.com/boxoffice.TestConcurrentPurchases.func1()
      /home/ana/boxoffice/concurrency_test.go:35 +0x28f

Goroutine 21 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38

Goroutine 20 (finished) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38
==================
--- FAIL: TestConcurrentPurchases (0.03s)
    testing.go:1865: race detected during execution of test
FAIL
FAIL	example.com/boxoffice	0.041s
FAIL
```

The detector watched every memory access while the test ran and found two goroutines touching the same
variable with nothing ordering them. The report names **the line, `concurrency_test.go:35`, which is
`sold++`**: fifty goroutines incrementing one integer. An increment is a read and a write, and two
goroutines can both read 7 and both write 8. The first run passed because, that time, they happened not
to; on a busier machine the count would come out 9 now and then, and the test would fail once a week with
nothing to explain it.

The defect is in the test, not in boxoffice: `memStore` holds its mutex, and the server sold exactly ten.
**A test's own code runs concurrently too, and it is held to the same rules as the code it tests.** The fix
is an `atomic.Int64`, whose `Add` is one indivisible step:

```go
// boxoffice/concurrency_test.go
package main

import (
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
)

// Fifty buyers want one seat each of an event with ten left. Ten get one.
func TestConcurrentPurchases(t *testing.T) {
	srv := newTestServer(t)
	body := `{"name": "Small Room", "seats": 10}`
	req, _ := http.NewRequest("POST", srv.URL+"/admin/events", strings.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+managerToken)
	resp, err := srv.Client().Do(req)
	if err != nil || resp.StatusCode != http.StatusCreated {
		t.Fatalf("creating the event: %v %v", resp, err)
	}
	resp.Body.Close()

	var wg sync.WaitGroup
	var sold atomic.Int64
	for range 50 {
		wg.Go(func() {
			resp, err := srv.Client().Post(srv.URL+"/events/3/tickets", "application/json",
				strings.NewReader(`{"quantity": 1, "email": "fan@example.com"}`))
			if err != nil {
				t.Error(err)
				return
			}
			resp.Body.Close()
			if resp.StatusCode == http.StatusCreated {
				sold.Add(1)
			}
		})
	}
	wg.Wait()
	if n := sold.Load(); n != 10 {
		t.Errorf("%d tickets sold, want 10", n)
	}
}
```

```
ana@vm:~/boxoffice$ go test -race -run TestConcurrentPurchases .
ok  	example.com/boxoffice	(cached)
```

The race detector needs cgo, which is why lesson 1 checked for gcc. It only sees races that happen while
it watches, so it finds nothing in code a test never runs concurrently; this test exists to make the
concurrent case happen. Section 08 measures what it costs to leave it on.
