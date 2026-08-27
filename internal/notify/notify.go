// Package notify writes the messages this platform sends to a person, and hands
// them to whatever sends them.
//
// # IT IS THE OTHER HALF OF `platform/mail`
//
// That package is the envelope and knows nothing about students. This one knows
// what a confirmation link is, which address it belongs to and what to say about
// it — and knows nothing about HTTP, providers or keys. The seam is `mail.Sender`,
// an interface with one method, so this package is tested against an outbox and
// never against a network.
//
// # WHAT LANGUAGE A MESSAGE IS IN
//
// The interface speaks five languages and this speaks two: English and
// Portuguese. That is not a shortcut, it is the precedent already set by the only
// other text this repository AUTHORS on the server — `internal/legal/documents`
// holds `privacy.en.md` and `privacy.pt.md` and nothing else. The five languages
// live in the browser, in `window.I18N`, where `check-interface` polices them; a
// message composed in Go has no such policing, and five half-maintained
// translations of a sentence somebody has to trust is worse than two.
//
// A locale nothing here covers gets English, which is the source language
// everywhere in this organisation.
//
// # NO TEMPLATES
//
// Four short strings and a URL. `text/template` would buy nothing and cost the
// one thing that matters in a message carrying a link: being able to read, in
// one screen, exactly what gets sent.
package notify

import (
	"context"
	"errors"
	"fmt"
	"html"
	"net/url"
	"strings"

	"github.com/codeschool-ing/schooling/internal/platform/mail"
)

// Barred answers whether an address has permanently refused us. It is a
// function type rather than a store so that this package keeps knowing nothing
// about a database — `Suppressions` in this same package satisfies it, and a
// test satisfies it with a closure.
type Barred func(ctx context.Context, address string) (bool, error)

// Notifier composes this platform's messages and sends them.
type Notifier struct {
	sender mail.Sender
	barred Barred

	// at is the origin a link points at, as `https://my.example.tld`. It is a
	// whole origin rather than a domain because a test serves on http and a
	// port, and a link built by pasting "https://" in front of a host is a link
	// that cannot be tested against anything real.
	at string
}

// New wires a notifier to a sender and to the origin its links point at.
//
// THE ORIGIN IS `my.`, WHICH IS THE ACCOUNT'S OWN HOST. An account crosses every
// school (N-01) and a confirmation token belongs to the account rather than to
// any one school, so a link into a school's host would have to pick one — and
// would pick wrongly for anybody enrolled in two. `my.` is the one host in K-17
// that is the person's.
func New(sender mail.Sender, origin string, barred Barred) *Notifier {
	return &Notifier{sender: sender, at: strings.TrimSuffix(origin, "/"), barred: barred}
}

// Person is who a message is going to. It is this package's own shape rather
// than `identity.Account`, so that `identity` and this stay strangers.
type Person struct {
	Name   string
	Email  string
	Locale string
}

// ConfirmAddress sends somebody the link that proves they can read their mail.
func (n *Notifier) ConfirmAddress(ctx context.Context, to Person, token string) error {
	if n == nil || n.sender == nil {
		return nil
	}
	if err := n.mayWrite(ctx, to.Email); err != nil {
		return err
	}
	words := speak(to.Locale).confirm
	link := n.at + "/confirm/" + url.PathEscape(token)

	return n.sender.Send(ctx, mail.Message{
		To:      mail.Address{Name: to.Name, Email: to.Email},
		Subject: words.subject,
		Text:    plain(words, to.Name, link),
		HTML:    marked(words, to.Name, link),
	})
}

/*
ChangeAddress sends the link that moves an account onto a new address.

	IT GOES TO THE NEW ADDRESS AND NOWHERE ELSE. What the link proves is that
	somebody can read the mailbox they are asking to move to, so sending it
	anywhere else would prove nothing — and sending a copy to the old one would
	be announcing a change that has not happened yet, which is how an authorised
	person is frightened by their own request.
*/
func (n *Notifier) ChangeAddress(ctx context.Context, to Person, token string) error {
	if n == nil || n.sender == nil {
		return nil
	}
	if err := n.mayWrite(ctx, to.Email); err != nil {
		return err
	}
	words := speak(to.Locale).change
	link := n.at + "/change/" + url.PathEscape(token)

	return n.sender.Send(ctx, mail.Message{
		To:      mail.Address{Name: to.Name, Email: to.Email},
		Subject: words.subject,
		Text:    plain(words, to.Name, link),
		HTML:    marked(words, to.Name, link),
	})
}

