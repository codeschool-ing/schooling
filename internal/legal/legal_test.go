package legal_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/legal"
)

// EVERY DOCUMENT LOADS, IN EVERY LANGUAGE IT CLAIMS. A policy that fails to
// parse is a blank page where a legal obligation should be, and it would fail
// at the moment somebody went looking for it rather than at the moment somebody
// broke it.
func TestEveryDocumentParsesInEveryLanguageItHas(t *testing.T) {
	for _, name := range legal.Names() {
		locales := legal.Locales(name)
		if len(locales) == 0 {
			t.Errorf("%s exists in no language at all", name)
		}

		for _, locale := range locales {
			doc, err := legal.Read(name, locale)
			if err != nil {
				t.Errorf("%s in %s: %v", name, locale, err)
				continue
			}
			if doc.Locale != locale {
				t.Errorf("%s in %s came back as %s", name, locale, doc.Locale)
			}
			if doc.Title == "" || doc.Body == "" {
				t.Errorf("%s in %s is missing its title or its body", name, locale)
			}
			if _, err := time.Parse(time.DateOnly, doc.Effective); err != nil {
				t.Errorf("%s in %s took effect on %q, which is not a date", name, locale, doc.Effective)
			}
		}
	}
}

// BOTH DOCUMENTS EXIST IN BOTH LANGUAGES. Portuguese and English are what this
// platform claims to speak, and a policy published in one of them is a policy
// half the students cannot read — which is worse than a missing button, because
// it is the document that tells them what is held about them.
func TestBothDocumentsExistInBothLanguages(t *testing.T) {
	for _, name := range legal.Names() {
		have := map[string]bool{}
		for _, locale := range legal.Locales(name) {
			have[locale] = true
		}
		for _, want := range []string{"en", "pt"} {
			if !have[want] {
				t.Errorf("%s has no %s version", name, want)
			}
		}
	}
}

// A LANGUAGE WE DO NOT SPEAK GETS ENGLISH, not nothing. English is the source
// language, so it is the version that always exists — and a blank page for
// somebody whose browser is set to Japanese would be an unpublished policy for
// that person.
func TestALanguageWeDoNotSpeakFallsBackRatherThanFailing(t *testing.T) {
	doc, err := legal.Read(legal.Privacy, "ja")
	if err != nil {
		t.Fatalf("asking for the policy in a language we do not have: %v", err)
	}
	if doc.Locale != "en" {
		t.Errorf("it came back in %s; the fallback is English and it should say so", doc.Locale)
	}
}

// A NAME WE DO NOT PUBLISH IS A MISS. The list is closed rather than "whatever
// is in the directory", so a file that lands there by accident is not a
// document this serves — and a path that tries to leave the directory is not
// even a name.
func TestOnlyTheDocumentsWePublishCanBeRead(t *testing.T) {
	for _, name := range []string{
		"", "readme", "../privacy", "../../etc/passwd", "privacy.en", "TERMS",
	} {
		if _, err := legal.Read(name, "en"); !errors.Is(err, legal.ErrNoSuchDocument) {
			t.Errorf("%q was read as a document: %v", name, err)
		}
	}
}

// AND A LOCALE CANNOT ESCAPE EITHER. The locale reaches a file path, so a
// locale that is a path is the other half of the same hole.
func TestALocaleCannotReachOutOfTheDirectory(t *testing.T) {
	doc, err := legal.Read(legal.Privacy, "../../../etc/passwd")
	if err != nil {
		t.Fatalf("a nonsense locale should fall back, not fail: %v", err)
	}
	if doc.Locale != "en" || !strings.Contains(doc.Title, "Privacy") {
		t.Errorf("a locale that is a path gave back %q in %s", doc.Title, doc.Locale)
	}
}

// NEITHER DOCUMENT IS BEHIND A SESSION OR A SCHOOL. A privacy policy only a
// signed-in student can read is one nobody can read before deciding whether to
// sign up, which is the moment it exists for.
func TestThePoliciesAreReadableByAnybody(t *testing.T) {
	mux := http.NewServeMux()
	legal.NewHandler(sevenDays).Routes(mux)

	for _, name := range legal.Names() {
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/api/v1/legal/"+name+"?lang=pt", nil))

		if w.Code != http.StatusOK {
			t.Errorf("%s answered %d to a stranger with no school header", name, w.Code)
			continue
		}

		var doc legal.Document
		if err := json.Unmarshal(w.Body.Bytes(), &doc); err != nil {
			t.Errorf("%s did not answer a document: %v", name, err)
			continue
		}
		if doc.Locale != "pt" || doc.Body == "" {
			t.Errorf("%s answered %q in %s with %d characters of body",
				name, doc.Title, doc.Locale, len(doc.Body))
		}
	}
}

