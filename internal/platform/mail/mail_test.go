package mail

/* The envelope, as bytes over HTTP.

   WHAT THESE HOLD is the shape of the request to the provider, the fact that
   the credential does not leak into anything a log will hold, and that a
   deployment without a key keeps its messages rather than dropping them.

   They are an internal test because the endpoint has to point at a server this
   file started — the alternative is a package that talks to Brevo in CI, which
   is a test that fails when somebody else's service has an afternoon. */

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
)

const secret = "xkeysib-not-a-real-key-0000000000"

// against stands a fake provider up and points a sender at it. The handler gets
// the decoded body, so a test can assert on the shape rather than on a string.
func against(t *testing.T, reply func(w http.ResponseWriter, got map[string]any, key string)) Sender {
	t.Helper()

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var got map[string]any
		raw, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(raw, &got)
		reply(w, got, r.Header.Get("api-key"))
	}))
	t.Cleanup(srv.Close)

	s := ViaBrevo(secret,
		Address{Name: "Schooling", Email: "schooling@example.tld"},
		Address{Email: "reply@example.tld"},
	).(*brevo)
	s.endpoint = srv.URL
	return s
}

// A MESSAGE ARRIVES AS THE PROVIDER EXPECTS IT, and with the key in the header
// rather than anywhere in the body.
func TestTheMessageIsPostedInTheProvidersShape(t *testing.T) {
	var seen map[string]any
	var sentKey string

	s := against(t, func(w http.ResponseWriter, got map[string]any, key string) {
		seen, sentKey = got, key
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"messageId":"<abc@brevo>"}`))
	})

	err := s.Send(context.Background(), Message{
		To:      Address{Name: "Alexandre", Email: "somebody@example.tld"},
		Subject: "Confirm your e-mail",
		Text:    "Open this link.",
		HTML:    "<p>Open this link.</p>",
	})
	if err != nil {
		t.Fatalf("a healthy provider produced an error: %v", err)
	}

	if sentKey != secret {
		t.Errorf("the api-key header carried %q", sentKey)
	}

	sender, _ := seen["sender"].(map[string]any)
	if sender["email"] != "schooling@example.tld" || sender["name"] != "Schooling" {
		t.Errorf("the sender went as %v — it is the deployment's address and not the message's", sender)
	}

	to, _ := seen["to"].([]any)
	if len(to) != 1 {
		t.Fatalf("the message went to %d recipients, want 1", len(to))
	}
	if first, _ := to[0].(map[string]any); first["email"] != "somebody@example.tld" {
		t.Errorf("the recipient went as %v", first)
	}

	if seen["subject"] != "Confirm your e-mail" {
		t.Errorf("the subject went as %v", seen["subject"])
	}
	if seen["textContent"] != "Open this link." {
		t.Errorf("the plain body went as %v", seen["textContent"])
	}
	if seen["htmlContent"] != "<p>Open this link.</p>" {
		t.Errorf("the HTML body went as %v", seen["htmlContent"])
	}

	/* THE REPLY-TO IS NOT THE FROM, and that is the whole point of it: the
	   sending domain has no MX, so a reply to the From bounces. */
	reply, _ := seen["replyTo"].(map[string]any)
	if reply["email"] != "reply@example.tld" {
		t.Errorf("the Reply-To went as %v", reply)
	}
}

// A MESSAGE WITH NO HTML SENDS NO HTML FIELD, rather than an empty one — an
// empty `htmlContent` is a body, and a client showing it shows a blank page
// where the plain text would have been.
func TestAnAbsentHTMLBodyIsAbsentAndNotEmpty(t *testing.T) {
	var seen map[string]any
	s := against(t, func(w http.ResponseWriter, got map[string]any, _ string) {
		seen = got
		w.WriteHeader(http.StatusCreated)
	})

	if err := s.Send(context.Background(), Message{
		To: Address{Email: "somebody@example.tld"}, Subject: "s", Text: "t",
	}); err != nil {
		t.Fatalf("send: %v", err)
	}

	if _, present := seen["htmlContent"]; present {
		t.Error("a message without an HTML body still sent an htmlContent field")
	}
}

// AND NEITHER DOES AN ABSENT REPLY-TO. No header means "the From is the
// address", which is at least true; a Reply-To pointing nowhere is not.
func TestAnAbsentReplyToSendsNoHeader(t *testing.T) {
	var seen map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(raw, &seen)
		w.WriteHeader(http.StatusCreated)
	}))
	t.Cleanup(srv.Close)

	s := ViaBrevo(secret, Address{Email: "schooling@example.tld"}, Address{}).(*brevo)
	s.endpoint = srv.URL

	if err := s.Send(context.Background(), Message{
		To: Address{Email: "somebody@example.tld"}, Subject: "s", Text: "t",
	}); err != nil {
		t.Fatalf("send: %v", err)
	}
	if _, present := seen["replyTo"]; present {
		t.Error("a sender configured without a Reply-To sent one anyway")
	}
}

/*
A REFUSAL SAYS WHAT THE PROVIDER SAID.

	The status alone turns "this key is wrong", "this sender is not
	authenticated" and "this recipient is blocked" into the same afternoon. The
	provider's own code and message are the only thing that separates them.
*/
func TestARefusalCarriesTheProvidersReason(t *testing.T) {
	s := against(t, func(w http.ResponseWriter, _ map[string]any, _ string) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"code":"unauthorized","message":"Key not found"}`))
	})

	err := s.Send(context.Background(), Message{
		To: Address{Email: "somebody@example.tld"}, Subject: "s", Text: "t",
	})
	if err == nil {
		t.Fatal("a 401 came back as a successful send")
	}
	for _, want := range []string{"401", "unauthorized", "Key not found"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("the error does not mention %q: %v", want, err)
		}
	}
}

