// Package mail sends a message to one person, and is the only place in this
// repository that talks to a mail provider.
//
// # NOTHING HERE KNOWS WHAT A STUDENT IS
//
// That is the rule `platform` lives by — it imports nothing from this
// repository and is the floor everything else stands on — and it is also what
// keeps this package honest. A verification link, a staff invitation and a
// receipt are three different sentences written by three different modules;
// what they share is an envelope, and an envelope is all this package is.
//
// So there is no `SendVerification` here, and there will not be one. What
// leaves this package is a `Message` somebody else composed.
//
// # THE PROVIDER IS ONE IMPLEMENTATION AND NOT THE INTERFACE
//
// `Sender` has one method because one method is what every caller needs, and
// because a deployment without a key has to be a first-class case rather than a
// crash. There are two implementations: `ViaBrevo`, which posts to an API over
// the network, and `Outbox`, which keeps the messages in memory and posts
// nothing.
//
// The second is not a test double that leaked into production code. Running
// this platform on a laptop, in CI, and in every test that touches sign-up must
// not require a mail account, and must not silently drop what it would have
// sent — a dropped message is indistinguishable from a delivered one until
// somebody complains. `Outbox` keeps them, and `cmd/api` says out loud which of
// the two it wired.
//
// # THE KEY IS NEVER IN AN ERROR, A LOG LINE OR A STRUCT THAT PRINTS
//
// It is an API key with permission to send mail as this platform, which makes
// it a credential rather than a setting. `%v` on a struct holding one puts it
// in whatever the caller does with the error, and errors end up in logs by
// definition. So the key lives in a field nothing formats, the errors here name
// the STATUS and the provider's message and never the request, and there is a
// test that reads the error text looking for it.
//
// # A FAILED SEND IS AN ERROR AND NOT A RETRY
//
// Nothing here retries. A provider that answered 500 will likely answer 500
// again a hundred milliseconds later, and a retry loop inside a request handler
// spends somebody's page load discovering that. What a caller does with the
// failure — tell the person, leave the token unsent, queue it — is a decision
// about that caller's screen, and this package refuses to make it for them.
package mail

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"
)

// Address is somebody's name and where they read their mail. The name is
// optional and the address is not.
type Address struct {
	Name  string
	Email string
}

// Message is one envelope.
//
// IT CARRIES BOTH BODIES BECAUSE THE PLAIN ONE IS NOT A COURTESY. A message
// with only HTML reads as empty in a client that shows text, and — more to the
// point here — scores worse with the filters that decide whether a verification
// link reaches an inbox at all. `Text` is required and `HTML` is not.
type Message struct {
	To      Address
	Subject string
	Text    string
	HTML    string
}

// Sender puts a message on its way, or says why it could not.
//
// The context bounds the call rather than the delivery: a provider that
// accepted the message has accepted it, and what happens between them and the
// recipient is not something an HTTP response can report.
type Sender interface {
	Send(ctx context.Context, m Message) error
}

// ErrNoRecipient is what an empty `To.Email` gets, from either implementation.
//
// IT IS CHECKED HERE RATHER THAN AT THE PROVIDER because the provider's answer
// to it is a 400 with a JSON body about a field name, arriving after a network
// round trip, in a language nobody in this repository writes. A message with
// nobody to receive it is a bug in the caller, and it should read like one.
var ErrNoRecipient = errors.New("mail: the message has no recipient")

/*
sendTimeout bounds one call to the provider.

	It is longer than a person will happily wait, on purpose: the alternative to
	waiting is a message the platform believes it failed to send and the provider
	believes it accepted, which is the one outcome that produces a duplicate. Ten
	seconds is past every healthy response and short of a hung socket.
*/
const sendTimeout = 10 * time.Second

// ---------- the provider ----------

// brevo posts to Brevo's transactional endpoint.
type brevo struct {
	// key is the credential. Nothing formats this struct, and this comment is
	// the reason: see the package's third section.
	key string

	from    Address
	replyTo Address

	endpoint string
	client   *http.Client
}

// ViaBrevo is the sender this platform uses in production.
//
// # THE `From` IS THE DEPLOYMENT'S AND NOT THE MESSAGE'S
//
// Every message this platform sends leaves the same address, because the
// address is what the receiving side authenticates: SPF and DKIM are published
// for one domain, and a From somebody composed per message is a From that can
// be published wrong. It is a parameter here rather than a constant because
// this repository holds no domain names (see `config.PlatformDomain`).
//
// # AND THE `Reply-To` IS A DIFFERENT ADDRESS ON PURPOSE
//
// The sending domain has no MX by design — it signs, it does not receive — so a
// reply to the From would bounce. Somebody who answers a message from this
// platform is a person with something to say, and bouncing them is the rudest
// possible answer. `replyTo` is where those land, and it is allowed to be a
// mailbox at a different domain entirely.
//
// An empty `replyTo.Email` sends no header at all, which is honest: no
// Reply-To means "the From is the address", and a Reply-To pointing nowhere is
// worse than none.
func ViaBrevo(key string, from, replyTo Address) Sender {
	return &brevo{
		key:      key,
		from:     from,
		replyTo:  replyTo,
		endpoint: "https://api.brevo.com/v3/smtp/email",
		client:   &http.Client{Timeout: sendTimeout},
	}
}