// A DOCUMENT NOBODY PUBLISHES IS A 404 rather than a 500 or an empty policy.
func TestAskingForSomethingElseIsANotFound(t *testing.T) {
	mux := http.NewServeMux()
	legal.NewHandler(sevenDays).Routes(mux)

	w := httptest.NewRecorder()
	mux.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/api/v1/legal/refunds", nil))
	if w.Code != http.StatusNotFound {
		t.Errorf("a document we do not publish answered %d", w.Code)
	}
}

// WHAT THE POLICY ACCOUNTS FOR NEVER REACHES A BROWSER. The `covers:` list is a
// check on ourselves, not a statement to a student — a policy that printed a
// list of table names would be a worse document, and this is the field that
// would do it by accident.
func TestTheTableNamesAreNotSentToAnybody(t *testing.T) {
	mux := http.NewServeMux()
	legal.NewHandler(sevenDays).Routes(mux)

	w := httptest.NewRecorder()
	mux.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/api/v1/legal/privacy", nil))

	if body := w.Body.String(); strings.Contains(body, "covers") ||
		strings.Contains(body, "ledger_entries") || strings.Contains(body, "account_visitors") {
		t.Error("the answer names the tables the policy accounts for; that list is a check " +
			"on ourselves and not something a student asked to read")
	}
}

// WHAT IS NOT FILLED IN IS FINDABLE, AND IS THE SAME IN EVERY LANGUAGE.
//
// One thing is left: the company itself — name, registration number, address,
// and where to write. It is written as `{{company.name}}` and friends rather
// than as a sentence saying it is missing, so that filling it in is a search and
// replace rather than a re-read of four files.
//
// The failure this catches is the one that search and replace actually has: it
// is done in English, the tests pass, and Portuguese still carries the token —
// which is a policy published with a blank in it, in the language half the
// students read. So the token SET has to match across languages, not merely be
// non-empty.
// sevenDays is the platform's window as `cmd/api` hands it in — a function,
// because `billing.WithdrawalDays` is a declared parameter and can move while
// the process runs. These tests are not about the parameter, so they wire the
// statutory floor and the documents read as they always have.
func sevenDays(context.Context) legal.Numbers {
	return legal.Numbers{WithdrawalDays: 7}
}

func TestWhatIsNotFilledInIsTheSameInEveryLanguage(t *testing.T) {
	for _, name := range legal.Names() {
		want := legal.Placeholders(mustRead(t, name, legal.Fallback).Body)

		for _, locale := range legal.Locales(name) {
			if locale == legal.Fallback {
				continue
			}
			got := legal.Placeholders(mustRead(t, name, locale).Body)

			if !slices.Equal(got, want) {
				t.Errorf("%s carries %v in %s and %v in %s — a placeholder filled in one "+
					"language and left in another is a document published with a blank in "+
					"it, in the version half the students read",
					name, got, locale, want, legal.Fallback)
			}
		}
	}
}

// AND THERE IS STILL SOMETHING TO FILL IN, said out loud.
//
// This test asserts the CURRENT state: the company is not known. When it is,
// this test is deleted deliberately — which is the point. A placeholder that
// quietly survives publication is how a policy goes out with a `{{…}}` in it,
// and the moment nobody is asserting that one exists is the moment nobody
// notices one does.
func TestTheCompanyIsStillAPlaceholder(t *testing.T) {
	for _, name := range legal.Names() {
		found := legal.Placeholders(mustRead(t, name, legal.Fallback).Body)
		if len(found) == 0 {
			t.Errorf("%s has no placeholders left. If the company details are real now, "+
				"delete this test on purpose and check that no `{{` survives anywhere", name)
			continue
		}
		for _, token := range found {
			if strings.HasPrefix(token, "{{company.") {
				continue
			}
			/* A TOKEN THIS PLATFORM FILLS IS NOT A PLACEHOLDER, and the two
			   look identical in the file. `{{withdrawal.days}}` is written into
			   the document at serve time from `billing.WithdrawalDays`, so it
			   never reaches a reader — which is what the test below proves, and
			   why it is the one that would notice a typo in the token name. */
			if _, fills := (legal.Numbers{}).Filled()[token]; fills {
				continue
			}
			t.Errorf("%s carries %s, which is neither one of the company details this is "+
				"waiting on nor a number this platform fills in — a new placeholder needs "+
				"a reason somebody can read", name, token)
		}
	}
}

