package ui

import (
	"embed"
	"io/fs"
	"net/http"
	"strings"
)

/* The student's own place, at `my.<platform domain>`.

   # IT IS A SIBLING OF THE STUDY INTERFACE AND NOT A MODE OF IT

   The study interface boots by asking for its school, its catalogue and its
   tracks, and none of those exist at this address. Serving it here does not
   crash — all three fetches carry a `.catch`, so the page renders — and that is
   the problem: `source.school` stays null, the brand paint is guarded and never
   runs, and the markup's own default stands. That default is `codeschool.ing`,
   the predecessor's name, on the platform's own address, over an empty school.

   Teaching that shell a second mode would have put the question "and with no
   school?" into every screen written from now on, with a silent failure mode —
   a screen that renders wrongly rather than not at all, which is exactly the
   paragraph above. So this is its own tree, its own routes and its own boot,
   the way the console is.

   # AND IT SHARES WHAT THERE IS NO EXCUSE TO COPY

   `assets/base.css` and the faces come from the study interface's embed, the
   same bytes, exactly as the console takes them. That stylesheet already exists
   three times across this organisation with a comment at the top asking whoever
   edits one to copy it to the others; a fourth inside one binary would be
   indefensible.

   IT IS IN THIS PACKAGE RATHER THAN A NEW ONE for the same reason: both trees
   are the student's, both want the same tokens and the same type, and a second
   package would have to reach for `ui.Files` to get them. The console does
   reach, because it is staff software in another vocabulary. This is not.

   # WHAT IT IS NOT

   No catalogue, no fragment router worth the name, no offline bundle. What
   lives at this address is what belongs to the PERSON rather than to a school
   (N-01) — today the review queue that crosses schools, and the account, the
   certificates and the subscription when they follow it here.
*/

//go:embed my
var mine embed.FS

// Mine serves the student's own place.
//
// The caching rule is `Handler`'s, for `Handler`'s reason: with no build step
// there are no hashed filenames, so every file revalidates and the validator is
// the build. An unstamped build offers no validator at all rather than offering
// `dev`, which every unstamped build shares.
func Mine(version string) http.Handler {
	shell, err := mine.ReadFile("my/index.html")
	if err != nil {
		// A compile-time fact; this cannot happen at run time.
		panic("ui: the embedded student's place cannot be read: " + err.Error())
	}

	// `my/` is stripped so that `/app/queue.js` reaches `my/app/queue.js`, which
	// keeps the served paths free of a directory that only exists to give
	// `go:embed` something to point at.
	own, err := fs.Sub(mine, "my")
	if err != nil {
		panic("ui: the embedded student's place has no my directory: " + err.Error())
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
		/* `assets/` IS THIS TREE'S FIRST AND THE STUDY INTERFACE'S SECOND —
		   the console's arrangement, for the console's reason. `mine.css` and
		   this place's own dictionary are here; `base.css`, the faces and the
		   i18n runtime are the shared ones. Asking here first and falling back
		   means neither side has to know which files the other has.

		   NOT `app/` THOUGH: those are the study interface's screens, and they
		   assume a school. Serving them here is the exact mistake this whole
		   file exists to avoid. */
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
