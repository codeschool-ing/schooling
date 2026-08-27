// Package web is the shared HTTP plumbing: the middleware chain, the two ways
//
// of writing a response, and the context values everything else reads.
//
// It imports nothing from this repository, and a test enforces that. Whatever
// ends up here is available to every module, so anything with an opinion about
// the product does not belong.
package web

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"log/slog"
	"net/http"
	"runtime/debug"
	"strings"
	"time"
)

// Middleware is a decorator over a handler. Chain applies them outside in, so
// the first listed is the outermost and sees the request first.
type Middleware func(http.Handler) http.Handler

func Chain(h http.Handler, m ...Middleware) http.Handler {
	for i := len(m) - 1; i >= 0; i-- {
		h = m[i](h)
	}
	return h
}

/* ---------- responses ----------

   Two shapes and no third. A success carries whatever the handler decided; a
   failure carries a machine-readable code and a sentence written for a person.
   The nesting under `error` is deliberate — it means a client can tell a
   failure from a success without knowing which route it called. */

type failure struct {
	Error failureBody `json:"error"`
}

type failureBody struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// Error codes. They are part of the API: a client branches on these, never on
// the message, which is prose and will be reworded.
const (
	CodeNotFound     = "not_found"
	CodeUnauthorized = "unauthorized"
	CodeInternal     = "internal"
)

func JSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if body == nil {
		return
	}
	/* The status line is already sent, so a failure here cannot become a 500 —
	   the client will see a truncated body instead. Logging it is the only
	   honest thing left, and dropping it silently is exactly the habit this
	   project has decided against. */
	if err := json.NewEncoder(w).Encode(body); err != nil {
		LoggerFrom(context.Background()).Error("writing a response body", "error", err)
	}
}

func Fail(w http.ResponseWriter, status int, code, message string) {
	JSON(w, status, failure{failureBody{Code: code, Message: message}})
}

// Locale takes the language off the query string, falling back to English.
//
// A QUERY PARAMETER AND NOT Accept-Language. The language a student chose is a
// setting they can change, not a property of the browser they happen to be
// using — and a page that reads differently depending on which machine opened
// it is the kind of thing nobody reports because nobody believes it.
//
// IT LIVES HERE BECAUSE TWO MODULES ASK. The catalogue serves prose per
// language and practice serves the same question per language; two copies of
// this would be two chances to disagree about what `lang=PT`, `lang=` or
// `lang=pt-BR` means — and a disagreement would show as one screen translated
// and the next one not.
func Locale(r *http.Request) string {
	l := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("lang")))
	if l == "" || len(l) > 8 || strings.ContainsAny(l, " /?&") {
		return "en"
	}
	return l
}

// Declared is the language the BROWSER says it reads, or `unknown`.
//
// IT IS NOT `Locale` ABOVE AND MUST NOT BE CONFUSED WITH IT. That one answers
// "which language do I serve this page in", and its right fallback is English,
// because a page has to be in some language. This one answers "which language
// does this person read", which is a fact about a person and has a fourth
// possible answer: we do not know. Falling back to English here would record
// every visitor who sent no header as an English reader — a plausible number,
// on every row, which is the shape of wrong this repository keeps finding.
//
// THE FIRST TAG IS ENOUGH. What this is used for is grouping a report; the
// weighted list underneath answers a question nobody asks.
func Declared(r *http.Request) string {
	first, _, _ := strings.Cut(r.Header.Get("Accept-Language"), ",")
	first, _, _ = strings.Cut(first, ";")
	first = strings.ToLower(strings.TrimSpace(first))
	if first == "" || len(first) > 35 {
		// 35 is the longest well-formed language tag there is; anything past
		// it is not a tag, it is a column somebody is filling in for us.
		return "unknown"
	}
	return first
}

/* ---------- context ---------- */

type ctxKey int

const (
	ctxRequestID ctxKey = iota
	ctxLogger
)

func RequestIDFrom(ctx context.Context) string {
	id, _ := ctx.Value(ctxRequestID).(string)
	return id
}

// LoggerFrom answers the request's logger, or the default one. It never
// answers nil, so no caller has to check.
func LoggerFrom(ctx context.Context) *slog.Logger {
	if l, ok := ctx.Value(ctxLogger).(*slog.Logger); ok {
		return l
	}
	return slog.Default()
}