// A BODY THAT IS NOT THE PROVIDER'S JSON IS STILL REPORTED. A proxy between
// here and there answers a 502 with a page, and discarding it leaves somebody
// staring at a bare number.
func TestARefusalWithoutJSONIsStillReported(t *testing.T) {
	s := against(t, func(w http.ResponseWriter, _ map[string]any, _ string) {
		w.WriteHeader(http.StatusBadGateway)
		_, _ = w.Write([]byte("<html>upstream is unwell</html>"))
	})

	err := s.Send(context.Background(), Message{
		To: Address{Email: "somebody@example.tld"}, Subject: "s", Text: "t",
	})
	if err == nil || !strings.Contains(err.Error(), "upstream is unwell") {
		t.Errorf("a non-JSON refusal came back as %v", err)
	}
}

/*
THE KEY IS IN NO ERROR THIS PACKAGE PRODUCES.

	It is a credential with permission to send mail as this platform, and errors
	end up in logs by definition. This is the assertion that keeps a future
	`fmt.Errorf("...: %v", b)` from shipping.
*/
func TestNoErrorCarriesTheKey(t *testing.T) {
	refused := against(t, func(w http.ResponseWriter, _ map[string]any, _ string) {
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte(`{"code":"forbidden","message":"no"}`))
	})

	// And one that cannot be reached at all, which is the other shape of error.
	closed := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	closed.Close()
	unreachable := ViaBrevo(secret, Address{Email: "schooling@example.tld"}, Address{}).(*brevo)
	unreachable.endpoint = closed.URL

	for _, s := range []Sender{refused, unreachable} {
		err := s.Send(context.Background(), Message{
			To: Address{Email: "somebody@example.tld"}, Subject: "s", Text: "t",
		})
		if err == nil {
			t.Fatal("expected an error")
		}
		if strings.Contains(err.Error(), secret) {
			t.Errorf("the api key is in an error message: %v", err)
		}
	}
}

// A MESSAGE WITH NOBODY TO RECEIVE IT IS A BUG IN THE CALLER, and it reads like
// one — before a network round trip, and identically in both implementations.
func TestAMessageWithNoRecipientIsRefusedByBoth(t *testing.T) {
	reached := false
	s := against(t, func(w http.ResponseWriter, _ map[string]any, _ string) {
		reached = true
		w.WriteHeader(http.StatusCreated)
	})

	for _, sender := range []Sender{s, &Outbox{}} {
		if err := sender.Send(context.Background(), Message{Subject: "s", Text: "t"}); !errors.Is(err, ErrNoRecipient) {
			t.Errorf("%T answered %v, want ErrNoRecipient", sender, err)
		}
	}
	if reached {
		t.Error("a message with no recipient was posted to the provider anyway")
	}
}

// ---------- the one that posts nothing ----------

// THE OUTBOX KEEPS WHAT IT WOULD HAVE SENT. A deployment without a key must not
// drop messages silently: a dropped one is indistinguishable from a delivered
// one until somebody complains.
func TestTheOutboxKeepsEveryMessage(t *testing.T) {
	var box Outbox

	if _, any := box.Last(); any {
		t.Error("an empty outbox reported a last message")
	}

	for _, subject := range []string{"first", "second"} {
		if err := box.Send(context.Background(), Message{
			To: Address{Email: "somebody@example.tld"}, Subject: subject, Text: "t",
		}); err != nil {
			t.Fatalf("the outbox failed a send: %v", err)
		}
	}

	sent := box.Sent()
	if len(sent) != 2 || sent[0].Subject != "first" || sent[1].Subject != "second" {
		t.Fatalf("the outbox holds %v, want the two in order", sent)
	}

	last, any := box.Last()
	if !any || last.Subject != "second" {
		t.Errorf("Last is %v", last)
	}

	// The slice is a copy: a caller ranging over it cannot be surprised, and
	// cannot edit what the outbox holds either.
	sent[0].Subject = "tampered"
	if again := box.Sent(); again[0].Subject != "first" {
		t.Error("Sent handed out the outbox's own slice")
	}
}

// AND IT IS SAFE TO SHARE. It is wired once at start-up and used by every
// request, which is the same as saying it is used from many goroutines at once.
func TestTheOutboxIsSafeToShare(t *testing.T) {
	var box Outbox
	var wg sync.WaitGroup

	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_ = box.Send(context.Background(), Message{
				To: Address{Email: "somebody@example.tld"}, Subject: "s", Text: "t",
			})
			_ = box.Sent()
		}()
	}
	wg.Wait()

	if got := len(box.Sent()); got != 50 {
		t.Errorf("the outbox holds %d of 50 messages", got)
	}
}