func (b *brevo) Send(ctx context.Context, m Message) error {
	if strings.TrimSpace(m.To.Email) == "" {
		return ErrNoRecipient
	}

	ctx, cancel := context.WithTimeout(ctx, sendTimeout)
	defer cancel()

	body, err := json.Marshal(b.payload(m))
	if err != nil {
		return fmt.Errorf("mail: composing the request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, b.endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("mail: building the request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("api-key", b.key)

	res, err := b.client.Do(req)
	if err != nil {
		/* THE URL IS IN THIS ERROR AND THE KEY IS NOT. `*url.Error` carries the
		   endpoint, which is public, and never the headers. Wrapping it is what
		   tells somebody reading a log that the provider was unreachable rather
		   than unhappy. */
		return fmt.Errorf("mail: asking the provider: %w", err)
	}
	// Discarded on purpose, and written this way because `.golangci.yml` says
	// so: closing a body whose content has been read cannot fail in a way this
	// caller could act on, and an error dropped without a line saying why is the
	// failure mode that file exists to catch.
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode < 200 || res.StatusCode >= 300 {
		return fmt.Errorf("mail: the provider answered %d: %s", res.StatusCode, complaint(res.Body))
	}

	// The 201 carries a messageId. Nothing here reads it: a caller that stored
	// one would be storing a handle to a provider this repository intends to be
	// able to replace, and nothing in the platform asks a question it answers.
	_, _ = io.Copy(io.Discard, io.LimitReader(res.Body, 1<<16))
	return nil
}

// payload is Brevo's shape, kept in one function so that the provider's field
// names live in one place rather than spread through Send.
func (b *brevo) payload(m Message) map[string]any {
	who := map[string]any{"email": b.from.Email}
	if b.from.Name != "" {
		who["name"] = b.from.Name
	}

	to := map[string]any{"email": m.To.Email}
	if m.To.Name != "" {
		to["name"] = m.To.Name
	}

	out := map[string]any{
		"sender":      who,
		"to":          []map[string]any{to},
		"subject":     m.Subject,
		"textContent": m.Text,
	}
	if m.HTML != "" {
		out["htmlContent"] = m.HTML
	}
	if b.replyTo.Email != "" {
		reply := map[string]any{"email": b.replyTo.Email}
		if b.replyTo.Name != "" {
			reply["name"] = b.replyTo.Name
		}
		out["replyTo"] = reply
	}
	return out
}

/*
complaint is what the provider said, cut to something a log line can hold.

	A refusal from Brevo is a small JSON object with a code and a message, and it
	is the only thing that distinguishes "this key is wrong" from "this sender is
	not authenticated" from "this recipient is on your blocklist". Discarding it
	and reporting the status alone would turn three different afternoons into the
	same one.

	It is read through a limit because an error body is not a promise: a proxy
	between here and there can answer a 502 with a page.
*/
func complaint(r io.Reader) string {
	raw, err := io.ReadAll(io.LimitReader(r, 4<<10))
	if err != nil || len(raw) == 0 {
		return "(no body)"
	}

	var said struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	}
	if json.Unmarshal(raw, &said) == nil && said.Message != "" {
		if said.Code != "" {
			return said.Code + ": " + said.Message
		}
		return said.Message
	}
	return strings.TrimSpace(string(raw))
}

// ---------- the one that posts nothing ----------

// Outbox keeps every message instead of sending it, and is safe to share
// between goroutines.
//
// IT IS WIRED WHEN THERE IS NO KEY, which is every laptop, every test and CI.
// The alternative — a nil Sender that callers check for — puts an `if` in front
// of every send in the repository, and the day somebody forgets it the platform
// panics on a sign-up. This never fails and never delivers, and `cmd/api` logs
// which one it chose so that "no mail arrived" has an answer in the start-up
// line rather than in an investigation.
type Outbox struct {
	mu   sync.Mutex
	sent []Message
}

func (o *Outbox) Send(_ context.Context, m Message) error {
	if strings.TrimSpace(m.To.Email) == "" {
		return ErrNoRecipient
	}
	o.mu.Lock()
	defer o.mu.Unlock()
	o.sent = append(o.sent, m)
	return nil
}

// Sent is everything this outbox was given, oldest first. The slice is a copy,
// so a caller ranging over it cannot be surprised by a concurrent send.
func (o *Outbox) Sent() []Message {
	o.mu.Lock()
	defer o.mu.Unlock()
	return append([]Message(nil), o.sent...)
}

// Last is the most recent message, which is what a test almost always wants.
func (o *Outbox) Last() (Message, bool) {
	o.mu.Lock()
	defer o.mu.Unlock()
	if len(o.sent) == 0 {
		return Message{}, false
	}
	return o.sent[len(o.sent)-1], true
}