/* ---------- middleware ---------- */

// RequestID gives every request an id and echoes it back, so a line in a log
// and a report from a person can be joined without guessing.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-Id")
		if id == "" {
			b := make([]byte, 8)
			if _, err := rand.Read(b); err != nil {
				// A request without an id is worth serving; one that fails
				// because the random source blinked is not.
				id = "unidentified"
			} else {
				id = hex.EncodeToString(b)
			}
		}
		w.Header().Set("X-Request-Id", id)
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), ctxRequestID, id)))
	})
}

// Hooks is the prefix under which a provider posts back to us.
//
// It lives here rather than beside the handlers because it is the LOGGER that
// has to know about it, and the logger is here.
const Hooks = "/hooks/"

/*
Loggable is a path with anything past a hook's own name taken out of it.

	NOTHING UNDER THIS PREFIX CARRIES A SECRET TODAY, AND THIS STAYS. That is a
	decision rather than an oversight, so here is the whole of it.

	The mail hook's credential used to be a segment of its path, because the
	provider was believed to offer nothing better. It offers HTTP Basic, and the
	credential moved to a header — which is the fix, since a header is in no
	request log, no address bar and no screenshot. This middleware writes
	`r.URL.Path` on every request, so while that secret was in the path it went
	to Cloud Logging in plain text on the first delivery and stayed for as long
	as logs are kept: the one measure protecting the endpoint, filed as the one
	artefact giving it away.

	THE REDACTION OUTLIVES THE PROBLEM IT WAS WRITTEN FOR. The payment gateway's
	webhooks arrive under this prefix next, from a provider whose arrangements
	nobody has read yet; the guarantee costs one string comparison; and the
	change that removed it would be the one somebody later puts a secret back
	into a path under, with nothing catching it.

	What survives is the first two segments — enough to see that a delivery
	arrived and to answer "is this endpoint being hit at all". IT REDACTS THE
	WHOLE TAIL rather than a segment it recognises as secret, because
	recognising one is guessing.
*/
func Loggable(path string) string {
	if !strings.HasPrefix(path, Hooks) {
		return path
	}
	// "/hooks/mail/anything" -> ["", "hooks", "mail", "anything"]
	parts := strings.SplitN(path, "/", 4)
	if len(parts) < 4 || parts[3] == "" {
		return path
	}
	return "/" + parts[1] + "/" + parts[2] + "/..."
}

// Logger puts a logger carrying the request id into the context and writes one
// line per request when it finishes.
func Logger(base *slog.Logger) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			started := time.Now()
			log := base.With("request_id", RequestIDFrom(r.Context()))
			rec := &recorder{ResponseWriter: w, status: http.StatusOK}

			next.ServeHTTP(rec, r.WithContext(context.WithValue(r.Context(), ctxLogger, log)))

			log.Info("request",
				"method", r.Method,
				"path", Loggable(r.URL.Path),
				"host", r.Host,
				"status", rec.status,
				"ms", time.Since(started).Milliseconds(),
			)
		})
	}
}

// Recover turns a panic into a 500 and a stack in the log, rather than a
// dropped connection the client cannot tell from a network fault.
func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			rec := recover()
			if rec == nil {
				return
			}
			LoggerFrom(r.Context()).Error("panic",
				"error", rec,
				"method", r.Method,
				"path", Loggable(r.URL.Path),
				"stack", string(debug.Stack()),
			)
			Fail(w, http.StatusInternalServerError, CodeInternal, "something went wrong")
		}()
		next.ServeHTTP(w, r)
	})
}

// NoStore keeps per-student responses out of any cache. A handler that has a
// reason to be cached says so itself, and says why.
func NoStore(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}

// recorder remembers the status so it can be logged after the fact.
type recorder struct {
	http.ResponseWriter
	status int
	wrote  bool
}

func (r *recorder) WriteHeader(status int) {
	if r.wrote {
		return
	}
	r.wrote = true
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func (r *recorder) Write(b []byte) (int, error) {
	r.wrote = true
	return r.ResponseWriter.Write(b)
}
