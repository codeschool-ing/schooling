package web_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

func TestDeclaredReadsTheBrowsersLanguage(t *testing.T) {
	for _, c := range []struct {
		header string
		want   string
	}{
		{"pt-BR,pt;q=0.9,en;q=0.8", "pt-br"},
		{"pt", "pt"},
		{"  DE  ", "de"},
		{"en-GB;q=1.0", "en-gb"},

		// THE ANSWER WHEN THERE IS NONE IS `unknown` AND NOT `en`. A browser
		// that sends no header is a browser we know nothing about, and
		// recording it as English is a plausible value on a real row — which
		// is worse than an honest gap, because nothing downstream can tell it
		// from a person who really does read English.
		{"", "unknown"},
		{"   ", "unknown"},
		{",", "unknown"},

		// Not a tag: a column somebody is filling in for us. The longest
		// well-formed language tag there is fits in 35 characters.
		{"pt-BR-and-then-a-great-deal-more-text-besides", "unknown"},
	} {
		r := httptest.NewRequest(http.MethodPost, "/api/v1/sign-up", nil)
		if c.header != "" {
			r.Header.Set("Accept-Language", c.header)
		}
		if got := web.Declared(r); got != c.want {
			t.Errorf("Declared(%q) = %q, want %q", c.header, got, c.want)
		}
	}
}

/*
THE TWO FUNCTIONS ANSWER DIFFERENT QUESTIONS, AND THIS IS THE DEFECT.

	`accounts.locale` was the literal string `unknown` on every account ever
	created, because sign-up built its `NewAccount` without one. The obvious fix
	was `web.Locale(r)`, which was already there and already used everywhere —
	and it would have been worse than the bug: sign-up sends no `?lang=` at all,
	so it falls back to English and would have written `en` against every
	account, on every row, forever.

	A missing value is a hole a report can see. A confident wrong one is not.
*/
func TestTheLanguageServedIsNotTheLanguageDeclared(t *testing.T) {
	// A Brazilian browser signing up, exactly as the interface does it: no
	// `lang` on the query string, because sign-up does not send one.
	r := httptest.NewRequest(http.MethodPost, "/api/v1/sign-up", nil)
	r.Header.Set("Accept-Language", "pt-BR,pt;q=0.9")

	if got := web.Locale(r); got != "en" {
		t.Errorf("Locale = %q, want %q — it answers which language to SERVE, and a "+
			"page has to be in one", got, "en")
	}
	if got := web.Declared(r); got != "pt-br" {
		t.Errorf("Declared = %q, want %q — it answers which language this person "+
			"READS, which is what a report about people is asking", got, "pt-br")
	}
}

func TestLocaleServesEnglishWhenNobodyAsked(t *testing.T) {
	for _, c := range []struct {
		query string
		want  string
	}{
		{"?lang=pt", "pt"},
		{"?lang=PT", "pt"},
		{"?lang=pt-BR", "pt-br"},
		{"", "en"},
		{"?lang=", "en"},
		{"?lang=a+language+nobody+has", "en"},
	} {
		r := httptest.NewRequest(http.MethodGet, "/api/v1/lessons"+c.query, nil)
		if got := web.Locale(r); got != c.want {
			t.Errorf("Locale(%q) = %q, want %q", c.query, got, c.want)
		}
	}
}
