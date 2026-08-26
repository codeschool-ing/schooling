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
	"fmt"
	"html"
	"net/url"
	"strings"

	"github.com/codeschool-ing/schooling/internal/platform/mail"
)

// Notifier composes this platform's messages and sends them.
type Notifier struct {
	sender mail.Sender

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
func New(sender mail.Sender, origin string) *Notifier {
	return &Notifier{sender: sender, at: strings.TrimSuffix(origin, "/")}
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
	words := speak(to.Locale)
	link := n.at + "/confirm/" + url.PathEscape(token)

	return n.sender.Send(ctx, mail.Message{
		To:      mail.Address{Name: to.Name, Email: to.Email},
		Subject: words.subject,
		Text:    plain(words, to.Name, link),
		HTML:    marked(words, to.Name, link),
	})
}

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

var (
	english = words{
		subject: "Confirm your e-mail address",
		greet:   "Hi %s,",
		lead:    "Follow this link to confirm that this address reaches you.",
		button:  "Confirm my address",
		fallb:   "If the button does not work, paste this into your browser:",
		expires: "The link works for one day.",
		ignore: "If you did not create an account, nothing happens — you can ignore " +
			"this message and the link will expire on its own.",
	}

	portuguese = words{
		subject: "Confirme seu endereço de e-mail",
		greet:   "Olá, %s,",
		lead:    "Siga este link para confirmar que este endereço chega até você.",
		button:  "Confirmar meu endereço",
		fallb:   "Se o botão não funcionar, cole isto no seu navegador:",
		expires: "O link vale por um dia.",
		ignore: "Se você não criou uma conta, nada acontece — pode ignorar esta " +
			"mensagem, e o link expira sozinho.",
	}
)

// speak picks the language for a locale, matching on the language subtag so that
// `pt-BR` and `pt-PT` are both Portuguese. Anything else is English.
func speak(locale string) words {
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