/*
AddressChanged tells the OLD address that it is no longer the account's.

	IT IS THE ONLY CHANNEL THAT REACHES THE REAL OWNER if the person who asked
	was not them, which is the whole reason it exists. Everything else about a
	hostile change happens inside a session the attacker controls.

	IT IS SENT AFTER THE CHANGE AND NOT WHEN IT IS ASKED FOR. On the request it
	would be a way to post a message to any address, repeatedly, by asking to
	move there and never clicking — which is the abuse `changeCap` bounds on the
	other side and this would walk straight around.

	A SUPPRESSED OLD ADDRESS IS NOT AN ERROR THE CALLER SHOULD ACT ON. It is the
	commonest reason this feature is used at all: the address refused our mail,
	so the person moved. `mayWrite` answers `ErrRefused`, the change has already
	happened, and the caller logs it and carries on.

	IT CARRIES NO LINK AND NOTHING TO CLICK. A message saying "if this was not
	you, press here" is the shape of every phishing mail anybody has ever
	received, and this one goes to somebody who may have just lost an account.
	What it says instead is what to do: sign in and change it back, and change
	the password.
*/
func (n *Notifier) AddressChanged(ctx context.Context, to Person, now string) error {
	if n == nil || n.sender == nil {
		return nil
	}
	if err := n.mayWrite(ctx, to.Email); err != nil {
		return err
	}
	w := speak(to.Locale).moved

	body := []string{
		greeting(w, to.Name),
		"",
		w.lead,
		"",
		now,
		"",
		w.ignore,
	}
	return n.sender.Send(ctx, mail.Message{
		To:      mail.Address{Name: to.Name, Email: to.Email},
		Subject: w.subject,
		Text:    strings.Join(body, "\n"),
		HTML: "<p>" + html.EscapeString(greeting(w, to.Name)) + "</p>" +
			"<p>" + html.EscapeString(w.lead) + "</p>" +
			"<p><strong>" + html.EscapeString(now) + "</strong></p>" +
			"<p>" + html.EscapeString(w.ignore) + "</p>",
	})
}

/*
mayWrite refuses an address that has told us to stop.

	IT IS CHECKED HERE AND NOT AT THE SENDER, because `platform/mail` is an
	envelope and knows nothing about who this platform has heard from. This is
	the package that knows both.

	A READ THAT FAILED IS A REFUSAL. A database we cannot ask is not permission
	to write to somebody who asked us not to — the cost of being wrong in that
	direction is one message that does not go out, and the cost of being wrong in
	the other is a mark against this domain with whoever decides if anybody's
	mail arrives.

	NO LIST WIRED MEANS NO LIST, and that is for the deployments that have none:
	a test, and a laptop whose outbox nobody reads. `cmd/api` always wires one.
*/
func (n *Notifier) mayWrite(ctx context.Context, address string) error {
	if n.barred == nil {
		return nil
	}
	barred, err := n.barred(ctx, address)
	if err != nil {
		return fmt.Errorf("notify: reading the suppression list: %w", err)
	}
	if barred {
		return ErrRefused
	}
	return nil
}

// ErrRefused is an address on the suppression list. It is an error and not a
// silent success, because a caller that logs it learns why nothing arrived —
// which is the question this whole list exists to be able to answer.
var ErrRefused = errors.New("notify: this address has refused our mail")

/*
words is one message in one language.

	IT IS A STRUCT AND NOT A MAP KEYED BY STRING, so that adding a sentence to the
	message fails to compile in every language that does not have it yet. A map
	would fail at run time, in the one place nobody is looking — inside a message
	that has already left.
*/
type words struct {
	subject string
	greet   string // "Hi %s," — and just "Hi," when there is no name
	lead    string
	button  string
	fallb   string // what to do when the button does not work
	expires string
	ignore  string
}

/*
messages is every message this platform sends, in one language.

	A STRUCT OF STRUCTS AND NOT THREE PACKAGE VARIABLES PER LANGUAGE, for the
	reason `words` is a struct: adding a message fails to compile in every
	language that does not have it yet, in the file rather than inside an
	envelope that has already left.
*/
type messages struct {
	confirm words
	change  words
	moved   words
}

