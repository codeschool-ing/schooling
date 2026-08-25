package ui

import (
	"embed"
	"io/fs"
	"net/http"
	"strings"
)

/* The platform's own front door, at the bare platform domain.

   # THE ADDRESS THAT MEANT NOTHING

   `console.` is the console, `my.` is a student's own place, `code.` and
   `math.` are schools — and the apex fell through to the school mux, where
   `tenant.Resolve` correctly answered that no school lives there. Correct and
   useless: the one address somebody types when they have heard the name and
   nothing else was the one address that said nothing.

   # IT IS A SIBLING OF THE OTHERS AND NOT A MODE OF ONE

   Serving the study interface here is the mistake `mine.go` exists to
   describe: it boots by asking for its school, its catalogue and its tracks,
   none of which exist at this address, and it does not crash — it renders, with
   the markup's default brand over an empty school. Serving `my.`'s tree here
   would be the mirror of it, and that file already says why not: "a personal
   address that greeted an anonymous visitor with a directory would have stopped
   being personal".

   The directory belongs here. That is the whole of what this tree is.

   # AND IT SHARES WHAT THERE IS NO EXCUSE TO COPY

   `assets/base.css`, the faces and the i18n runtime come from the study
   interface's embed, the same bytes, exactly as the console and `my.` take
   them. Its own `front.css` and its own Portuguese are here.

   # WHAT IT IS NOT

   No session, no sign-in, no account. Signing in is a school's: the school
   knows who its students are and the school is the public website (N-04). This
   address introduces them and gets out of the way — which is also why it is the
   only interface on this platform that asks to be indexed.
*/

//go:embed front
var front embed.FS

// Front serves the platform's front door.
//
// The caching rule is `Handler`'s, for `Handler`'s reason: with no build step
// there are no hashed filenames, so every file revalidates and the validator is
// the build. An unstamped build offers no validator at all rather than offering
// `dev`, which every unstamped build shares.
func Front(version string) http.Handler {
	shell, err := front.ReadFile("front/index.html")
	if err != nil {
		// A compile-time fact; this cannot happen at run time.
		panic("ui: the embedded front door cannot be read: " + err.Error())
	}

	// `front/` is stripped so that `/app/main.js` reaches `front/app/main.js`,
	// which keeps the served paths free of a directory that only exists to give
	// `go:embed` something to point at.
	own, err := fs.Sub(front, "front")
	if err != nil {
		panic("ui: the embedded front door has no front directory: " + err.Error())
	}
	here := http.FileServerFS(own)
	shared := http.FileServerFS(files)

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
		/* `assets/` IS THIS TREE'S FIRST AND THE STUDY INTERFACE'S SECOND — the
		   console's arrangement and `my.`'s, for their reason. `front.css` and
		   this place's own dictionary are here; `base.css`, the faces and the
		   i18n runtime are the shared ones. Asking here first and falling back
		   means neither side has to know which files the other has.

		   NOT `app/` THOUGH: those are the study interface's screens and they
		   assume a school, which is the exact mistake this file is about. */
		case strings.HasPrefix(path, "assets/"):
			if stamp(w, r) {
				return
			}
			if _, err := fs.Stat(own, path); err == nil {
				here.ServeHTTP(w, r)
				return
			}
			shared.ServeHTTP(w, r)

		case strings.HasPrefix(path, "app/"):
			if stamp(w, r) {
				return
			}
			here.ServeHTTP(w, r)

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
