package notify_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/notify"
	"github.com/codeschool-ing/schooling/internal/platform/mail"
)

/* The messages this platform sends.

   THEY ARE TESTED AGAINST AN OUTBOX AND NEVER AGAINST A NETWORK. That is what
   `mail.Sender` being an interface with one method buys, and it is why the
   outbox is production code rather than a double living in a test file. */

func sent(t *testing.T, to notify.Person, token string) mail.Message {
	t.Helper()
	var box mail.Outbox
	n := notify.New(&box, "https://my.example.tld", nil)

	if err := n.ConfirmAddress(context.Background(), to, token); err != nil {
		t.Fatalf("sending: %v", err)
	}
	m, any := box.Last()
	if !any {
		t.Fatal("nothing was sent")
	}
	return m
}

// THE LINK POINTS AT `my.`, WHICH IS THE ACCOUNT'S OWN HOST. A token belongs to
// an account and an account crosses every school, so a link into a school's host
// would have to pick one — and would pick wrongly for anybody enrolled in two.
func TestTheLinkPointsAtTheAccountsOwnHost(t *testing.T) {
	m := sent(t, notify.Person{Name: "Alexandre", Email: "somebody@example.tld"}, "abc123")

	const want = "https://my.example.tld/confirm/abc123"
	if !strings.Contains(m.Text, want) {
		t.Errorf("the plain body does not carry %q:\n%s", want, m.Text)
	}
	if !strings.Contains(m.HTML, `href="`+want+`"`) {
		t.Errorf("the HTML body does not link to %q:\n%s", want, m.HTML)
	}
	if m.To.Email != "somebody@example.tld" || m.To.Name != "Alexandre" {
		t.Errorf("the message went to %+v", m.To)
	}
}

// A TOKEN IS ESCAPED INTO THE PATH. Base64url produces none of the characters
// that would matter, and this is the assertion that keeps it true the day the
// alphabet changes.
func TestATokenIsEscapedIntoTheLink(t *testing.T) {
	m := sent(t, notify.Person{Email: "somebody@example.tld"}, "a/b c?d")

	if strings.Contains(m.Text, "a/b c?d") {
		t.Errorf("the token went into the link unescaped:\n%s", m.Text)
	}
	if !strings.Contains(m.Text, "a%2Fb%20c%3Fd") {
		t.Errorf("the token was not escaped as expected:\n%s", m.Text)
	}
}

/*
BOTH BODIES ARE THERE, AND THAT IS NOT A COURTESY.

	A message with only HTML reads as empty in some clients and scores worse with
	the filters that decide whether a confirmation link reaches an inbox at all —
	which, for this message, is the entire thing it is for.
*/
func TestTheMessageCarriesAPlainBodyAsWellAsHTML(t *testing.T) {
	m := sent(t, notify.Person{Name: "Alexandre", Email: "somebody@example.tld"}, "abc123")

	if strings.TrimSpace(m.Text) == "" {
		t.Error("the message has no plain body")
	}
	if strings.TrimSpace(m.HTML) == "" {
		t.Error("the message has no HTML body")
	}
	if strings.Contains(m.Text, "<p>") || strings.Contains(m.Text, "<a ") {
		t.Errorf("the plain body carries markup:\n%s", m.Text)
	}
	if m.Subject == "" {
		t.Error("the message has no subject")
	}
}

// PORTUGUESE IS ONE OF THE TWO LANGUAGES THE SERVER WRITES IN, following the
// precedent of `internal/legal/documents`, which holds `privacy.en.md` and
// `privacy.pt.md` and nothing else.
func TestAPortugueseAccountIsWrittenToInPortuguese(t *testing.T) {
	for _, locale := range []string{"pt", "pt-BR", "PT-br"} {
		m := sent(t, notify.Person{
			Name: "Alexandre", Email: "somebody@example.tld", Locale: locale,
		}, "abc123")

		if m.Subject != "Confirme seu endereço de e-mail" {
			t.Errorf("%q got the subject %q", locale, m.Subject)
		}
		if !strings.Contains(m.Text, "O link vale por um dia.") {
			t.Errorf("%q got a body that is not Portuguese:\n%s", locale, m.Text)
		}
	}
}

// AND EVERY OTHER LOCALE GETS ENGLISH, which is the source language everywhere
// in this organisation. The interface speaks five; the server writes two, and a
// locale it does not cover must fall back rather than send an empty message.
func TestAnUncoveredLocaleGetsEnglish(t *testing.T) {
	for _, locale := range []string{"", "es", "fr", "it", "de-AT", "  "} {
		m := sent(t, notify.Person{Email: "somebody@example.tld", Locale: locale}, "abc123")

		if m.Subject != "Confirm your e-mail address" {
			t.Errorf("%q got the subject %q, want the English one", locale, m.Subject)
		}
	}
}

/*
A NAME IS SOMEBODY'S TEXT ARRIVING IN A DOCUMENT.

	It comes from a sign-up form, and the one place this platform composes HTML
	outside a browser is the last place to decide that a name is safe because it
	usually is.
*/
func TestANameCannotCarryMarkupIntoTheMessage(t *testing.T) {
	m := sent(t, notify.Person{
		Name:  `<script>alert(1)</script>`,
		Email: "somebody@example.tld",
	}, "abc123")

	if strings.Contains(m.HTML, "<script>") {
		t.Errorf("a name put a script tag into the message:\n%s", m.HTML)
	}
	if !strings.Contains(m.HTML, "&lt;script&gt;") {
		t.Errorf("the name was not escaped at all:\n%s", m.HTML)
	}
}

