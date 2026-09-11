// Package device answers what kind of thing a request came from, in four
// words, and is deliberately incapable of answering anything finer.
//
// # WHY FOUR WORDS AND NOT A DEVICE STRING
//
// The useful question is whether the experience differs by shape of screen:
// arrivals on a phone that convert at half the rate of arrivals on a laptop is
// a defect with an address. Every finer answer — the model, the screen size,
// the operating system version — answers nothing anybody asks and costs
// something real, because GRANULARITY IS WHAT TURNS TELEMETRY INTO A
// FINGERPRINT. Three values plus "we do not know" cannot identify anybody, and
// that is a property of the type rather than a promise about how it is used.
//
// So this package has no way to return more. There is no model here, no
// resolution, no version, and adding one would be visible as an addition rather
// than as a field somebody started filling in.
//
// # IT DOES NOT PARSE THE USER-AGENT, ON PURPOSE
//
// That string is thirty years of browsers claiming to be each other — Chrome
// says it is Safari, which says it is Gecko, which says it is Mozilla — and
// every library that reads it is a table of exceptions being maintained against
// a moving target. Lesson six of `web-fundamentals` teaches students exactly
// that, which makes reading it here a small hypocrisy as well as a bad idea.
//
// What is read instead is the CLIENT HINTS: `Sec-CH-UA-Mobile` and
// `Sec-CH-UA-Platform`, which browsers send by design, which are low-entropy by
// definition, and which say what they mean.
//
// # THE HOLE, NAMED RATHER THAN FILLED WITH A GUESS
//
// Only Chromium sends those hints. Firefox and Safari send neither, so every
// iPhone on Safari would be `Unknown` — a hole big enough to make the whole
// number a lie by omission.
//
// So the page reports one too, in a header of ours, and the hint wins where
// there is one. The page's answer comes from `matchMedia` and the pointer,
// which is the thing the layout itself responds to, and it is the caller's to
// choose — bounded here to the same four words, because a dimension a client
// can write is a column a client can fill with anything.
//
// WHAT IS LEFT IS STILL `Unknown` FOR ANYBODY WHO SENDS NEITHER, and that stays
// a row on every report rather than being folded into the largest bucket. A
// plausible number on every row is the shape of wrong this repository keeps
// finding.
//
// # THE HINTS DO NOT EXIST IN LOCAL DEVELOPMENT, AND THAT IS NOT A DEFECT
//
// Client hints are sent on SECURE CONTEXTS only. The browser suites here run
// against `http://code.example.tld:8099` — plain HTTP, and not `localhost`, so
// not a secure context either — which means `Sec-CH-UA-Mobile` is absent from
// every request a local run will ever make.
//
// So locally the page's header is not the fallback, it is the whole mechanism,
// and in production it is the other way round. Both paths are exercised by the
// tests for that reason. Anybody who reads the hints on a laptop, sees nothing
// arrive, and concludes this is broken has found the deployment rather than a
// bug — which is why it is written down here instead of being rediscovered.
package device

import (
	"context"
	"net/http"
	"strings"
)

// The four answers. They are words rather than an enum of integers for the
// reason every dimension here is: they land in a column a person reads.
const (
	// Phone is a handset: the hint says mobile.
	Phone = "phone"

	// Tablet is not mobile and is on a handset operating system, which is what
	// Chromium reports for an Android tablet and an iPad.
	Tablet = "tablet"

	// Computer is not mobile and is on a desktop operating system.
	Computer = "computer"

	// Unknown is a browser that sent no hint and no header of ours. It is a
	// real answer and appears on every report as one — most of the web is not
	// Chromium, and a screen that hid this row would be a screen quietly
	// reporting a minority as the whole.
	Unknown = "unknown"
)

// Known answers whether a word is one of the four. Exported because the header
// below is the caller's to write, and both this package and its tests have to
// hold it to the list.
func Known(word string) bool {
	switch word {
	case Phone, Tablet, Computer, Unknown:
		return true
	}
	return false
}

// The hints, named here because this is the package that reads them.
//
// THEY ARE EXPORTED SO THAT NOBODY ELSE SPELLS THEM, which is `geo`'s argument
// for `HeaderForwardedFor` exactly: a test that builds such a request is not a
// second reader, and a raw literal in its source is indistinguishable from one.
const (
	HeaderMobile   = "Sec-CH-UA-Mobile"
	HeaderPlatform = "Sec-CH-UA-Platform"

	// HeaderReported is the page's own answer, for the browsers that send no
	// hint. See `ui/app/api.js`, and the paragraph in the package comment for
	// why it has to exist at all.
	HeaderReported = "X-Schooling-Device"
)

/*
The operating systems that are handsets rather than machines.

	`Sec-CH-UA-Platform` is a short, closed list defined by the specification,
	and these are the two entries on it that are not a computer. Anything else —
	Windows, macOS, Linux, Chrome OS, and whatever is added next — is a
	computer, which is the right direction for a list that grows: a new desktop
	platform lands in the bucket it belongs in, and a new handset platform lands
	in the wrong one and is one line to fix.
*/
var handsets = map[string]bool{"android": true, "ios": true, "ipados": true}

// Of works out what a request came from.
//
// THE HINT BEATS THE HEADER, and the order is the whole of the policy: the hint
// is written by the browser and the header is written by the page. Both are
// ultimately the caller's, and one of them is at least not something a page
// author chose.
func Of(r *http.Request) string {
	if r == nil {
		return Unknown
	}

	/* `?1` AND `?0` ARE THE WHOLE SYNTAX. The header is a structured-fields
	   boolean and has exactly those two values; anything else is not a hint
	   this understands and is treated as absent rather than guessed at. */
	switch strings.TrimSpace(r.Header.Get(HeaderMobile)) {
	case "?1":
		return Phone
	case "?0":
		/* NOT MOBILE IS NOT THE SAME AS A COMPUTER. Chromium sends `?0` for an
		   Android tablet and for an iPad as well as for a laptop, so the
		   platform is what splits them — and with no platform to read, this
		   says so instead of choosing the likelier one. A tablet counted as a
		   computer is a row that looks right and is not. */
		platform := strings.ToLower(strings.Trim(
			strings.TrimSpace(r.Header.Get(HeaderPlatform)), `"`))
		switch {
		case platform == "":
			return Unknown
		case handsets[platform]:
			return Tablet
		default:
			return Computer
		}
	}

	// And the page's own answer, for everybody else. Bounded to the four words:
	// this is a column a client can write into, and `Known` is what stops it
	// being a column a client can write anything into.
	if said := strings.ToLower(strings.TrimSpace(r.Header.Get(HeaderReported))); Known(said) {
		return said
	}
	return Unknown
}

type ctxKey int

const ctxDevice ctxKey = iota

// FromContext answers what this request came from.
//
// IT NEVER ANSWERS EMPTY, which is `geo.FromContext`'s rule and for its reason:
// a handler reached without the middleware in front of it gets `Unknown`, which
// is true, rather than an empty string that fails a constraint three layers
// down in an INSERT whose message says nothing about a middleware.
func FromContext(ctx context.Context) string {
	if what, ok := ctx.Value(ctxDevice).(string); ok && what != "" {
		return what
	}
	return Unknown
}

// Kind works the device out once per request and puts it in the context.
//
// ONCE, AND NOT WHERE IT IS USED, which is the argument `geo.Country` makes:
// several places want this — the arrival, a sign-up, every student event — and
// working it out in each would be several places for the rule to be different.
func Kind() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			next.ServeHTTP(w, r.WithContext(
				context.WithValue(r.Context(), ctxDevice, Of(r))))
		})
	}
}
