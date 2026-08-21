package console

import (
	"embed"
	"io/fs"
	"net/http"
	"strings"

	"github.com/codeschool-ing/schooling/ui"
)

/* The console's own interface, carried into the same binary.

   IT IS A SIBLING OF `ui/` AND NOT A COPY OF IT. The study interface is mostly
   `portal-frontend`'s files unchanged; this is not a copy of anything, so it
   gets its own tree, its own routes and none of the assumptions that make sense
   for a school — no offline bundle, no fragment router worth the name, no
   catalogue.

   IT SHARES ONE FILE ON PURPOSE: `assets/base.css`, served from `ui.Files`.
   That stylesheet already exists three times across this organisation, with a
   comment at the top asking whoever edits one to copy it to the others; a
   fourth copy inside the same binary would be indefensible. Two visual systems
   for one product is also how a console starts looking like a different
   company's software.

   THE SHELL IS NOT BEHIND THE STAFF GATE, and `cmd/api` is where that is
   arranged: a console nobody can open without a role also cannot tell somebody
   they need one. What is behind the gate is `/console/api/v1/`, and the shell's
   first request to it is how the screen finds out who — if anybody — is here. */

//go:embed ui
var screen embed.FS

// Interface serves the console's screen.
//
// The caching rule is the study interface's, for the study interface's reason:
// with no build step there are no hashed filenames, so every file revalidates
// and the validator is the build. An unstamped build offers no validator at
// all rather than offering `dev`, which every unstamped build shares — a
// browser would hold the first file it ever saw and revalidate it happily
// against every later one.
func Interface(version string) http.Handler {
	shell, err := screen.ReadFile("ui/index.html")
	if err != nil {
		// A compile-time fact; this cannot happen at run time.
		panic("console: the embedded interface cannot be read: " + err.Error())
	}

	// `ui/` is stripped so that `/app/console.js` reaches `ui/app/console.js`,
	// which keeps the served paths free of a directory that only exists to give
	// `go:embed` something to point at.
	own, err := fs.Sub(screen, "ui")
	if err != nil {
		panic("console: the embedded interface has no ui directory: " + err.Error())
	}
	mine := http.FileServerFS(own)
	shared := http.FileServerFS(ui.Files)

	etag := `"` + version + `"`
	stamp := func(w http.ResponseWriter, r *http.Request) bool {
		if version == "" {
			w.Header().Set("Cache-Control", "no-store")
			return false
		}
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("ETag", etag)
		if match := r.Header.Get("If-None-Match"); match != "" && strings.Contains(match, etag) {
			w.WriteHeader(http.StatusNotModified)
			return true
		}
		return false
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := strings.TrimPrefix(r.URL.Path, "/")

		switch {
		// The shared stylesheet, out of the study interface's embed. Only
		// `assets/` — the console has no business serving `app/`, which is a
		// student's screens.
		case strings.HasPrefix(path, "assets/"):
			if stamp(w, r) {
				return
			}
			shared.ServeHTTP(w, r)

		case strings.HasPrefix(path, "app/"):
			if stamp(w, r) {
				return
			}
			mine.ServeHTTP(w, r)

		case path == "", path == "index.html":
			if stamp(w, r) {
				return
			}
			w.Header().Set("Content-Type", "text/html; charset=utf-8")
			_, _ = w.Write(shell)

		default:
			// NO CATCH-ALL, for the study interface's reason: a shell that
			// rendered itself at any address leaves somebody staring at an
			// empty screen wondering what they typed.
			http.NotFound(w, r)
		}
	})
}
