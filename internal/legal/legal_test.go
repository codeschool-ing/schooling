package legal_test

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
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
	legal.NewHandler().Routes(mux)

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
	legal.NewHandler().Routes(mux)

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
	legal.NewHandler().Routes(mux)

	w := httptest.NewRecorder()
	mux.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/api/v1/legal/privacy", nil))

	if body := w.Body.String(); strings.Contains(body, "covers") ||
		strings.Contains(body, "ledger_entries") || strings.Contains(body, "account_visitors") {
		t.Error("the answer names the tables the policy accounts for; that list is a check " +
			"on ourselves and not something a student asked to read")
	}
}

// THE PLACEHOLDERS ARE FINDABLE. Four things in these documents are somebody
// else's decision — the company, the jurisdiction, the refund window, the
// notice before a price change — and they are marked so that the day somebody
// answers them, finding every place they belong is a search rather than a
// re-read.
//
// This test asserts they are still there. When they are filled in, it is the
// test that has to be deleted deliberately, which is the point: a placeholder
// that quietly survives publication is how a policy goes out with a blank in it.
func TestWhatIsStillUndecidedIsMarkedInEveryVersion(t *testing.T) {
	for _, name := range legal.Names() {
		for _, locale := range legal.Locales(name) {
			doc, err := legal.Read(name, locale)
			if err != nil {
				t.Fatal(err)
			}
			if !strings.Contains(doc.Body, "\n> **") && !strings.HasPrefix(doc.Body, "> **") {
				t.Errorf("%s in %s carries no `> **…**` block. Every version of a document "+
					"has to mark the same open questions, or one language publishes a "+
					"decision the other still calls undecided — and when they are all "+
					"answered, this test is deleted on purpose rather than left to pass "+
					"on a stray quote", name, locale)
			}
		}
	}
}