var (
	english = messages{
		confirm: words{
			subject: "Confirm your e-mail address",
			greet:   "Hi %s,",
			lead:    "Follow this link to confirm that this address reaches you.",
			button:  "Confirm my address",
			fallb:   "If the button does not work, paste this into your browser:",
			expires: "The link works for one day.",
			ignore: "If you did not create an account, nothing happens — you can ignore " +
				"this message and the link will expire on its own.",
		},

		change: words{
			subject: "Confirm your new e-mail address",
			greet:   "Hi %s,",
			lead: "Somebody asked to move an account to this address. Follow this link " +
				"to confirm that it reaches you, and it becomes the address we write to.",
			button:  "Use this address",
			fallb:   "If the button does not work, paste this into your browser:",
			expires: "The link works for one day, and nothing changes until you follow it.",
			ignore: "If you did not ask for this, nothing happens — you can ignore this " +
				"message and the link will expire on its own.",
		},

		/* THE ONE WITH NO LINK IN IT. `button`, `fallb` and `expires` are unused
		   here and are left empty rather than filled with something plausible:
		   a message that tells somebody they may have lost their account is the
		   last place to put a button, because that is the shape of every
		   phishing mail they have ever received. */
		moved: words{
			subject: "The e-mail address on your account changed",
			greet:   "Hi %s,",
			lead: "This account no longer uses this address. From now on we write to " +
				"the one below, and this message is the last one you will get here.",
			ignore: "If you did not do this, sign in and change it back — and change " +
				"your password, because whoever did had it.",
		},
	}

	portuguese = messages{
		confirm: words{
			subject: "Confirme seu endereço de e-mail",
			greet:   "Olá, %s,",
			lead:    "Siga este link para confirmar que este endereço chega até você.",
			button:  "Confirmar meu endereço",
			fallb:   "Se o botão não funcionar, cole isto no seu navegador:",
			expires: "O link vale por um dia.",
			ignore: "Se você não criou uma conta, nada acontece — pode ignorar esta " +
				"mensagem, e o link expira sozinho.",
		},

		change: words{
			subject: "Confirme seu novo endereço de e-mail",
			greet:   "Olá, %s,",
			lead: "Alguém pediu para mudar uma conta para este endereço. Siga este link " +
				"para confirmar que ele chega até você, e ele passa a ser o endereço " +
				"para onde escrevemos.",
			button:  "Usar este endereço",
			fallb:   "Se o botão não funcionar, cole isto no seu navegador:",
			expires: "O link vale por um dia, e nada muda até você segui-lo.",
			ignore: "Se você não pediu isso, nada acontece — pode ignorar esta mensagem, " +
				"e o link expira sozinho.",
		},

		moved: words{
			subject: "O endereço de e-mail da sua conta mudou",
			greet:   "Olá, %s,",
			lead: "Esta conta não usa mais este endereço. De agora em diante escrevemos " +
				"para o que está abaixo, e esta é a última mensagem que você recebe aqui.",
			ignore: "Se não foi você, entre e troque de volta — e troque sua senha, " +
				"porque quem fez isso a tinha.",
		},
	}
)

// speak picks the language for a locale, matching on the language subtag so that
// `pt-BR` and `pt-PT` are both Portuguese. Anything else is English.
func speak(locale string) messages {
	lang, _, _ := strings.Cut(strings.ToLower(strings.TrimSpace(locale)), "-")
	if lang == "pt" {
		return portuguese
	}
	return english
}

// greeting is the first line, and it copes with an account that has no name —
// which `identity.NewAccount` allows, since `name` defaults to empty.
func greeting(w words, name string) string {
	if strings.TrimSpace(name) == "" {
		before, _, _ := strings.Cut(w.greet, " %s")
		return before + ","
	}
	return fmt.Sprintf(w.greet, name)
}

/*
plain is the message a text-only client shows.

	IT IS NOT A COURTESY. A message with only HTML reads as empty in some clients
	and scores worse with the filters deciding whether a confirmation link reaches
	an inbox at all — which, for this particular message, is the whole point of
	sending it.

	The URL is on its own line, unwrapped, because a mail client that folds it is
	a link somebody cannot paste.
*/
func plain(w words, name, link string) string {
	return strings.Join([]string{
		greeting(w, name),
		"",
		w.lead,
		"",
		link,
		"",
		w.expires,
		"",
		w.ignore,
	}, "\n")
}

/*
marked is the same message with a button.

	EVERY VALUE THAT REACHES IT IS ESCAPED, including the link. A name comes from
	a sign-up form, so it is somebody's text arriving in a document — and the one
	place this platform composes HTML outside a browser is the last place to
	decide that a name is safe because it usually is.

	No stylesheet, no image, no external anything. Mail clients strip most of it,
	the ones that do not are inconsistent about which, and a message that depends
	on CSS to be readable is a message that is unreadable somewhere.
*/
func marked(w words, name, link string) string {
	safe := html.EscapeString(link)
	return "<p>" + html.EscapeString(greeting(w, name)) + "</p>" +
		"<p>" + html.EscapeString(w.lead) + "</p>" +
		`<p><a href="` + safe + `">` + html.EscapeString(w.button) + "</a></p>" +
		"<p>" + html.EscapeString(w.fallb) + "<br>" + safe + "</p>" +
		"<p>" + html.EscapeString(w.expires) + "</p>" +
		"<p>" + html.EscapeString(w.ignore) + "</p>"
}
