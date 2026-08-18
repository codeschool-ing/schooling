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
				"path", r.URL.Path,
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
				"path", r.URL.Path,
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
