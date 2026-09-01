package main

import "testing"

/* What the browser fetches on its own, which is the only question this tool
   asks. Every case below is a shape that has cost somebody their users'
   privacy somewhere, written out so that the line between a subresource and a
   navigation is a thing this repository can point at. */

// found is the hosts a source would have the browser talk to, in order.
func found(t *testing.T, source string) []string {
	t.Helper()
	var out []string
	for _, f := range fetchesIn(source) {
		if host := hostOf.FindStringSubmatch(f.url); host != nil {
			out = append(out, host[1])
		}
	}
	return out
}

func same(t *testing.T, source string, want ...string) {
	t.Helper()
	got := found(t, source)
	if len(got) != len(want) {
		t.Fatalf("found %q, want %q", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("found %q, want %q", got, want)
		}
	}
}

// THE ONE THAT WAS THERE. A YouTube thumbnail is an `<img src>`, which is
// fetched with the page and before any click — `ui/app/screens/common.js`
// carried this under a comment saying a screen asks YouTube for nothing.
func TestAThumbnailIsAFetch(t *testing.T) {
	same(t, `'<img src="https://i.ytimg.com/vi/' + id + '/hqdefault.jpg" alt="" />'`,
		"i.ytimg.com")
}

// THE SHAPES THAT COST OTHER PEOPLE THEIR USERS. A font, a script, a
// stylesheet, an icon: none of them looks like a decision in a diff.
func TestTheUsualWaysAPageStartsTalkingToAThirdParty(t *testing.T) {
	same(t, `<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter">`,
		"fonts.googleapis.com")
	same(t, `<script src="https://cdn.example.net/analytics.js"></script>`,
		"cdn.example.net")
	same(t, `@import "https://cdn.example.net/reset.css";`, "cdn.example.net")
	same(t, `@font-face { src: url(https://fonts.gstatic.com/s/inter.woff2) format('woff2'); }`,
		"fonts.gstatic.com")
	same(t, `const r = await fetch("https://api.example.net/track");`, "api.example.net")

	// PROTOCOL-RELATIVE IS STILL ABSOLUTE, and it is the form people forget:
	// it inherits the page's scheme and none of its host.
	same(t, `<script src="//cdn.example.net/x.js"></script>`, "cdn.example.net")
}

/*
A LINK IS NOT A FETCH, and reading it as one would fail on the two pages most
likely to have external links: the terms and the privacy policy.

	`<a href>` is a person choosing to go somewhere. `<link href>` is the browser
	being told to fetch a stylesheet before anybody has chosen anything. They
	share an attribute and nothing else, so the tag decides.
*/
func TestALinkSomebodyClicksIsNotAFetch(t *testing.T) {
	same(t, `<p>See <a href="https://example.tld/terms">the terms</a>.</p>`)
	same(t, `<a href="//example.tld/x">and protocol-relative</a>`)
	same(t, `'<a href="' + esc(url) + '">' + esc(name) + '</a>'`)
}

// AND WHAT IS OURS STAYS OURS. Every path this interface actually uses is
// relative or rooted, and none of it may be reported — a tool that cried on
// `/assets/app.css` would be turned off within the day.
func TestOurOwnPathsAreNotReported(t *testing.T) {
	same(t, `<link rel="stylesheet" href="/assets/app.css">`)
	same(t, `<script type="module" src="./app/main.js"></script>`)
	same(t, `<img src="../images/diagram.png" alt="">`)
	same(t, `const r = await fetch('/api/v1/checkout', { method: 'POST' });`)
	same(t, `.mark { background: url("data:image/svg+xml;base64,PHN2Zz4=") }`)
}

// THE DECLARED EXCEPTION IS A HOST AND A REASON. A bare host would be a rule
// with its argument deleted, and the next person could not disagree with it.
func TestTheAllowedListCarriesItsReasons(t *testing.T) {
	if len(allowed) == 0 {
		t.Fatal("nothing is allowed, which would mean the exception was deleted rather than argued")
	}
	for host, why := range allowed {
		if len(why) < 40 {
			t.Errorf("%s is allowed with %q, which is a host and not a reason", host, why)
		}
	}
}