// AN ACCOUNT WITH NO NAME IS ALLOWED — `identity.NewAccount` defaults it to
// empty — so the greeting has to cope rather than say "Hi ,".
func TestAnAccountWithNoNameIsGreetedAnyway(t *testing.T) {
	m := sent(t, notify.Person{Email: "somebody@example.tld"}, "abc123")

	if strings.Contains(m.Text, " ,") || strings.Contains(m.Text, "%!s") {
		t.Errorf("the greeting has a hole where a name would be:\n%s", m.Text)
	}
	if !strings.HasPrefix(m.Text, "Hi,") {
		t.Errorf("the message does not open with a greeting:\n%s", m.Text)
	}
}

// A NOTIFIER WITH NOWHERE TO SEND DOES NOTHING AND SAYS SO QUIETLY. Every caller
// of this is on the path of a request that must not fail because mail is not
// configured — a sign-up that returns an error because there is no key would be
// mail deciding whether somebody may study here.
func TestANotifierWithNoSenderIsHarmless(t *testing.T) {
	var none *notify.Notifier
	if err := none.ConfirmAddress(context.Background(),
		notify.Person{Email: "somebody@example.tld"}, "abc123"); err != nil {
		t.Errorf("a nil notifier answered %v, want nothing", err)
	}

	quiet := notify.New(nil, "https://my.example.tld", nil)
	if err := quiet.ConfirmAddress(context.Background(),
		notify.Person{Email: "somebody@example.tld"}, "abc123"); err != nil {
		t.Errorf("a notifier with no sender answered %v, want nothing", err)
	}
}

// A TRAILING SLASH ON THE ORIGIN IS SOMEBODY'S ENVIRONMENT VARIABLE, not a bug
// worth a deploy. Two slashes in a confirmation link is a 404 with nothing in it
// to explain itself.
func TestATrailingSlashOnTheOriginDoesNotDoubleUp(t *testing.T) {
	var box mail.Outbox
	n := notify.New(&box, "https://my.example.tld/", nil)

	if err := n.ConfirmAddress(context.Background(),
		notify.Person{Email: "somebody@example.tld"}, "abc123"); err != nil {
		t.Fatalf("sending: %v", err)
	}
	m, _ := box.Last()
	if strings.Contains(m.Text, "//confirm") {
		t.Errorf("the link doubled its slash:\n%s", m.Text)
	}
}

/* Asking before writing.

   The list itself is tested against a database in `suppress_test.go`. These
   test the DECISION — that a refusal stops a message, that a database which
   would not answer also stops it, and that the two are told apart. */

// AN ADDRESS THAT REFUSED US IS NOT WRITTEN TO, and the caller is told why
// rather than handed a silent success — a message that never arrives and no
// error to explain it is the failure the whole list exists to make legible.
func TestARefusedAddressIsNotWrittenTo(t *testing.T) {
	var box mail.Outbox
	var asked string
	n := notify.New(&box, "https://my.example.tld",
		func(_ context.Context, address string) (bool, error) {
			asked = address
			return true, nil
		})

	err := n.ConfirmAddress(context.Background(),
		notify.Person{Email: "gone@example.tld"}, "abc123")
	if !errors.Is(err, notify.ErrRefused) {
		t.Errorf("sending to a refused address answered %v, want ErrRefused", err)
	}
	if asked != "gone@example.tld" {
		t.Errorf("the list was asked about %q, want the recipient", asked)
	}
	if _, any := box.Last(); any {
		t.Error("the message went out anyway")
	}
}

// AND AN ADDRESS THAT DID NOT STILL GETS ITS LINK. The obvious half, and the
// one that would fail if the check were inverted — which is a failure nothing
// else here would catch, because every other test wires no list at all.
func TestAnAddressThatNeverRefusedUsIsStillWrittenTo(t *testing.T) {
	var box mail.Outbox
	n := notify.New(&box, "https://my.example.tld",
		func(context.Context, string) (bool, error) { return false, nil })

	if err := n.ConfirmAddress(context.Background(),
		notify.Person{Email: "somebody@example.tld"}, "abc123"); err != nil {
		t.Fatalf("sending: %v", err)
	}
	if _, any := box.Last(); !any {
		t.Error("nothing was sent")
	}
}

/*
A LIST WE CANNOT READ IS A REFUSAL.

	The safe direction, and it is not obvious enough to leave to a comment: a
	database that will not answer is not permission to write to somebody who
	told us to stop. Being wrong this way costs one message; being wrong the
	other way costs the domain's standing with the providers that decide whether
	anybody's mail arrives at all.
*/
func TestAListThatCannotBeReadStopsTheMessage(t *testing.T) {
	var box mail.Outbox
	blown := errors.New("the database is on fire")
	n := notify.New(&box, "https://my.example.tld",
		func(context.Context, string) (bool, error) { return false, blown })

	err := n.ConfirmAddress(context.Background(),
		notify.Person{Email: "somebody@example.tld"}, "abc123")
	if !errors.Is(err, blown) {
		t.Errorf("a broken list answered %v, want the failure underneath it", err)
	}
	if _, any := box.Last(); any {
		t.Error("the message went out while the list was unreadable")
	}
}
