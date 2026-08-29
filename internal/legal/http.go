package legal

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// The two documents over HTTP.
//
// THEY ARE NOT SCHOOL-SCOPED AND THEY ARE NOT BEHIND A SESSION. A privacy
// policy that only a signed-in student could read would be a privacy policy
// nobody can read before deciding whether to sign up — which is the moment it
// exists for. It is the same document in every school, because there is one
// platform and one company behind it.

type Handler struct {
	/* numbers is what the documents state about this platform that is not
	   written in them — today, one: the withdrawal window. It is a function
	   because `billing.WithdrawalDays` is a declared parameter and can move
	   while this process runs, and a document rendered from a number captured
	   at start-up would publish yesterday's promise. */
	numbers func(ctx context.Context) Numbers
}

/*
NewHandler is the two documents.

	A NIL `numbers` PUBLISHES THE STATUTORY MINIMUM rather than a document with
	a hole in it. It is a wiring mistake either way; what makes this the right
	end of it is that the number is a promise to a consumer, and the safe
	direction of a wrong promise is the one where the platform owes more than it
	said. `billing.WithdrawalDays.Fallback` is seven, which is what the law
	gives — see `defaults`.
*/
func NewHandler(numbers func(ctx context.Context) Numbers) *Handler {
	return &Handler{numbers: numbers}
}

/*
statutoryMinimum is the seven days art. 49 of the Código de Defesa do Consumidor
gives for a purchase made at a distance.

	IT IS NOT A COPY OF `billing.WithdrawalDays`, and the distinction is the
	whole reason it may live here. That one is what this PLATFORM offers, which
	is a decision and can be more; this is what the LAW guarantees, which is a
	fact about Brazil and is already written out in words in both documents for
	the same reason. `legal` may not import `billing` (X-02) and does not need
	to: what it needs is the floor, and the floor is not the platform's to set.

	It is used in one place — a handler nobody wired — where the alternative is
	publishing "0 dias" to a consumer.
*/
const statutoryMinimum = 7

// defaults is what a document states when nothing was wired. See NewHandler.
func defaults() Numbers { return Numbers{WithdrawalDays: statutoryMinimum} }

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/legal/{document}", h.document)
}

func (h *Handler) document(w http.ResponseWriter, r *http.Request) {
	doc, err := Read(r.PathValue("document"), locale(r))
	if errors.Is(err, ErrNoSuchDocument) {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "there is no such document")
		return
	}
	if err != nil {
		// A document that will not parse is a build-time mistake that reached
		// production: the checker below runs over every one of them in CI, so
		// this is the path that should be unreachable. It says so rather than
		// answering an empty policy.
		web.LoggerFrom(r.Context()).Error("reading a legal document",
			"error", err, "document", r.PathValue("document"))
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}

	numbers := defaults()
	if h.numbers != nil {
		numbers = h.numbers(r.Context())
	}
	web.JSON(w, http.StatusOK, doc.With(numbers))
}

// locale is the same reading as the catalogue's, so a lesson and a policy are
// asked for in the same language by the same query string.
func locale(r *http.Request) string {
	l := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("lang")))
	if l == "" || len(l) > 8 || strings.ContainsAny(l, " /?&") {
		return Fallback
	}
	return l
}