func mustRead(t *testing.T, name, locale string) legal.Document {
	t.Helper()
	doc, err := legal.Read(name, locale)
	if err != nil {
		t.Fatalf("reading %s in %s: %v", name, locale, err)
	}
	return doc
}

/*
NOTHING REACHES A READER WITH A HOLE IN IT.

	This is the test that makes a generated number safe to put in a legal
	document. `{{withdrawal.days}}` looks exactly like `{{company.name}}` in the
	file, and the difference between them is entirely in whether something fills
	it — so a token misspelt in the Markdown, or a substitution removed from
	`Numbers`, publishes `{{withdrawal.days}}` to a consumer in the clause that
	tells them how long they have to change their mind.

	IT CHECKS THE PUBLISHED FORM AND NOT THE FILE, in every language, and what
	it allows to survive is the company details and nothing else.
*/
func TestADocumentNeverReachesAReaderUnfilled(t *testing.T) {
	numbers := legal.Numbers{WithdrawalDays: 7}

	for _, name := range legal.Names() {
		for _, locale := range legal.Locales(name) {
			published := mustRead(t, name, locale).With(numbers)

			for _, token := range legal.Placeholders(published.Body) {
				if strings.HasPrefix(token, "{{company.") {
					continue
				}
				t.Errorf("%s in %s still carries %s after publication — a reader gets that "+
					"literal text, in a document whose job is to be exact", name, locale, token)
			}
		}
	}
}

/*
AND EVERY SUBSTITUTION IS ACTUALLY USED.

	The other direction, and the one that goes wrong silently: a token renamed
	in the Markdown leaves `Numbers` filling something no document contains, and
	the test above still passes because there is nothing left to find. What
	would reach a reader then is the OLD prose, unchanged, with a number nobody
	is maintaining.
*/
func TestEveryNumberThisPlatformFillsAppearsInADocument(t *testing.T) {
	for token := range (legal.Numbers{}).Filled() {
		found := false
		for _, name := range legal.Names() {
			for _, locale := range legal.Locales(name) {
				if strings.Contains(mustRead(t, name, locale).Body, token) {
					found = true
				}
			}
		}
		if !found {
			t.Errorf("%s is filled in and no document contains it — either the token was "+
				"renamed in the Markdown, in which case the prose is now saying whatever it "+
				"said before, or this substitution is dead", token)
		}
	}
}

/*
AND THE NUMBER IN THE DOCUMENT IS THE ONE THAT WAS PASSED.

	Weak on its own and load-bearing beside the two above: they prove no hole
	survives and no filler is dead, and this proves the value that lands is the
	caller's rather than something the package decided. Together they are the
	claim — the terms of use state what `billing.WithdrawalDays` is set to, and
	cannot state anything else.
*/
func TestTheWindowInTheTermsIsTheOneItWasGiven(t *testing.T) {
	for _, days := range []int{7, 14, 30} {
		body := mustRead(t, legal.Terms, "pt").With(legal.Numbers{WithdrawalDays: days}).Body

		want := fmt.Sprintf("%d dias para desistir", days)
		if !strings.Contains(body, want) {
			t.Errorf("the terms do not say %q at a window of %d days", want, days)
		}
	}

	// AND THE STATUTE IS STILL WRITTEN OUT IN WORDS, at every value. It is not
	// ours to move, so it is not a hole — and a document that printed the
	// platform's number where it means the law's would misquote art. 49.
	body := mustRead(t, legal.Terms, "pt").With(legal.Numbers{WithdrawalDays: 30}).Body
	if !strings.Contains(body, "garante sete dias") {
		t.Error("the terms stopped saying that the law guarantees seven days — the statute " +
			"is a fact about Brazil and does not move when this platform offers more")
	}
}
